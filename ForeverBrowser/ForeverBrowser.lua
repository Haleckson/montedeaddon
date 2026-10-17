-- ForeverBrowser v1.0.1
--------------------------------------------------
-- ForeverBrowser
-- WoW Forever In-Game Database Browser
-- Interface 16001
--------------------------------------------------

ForeverBrowserVersion = "v1.0.1"
ForeverBrowserBuild225 = "2026-10-09 stabilization"
ForeverBrowserReleaseURL = "https://www.curseforge.com/wow/addons/forever-browser/files"

-- Static source indexes are session-only; saved player data remains untouched.
function ForeverBrowser_QuestRewardSources225(questID)
    local items=ForeverSourceData and ForeverSourceData.items or {}
    local cache=ForeverBrowserQuestRewardIndex225
    if not cache or cache.items~=items then
        cache={items=items,quests={}}
        for key,item in pairs(items) do
            if type(item)=="table" then
                local seen={}
                for _,source in pairs(type(item.sources)=="table" and item.sources or {}) do
                    local id=type(source)=="table" and source.type=="quest" and tonumber(source.id or source.questID)
                    if id and not seen[id] then
                        seen[id]=true cache.quests[id]=cache.quests[id] or {}
                        cache.quests[id][#cache.quests[id]+1]={id=key,item=item}
                    end
                end
            end
        end
        ForeverBrowserQuestRewardIndex225=cache
    end
    return cache.quests[tonumber(questID)] or {}
end

function ForeverBrowser_QuestRelation225(value)
    local id=tonumber(type(value)=="table" and (value.id or value.questID or value.questId) or value)
    if not id or id<=0 then return nil end
    local quests=ForeverSourceData and ForeverSourceData.quests or {}
    local record=quests[id] or quests[tostring(id)]
    return {id=id,name=(type(value)=="table" and value.name)
        or (type(record)=="table" and record.name) or ("Quest "..id)}
end

function ForeverBrowser_QuestStatusText225(id)
    local completed,inLog=ForeverBrowser_GetQuestPlayerStatus(id)
    if completed then return "Completed" end
    if inLog then return "In Progress" end
    local api=(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted) or IsQuestFlaggedCompleted
    if type(api)=="function" then
        local ok,value=pcall(api,tonumber(id))
        if ok and value==false then return "Not Completed" end
    end
    return "Completion not recorded"
end

local ADDON_NAME = "ForeverBrowser"

--------------------------------------------------
-- MAIN VARIABLES
--------------------------------------------------

local BrowserFrame = nil
local PageContent = nil
local ItemActionsAnchor = nil
local ScrollFrame = nil
local AddressBox = nil
local SuggestionFrame = nil
local NavigationFrame = nil
local NavigationButtons = {}

local CurrentURL = "forever://home"

local History = {}
local HistoryPosition = 0

local DatabaseTooltip = nil
local CompareFirstItemID = nil
local ApplyForeverTheme = nil

--------------------------------------------------
-- FOREVER SPELL DATA RESOLVER
-- Uses the same asynchronous spell-cache pattern used by
-- Forever-compatible addons. This is only a fallback when
-- generated trainer data does not already contain a name.
--------------------------------------------------

local ForeverSpellWaiting = {}
local ForeverSpellLoader = nil

local function ReadForeverSpellData(spellID)
    spellID = tonumber(spellID)

    if not spellID or spellID <= 0 then
        return nil, nil
    end

    if not Spell
        or not Spell.CreateFromSpellID
        or not C_Spell then
        return nil, nil
    end

    local okObject, spellObject =
        pcall(Spell.CreateFromSpellID, spellID)

    if not okObject or not spellObject then
        return nil, nil
    end

    local spellName = nil
    local spellIcon = nil

    if spellObject.GetSpellName then
        local okName, name =
            pcall(spellObject.GetSpellName, spellObject)

        if okName and name and tostring(name) ~= "" then
            spellName = name
        end
    end

    if C_Spell.GetSpellTexture then
        local okIcon, icon =
            pcall(C_Spell.GetSpellTexture, spellID)

        if okIcon and icon then
            spellIcon = icon
        end
    end

    return spellName, spellIcon
end

local function EnsureForeverSpellLoader()
    if ForeverSpellLoader then
        return ForeverSpellLoader
    end

    ForeverSpellLoader = CreateFrame("Frame")
    ForeverSpellLoader:RegisterEvent("SPELL_DATA_LOAD_RESULT")
    ForeverSpellLoader:SetScript(
        "OnEvent",
        function(self, event, spellID, success)
            spellID = tonumber(spellID)
            local callbacks = spellID and ForeverSpellWaiting[spellID]

            if not callbacks then
                return
            end

            ForeverSpellWaiting[spellID] = nil

            if not success then
                return
            end

            local spellName, spellIcon =
                ReadForeverSpellData(spellID)

            if not spellName and not spellIcon then
                return
            end

            for _, callback in ipairs(callbacks) do
                pcall(callback, spellName, spellIcon)
            end
        end
    )

    return ForeverSpellLoader
end

local function ResolveForeverSpellData(spellID, callback)
    spellID = tonumber(spellID)

    if not spellID or spellID <= 0 then
        return nil, nil
    end

    if not C_Spell
        or not C_Spell.IsSpellDataCached
        or not C_Spell.RequestLoadSpellData
        or not Spell
        or not Spell.CreateFromSpellID then
        return nil, nil
    end

    local cached = false
    local okCached, cachedResult =
        pcall(C_Spell.IsSpellDataCached, spellID)

    if okCached and cachedResult then
        cached = true
    end

    if cached then
        return ReadForeverSpellData(spellID)
    end

    if callback then
        EnsureForeverSpellLoader()

        ForeverSpellWaiting[spellID] =
            ForeverSpellWaiting[spellID]
            or {}

        table.insert(
            ForeverSpellWaiting[spellID],
            callback
        )
    end

    pcall(C_Spell.RequestLoadSpellData, spellID)
    return nil, nil
end


--------------------------------------------------
-- DATABASE
--------------------------------------------------

local function GetDatabase()

    if ForeverDBDatabase then

        return ForeverDBDatabase

    end

    return nil
end

local function GetForeverCollection()
    if type(ForeverDBDatabase) ~= "table" then ForeverDBDatabase = {} end
    ForeverDBDatabase.collectedItems = ForeverDBDatabase.collectedItems or {}
    return ForeverDBDatabase.collectedItems
end

local function MarkForeverItemCollected(itemID)
    itemID = tonumber(itemID)
    if itemID then GetForeverCollection()[itemID] = true end
end

local function IsForeverItemCollected(itemID)
    itemID = tonumber(itemID)
    if not itemID then return false end
    local collection = GetForeverCollection()
    return collection[itemID] == true or collection[tostring(itemID)] == true
end

local function SetForeverItemCollected(itemID, collected)
    itemID = tonumber(itemID)
    if not itemID then return end
    local collection = GetForeverCollection()
    if collected then
        collection[itemID] = true
        collection[tostring(itemID)] = nil
    else
        collection[itemID] = nil
        collection[tostring(itemID)] = nil
    end
end


local function GetForeverWishlist()
    if type(ForeverDBDatabase) ~= "table" then ForeverDBDatabase = {} end
    ForeverDBDatabase.farmingWishlist = ForeverDBDatabase.farmingWishlist or {}
    return ForeverDBDatabase.farmingWishlist
end

local function IsForeverItemTracked(itemID)
    itemID = tonumber(itemID)
    if not itemID then return false end
    local wishlist = GetForeverWishlist()
    return wishlist[itemID] == true or wishlist[tostring(itemID)] == true
end

local function SetForeverItemTracked(itemID, tracked)
    itemID = tonumber(itemID)
    if not itemID then return end
    local wishlist = GetForeverWishlist()
    if tracked then
        wishlist[itemID] = true
        wishlist[tostring(itemID)] = nil
    else
        wishlist[itemID] = nil
        wishlist[tostring(itemID)] = nil
    end
end

local function ScanForeverOwnedItems()
    -- Equipped items.
    if GetInventoryItemID then
        for slot = 1, 19 do
            local ok, itemID = pcall(GetInventoryItemID, "player", slot)
            if ok and itemID then MarkForeverItemCollected(itemID) end
        end
    end

    -- Bags. Support both legacy and C_Container APIs.
    local function BagSlots(bag)
        if C_Container and C_Container.GetContainerNumSlots then
            local ok,n=pcall(C_Container.GetContainerNumSlots,bag)
            if ok then return tonumber(n) or 0 end
        end
        if GetContainerNumSlots then
            local ok,n=pcall(GetContainerNumSlots,bag)
            if ok then return tonumber(n) or 0 end
        end
        return 0
    end
    local function BagItemID(bag,slot)
        if C_Container and C_Container.GetContainerItemID then
            local ok,id=pcall(C_Container.GetContainerItemID,bag,slot)
            if ok then return id end
        end
        if GetContainerItemID then
            local ok,id=pcall(GetContainerItemID,bag,slot)
            if ok then return id end
        end
        return nil
    end

    -- Backpack/bags plus bank container and bank bags when accessible.
    for bag = 0, 11 do
        local slots=BagSlots(bag)
        for slot=1,slots do
            local itemID=BagItemID(bag,slot)
            if itemID then MarkForeverItemCollected(itemID) end
        end
    end
    local bankSlots=BagSlots(-1)
    for slot=1,bankSlots do
        local itemID=BagItemID(-1,slot)
        if itemID then MarkForeverItemCollected(itemID) end
    end
end


--------------------------------------------------
-- BROWSER SETTINGS
--------------------------------------------------

local FOREVER_BROWSER_DEFAULT_SETTINGS = {
    showItemTooltips = true,
    enableMapMarkers = true,
    saveRecentSearches = true,
}

local function GetBrowserSettings()
    if type(ForeverDBDatabase) ~= "table" then
        ForeverDBDatabase = {}
    end

    ForeverDBDatabase.browserSettings =
        ForeverDBDatabase.browserSettings
        or {}

    local settings = ForeverDBDatabase.browserSettings

    for key, value in pairs(FOREVER_BROWSER_DEFAULT_SETTINGS) do
        if settings[key] == nil then
            settings[key] = value
        end
    end

    return settings
end

local function BrowserSettingEnabled(key)
    local settings = GetBrowserSettings()
    return settings[key] ~= false
end

local function SetBrowserSetting(key, value)
    GetBrowserSettings()[key] = value and true or false
end


local function GetPlayerItems()

    local db =
        GetDatabase()

    if not db then
        return {}
    end


    return db.items
        or db.Items
        or db.discoveredItems
        or db.DiscoveredItems
        or {}
end


local function GetWorldItems()

    if ForeverWorldData
        and ForeverWorldData.items then

        return ForeverWorldData.items

    end


    if ForeverDB
        and ForeverDB.GetWorldItems then

        local result =
            ForeverDB:GetWorldItems()

        if result then
            return result
        end

    end


    return {}
end


--------------------------------------------------
-- FAVORITES
--------------------------------------------------

local function GetFavorites()

    local db =
        GetDatabase()

    if not db then
        return {}
    end

    db.favorites =
        db.favorites
        or {}

    return db.favorites
end


local function IsFavorite(itemID)

    itemID =
        tonumber(itemID)

    if not itemID then
        return false
    end

    local favorites =
        GetFavorites()

    return favorites[itemID] == true
        or favorites[tostring(itemID)] == true
end


local function SetFavorite(
    itemID,
    enabled
)

    itemID =
        tonumber(itemID)

    if not itemID then
        return
    end

    local favorites =
        GetFavorites()

    favorites[itemID] =
        enabled
            and true
            or nil

    favorites[tostring(itemID)] =
        nil
end


--------------------------------------------------
-- RECENTLY VIEWED
--------------------------------------------------

local function GetRecentItems()

    local db =
        GetDatabase()

    if not db then
        return {}
    end

    db.recentItems =
        db.recentItems
        or {}

    return db.recentItems
end


local function AddRecentItem(itemID)

    itemID =
        tonumber(itemID)

    if not itemID then
        return
    end

    local recent =
        GetRecentItems()

    for i = #recent, 1, -1 do

        if tonumber(recent[i]) == itemID then

            table.remove(
                recent,
                i
            )

        end
    end

    table.insert(
        recent,
        1,
        itemID
    )

    while #recent > 10 do

        table.remove(
            recent,
            #recent
        )

    end
end


--------------------------------------------------
-- CUSTOM LISTS
--------------------------------------------------

local function GetCustomLists()

    local db =
        GetDatabase()

    if not db then
        return {}
    end

    db.customLists =
        db.customLists
        or {}

    return db.customLists
end


local function CreateCustomList(name)

    name =
        tostring(name or "")

    name =
        string.gsub(
            name,
            "^%s+",
            ""
        )

    name =
        string.gsub(
            name,
            "%s+$",
            ""
        )

    if name == "" then
        return false
    end

    local lists =
        GetCustomLists()

    if not lists[name] then

        lists[name] = {
            items = {}
        }
    end

    lists[name].items =
        lists[name].items
        or {}

    return true
end


local function ToggleItemInCustomList(
    listName,
    itemID
)

    local lists =
        GetCustomLists()

    local list =
        lists[listName]

    if not list then
        return
    end

    list.items =
        list.items
        or {}

    itemID =
        tonumber(itemID)

    if not itemID then
        return
    end

    if list.items[itemID] then

        list.items[itemID] =
            nil

    else

        list.items[itemID] =
            true
    end
end


local function IsItemInCustomList(
    listName,
    itemID
)

    local list =
        GetCustomLists()[listName]

    if not list
        or not list.items then
        return false
    end

    itemID =
        tonumber(itemID)

    return list.items[itemID] == true
        or list.items[tostring(itemID)] == true
end


local function RenameCustomList(
    oldName,
    newName
)

    newName =
        tostring(newName or "")

    newName =
        string.gsub(
            newName,
            "^%s+",
            ""
        )

    newName =
        string.gsub(
            newName,
            "%s+$",
            ""
        )

    if newName == ""
        or newName == oldName then
        return false
    end

    local lists =
        GetCustomLists()

    if not lists[oldName]
        or lists[newName] then
        return false
    end

    lists[newName] =
        lists[oldName]

    lists[oldName] =
        nil

    return true
end


local function DeleteCustomList(name)

    local lists =
        GetCustomLists()

    if not lists[name] then
        return false
    end

    lists[name] =
        nil

    return true
end


--------------------------------------------------
-- ITEM NOTES AND TAGS
--------------------------------------------------

local function GetItemNotes()

    local db =
        GetDatabase()

    if not db then
        return {}
    end

    db.itemNotes =
        db.itemNotes
        or {}

    return db.itemNotes
end


local function GetItemTags()

    local db =
        GetDatabase()

    if not db then
        return {}
    end

    db.itemTags =
        db.itemTags
        or {}

    return db.itemTags
end


local function GetSavedItemNote(itemID)

    itemID =
        tonumber(itemID)

    if not itemID then
        return ""
    end

    local notes =
        GetItemNotes()

    return tostring(
        notes[itemID]
        or notes[tostring(itemID)]
        or ""
    )
end


local function SaveItemNote(
    itemID,
    text
)

    itemID =
        tonumber(itemID)

    if not itemID then
        return
    end

    local notes =
        GetItemNotes()

    text =
        tostring(text or "")

    if text == "" then

        notes[itemID] =
            nil

    else

        notes[itemID] =
            text
    end

    notes[tostring(itemID)] =
        nil
end


local function GetSavedItemTags(itemID)

    itemID =
        tonumber(itemID)

    if not itemID then
        return ""
    end

    local tags =
        GetItemTags()

    return tostring(
        tags[itemID]
        or tags[tostring(itemID)]
        or ""
    )
end


local function SaveItemTags(
    itemID,
    text
)

    itemID =
        tonumber(itemID)

    if not itemID then
        return
    end

    local tags =
        GetItemTags()

    text = ForeverBrowser_L206Tags(text)

    if text == "" then

        tags[itemID] =
            nil

    else

        tags[itemID] =
            text
    end

    tags[tostring(itemID)] =
        nil
end


--------------------------------------------------
-- ITEM HELPERS
--------------------------------------------------

local function GetPlayerItem(itemID)

    itemID =
        tonumber(itemID)

    if not itemID then
        return nil
    end


    local items =
        GetPlayerItems()


    return items[itemID]
end


local function GetWorldItem(itemID)

    itemID =
        tonumber(itemID)

    if not itemID then
        return nil
    end


    local items =
        GetWorldItems()


    return items[itemID]
end


local function GetAnyItem(itemID)

    itemID =
        tonumber(itemID)

    if not itemID then
        return nil
    end


    local playerItem =
        GetPlayerItem(itemID)


    if playerItem then
        return playerItem
    end


    local worldItem =
        GetWorldItem(itemID)

    if worldItem then
        return worldItem
    end

    -- Forever-only/server-supplied items may not exist in the client/world
    -- cache. Fall back to the generated source database so their item pages
    -- can still open (for example Corpse Chopper, item 271217).
    if ForeverSourceData
        and ForeverSourceData.items then

        return ForeverSourceData.items[itemID]
            or ForeverSourceData.items[tostring(itemID)]
    end

    return nil
end


local function CleanItemDisplayName(itemID, item, rawName)
    local name = tostring(rawName or "")
    if name == "" then return name end

    local prefix, remainder = string.match(name, "^(%d+)%s+(.+)$")
    if not prefix or not remainder then
        return name
    end

    -- Known malformed Forever import family: the level was prepended to the
    -- actual item name. These records visibly appear as "63 Green ..." while
    -- also reporting Item Level 63. Correct this family directly instead of
    -- relying on inconsistent legacy item metadata.
    if prefix == "63"
        and string.sub(remainder, 1, 6) == "Green " then

        return remainder
    end

    local prefixNumber = tonumber(prefix)

    -- The visible item-level getter is authoritative for Browser display.
    -- This catches imported names like "63 Green Warrior Ring" even when the
    -- raw record stores its level under an unexpected field.
    if itemID and GetItemLevel then
        local ok, visibleLevel =
            pcall(
                GetItemLevel,
                itemID,
                item
            )

        if ok
            and visibleLevel
            and prefixNumber == tonumber(visibleLevel) then

            return remainder
        end
    end

    -- Check all known record-level fields first.
    local storedLevel = item and (
        item.itemLevel
        or item.ItemLevel
        or item.ilevel
        or item.level
        or item.requiredLevel
    )

    if storedLevel and prefixNumber == tonumber(storedLevel) then
        return remainder
    end

    -- Ask the legacy C_Item API. Some Forever builds return the malformed name
    -- but still return a valid item level in the normal GetItemInfo tuple.
    if C_Item and C_Item.GetItemInfo then
        local ok,
            clientName,
            itemLink,
            quality,
            itemLevel,
            requiredLevel =
            pcall(C_Item.GetItemInfo, itemID)

        if ok then
            if clientName and tostring(clientName) == remainder then
                return remainder
            end
            if itemLevel and prefixNumber == tonumber(itemLevel) then
                return remainder
            end
        end
    end

    if GetItemInfo then
        local ok,
            clientName,
            itemLink,
            quality,
            itemLevel,
            requiredLevel =
            pcall(GetItemInfo, itemID)

        if ok then
            if clientName and tostring(clientName) == remainder then
                return remainder
            end
            if itemLevel and prefixNumber == tonumber(itemLevel) then
                return remainder
            end
        end
    end

    return name
end


local function GetItemName(itemID)

    local item =
        GetAnyItem(itemID)


    if item
        and item.name then

        return CleanItemDisplayName(itemID, item, item.name)
    end


    if C_Item
        and C_Item.GetItemInfo then

        local name =
            pcall(
                C_Item.GetItemInfo,
                itemID
            )

        local ok,
            itemName =
            pcall(
                C_Item.GetItemInfo,
                itemID
            )

        if ok
            and itemName then

            return CleanItemDisplayName(itemID, item, itemName)
        end

    end


    if GetItemInfo then

        local ok,
            itemName =
            pcall(
                GetItemInfo,
                itemID
            )

        if ok
            and itemName then

            return CleanItemDisplayName(itemID, item, itemName)
        end

    end


    return "Unknown Item"
end


--------------------------------------------------
-- ITEM INFORMATION
--------------------------------------------------

local function GetItemField(item, ...)

    if not item then
        return nil
    end


    local fields = {...}


    for _, field
        in ipairs(fields) do

        if item[field] ~= nil then
            return item[field]
        end

    end


    return nil
end


--------------------------------------------------
-- ICON
--------------------------------------------------

local function GetItemIcon(itemID, item)

    --------------------------------------------------
    -- ITEM / DATABASE ICON
    --------------------------------------------------

    if item then

        local icon =
            GetItemField(
                item,
                "icon",
                "texture",
                "iconFileDataID",
                "IconFileDataID",
                "iconFileDataId",
                "iconID",
                "iconId"
            )

        -- WoW Forever accepts numeric FileDataIDs directly in
        -- Texture:SetTexture(). Do NOT convert them to filenames.
        if type(icon) == "number" then
            return icon
        end

        if type(icon) == "string"
            and icon ~= "" then

            local numericIcon =
                tonumber(icon)

            if numericIcon then
                return numericIcon
            end

            return icon
        end
    end


    --------------------------------------------------
    -- WORLD DATABASE ICON
    --------------------------------------------------

    local worldItem =
        GetWorldItem(itemID)

    if worldItem then

        local iconID =
            GetItemField(
                worldItem,
                "icon",
                "texture",
                "iconFileDataID",
                "IconFileDataID",
                "iconFileDataId",
                "iconID",
                "iconId"
            )

        if type(iconID) == "number" then
            return iconID
        end

        if type(iconID) == "string"
            and iconID ~= "" then

            local numericIcon =
                tonumber(iconID)

            if numericIcon then
                return numericIcon
            end

            return iconID
        end
    end


    --------------------------------------------------
    -- C_ITEM
    --------------------------------------------------

    if C_Item
        and C_Item.GetItemInfo then

        local ok,
            name,
            link,
            quality,
            itemLevel,
            requiredLevel,
            class,
            subclass,
            maxStack,
            equipSlot,
            texture =
            pcall(
                C_Item.GetItemInfo,
                itemID
            )

        if ok
            and texture then

            -- Tested on WoW Forever:
            -- C_Item.GetItemInfo(2770) returns 134566 and
            -- SetTexture(134566) correctly displays Copper Ore.
            return texture
        end
    end


    --------------------------------------------------
    -- OLD API
    --------------------------------------------------

    if GetItemInfo then

        local ok,
            name,
            link,
            quality,
            itemLevel,
            requiredLevel,
            class,
            subclass,
            maxStack,
            equipSlot,
            texture =
            pcall(
                GetItemInfo,
                itemID
            )

        if ok
            and texture then

            return texture
        end
    end


    --------------------------------------------------
    -- GET ITEM ICON FALLBACK
    --------------------------------------------------

    if GetItemIcon then

        local ok,
            texture =
            pcall(
                GetItemIcon,
                itemID
            )

        if ok
            and texture then

            return texture
        end
    end


    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

--------------------------------------------------
-- ITEM QUALITY
--------------------------------------------------

local QualityNames = {

    [0] = "Poor",
    [1] = "Common",
    [2] = "Uncommon",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
    [6] = "Artifact",
    [7] = "Heirloom",

}


local function GetQuality(itemID, item)

    local quality =
        GetItemField(
            item,
            "quality",
            "Quality",
            "overallQualityID",
            "OverallQualityID"
        )


    if quality ~= nil then
        return tonumber(quality) or 0
    end


    if C_Item
        and C_Item.GetItemInfo then

        local ok,
            name,
            link,
            itemQuality =
            pcall(
                C_Item.GetItemInfo,
                itemID
            )


        if ok
            and itemQuality then

            return tonumber(itemQuality)
                or 0

        end

    end


    if GetItemInfo then

        local ok,
            name,
            link,
            itemQuality =
            pcall(
                GetItemInfo,
                itemID
            )


        if ok
            and itemQuality then

            return tonumber(itemQuality)
                or 0

        end

    end


    return 0
end


local function GetQualityName(quality)

    return QualityNames[
        tonumber(quality)
    ] or "Unknown"
end


--------------------------------------------------
-- ITEM LEVEL
--------------------------------------------------

local function GetItemLevel(itemID, item)

    local level =
        GetItemField(
            item,
            "itemLevel",
            "ItemLevel",
            "ilevel"
        )


    if level ~= nil then
        return tonumber(level) or 0
    end


    if C_Item
        and C_Item.GetItemInfo then

        local ok,
            name,
            link,
            quality,
            itemLevel =
            pcall(
                C_Item.GetItemInfo,
                itemID
            )


        if ok
            and itemLevel then

            return tonumber(itemLevel)
                or 0

        end

    end


    if GetItemInfo then

        local ok,
            name,
            link,
            quality,
            itemLevel =
            pcall(
                GetItemInfo,
                itemID
            )


        if ok
            and itemLevel then

            return tonumber(itemLevel)
                or 0

        end

    end


    return 0
end


--------------------------------------------------
-- CLASS
--------------------------------------------------

local ClassNames = {

    [0] = "Consumables",
    [1] = "Containers",
    [2] = "Weapons",
    [3] = "Gems",
    [4] = "Armor",
    [5] = "Reagents",
    [6] = "Projectile",
    [7] = "Trade Goods",
    [8] = "Generic",
    [9] = "Recipes",
    [10] = "Money",
    [11] = "Quiver",
    [12] = "Quest Items",
    [13] = "Keys",
    [14] = "Miscellaneous",
    [15] = "Miscellaneous",
    [16] = "Glyphs",
}


local function GetItemClass(itemID, item)

    local classID =
        GetItemField(
            item,
            "classID",
            "ClassID",
            "classId"
        )


    if classID ~= nil then

        return tonumber(classID)

    end


    if C_Item
        and C_Item.GetItemInfo then

        local ok,
            name,
            link,
            quality,
            itemLevel,
            requiredLevel,
            classIDValue =
            pcall(
                C_Item.GetItemInfo,
                itemID
            )


        if ok
            and classIDValue then

            return tonumber(classIDValue)

        end

    end


    return nil
end


local function GetClassName(itemID, item)

    local classID =
        GetItemClass(
            itemID,
            item
        )


    if classID ~= nil then

        return ClassNames[classID]
            or "Other"

    end


    return "Other"
end


--------------------------------------------------
-- CATEGORY DATA
--------------------------------------------------

local DatabaseCategories = {

    {
        id = 2,
        name = "Weapons",
        icon = "Interface\\Icons\\INV_Sword_07",
        description =
            "Swords, axes, maces, bows and more.",
    },

    {
        id = 4,
        name = "Armor",
        icon = "Interface\\Icons\\INV_Chest_Plate16",
        description =
            "Helms, shoulders, chest, gloves and armor.",
    },

    {
        id = 0,
        name = "Consumables",
        icon = "Interface\\Icons\\INV_Potion_54",
        description =
            "Potions, food, drinks and usable items.",
    },

    {
        id = 1,
        name = "Containers",
        icon = "Interface\\Icons\\INV_Misc_Bag_07",
        description =
            "Bags and other storage containers.",
    },

    {
        id = 3,
        name = "Gems",
        icon = "Interface\\Icons\\INV_Misc_Gem_01",
        description =
            "Gems and jewelcrafting items.",
    },

    {
        id = 7,
        name = "Trade Goods",
        icon = "Interface\\Icons\\INV_Misc_LeatherScrap_02",
        description =
            "Materials, crafting items and reagents.",
    },

    {
        id = 9,
        name = "Recipes",
        icon = "Interface\\Icons\\INV_Scroll_03",
        description =
            "Recipes, patterns, plans and formulas.",
    },

    {
        id = 12,
        name = "Quest Items",
        icon = "Interface\\Icons\\INV_Misc_Book_09",
        description =
            "Items used for quests and objectives.",
    },

    {
        id = 13,
        name = "Keys",
        icon = "Interface\\Icons\\INV_Misc_Key_03",
        description =
            "Keys and items used to unlock things.",
    },

    {
        id = 16,
        name = "Glyphs",
        icon = "Interface\\Icons\\INV_Inscription_Glyph_01",
        description =
            "Glyphs and inscription items.",
    },

    {
        id = 15,
        name = "Miscellaneous",
        icon = "Interface\\Icons\\INV_Misc_QuestionMark",
        description =
            "Other items that don't fit another category.",
    },

}


--------------------------------------------------
-- CATEGORY LOOKUP
--------------------------------------------------

local function GetCategoryName(categoryID)

    categoryID =
        tonumber(categoryID)


    for _, category
        in ipairs(DatabaseCategories) do

        if category.id == categoryID then

            return category.name

        end

    end


    return "Other"
end


--------------------------------------------------
-- BACKGROUND
--------------------------------------------------

if not ForeverBrowserTheme then
    error("ForeverBrowserThemes.lua must be loaded before ForeverBrowser.lua. Update the addon TOC load order.")
end
local WOW_THEME=ForeverBrowserTheme.palette
local FOREVER_THEMES=ForeverBrowserTheme.themes
local FOREVER_THEME_ORDER=ForeverBrowserTheme.order
local CreateSolidBackground=ForeverBrowserTheme.CreateSolidBackground
local CopyThemeIntoActive=ForeverBrowserTheme.CopyThemeIntoActive
local RegisterThemeVisual=ForeverBrowserTheme.RegisterThemeVisual
local ThemeColor=ForeverBrowserTheme.ThemeColor
local ResolveThemeModelDisplay=ForeverBrowserTheme.ResolveThemeModelDisplay
local ApplyRegisteredThemeVisuals=ForeverBrowserTheme.ApplyRegisteredThemeVisuals
local SaveForeverTheme=ForeverBrowserTheme.SaveForeverTheme
local LoadForeverTheme=ForeverBrowserTheme.LoadForeverTheme
local AddWoWBorder=ForeverBrowserTheme.AddWoWBorder
local MakeEdge=ForeverBrowserTheme.MakeEdge
local AddWoWPanelTexture=ForeverBrowserTheme.AddWoWPanelTexture
local AddWoWInset=ForeverBrowserTheme.AddWoWInset
local AddWoWDivider=ForeverBrowserTheme.AddWoWDivider
local AddWoWCornerOrnaments=ForeverBrowserTheme.AddWoWCornerOrnaments
local AddWoWHeaderAccent=ForeverBrowserTheme.AddWoWHeaderAccent
local AddWoWIconFrame=ForeverBrowserTheme.AddWoWIconFrame
local AddWoWSoftGlow=ForeverBrowserTheme.AddWoWSoftGlow
local CreateWoWMedallion=ForeverBrowserTheme.CreateWoWMedallion
local CreateWoWBanner=ForeverBrowserTheme.CreateWoWBanner
local CreateWoWCategoryTile=ForeverBrowserTheme.CreateWoWCategoryTile
local CreateWoWSectionRibbon=ForeverBrowserTheme.CreateWoWSectionRibbon
local CreateLabel=ForeverBrowserTheme.CreateLabel
local CreateButton=ForeverBrowserTheme.CreateButton

local function ClearPage()
    ItemActionsAnchor = nil

    if not PageContent then
        return
    end


    local children = {
        PageContent:GetChildren()
    }


    for _, child
        in ipairs(children) do

        if type(ForeverBrowserTheme.ForgetSubtree)=="function" then ForeverBrowserTheme.ForgetSubtree(child) end
        child:Hide()
        child:SetParent(nil)

    end


    local regions = {
        PageContent:GetRegions()
    }


    for _, region
        in ipairs(regions) do

        if type(ForeverBrowserTheme.ForgetSubtree)=="function" then ForeverBrowserTheme.ForgetSubtree(region) end
        region:Hide()

    end


    PageContent:SetHeight(
        500
    )
end


--------------------------------------------------
-- ITEM CHAT LINK
--------------------------------------------------

local function GetChatItemLink(itemID)

    itemID =
        tonumber(itemID)

    if not itemID then
        return nil
    end

    if C_Item
        and C_Item.GetItemInfo then

        local ok,
            itemName,
            itemLink =
            pcall(
                C_Item.GetItemInfo,
                itemID
            )

        if ok
            and itemLink then

            return itemLink
        end
    end

    if GetItemInfo then

        local ok,
            itemName,
            itemLink =
            pcall(
                GetItemInfo,
                itemID
            )

        if ok
            and itemLink then

            return itemLink
        end
    end

    return nil
end


local function LinkItemToChat(itemID)

    local link =
        GetChatItemLink(itemID)

    if not link then

        if DEFAULT_CHAT_FRAME then

            DEFAULT_CHAT_FRAME:AddMessage(
                "|cffffcc00ForeverBrowser:|r Item link is not available yet."
            )
        end

        return false
    end

    if ChatEdit_InsertLink
        and ChatEdit_InsertLink(link) then

        return true
    end

    if ChatFrame_OpenChat then

        ChatFrame_OpenChat(
            link
        )

        return true
    end

    if DEFAULT_CHAT_FRAME then

        DEFAULT_CHAT_FRAME:AddMessage(
            link
        )
    end

    return true
end


local function IsShiftLinkClick()

    return IsShiftKeyDown
        and IsShiftKeyDown()
end


--------------------------------------------------
-- ITEM TOOLTIP
--------------------------------------------------

local function ShowItemTooltip(itemID, anchor)
    if not BrowserSettingEnabled("showItemTooltips") or not GameTooltip then return end

    GameTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
    if type(ForeverBrowserTheme.StyleTooltip)=="function" then ForeverBrowserTheme.StyleTooltip(GameTooltip) end

    -- v1.114: use the native item tooltip for full item information, but for
    -- the known malformed "63 Green ..." family use a clean Browser tooltip.
    -- Native tooltip title text is protected/secret on this client, so it
    -- must never be read or rewritten after SetHyperlink().
    local item = GetAnyItem(itemID)
    local rawName = item and GetItemField(item, "name", "itemName") or nil
    local cleanName = GetItemName(itemID)
    local useSafeTooltip = ForeverBrowser_S222().simpleTooltips

    if rawName then
        local raw = tostring(rawName)
        if string.sub(raw, 1, 3) == "63 "
            and string.sub(raw, 4, 9) == "Green " then
            useSafeTooltip = true
        end
    end

    if not useSafeTooltip and GameTooltip.SetHyperlink then
        local link = nil

        if C_Item and C_Item.GetItemInfo then
            local ok, itemName, itemLink = pcall(C_Item.GetItemInfo, itemID)
            if ok then link = itemLink end
        end

        if not link and GetItemInfo then
            local ok, itemName, itemLink = pcall(GetItemInfo, itemID)
            if ok then link = itemLink end
        end

        if link then
            GameTooltip:SetHyperlink(link)
            ForeverBrowser_S222Tooltip(itemID,item)
            GameTooltip:Show()
            return
        end
    end

    -- Safe fallback for malformed items. Recreate the useful database fields
    -- without touching protected native tooltip text.
    local quality = GetQuality(itemID, item)
    local qc = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
    if qc then
        GameTooltip:AddLine(cleanName, qc.r or 1, qc.g or 1, qc.b or 1)
    else
        GameTooltip:AddLine(cleanName, 1, 1, 1)
    end

    local itemLevel = GetItemLevel(itemID, item)
    if tonumber(itemLevel) and tonumber(itemLevel) > 0 then
        GameTooltip:AddLine("Item Level " .. tostring(itemLevel), 1, 0.82, 0.25)
    end

    local requiredLevel = GetItemField(item, "requiredLevel", "RequiredLevel", "reqLevel")
    if tonumber(requiredLevel) and tonumber(requiredLevel) > 0 then
        GameTooltip:AddLine("Requires Level " .. tostring(requiredLevel), 1, 1, 1)
    end

    local className = GetClassName(itemID, item)
    if className and className ~= "" and className ~= "Other" then
        GameTooltip:AddLine(className, 0.72, 0.74, 0.80)
    end

    local subclass = GetItemField(item, "subclass", "subClass", "subclassName", "SubClass")
    if subclass and tostring(subclass) ~= "" then
        GameTooltip:AddLine(tostring(subclass), 0.72, 0.74, 0.80)
    end

    local description = GetItemField(item, "description", "Description", "desc")
    if description and tostring(description) ~= "" then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(tostring(description), 1, 0.82, 0, true)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Item ID: " .. tostring(itemID), 0.58, 0.61, 0.68)
    ForeverBrowser_S222Tooltip(itemID,item)
    GameTooltip:Show()
end


--------------------------------------------------
-- NAVIGATION
--------------------------------------------------

local Navigate
local HideSearchSuggestions


local function AddHistory(url)

    if HistoryPosition > 0
        and HistoryPosition < #History then

        for i =
            #History,
            HistoryPosition + 1,
            -1 do

            table.remove(
                History,
                i
            )

        end

    end


    if History[#History] ~= url then

        table.insert(
            History,
            url
        )

    end


    HistoryPosition =
        #History

end


--------------------------------------------------
-- WHERE TO OBTAIN
--------------------------------------------------

local function GetAutomaticItemSources(itemID)
    itemID = tonumber(itemID)

    if not itemID
        or not ForeverSourceData
        or not ForeverSourceData.items then
        return nil
    end

    return ForeverSourceData.items[itemID]
        or ForeverSourceData.items[tostring(itemID)]
end

local function GetSourceTypeLabel(sourceType)
    local labels = {
        drop = "DROPPED BY",
        object = "OBJECT / CHEST",
        pickpocket = "PICKPOCKETED FROM",
        skinning = "SKINNED FROM",
        quest = "QUEST REWARD",
        vendor = "SOLD BY",
        crafted = "CRAFTED BY",
    }

    return labels[tostring(sourceType or "")]
        or string.upper(tostring(sourceType or "UNKNOWN"))
end

local function GetSourceTypeOrder(sourceType)
    local order = {
        drop = 1,
        quest = 2,
        object = 3,
        pickpocket = 4,
        skinning = 5,
        vendor = 6,
        crafted = 7,
    }

    return order[tostring(sourceType or "")] or 99
end

local function GetAutomaticMapName(mapID)
    mapID = tonumber(mapID)

    if not mapID
        or mapID <= 0 then
        return nil
    end

    --------------------------------------------------
    -- UI MAP NAME FROM THE CLIENT
    --------------------------------------------------

    if C_Map
        and C_Map.GetMapInfo then

        local ok, mapInfo =
            pcall(
                C_Map.GetMapInfo,
                mapID
            )

        if ok
            and mapInfo
            and mapInfo.name
            and tostring(mapInfo.name) ~= "" then

            return tostring(mapInfo.name)
        end
    end

    --------------------------------------------------
    -- GENERATED MAP DATABASE FALLBACK
    --------------------------------------------------

    if ForeverSourceData
        and ForeverSourceData.maps then

        local mapData =
            ForeverSourceData.maps[mapID]
            or ForeverSourceData.maps[tostring(mapID)]

        if mapData
            and mapData.name
            and tostring(mapData.name) ~= "" then

            return tostring(mapData.name)
        end
    end

    return nil
end


--------------------------------------------------
-- FOREVERBROWSER WORLD MAP MARKER
--------------------------------------------------

local ForeverBrowserMapMarker = nil
local ForeverBrowserAllMapMarkers = {}
local ForeverBrowserAllMarkerMapID = nil
local ForeverBrowserMapWatcher = nil
local ForeverBrowserSingleMarkerWatcher = nil
local ForeverBrowserMarkerPendingUpdater = nil

local function ClearForeverBrowserAllMapMarkers()
    for _, marker in ipairs(ForeverBrowserAllMapMarkers) do
        if marker then
            marker:Hide()
        end
    end

    ForeverBrowserAllMapMarkers = {}
    ForeverBrowserAllMarkerMapID = nil
end

local function GetForeverBrowserCurrentMapID()
    if not WorldMapFrame then
        return nil
    end

    if WorldMapFrame.GetMapID then
        local ok, mapID = pcall(
            WorldMapFrame.GetMapID,
            WorldMapFrame
        )

        if ok and mapID then
            return tonumber(mapID)
        end
    end

    return nil
end

local function StartForeverBrowserAllMarkerWatcher(mapID)
    ForeverBrowserAllMarkerMapID = tonumber(mapID)

    if not ForeverBrowserMapWatcher then
        ForeverBrowserMapWatcher = CreateFrame("Frame")
    end

    ForeverBrowserMapWatcher.elapsed = 0

    ForeverBrowserMapWatcher:SetScript(
        "OnUpdate",
        function(self, elapsed)
            self.elapsed = (self.elapsed or 0) + (elapsed or 0)

            if self.elapsed < 0.15 then
                return
            end

            self.elapsed = 0

            if #ForeverBrowserAllMapMarkers == 0 then
                self:SetScript("OnUpdate", nil)
                self:Hide()
                return
            end

            if not WorldMapFrame
                or not WorldMapFrame.IsShown
                or not WorldMapFrame:IsShown() then

                ClearForeverBrowserAllMapMarkers()
                self:SetScript("OnUpdate", nil)
                self:Hide()
                return
            end

            local currentMapID =
                GetForeverBrowserCurrentMapID()

            if currentMapID
                and ForeverBrowserAllMarkerMapID
                and currentMapID ~= ForeverBrowserAllMarkerMapID then

                ClearForeverBrowserAllMapMarkers()
                self:SetScript("OnUpdate", nil)
                self:Hide()
                return
            end
        end
    )

    ForeverBrowserMapWatcher:Show()
end

local function IsUsableForeverBrowserMapCanvas(frame)
    return frame
        and frame.GetWidth
        and frame.GetHeight
        and frame:GetWidth() > 0
        and frame:GetHeight() > 0
end

local function GetForeverBrowserMapCanvas()
    if not WorldMapFrame then
        return nil
    end

    -- Prefer the actual map canvas/scroll child.  The old children[5]
    -- fallback can cover the surrounding World Map UI in windowed mode,
    -- which makes coordinate markers appear in the wrong zone.
    local scrollContainer =
        WorldMapFrame.ScrollContainer
        or WorldMapFrame.scrollContainer

    if scrollContainer then
        local scrollChild

        if scrollContainer.GetScrollChild then
            local ok, child = pcall(
                scrollContainer.GetScrollChild,
                scrollContainer
            )

            if ok then
                scrollChild = child
            end
        end

        scrollChild =
            scrollChild
            or scrollContainer.Child
            or scrollContainer.child

        if IsUsableForeverBrowserMapCanvas(scrollChild) then
            return scrollChild
        end

        if IsUsableForeverBrowserMapCanvas(scrollContainer) then
            return scrollContainer
        end
    end

    local canvasCandidates = {
        WorldMapFrame.Canvas,
        WorldMapFrame.canvas,
        WorldMapFrame.MapCanvas,
        WorldMapFrame.mapCanvas,
        WorldMapFrame.Map,
        WorldMapFrame.map,
    }

    for _, candidate in ipairs(canvasCandidates) do
        if IsUsableForeverBrowserMapCanvas(candidate) then
            return candidate
        end
    end

    -- Compatibility fallback for the WoW Forever client.
    local children = {WorldMapFrame:GetChildren()}
    local oldCanvas = children[5]

    if IsUsableForeverBrowserMapCanvas(oldCanvas) then
        return oldCanvas
    end

    return nil
end

local function PositionForeverBrowserSingleMarker()
    if not ForeverBrowserMapMarker
        or not ForeverBrowserMapMarker.fbX
        or not ForeverBrowserMapMarker.fbY then
        return false
    end

    local mapParent = GetForeverBrowserMapCanvas()

    if not mapParent
        or not mapParent.GetWidth
        or not mapParent.GetHeight then
        return false
    end

    local width = mapParent:GetWidth()
    local height = mapParent:GetHeight()

    if not width
        or not height
        or width <= 0
        or height <= 0 then
        return false
    end

    -- Fullscreen/windowed map mode can rebuild or resize the canvas.
    -- Always attach to the CURRENT canvas and calculate from its CURRENT size.
    if ForeverBrowserMapMarker:GetParent() ~= mapParent then
        ForeverBrowserMapMarker:SetParent(mapParent)
    end

    ForeverBrowserMapMarker:ClearAllPoints()
    ForeverBrowserMapMarker:SetPoint(
        "CENTER",
        mapParent,
        "TOPLEFT",
        width * ForeverBrowserMapMarker.fbX,
        -height * ForeverBrowserMapMarker.fbY
    )

    if ForeverBrowserMapMarker.SetFrameLevel
        and mapParent.GetFrameLevel then
        ForeverBrowserMapMarker:SetFrameLevel(
            mapParent:GetFrameLevel() + 50
        )
    end

    return true
end

local function StartForeverBrowserSingleMarkerWatcher()
    if not ForeverBrowserSingleMarkerWatcher then
        ForeverBrowserSingleMarkerWatcher = CreateFrame("Frame")
    end

    ForeverBrowserSingleMarkerWatcher.elapsed = 0

    ForeverBrowserSingleMarkerWatcher:SetScript(
        "OnUpdate",
        function(self, elapsed)
            self.elapsed = (self.elapsed or 0) + (elapsed or 0)

            if self.elapsed < 0.10 then
                return
            end

            self.elapsed = 0

            if not ForeverBrowserMapMarker
                or not ForeverBrowserMapMarker:IsShown() then
                self:SetScript("OnUpdate", nil)
                self:Hide()
                return
            end

            if not WorldMapFrame
                or not WorldMapFrame.IsShown
                or not WorldMapFrame:IsShown() then
                ForeverBrowserMapMarker:Hide()
                self:SetScript("OnUpdate", nil)
                self:Hide()
                return
            end

            local currentMapID = GetForeverBrowserCurrentMapID()

            if currentMapID
                and ForeverBrowserMapMarker.fbMapID
                and currentMapID ~= ForeverBrowserMapMarker.fbMapID then
                -- A map transition can be temporary. Keep the marker pending
                -- rather than permanently hiding it during the transition.
                return
            end

            PositionForeverBrowserSingleMarker()
        end
    )

    ForeverBrowserSingleMarkerWatcher:Show()
end

local function ShowForeverBrowserMapMarker(mapID, x, y, sourceName)
    if not BrowserSettingEnabled("enableMapMarkers") then
        return false
    end
    mapID = tonumber(mapID)
    x = tonumber(x)
    y = tonumber(y)

    if not mapID or not x or not y then
        return false
    end

    if x > 1 or y > 1 then
        x = x / 100
        y = y / 100
    end

    if x < 0 then x = 0 end
    if x > 1 then x = 1 end
    if y < 0 then y = 0 end
    if y > 1 then y = 1 end

    if ForeverBrowser_S222().openMap then
    -- Open the Zone Map first.
    if WorldMapFrame
        and WorldMapFrame.IsShown
        and WorldMapFrame:IsShown() then
        -- Already open.
    elseif ToggleWorldMap then
        ToggleWorldMap()
    elseif WorldMapFrame and WorldMapFrame.Show then
        WorldMapFrame:Show()
    end

    end

    if not WorldMapFrame then
        return false
    end

    -- WoW Forever test confirmed this API changes to the requested zone.
    if WorldMapFrame.SetMapID then
        WorldMapFrame:SetMapID(mapID)
    else
        return false
    end

    local function PlaceMarker()
        local mapParent = GetForeverBrowserMapCanvas()

        if not mapParent then
            return false
        end

        if not ForeverBrowserMapMarker then
            ForeverBrowserMapMarker = CreateFrame(
                "Button",
                "ForeverBrowserWorldMapMarker",
                mapParent
            )

            ForeverBrowserMapMarker:SetSize(24, 24)

            -- Clean WoW-style location marker:
            -- dark outer ring + warm gold center + small highlight.
            local outer =
                ForeverBrowserMapMarker:CreateTexture(
                    nil,
                    "ARTWORK"
                )

            outer:SetAllPoints(ForeverBrowserMapMarker)
            outer:SetTexture("Interface\\COMMON\\Indicator-Yellow")
            outer:SetVertexColor(0.12, 0.10, 0.06, 1)
            ForeverBrowserMapMarker.outerTexture = outer

            local inner =
                ForeverBrowserMapMarker:CreateTexture(
                    nil,
                    "OVERLAY"
                )

            inner:SetPoint(
                "TOPLEFT",
                ForeverBrowserMapMarker,
                "TOPLEFT",
                4,
                -4
            )
            inner:SetPoint(
                "BOTTOMRIGHT",
                ForeverBrowserMapMarker,
                "BOTTOMRIGHT",
                -4,
                4
            )
            inner:SetTexture("Interface\\COMMON\\Indicator-Yellow")
            inner:SetVertexColor(1.00, 0.72, 0.12, 1)
            ForeverBrowserMapMarker.texture = inner

            local highlight =
                ForeverBrowserMapMarker:CreateTexture(
                    nil,
                    "OVERLAY"
                )

            highlight:SetSize(5, 5)
            highlight:SetPoint(
                "TOPLEFT",
                ForeverBrowserMapMarker,
                "TOPLEFT",
                6,
                -5
            )
            highlight:SetTexture("Interface\\COMMON\\Indicator-Yellow")
            highlight:SetVertexColor(1, 0.95, 0.65, 0.95)
            ForeverBrowserMapMarker.highlightTexture = highlight

            ForeverBrowserMapMarker:SetScript(
                "OnEnter",
                function(self)
                    if GameTooltip then
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:AddLine(
                            self.sourceName
                            or "ForeverBrowser Location"
                        )

                        if self.zoneName then
                            GameTooltip:AddLine(
                                self.zoneName,
                                0.8,
                                0.8,
                                0.8
                            )
                        end

                        if self.coordText then
                            GameTooltip:AddLine(
                                self.coordText,
                                0.65,
                                0.68,
                                0.75
                            )
                        end

                        GameTooltip:Show()
                    end
                end
            )

            ForeverBrowserMapMarker:SetScript(
                "OnLeave",
                function()
                    if GameTooltip then
                        GameTooltip:Hide()
                    end
                end
            )
        end

        ForeverBrowserMapMarker.fbMapID = mapID
        ForeverBrowserMapMarker.fbX = x
        ForeverBrowserMapMarker.fbY = y

        if not PositionForeverBrowserSingleMarker() then
            return false
        end

        ForeverBrowserMapMarker.sourceName =
            sourceName or "ForeverBrowser Location"

        ForeverBrowserMapMarker.zoneName =
            GetAutomaticMapName(mapID)

        ForeverBrowserMapMarker.coordText =
            "Coordinates: "
            .. string.format(
                "%.1f, %.1f",
                x * 100,
                y * 100
            )

        ForeverBrowserMapMarker:Show()
        StartForeverBrowserSingleMarkerWatcher()
        return true
    end

    -- SetMapID can rebuild/update the map canvas. Wait briefly before
    -- positioning the marker so it is attached to the newly selected zone.
    -- Retry while the map canvas is loading/rebuilding.  The previous one-shot
    -- 0.10 second attempt could fail silently and never try again.
    if ForeverBrowserMarkerPendingUpdater then
        ForeverBrowserMarkerPendingUpdater:SetScript("OnUpdate", nil)
        ForeverBrowserMarkerPendingUpdater:Hide()
    end
    local updater = CreateFrame("Frame")
    ForeverBrowserMarkerPendingUpdater = updater
    updater.elapsed, updater.attemptElapsed = 0, 0
    updater:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + (elapsed or 0)
        self.attemptElapsed = self.attemptElapsed + (elapsed or 0)
        if self.attemptElapsed < 0.15 then return end
        self.attemptElapsed = 0
        if WorldMapFrame and WorldMapFrame.IsShown and WorldMapFrame:IsShown() then
            local current = GetForeverBrowserCurrentMapID()
            if current and current ~= mapID and WorldMapFrame.SetMapID then
                WorldMapFrame:SetMapID(mapID)
            elseif current == mapID and PlaceMarker() then
                self:SetScript("OnUpdate", nil)
                self:Hide()
                if ForeverBrowserMarkerPendingUpdater == self then
                    ForeverBrowserMarkerPendingUpdater = nil
                end
                return
            end
        end
        if self.elapsed > 6 then
            self:SetScript("OnUpdate", nil)
            self:Hide()
            if ForeverBrowserMarkerPendingUpdater == self then
                ForeverBrowserMarkerPendingUpdater = nil
            end
            if DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00ForeverBrowser:|r Unable to place map dot for " .. tostring(sourceName or "location") .. ". Check recorded map coordinates.")
            end
        end
    end)
    updater:Show()
    return true
end

-- Multi-location explorer: uses the live canvas, retries map loading,
-- and keeps pins aligned when the map is resized or reopened.
local ForeverBrowserMultiRequest = 0
local ForeverBrowserMultiUpdater = nil

local function ShowAllForeverBrowserLocations(locations, requestedMapID, sourceName)
    if not BrowserSettingEnabled("enableMapMarkers") or type(locations) ~= "table" then
        return false
    end

    local grouped = {}
    local ordered = {}
    for _, loc in ipairs(locations) do
        if type(loc) == "table" then
            local id = tonumber(loc.uiMapID)
            local x, y = tonumber(loc.x), tonumber(loc.y)
            if id and x and y then
                if x > 1 then x=x/100 end
                if y > 1 then y=y/100 end
                if x >= 0 and x <= 1 and y >= 0 and y <= 1 then
                    if not grouped[id] then
                        grouped[id] = {}
                        table.insert(ordered, id)
                    end
                    table.insert(grouped[id], {
                        x=x,y=y,name=loc.name or sourceName or "NPC Location",
                        mapID=id
                    })
                end
            end
        end
    end

    if #ordered == 0 then
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00ForeverBrowser:|r No valid map coordinates for these locations.")
        end
        return false
    end

    local mapID = tonumber(requestedMapID)
    if not mapID or not grouped[mapID] then mapID=ordered[1] end

    ForeverBrowserMultiRequest = ForeverBrowserMultiRequest + 1
    local request = ForeverBrowserMultiRequest
    if ForeverBrowserMultiUpdater then
        ForeverBrowserMultiUpdater:SetScript("OnUpdate",nil)
        ForeverBrowserMultiUpdater:Hide()
    end
    ClearForeverBrowserAllMapMarkers()
    if ForeverBrowserMapMarker then ForeverBrowserMapMarker:Hide() end

    if not WorldMapFrame or not WorldMapFrame.SetMapID then return false end
    if not (WorldMapFrame.IsShown and WorldMapFrame:IsShown()) then
        if ToggleWorldMap then ToggleWorldMap()
        elseif WorldMapFrame.Show then WorldMapFrame:Show() end
    end
    WorldMapFrame:SetMapID(mapID)

    local updater=CreateFrame("Frame")
    ForeverBrowserMultiUpdater=updater
    updater.elapsed=0
    updater.tick=0
    updater.ready=false
    updater:SetScript("OnUpdate",function(self,dt)
        if request ~= ForeverBrowserMultiRequest then
            self:SetScript("OnUpdate",nil)
            self:Hide()
            return
        end
        self.elapsed=self.elapsed+(dt or 0)
        self.tick=self.tick+(dt or 0)
        if self.tick < 0.12 then return end
        self.tick=0

        if not WorldMapFrame or not WorldMapFrame.IsShown or not WorldMapFrame:IsShown() then
            if self.ready or self.elapsed > 6 then
                ClearForeverBrowserAllMapMarkers()
                self:SetScript("OnUpdate",nil)
                self:Hide()
            end
            return
        end
        local current=GetForeverBrowserCurrentMapID()
        if current ~= mapID then
            if self.elapsed < 6 and WorldMapFrame.SetMapID then
                WorldMapFrame:SetMapID(mapID)
            end
            return
        end
        local canvas=GetForeverBrowserMapCanvas()
        if not canvas or canvas:GetWidth()<=0 or canvas:GetHeight()<=0 then return end
        if not self.ready then
            ClearForeverBrowserAllMapMarkers()
            for i,loc in ipairs(grouped[mapID]) do
                local pin=CreateFrame("Button",nil,canvas)
                pin:SetSize(25,25)
                local ring=pin:CreateTexture(nil,"ARTWORK")
                ring:SetAllPoints(pin)
                ring:SetTexture("Interface\\COMMON\\Indicator-Yellow")
                ring:SetVertexColor(0.13,0.10,0.04,1)
                local dot=pin:CreateTexture(nil,"OVERLAY")
                dot:SetPoint("TOPLEFT",pin,"TOPLEFT",4,-4)
                dot:SetPoint("BOTTOMRIGHT",pin,"BOTTOMRIGHT",-4,4)
                dot:SetTexture("Interface\\COMMON\\Indicator-Yellow")
                dot:SetVertexColor(1,0.76,0.15,1)
                pin.fbX=loc.x
                pin.fbY=loc.y
                pin.fbName=loc.name
                pin.fbMapID=mapID
                pin:SetScript("OnEnter",function(button)
                    if GameTooltip then
                        GameTooltip:SetOwner(button,"ANCHOR_RIGHT")
                        GameTooltip:AddLine(button.fbName,1,0.82,0.3)
                        GameTooltip:AddLine(GetAutomaticMapName(button.fbMapID) or "Unknown Zone",0.85,0.85,0.85)
                        GameTooltip:AddLine(string.format("Location %d of %d  -  %.1f, %.1f",
                            i,#grouped[mapID],button.fbX*100,button.fbY*100),0.65,0.85,0.65)
                        GameTooltip:Show()
                    end
                end)
                pin:SetScript("OnLeave",function()
                    if GameTooltip then GameTooltip:Hide() end
                end)
                pin:Show()
                table.insert(ForeverBrowserAllMapMarkers,pin)
            end
            ForeverBrowserAllMarkerMapID=mapID
            self.ready=true
        end
        local width,height=canvas:GetWidth(),canvas:GetHeight()
        for _,pin in ipairs(ForeverBrowserAllMapMarkers) do
            if pin:GetParent() ~= canvas then pin:SetParent(canvas) end
            pin:ClearAllPoints()
            pin:SetPoint("CENTER",canvas,"TOPLEFT",width*pin.fbX,-height*pin.fbY)
            if pin.SetFrameLevel and canvas.GetFrameLevel then
                pin:SetFrameLevel(canvas:GetFrameLevel()+50)
            end
            pin:Show()
        end
    end)
    updater:Show()
    if #ordered>1 and DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00ForeverBrowser:|r Showing "
            ..tostring(#grouped[mapID]).." locations in "
            ..tostring(GetAutomaticMapName(mapID) or ("Map "..mapID))
            ..". Use the NPC's zone list to view other zones.")
    end
    return true
end

local function FormatSourceChance(chance)
    chance = tonumber(chance)

    if not chance then
        return nil
    end

    if chance >= 10 then
        return string.format("%.1f%%", chance)
    end

    return string.format("%.2f%%", chance)
end

local function CreateWhereToObtainSection(parent, itemID, startY)
    local title = CreateLabel(
        parent,
        "WHERE TO OBTAIN",
        18,
        {1, 0.82, 0.25, 1}
    )

    title:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        25,
        startY
    )

    local automatic = GetAutomaticItemSources(itemID)
    local sources = automatic and automatic.sources

    if not sources or #sources == 0 then
        local playerItem = GetPlayerItem(itemID)
        sources = playerItem and playerItem.sources
    end

    if not sources or #sources == 0 then
        local empty = CreateLabel(
            parent,
            "No source information is currently available for this item.",
            13,
            {0.68, 0.64, 0.56, 1}
        )

        empty:SetPoint(
            "TOPLEFT",
            title,
            "BOTTOMLEFT",
            0,
            -12
        )

        return 55
    end

    -- v1.118 source overview: compact acquisition summary before the
    -- detailed source rows. Counts are derived only from real source records.
    local sourceCounts = {}
    local bestDropChance = nil
    local mappedSources = 0

    for _, source in ipairs(sources) do
        local st = tostring(source.type or "unknown")
        sourceCounts[st] = (sourceCounts[st] or 0) + 1

        if st == "drop" then
            local c = tonumber(source.chance)
            if c and (not bestDropChance or c > bestDropChance) then
                bestDropChance = c
            end
        end

        if (type(source.locations) == "table" and #source.locations > 0)
            or (type(source.giverLocations) == "table" and #source.giverLocations > 0)
            or (source.uiMapID and source.x ~= nil and source.y ~= nil) then
            mappedSources = mappedSources + 1
        end
    end

    local summaryPanel = CreateFrame("Frame", nil, parent)
    summaryPanel:SetSize(790, 58)
    summaryPanel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    CreateSolidBackground(summaryPanel, 0.02, 0.027, 0.045, 1)

    local summaryTitle = CreateLabel(
        summaryPanel,
        "ACQUISITION OVERVIEW",
        11,
        {0.58, 0.61, 0.68, 1}
    )
    summaryTitle:SetPoint("TOPLEFT", summaryPanel, "TOPLEFT", 12, -8)

    local overviewParts = {}
    local overviewOrder = {
        {"drop", "Drops"},
        {"quest", "Quests"},
        {"vendor", "Vendors"},
        {"crafted", "Crafted"},
        {"object", "Objects"},
        {"pickpocket", "Pickpocket"},
        {"skinning", "Skinning"},
    }

    for _, info in ipairs(overviewOrder) do
        local count = sourceCounts[info[1]]
        if count and count > 0 then
            table.insert(overviewParts, info[2] .. ": " .. tostring(count))
        end
    end

    local overviewText = CreateLabel(
        summaryPanel,
        table.concat(overviewParts, "   |   "),
        12,
        {0.88, 0.88, 0.92, 1}
    )
    overviewText:SetPoint("TOPLEFT", summaryPanel, "TOPLEFT", 12, -29)

    if bestDropChance then
        local bestText = CreateLabel(
            summaryPanel,
            "Best drop: " .. (FormatSourceChance(bestDropChance) or "?"),
            11,
            {0.45, 0.85, 0.45, 1}
        )
        bestText:SetPoint("TOPRIGHT", summaryPanel, "TOPRIGHT", -12, -8)
    end

    if mappedSources > 0 then
        local mappedText = CreateLabel(
            summaryPanel,
            tostring(mappedSources) .. " mapped source"
                .. (mappedSources == 1 and "" or "s"),
            10,
            {0.45, 0.75, 1, 1}
        )
        mappedText:SetPoint("TOPRIGHT", summaryPanel, "TOPRIGHT", -12, -31)
    end

    local dataSource = automatic and automatic.dataSource
    local sourceNotice

    if dataSource == "classic" then
        sourceNotice = CreateLabel(
            parent,
            "Classic source data - may differ in WoW Forever.",
            12,
            {0.75, 0.62, 0.32, 1}
        )

        sourceNotice:SetPoint(
            "TOPLEFT",
            summaryPanel,
            "BOTTOMLEFT",
            0,
            -7
        )
    end

    local grouped = {}
    local groupTypes = {}

    for _, source in ipairs(sources) do
        local sourceType = tostring(source.type or "unknown")

        if not grouped[sourceType] then
            grouped[sourceType] = {}
            table.insert(groupTypes, sourceType)
        end

        table.insert(grouped[sourceType], source)
    end

    table.sort(
        groupTypes,
        function(a, b)
            local orderA = GetSourceTypeOrder(a)
            local orderB = GetSourceTypeOrder(b)

            if orderA ~= orderB then
                return orderA < orderB
            end

            return tostring(a) < tostring(b)
        end
    )

    for _, sourceType in ipairs(groupTypes) do
        table.sort(
            grouped[sourceType],
            function(a, b)
                local chanceA = tonumber(a.chance) or -1
                local chanceB = tonumber(b.chance) or -1

                if chanceA ~= chanceB then
                    return chanceA > chanceB
                end

                return tostring(a.name or "") < tostring(b.name or "")
            end
        )
    end

    local function CreateLocationButton(
        row,
        mapID,
        mapX,
        mapY,
        sourceName,
        yOffset
    )
        mapID = tonumber(mapID)
        mapX = tonumber(mapX)
        mapY = tonumber(mapY)
        sourceName = tostring(sourceName or "Unknown Source")

        if not mapID or not mapX or not mapY then
            return
        end

        local mapButton = CreateButton(
            row,
            "MAP",
            82,
            22
        )

        mapButton:SetPoint(
            "TOPRIGHT",
            row,
            "TOPRIGHT",
            -12,
            yOffset
        )

        mapButton:SetScript(
            "OnClick",
            function()
                ShowForeverBrowserMapMarker(
                    mapID,
                    mapX,
                    mapY,
                    sourceName
                )
            end
        )
    end

    -- Shared per-source-type browsing state, session-only.
    ForeverBrowserSourceViews = ForeverBrowserSourceViews or {}
    local sourceViews = ForeverBrowserSourceViews
    local function SourceZone(source)
        local first = type(source.locations)=="table" and source.locations[1] or nil
        local mapID = tonumber((first and first.uiMapID) or source.uiMapID)
        local zone = source.zone or (first and first.zone)
            or (mapID and GetAutomaticMapName(mapID))
        return tostring(zone and zone~="" and zone or "Unknown Zone")
    end
    local function RefreshSourcePage()
        if Navigate and CurrentURL then Navigate(CurrentURL) end
    end

    local y = sourceNotice and -112 or -84
    local maxSources = 40
    local shown = 0
    local totalSources = #sources

    for _, sourceType in ipairs(groupTypes) do
        -- Each source type now paginates independently.

        local group = grouped[sourceType]

        local heading = CreateLabel(
            parent,
            GetSourceTypeLabel(sourceType)
                .. "  ("
                .. tostring(#group)
                .. ")",
            14,
            {0.88, 0.72, 0.24, 1}
        )

        heading:SetPoint(
            "TOPLEFT",
            title,
            "BOTTOMLEFT",
            2,
            y
        )

        local headingLine = parent:CreateTexture(nil, "ARTWORK")
        headingLine:SetTexture("Interface\\Buttons\\WHITE8X8")
        headingLine:SetVertexColor(0.28, 0.23, 0.08, 0.75)
        headingLine:SetPoint("LEFT", heading, "RIGHT", 10, 0)
        headingLine:SetSize(555, 1)

        y = y - 25

        local displayGroup = group
        if true then
            local vendorView = sourceViews[sourceType]
            if not vendorView then
                vendorView = {page=1,perPage=10,sort="zone",zone="All Zones"}
                sourceViews[sourceType]=vendorView
            end
            displayGroup = {}
            for _, entry in ipairs(group) do table.insert(displayGroup, entry) end
            local zones, seenZones = {}, {}
            for _, entry in ipairs(displayGroup) do
                local zone=SourceZone(entry)
                if not seenZones[zone] then
                    seenZones[zone]=true
                    table.insert(zones,zone)
                end
            end
            table.sort(zones)
            if vendorView.zone ~= "All Zones" and not seenZones[vendorView.zone] then
                vendorView.zone="All Zones"
            end
            if vendorView.zone ~= "All Zones" then
                local filtered={}
                for _, entry in ipairs(displayGroup) do
                    if SourceZone(entry)==vendorView.zone then
                        table.insert(filtered,entry)
                    end
                end
                displayGroup=filtered
            end
            if vendorView.sort ~= "original" then
                table.sort(displayGroup, function(a,b)
                    if vendorView.sort == "zone" then
                        local za,zb=string.lower(SourceZone(a)),string.lower(SourceZone(b))
                        if za~=zb then return za<zb end
                    end
                    return string.lower(tostring(a.name or "")) <
                        string.lower(tostring(b.name or ""))
                end)
            end
            local perPage = tonumber(vendorView.perPage) or 10
            local pages = math.max(1, math.ceil(#displayGroup/perPage))
            vendorView.page = math.max(1, math.min(tonumber(vendorView.page) or 1,pages))
            local function VendorControl(label,width,x,callback)
                local b=CreateButton(parent,label,width,22)
                b:SetPoint("TOPLEFT",title,"BOTTOMLEFT",x,y)
                b:SetScript("OnClick",function() callback() RefreshSourcePage() end)
                return b
            end
            -- Custom dropdowns: compatible with WoW Forever without UIDropDownMenu.
            local function VendorDropdown(label,width,x,options,selected,callback)
                local toggle=CreateButton(parent,label.." "..selected.." v",width,22)
                toggle:SetPoint("TOPLEFT",title,"BOTTOMLEFT",x,y)
                local menu=CreateFrame("Frame",nil,parent)
                menu:SetSize(width,math.min(#options,8)*23+8)
                menu:SetPoint("TOPLEFT",toggle,"BOTTOMLEFT",0,-2)
                menu:SetFrameStrata("DIALOG")
                menu:SetFrameLevel(toggle:GetFrameLevel()+30)
                local bg=menu:CreateTexture(nil,"BACKGROUND")
                bg:SetAllPoints(menu)
                bg:SetTexture("Interface\\\\Buttons\\\\WHITE8X8")
                bg:SetVertexColor(0.045,0.05,0.07,0.98)
                local border=menu:CreateTexture(nil,"BORDER")
                border:SetPoint("TOPLEFT",menu,"TOPLEFT",0,0)
                border:SetPoint("TOPRIGHT",menu,"TOPRIGHT",0,0)
                border:SetHeight(1)
                border:SetTexture("Interface\\\\Buttons\\\\WHITE8X8")
                border:SetVertexColor(0.8,0.62,0.2,1)
                local scroll=CreateFrame("ScrollFrame",nil,menu)
                scroll:SetPoint("TOPLEFT",menu,"TOPLEFT",4,-4)
                scroll:SetPoint("BOTTOMRIGHT",menu,"BOTTOMRIGHT",-4,4)
                local inner=CreateFrame("Frame",nil,scroll)
                inner:SetSize(width-8,#options*23)
                scroll:SetScrollChild(inner)
                if scroll.EnableMouseWheel then
                    scroll:EnableMouseWheel(true)
                    scroll:SetScript("OnMouseWheel",function(self,delta)
                        local maximum=math.max(0,#options*23-scroll:GetHeight())
                        local current=self:GetVerticalScroll() or 0
                        self:SetVerticalScroll(math.max(0,math.min(maximum,current-delta*46)))
                    end)
                end
                for i,opt in ipairs(options) do
                    local option=CreateButton(inner,opt.label,opt.width or (width-10),21)
                    option:SetPoint("TOPLEFT",inner,"TOPLEFT",1,-(i-1)*23)
                    option:SetScript("OnClick",function()
                        menu:Hide()
                        callback(opt.value)
                        RefreshSourcePage()
                    end)
                end
                menu:Hide()
                toggle:SetScript("OnClick",function()
                    if menu:IsShown() then menu:Hide() else menu:Show() end
                end)
            end
            local zoneOptions={{label="All Zones",value="All Zones"}}
            for _,zone in ipairs(zones) do
                table.insert(zoneOptions,{label=zone,value=zone})
            end
            VendorDropdown("ZONE:",176,0,zoneOptions,
                vendorView.zone=="All Zones" and "ALL" or vendorView.zone,
                function(value) vendorView.zone=value vendorView.page=1 end)
            VendorDropdown("SORT:",152,184,{
                {label="Zone (A-Z)",value="zone"},
                {label="Vendor Name (A-Z)",value="name"},
                {label="Original Order",value="original"}
            },vendorView.sort=="zone" and "ZONE" or
                (vendorView.sort=="name" and "NAME" or "ORIGINAL"),
                function(value) vendorView.sort=value vendorView.page=1 end)
            VendorControl("SHOW: "..perPage,100,344,
                function() vendorView.perPage=perPage==10 and 20 or (perPage==20 and 40 or 10) vendorView.page=1 end)
            VendorControl("< PREV",82,455,
                function() vendorView.page=math.max(1,vendorView.page-1) end)
            VendorControl("NEXT >",82,543,
                function() vendorView.page=math.min(pages,vendorView.page+1) end)
            local pageLabel=CreateLabel(parent,"PAGE "..vendorView.page.." / "..pages,11,{0.88,0.72,0.24,1})
            pageLabel:SetPoint("TOPLEFT",title,"BOTTOMLEFT",637,y-4)
            y=y-34
            local firstIndex=(vendorView.page-1)*perPage+1
            local lastIndex=math.min(#displayGroup,firstIndex+perPage-1)
            local pageGroup={}
            for i=firstIndex,lastIndex do table.insert(pageGroup,displayGroup[i]) end
            displayGroup=pageGroup
        end

        local lastVendorZone = nil
        local activeView = sourceViews[sourceType]
        for _, source in ipairs(displayGroup) do
            if activeView and activeView.sort == "zone" then
                local zone=SourceZone(source)
                if zone ~= lastVendorZone then
                    local zoneHeader=CreateLabel(parent,zone,12,{0.50,0.77,1,1})
                    zoneHeader:SetPoint("TOPLEFT",title,"BOTTOMLEFT",12,y)
                    y=y-23
                    lastVendorZone=zone
                end
            end
            shown=shown+1

            local locations = {}

            if sourceType == "quest"
                and type(source.giverLocations) == "table"
                and #source.giverLocations > 0 then

                for _, location in ipairs(source.giverLocations) do
                    table.insert(locations, location)
                end

            elseif type(source.locations) == "table"
                and #source.locations > 0 then

                for _, location in ipairs(source.locations) do
                    table.insert(locations, location)
                end

            elseif source.uiMapID
                and source.x ~= nil
                and source.y ~= nil then

                table.insert(
                    locations,
                    {
                        uiMapID = source.uiMapID,
                        x = source.x,
                        y = source.y,
                        zone = source.zone
                    }
                )
            end

            local locationCount = #locations
            local isQuestSource = sourceType == "quest"

            local previousQuests =
                isQuestSource
                and type(source.previousQuests) == "table"
                and source.previousQuests
                or {}

            local nextQuests =
                isQuestSource
                and type(source.nextQuests) == "table"
                and source.nextQuests
                or {}

            local hasQuestChain =
                #previousQuests > 0
                or #nextQuests > 0

            local questChainHeight = 0

            if hasQuestChain then
                questChainHeight =
                    28
                    + (#previousQuests * 20)
                    + 28
                    + (#nextQuests * 20)
            end

            local questExtraHeight =
                isQuestSource
                and (42 + questChainHeight)
                or 0

            local rowHeight = 58 + questExtraHeight

            if locationCount > 0 then
                -- Reserve a separate line for the source-type badge above LOCATION.
                rowHeight = (isQuestSource and 44 or 60) + questExtraHeight + (locationCount * 28)
            end

            local row = CreateFrame(
                "Button",
                nil,
                parent
            )

            row:SetSize(790, rowHeight)
            row:SetPoint(
                "TOPLEFT",
                title,
                "BOTTOMLEFT",
                0,
                y
            )

            local bg = CreateSolidBackground(
                row,
                0.025,
                0.03,
                0.05,
                1
            )

            local sourceAccent = row:CreateTexture(nil, "ARTWORK")
            sourceAccent:SetTexture("Interface\\Buttons\\WHITE8X8")
            sourceAccent:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
            sourceAccent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
            sourceAccent:SetWidth(3)
            if sourceType == "drop" then
                sourceAccent:SetVertexColor(0.80, 0.28, 0.22, 0.95)
            elseif sourceType == "quest" then
                sourceAccent:SetVertexColor(1.00, 0.78, 0.20, 0.95)
            elseif sourceType == "vendor" then
                sourceAccent:SetVertexColor(0.30, 0.72, 1.00, 0.95)
            elseif sourceType == "crafted" then
                sourceAccent:SetVertexColor(0.72, 0.48, 1.00, 0.95)
            else
                sourceAccent:SetVertexColor(0.42, 0.46, 0.55, 0.90)
            end

            local sourceNameText =
                tostring(source.name or "Unknown Source")

            local sourceName = CreateLabel(
                row,
                sourceNameText,
                14,
                {0.92, 0.92, 0.96, 1}
            )

            sourceName:SetPoint(
                "TOPLEFT",
                row,
                "TOPLEFT",
                12,
                -9
            )

            local typeBadge = CreateLabel(
                row,
                GetSourceTypeLabel(sourceType),
                9,
                {0.58, 0.61, 0.68, 1}
            )
            typeBadge:SetPoint(
                "TOPLEFT",
                sourceName,
                "BOTTOMLEFT",
                0,
                -3
            )

            local chanceText = FormatSourceChance(source.chance)
            if chanceText then
                local chanceLabel = CreateLabel(
                    row,
                    chanceText,
                    12,
                    {0.45, 0.85, 0.45, 1}
                )
                chanceLabel:SetPoint(
                    "TOPRIGHT",
                    row,
                    "TOPRIGHT",
                    -130,
                    -9
                )
            end

            local firstLocation = locations[1]
            local firstMapID = firstLocation and tonumber(firstLocation.uiMapID)
            local zoneText =
                tostring(
                    source.zone
                    or (firstLocation and firstLocation.zone)
                    or (firstMapID and GetAutomaticMapName(firstMapID))
                    or ""
                )

            if zoneText ~= "" then
                local zoneLabel = CreateLabel(
                    row,
                    zoneText,
                    10,
                    {0.62, 0.66, 0.75, 1}
                )
                zoneLabel:SetPoint(
                    "TOPRIGHT",
                    row,
                    "TOPRIGHT",
                    -130,
                    -29
                )
            end

            --------------------------------------------------
            -- CLICKABLE NPC SOURCE
            --------------------------------------------------

            local sourceNPCID = nil

            if sourceType == "drop"
                or sourceType == "pickpocket"
                or sourceType == "skinning"
                or sourceType == "vendor" then

                sourceNPCID = tonumber(source.id)

                -- Stage 3 Forever dungeon sources may know the boss name
                -- and dungeon before a real server NPC ID is available.
                -- ID 0 is a sentinel, not a valid NPC page target.
                if sourceNPCID and sourceNPCID <= 0 then
                    sourceNPCID = nil
                end
            end

            if sourceNPCID then
                sourceName:SetTextColor(0.45, 0.75, 1, 1)

                local npcButton = CreateFrame(
                    "Button",
                    nil,
                    row
                )

                npcButton:SetPoint(
                    "TOPLEFT",
                    sourceName,
                    "TOPLEFT",
                    -2,
                    2
                )

                npcButton:SetPoint(
                    "BOTTOMRIGHT",
                    sourceName,
                    "BOTTOMRIGHT",
                    2,
                    -2
                )

                npcButton:SetScript(
                    "OnClick",
                    function()
                        Navigate(
                            "forever://npc/"
                            .. tostring(sourceNPCID)
                        )
                    end
                )

                npcButton:SetScript(
                    "OnEnter",
                    function()
                        sourceName:SetTextColor(0.70, 0.88, 1, 1)
                    end
                )

                npcButton:SetScript(
                    "OnLeave",
                    function()
                        sourceName:SetTextColor(0.45, 0.75, 1, 1)
                    end
                )
            end

            if isQuestSource then
                -- FOREVER_QUEST_DISPLAY_247
                typeBadge:Hide()
                sourceName:ClearAllPoints()
                sourceName:SetPoint("TOPLEFT", row, "TOPLEFT", 12, -9)
                sourceName:SetWidth(math.max(100, row:GetWidth() - 24))
                sourceName:SetHeight(18)
                sourceName:SetJustifyH("LEFT")
                sourceName:SetWordWrap(false)
                local clickableQuestName =
                    "|cffffd100["
                    .. tostring(source.name or "Unknown Quest")
                    .. "]|r"

                -- The main quest name is yellow + bracketed to signal a link.
                sourceName:SetText(clickableQuestName)

                local questNameText = CreateLabel(
                    row,
                    (source.choiceReward and "CHOICE QUEST REWARD" or "QUEST REWARD"),
                    10,
                    {0.45, 0.75, 1, 1}
                )

                questNameText:SetPoint(
                    "TOPLEFT",
                    row,
                    "TOPLEFT",
                    12,
                    -29
                )

                --------------------------------------------------
                -- CLICKABLE QUEST SOURCE
                --------------------------------------------------

                local sourceQuestID = tonumber(source.id)

                if sourceQuestID then
                    sourceName:SetTextColor(1, 1, 1, 1)
                    questNameText:SetTextColor(1, 1, 1, 1)

                    local questSourceButton = CreateFrame(
                        "Button",
                        nil,
                        row
                    )

                    questSourceButton:SetPoint(
                        "TOPLEFT",
                        sourceName,
                        "TOPLEFT",
                        -2,
                        2
                    )

                    questSourceButton:SetPoint(
                        "BOTTOMRIGHT",
                        questNameText,
                        "BOTTOMRIGHT",
                        2,
                        -2
                    )

                    questSourceButton:SetScript(
                        "OnClick",
                        function()
                            Navigate(
                                "forever://quest/"
                                .. tostring(sourceQuestID)
                            )
                        end
                    )

                    questSourceButton:SetScript(
                        "OnEnter",
                        function()
                            sourceName:SetTextColor(1, 1, 1, 1)
                            questNameText:SetTextColor(1, 1, 1, 1)
                        end
                    )

                    questSourceButton:SetScript(
                        "OnLeave",
                        function()
                            sourceName:SetTextColor(1, 1, 1, 1)
                            questNameText:SetTextColor(1, 1, 1, 1)
                        end
                    )
                end

                local giverLabel = CreateLabel(
                    row,
                    "GIVEN BY",
                    10,
                    {0.72, 0.72, 0.78, 1}
                )

                giverLabel:SetPoint(
                    "TOPLEFT",
                    row,
                    "TOPLEFT",
                    12,
                    -47
                )

                local giverName = CreateLabel(
                    row,
                    tostring(source.giverName or "Quest giver not available"),
                    12,
                    source.giverName
                        and {0.88, 0.88, 0.94, 1}
                        or {0.68, 0.64, 0.56, 1}
                )

                giverName:SetPoint(
                    "TOPLEFT",
                    row,
                    "TOPLEFT",
                    82,
                    -45
                )

                local questGiverID =
                    tonumber(source.giverID)

                if questGiverID
                    and source.giverName then

                    giverName:SetTextColor(0.45, 0.75, 1, 1)

                    local giverButton = CreateFrame(
                        "Button",
                        nil,
                        row
                    )

                    giverButton:SetPoint(
                        "TOPLEFT",
                        giverName,
                        "TOPLEFT",
                        -2,
                        2
                    )

                    giverButton:SetPoint(
                        "BOTTOMRIGHT",
                        giverName,
                        "BOTTOMRIGHT",
                        2,
                        -2
                    )

                    giverButton:SetScript(
                        "OnClick",
                        function()
                            Navigate(
                                "forever://npc/"
                                .. tostring(questGiverID)
                            )
                        end
                    )

                    giverButton:SetScript(
                        "OnEnter",
                        function()
                            giverName:SetTextColor(0.70, 0.88, 1, 1)
                        end
                    )

                    giverButton:SetScript(
                        "OnLeave",
                        function()
                            giverName:SetTextColor(0.45, 0.75, 1, 1)
                        end
                    )
                end

                if hasQuestChain then
                    local chainY = -70

                    local chainTitle = CreateLabel(
                        row,
                        "QUEST CHAIN",
                        11,
                        {1, 0.82, 0.25, 1}
                    )

                    chainTitle:SetPoint(
                        "TOPLEFT",
                        row,
                        "TOPLEFT",
                        12,
                        chainY
                    )

                    chainY = chainY - 22

                    if #previousQuests > 0 then
                        local previousLabel = CreateLabel(
                            row,
                            "PREVIOUS QUEST",
                            10,
                            {0.72, 0.72, 0.78, 1}
                        )

                        previousLabel:SetPoint(
                            "TOPLEFT",
                            row,
                            "TOPLEFT",
                            12,
                            chainY
                        )

                        chainY = chainY - 18

                        for _, relatedQuest in ipairs(previousQuests) do
                            local relatedID = tonumber(relatedQuest.id)
                            local relatedName = tostring(
                                relatedQuest.name
                                or ("Quest " .. tostring(relatedID or "?"))
                            )

                            local previousText = CreateLabel(
                                row,
                                relatedName
                                .. "  ["
                                .. tostring(relatedID or "?")
                                .. "]",
                                11,
                                {0.45, 0.75, 1, 1}
                            )

                            previousText:SetPoint(
                                "TOPLEFT",
                                row,
                                "TOPLEFT",
                                24,
                                chainY
                            )

                            chainY = chainY - 20
                        end
                    end

                    if #nextQuests > 0 then
                        local nextLabel = CreateLabel(
                            row,
                            "NEXT QUEST",
                            10,
                            {0.72, 0.72, 0.78, 1}
                        )

                        nextLabel:SetPoint(
                            "TOPLEFT",
                            row,
                            "TOPLEFT",
                            12,
                            chainY
                        )

                        chainY = chainY - 18

                        for _, relatedQuest in ipairs(nextQuests) do
                            local relatedID = tonumber(relatedQuest.id)
                            local relatedName = tostring(
                                relatedQuest.name
                                or ("Quest " .. tostring(relatedID or "?"))
                            )

                            local nextText = CreateLabel(
                                row,
                                relatedName
                                .. "  ["
                                .. tostring(relatedID or "?")
                                .. "]",
                                11,
                                {0.45, 0.75, 1, 1}
                            )

                            nextText:SetPoint(
                                "TOPLEFT",
                                row,
                                "TOPLEFT",
                                24,
                                chainY
                            )

                            chainY = chainY - 20
                        end
                    end
                end
            end

            local chanceText = FormatSourceChance(source.chance)

            if chanceText then
                local chanceLabel = CreateLabel(
                    row,
                    "DROP CHANCE  " .. chanceText,
                    12,
                    {0.45, 0.85, 0.45, 1}
                )

                chanceLabel:SetPoint(
                    "TOPRIGHT",
                    row,
                    "TOPRIGHT",
                    -12,
                    -8
                )
            end

            if locationCount > 1 then
                local savedLocations = locations

                local showAllButton = CreateButton(
                    row,
                    "SHOW ALL",
                    90,
                    20
                )

                showAllButton:SetPoint(
                    "TOPRIGHT",
                    row,
                    "TOPRIGHT",
                    -12,
                    isQuestSource
                        and (-67 - questChainHeight)
                        or -29
                )

                showAllButton:SetScript(
                    "OnClick",
                    function()
                        ShowAllForeverBrowserLocations(savedLocations)
                    end
                )
            end

            if locationCount > 0 then
                local locationHeader = CreateLabel(
                    row,
                    locationCount == 1
                        and "LOCATION"
                        or ("LOCATIONS  (" .. tostring(locationCount) .. ")"),
                    10,
                    {0.72, 0.72, 0.78, 1}
                )

                locationHeader:SetPoint(
                    "TOPLEFT",
                    row,
                    "TOPLEFT",
                    12,
                    isQuestSource
                        and (-73 - questChainHeight)
                        or -46
                )

                local locationY =
                    isQuestSource
                    and (-91 - questChainHeight)
                    or -64

                for _, location in ipairs(locations) do
                    local mapID = tonumber(location.uiMapID)
                    local mapX = tonumber(location.x)
                    local mapY = tonumber(location.y)

                    if mapID and mapX and mapY then
                        local zoneName = location.zone

                        if not zoneName
                            or tostring(zoneName) == "" then
                            zoneName = GetAutomaticMapName(mapID)
                        end

                        local locationText = ""

                        if zoneName
                            and tostring(zoneName) ~= "" then
                            locationText =
                                tostring(zoneName) .. "  -  "
                        end

                        locationText =
                            locationText
                            .. string.format(
                                "%.1f, %.1f",
                                mapX,
                                mapY
                            )

                        local info = CreateLabel(
                            row,
                            locationText,
                            11,
                            {0.78, 0.71, 0.58, 1}
                        )

                        info:SetPoint(
                            "TOPLEFT",
                            row,
                            "TOPLEFT",
                            24,
                            locationY
                        )

                        local markerName = sourceNameText

                        if isQuestSource and source.giverName then
                            markerName =
                                tostring(source.giverName)
                                .. " - "
                                .. sourceNameText
                        end

                        CreateLocationButton(
                            row,
                            mapID,
                            mapX,
                            mapY,
                            markerName,
                            locationY + 5
                        )

                        locationY = locationY - 28
                    end
                end
            end

            local provenanceText
            local provenanceColor

            if source.forever then
                provenanceText = "FOREVER DATA"
                provenanceColor = {0.35, 0.90, 0.45, 1}
            elseif dataSource == "classic" then
                provenanceText = "CLASSIC DATA"
                provenanceColor = {0.72, 0.62, 0.35, 1}
            end

            if provenanceText then
                local provenance = CreateLabel(
                    row,
                    provenanceText,
                    10,
                    provenanceColor
                )

                provenance:SetPoint(
                    "BOTTOMRIGHT",
                    row,
                    "BOTTOMRIGHT",
                    -12,
                    7
                )
            end

            row:SetScript(
                "OnEnter",
                function()
                    bg:SetVertexColor(0.08, 0.10, 0.16, 1)
                end
            )

            row:SetScript(
                "OnLeave",
                function()
                    bg:SetVertexColor(unpack(WOW_THEME.row))
                end
            )

            y = y - rowHeight - 6
        end

        y = y - 10
    end

    if false then -- All source groups are paginated; legacy truncation notice disabled.
        local more = CreateLabel(
            parent,
            "+ " .. tostring(totalSources - maxSources) .. " additional sources",
            12,
            {0.60, 0.63, 0.70, 1}
        )

        more:SetPoint(
            "TOPLEFT",
            title,
            "BOTTOMLEFT",
            4,
            y + 2
        )

        y = y - 26
    end

    return math.abs(y) + 25
end

--------------------------------------------------
-- EXTRA ITEM DETAILS
--------------------------------------------------

local function GetRequiredLevel(itemID, item)

    local level =
        GetItemField(
            item,
            "requiredLevel",
            "RequiredLevel",
            "reqLevel"
        )

    if level ~= nil then
        return tonumber(level) or 0
    end

    if C_Item
        and C_Item.GetItemInfo then

        local ok,
            name,
            link,
            quality,
            itemLevel,
            requiredLevel =
            pcall(
                C_Item.GetItemInfo,
                itemID
            )

        if ok
            and requiredLevel then

            return tonumber(requiredLevel) or 0
        end
    end

    if GetItemInfo then

        local ok,
            name,
            link,
            quality,
            itemLevel,
            requiredLevel =
            pcall(
                GetItemInfo,
                itemID
            )

        if ok
            and requiredLevel then

            return tonumber(requiredLevel) or 0
        end
    end

    return 0
end


local function GetMaxStack(itemID, item)

    local stack =
        GetItemField(
            item,
            "maxStack",
            "MaxStack",
            "maxStackCount"
        )

    if stack ~= nil then
        return tonumber(stack) or 1
    end

    if C_Item
        and C_Item.GetItemInfo then

        local ok,
            name,
            link,
            quality,
            itemLevel,
            requiredLevel,
            class,
            subclass,
            maxStack =
            pcall(
                C_Item.GetItemInfo,
                itemID
            )

        if ok
            and maxStack then

            return tonumber(maxStack) or 1
        end
    end

    if GetItemInfo then

        local ok,
            name,
            link,
            quality,
            itemLevel,
            requiredLevel,
            class,
            subclass,
            maxStack =
            pcall(
                GetItemInfo,
                itemID
            )

        if ok
            and maxStack then

            return tonumber(maxStack) or 1
        end
    end

    return 1
end


local function GetSellPrice(itemID, item)

    local price =
        GetItemField(
            item,
            "sellPrice",
            "SellPrice",
            "vendorSellPrice"
        )

    if price ~= nil then
        return tonumber(price) or 0
    end

    if C_Item
        and C_Item.GetItemInfo then

        local ok,
            name,
            link,
            quality,
            itemLevel,
            requiredLevel,
            class,
            subclass,
            maxStack,
            equipSlot,
            texture,
            sellPrice =
            pcall(
                C_Item.GetItemInfo,
                itemID
            )

        if ok
            and sellPrice then

            return tonumber(sellPrice) or 0
        end
    end

    if GetItemInfo then

        local ok,
            name,
            link,
            quality,
            itemLevel,
            requiredLevel,
            class,
            subclass,
            maxStack,
            equipSlot,
            texture,
            sellPrice =
            pcall(
                GetItemInfo,
                itemID
            )

        if ok
            and sellPrice then

            return tonumber(sellPrice) or 0
        end
    end

    return 0
end


local function FormatMoney(copper)

    copper =
        tonumber(copper) or 0

    if copper <= 0 then
        return "Not available"
    end

    local gold =
        math.floor(copper / 10000)

    local silver =
        math.floor(
            (copper % 10000) / 100
        )

    local copperOnly =
        copper % 100

    local parts = {}

    if gold > 0 then
        table.insert(
            parts,
            tostring(gold) .. "g"
        )
    end

    if silver > 0 then
        table.insert(
            parts,
            tostring(silver) .. "s"
        )
    end

    if copperOnly > 0
        or #parts == 0 then

        table.insert(
            parts,
            tostring(copperOnly) .. "c"
        )
    end

    return table.concat(
        parts,
        " "
    )
end


local function GetItemTypeInfo(itemID, item)

    local class =
        GetItemField(
            item,
            "class",
            "Class",
            "className"
        )

    local subclass =
        GetItemField(
            item,
            "subclass",
            "Subclass",
            "subClass",
            "subclassName"
        )

    if class
        or subclass then

        return tostring(class or GetClassName(itemID, item)),
            tostring(subclass or "Other")
    end

    if C_Item
        and C_Item.GetItemInfo then

        local ok,
            name,
            link,
            quality,
            itemLevel,
            requiredLevel,
            apiClass,
            apiSubclass =
            pcall(
                C_Item.GetItemInfo,
                itemID
            )

        if ok then
            return tostring(apiClass or GetClassName(itemID, item)),
                tostring(apiSubclass or "Other")
        end
    end

    if GetItemInfo then

        local ok,
            name,
            link,
            quality,
            itemLevel,
            requiredLevel,
            apiClass,
            apiSubclass =
            pcall(
                GetItemInfo,
                itemID
            )

        if ok then
            return tostring(apiClass or GetClassName(itemID, item)),
                tostring(apiSubclass or "Other")
        end
    end

    return GetClassName(itemID, item),
        "Other"
end


local function GetQualityColor(quality)

    local colors = {
        [0] = {0.62, 0.62, 0.62},
        [1] = {1.00, 1.00, 1.00},
        [2] = {0.30, 1.00, 0.30},
        [3] = {0.30, 0.55, 1.00},
        [4] = {0.70, 0.35, 1.00},
        [5] = {1.00, 0.50, 0.05},
        [6] = {0.95, 0.85, 0.25},
        [7] = {0.00, 0.85, 1.00},
    }

    return colors[
        tonumber(quality) or 0
    ] or {1, 1, 1}
end


--------------------------------------------------
-- ITEM PAGE
--------------------------------------------------

-- Native item actions retain the text field used by favorite updates.
-- Addon-wide Codex surface and title styling, independent of saved colors.
local function BuildItemPage(itemID)

    ClearPage()

    itemID =
        tonumber(itemID)

    if not itemID then
        return
    end

    local item =
        GetAnyItem(
            itemID
        )

    if not item then

        local missing =
            ForeverBrowser_AchievementLabel(
                PageContent,
                "Item not found.",
                22,
                {
                    1,
                    0.35,
                    0.35,
                    1
                }
            )

        missing:SetPoint(
            "TOPLEFT",
            PageContent,
            "TOPLEFT",
            25,
            -30
        )

        return
    end

    AddRecentItem(
        itemID
    )

    --------------------------------------------------
    -- BACK BUTTON
    --------------------------------------------------

    local back =
        ForeverBrowser_ItemButton190(
            PageContent,
            "< Back",
            90,
            30
        )

    back:SetPoint(
        "TOPLEFT",
        PageContent,
        "TOPLEFT",
        20,
        -20
    )

    back:SetScript(
        "OnClick",
        function()

            if HistoryPosition > 1 then

                HistoryPosition =
                    HistoryPosition - 1

                local url =
                    History[
                        HistoryPosition
                    ]

                Navigate(
                    url,
                    true
                )

            else

                Navigate(
                    "forever://home"
                )

            end

        end
    )

    --------------------------------------------------
    -- BASIC DATA
    --------------------------------------------------

    local name =
        GetItemField(
            item,
            "name",
            "itemName"
        )

    if not name then
        name =
            GetItemName(
                itemID
            )
    end

    -- The item details page reads the raw record name directly above,
    -- so normalize it here as well before creating the large name label.
    name =
        CleanItemDisplayName(
            itemID,
            item,
            name
        )

    local quality =
        GetQuality(
            itemID,
            item
        )

    local qualityColor =
        GetQualityColor(
            quality
        )

    local itemLevel =
        GetItemLevel(
            itemID,
            item
        )

    local className =
        GetClassName(
            itemID,
            item
        )

    local itemType,
        itemSubtype =
        GetItemTypeInfo(
            itemID,
            item
        )

    local requiredLevel =
        GetRequiredLevel(
            itemID,
            item
        )

    local maxStack =
        GetMaxStack(
            itemID,
            item
        )

    local sellPrice =
        GetSellPrice(
            itemID,
            item
        )

    local owned =
        GetPlayerItem(
            itemID
        )

    --------------------------------------------------
    -- ITEM HERO PANEL
    --------------------------------------------------

    local heroPanel = CreateFrame("Frame", nil, PageContent)
    heroPanel:SetSize(790, 170)
    heroPanel:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, -62)
    CreateSolidBackground(heroPanel, 0.055, 0.045, 0.033, 1)
    ForeverBrowser_AchievementBorder(heroPanel, true)

    local heroAccent = heroPanel:CreateTexture(nil, "ARTWORK")
    heroAccent:SetTexture("Interface\\Buttons\\WHITE8X8")
    heroAccent:SetVertexColor(
        qualityColor[1] or 1,
        qualityColor[2] or 0.82,
        qualityColor[3] or 0.25,
        0.9
    )
    heroAccent:SetPoint("TOPLEFT", heroPanel, "TOPLEFT", 0, 0)
    heroAccent:SetPoint("TOPRIGHT", heroPanel, "TOPRIGHT", 0, 0)
    heroAccent:SetHeight(2)

    --------------------------------------------------
    -- LARGE ICON
    --------------------------------------------------

    local icon =
        heroPanel:CreateTexture(
            nil,
            "ARTWORK"
        )

    icon:SetSize(
        104,
        104
    )

    icon:SetPoint(
        "TOPLEFT",
        heroPanel,
        "TOPLEFT",
        15,
        -15
    )

    icon:SetTexture(
        GetItemIcon(
            itemID,
            item
        )
    )

    -- Quality-colored icon frame.
    local iconBorder = CreateFrame("Frame", nil, heroPanel)
    iconBorder:SetPoint("TOPLEFT", icon, "TOPLEFT", -3, 3)
    iconBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 3, -3)

    local function AddIconBorderEdge(point1, point2, vertical)
        local edge = iconBorder:CreateTexture(nil, "OVERLAY")
        edge:SetTexture("Interface\\Buttons\\WHITE8X8")
        edge:SetVertexColor(qualityColor[1], qualityColor[2], qualityColor[3], 0.95)
        edge:SetPoint(point1, iconBorder, point1, 0, 0)
        edge:SetPoint(point2, iconBorder, point2, 0, 0)
        if vertical then edge:SetWidth(2) else edge:SetHeight(2) end
    end

    AddIconBorderEdge("TOPLEFT", "TOPRIGHT", false)
    AddIconBorderEdge("BOTTOMLEFT", "BOTTOMRIGHT", false)
    AddIconBorderEdge("TOPLEFT", "BOTTOMLEFT", true)
    AddIconBorderEdge("TOPRIGHT", "BOTTOMRIGHT", true)

    local heroItemID = ForeverBrowser_AchievementLabel(
        heroPanel, "ID " .. tostring(itemID), 10, {0.45, 0.48, 0.56, 1}
    )
    heroItemID:SetPoint("BOTTOMLEFT", heroPanel, "BOTTOMLEFT", 15, 12)


    --------------------------------------------------
    -- ITEM NAME
    --------------------------------------------------

    local nameLabel =
        ForeverBrowser_AchievementLabel(
            heroPanel,
            name or "Unknown Item",
            22,
            qualityColor
        )

    nameLabel:SetPoint(
        "TOPLEFT",
        icon,
        "TOPRIGHT",
        25,
        -5
    )

    nameLabel:SetWidth(440)
    nameLabel:SetHeight(48)
    nameLabel:SetJustifyH("LEFT")
    nameLabel:SetJustifyV("TOP")

    --------------------------------------------------
    -- FAVORITE BUTTON
    --------------------------------------------------

    local favoriteButton =
        ForeverBrowser_ItemButton190(
            heroPanel,
            IsFavorite(itemID)
                and "FAVORITED"
                or "FAVORITE",
            145,
            30
        )

    favoriteButton:SetPoint(
        "TOPRIGHT",
        heroPanel,
        "TOPRIGHT",
        -15,
        -15
    )

    local favoriteIcon =
        favoriteButton:CreateTexture(
            nil,
            "ARTWORK"
        )

    favoriteIcon:SetSize(
        18,
        18
    )

    favoriteIcon:SetPoint(
        "LEFT",
        favoriteButton,
        "LEFT",
        10,
        0
    )

    favoriteIcon:SetTexture(
        "Interface\\COMMON\\ReputationStar"
    )

    if favoriteButton.text then

        favoriteButton.text:ClearAllPoints()

        favoriteButton.text:SetPoint(
            "LEFT",
            favoriteIcon,
            "RIGHT",
            7,
            0
        )

    end

    local function UpdateFavoriteButton()

        local active =
            IsFavorite(itemID)

        if favoriteButton.text then

            favoriteButton.text:SetText(
                active
                    and "FAVORITED"
                    or "FAVORITE"
            )

        end

        if active then

            favoriteIcon:SetVertexColor(
                1,
                0.82,
                0.20,
                1
            )

        else

            favoriteIcon:SetVertexColor(
                0.55,
                0.55,
                0.55,
                1
            )

        end
    end

    UpdateFavoriteButton()

    favoriteButton:SetScript(
        "OnClick",
        function()

            SetFavorite(
                itemID,
                not IsFavorite(itemID)
            )

            UpdateFavoriteButton()

        end
    )

    --------------------------------------------------
    -- COMPARE BUTTON
    --------------------------------------------------

    local compareButton =
        ForeverBrowser_ItemButton190(
            heroPanel,
            "COMPARE",
            145,
            30
        )

    compareButton:SetPoint(
        "TOPRIGHT",
        favoriteButton,
        "BOTTOMRIGHT",
        0,
        -8
    )

    compareButton:SetScript(
        "OnClick",
        function()

            CompareFirstItemID =
                itemID

            Navigate(
                "forever://compare-select/"
                .. tostring(itemID)
            )

        end
    )

    --------------------------------------------------
    -- LINK ITEM BUTTON
    --------------------------------------------------

    local linkButton =
        ForeverBrowser_ItemButton190(
            heroPanel,
            "LINK ITEM",
            145,
            30
        )

    linkButton:SetPoint(
        "TOPRIGHT",
        compareButton,
        "BOTTOMRIGHT",
        0,
        -8
    )

    linkButton:SetScript(
        "OnClick",
        function()

            LinkItemToChat(
                itemID
            )

        end
    )

    --------------------------------------------------
    -- ADD TO LIST BUTTON
    --------------------------------------------------

    local listButton =
        ForeverBrowser_ItemButton190(
            heroPanel,
            "ADD TO LIST",
            145,
            30
        )

    listButton:SetPoint(
        "TOPRIGHT",
        linkButton,
        "BOTTOMRIGHT",
        0,
        -8
    )

    listButton:SetScript(
        "OnClick",
        function()

            Navigate(
                "forever://lists/add/"
                .. tostring(itemID)
            )

        end
    )

    --------------------------------------------------
    -- QUALITY / TYPE
    --------------------------------------------------

    local qualityLabel =
        ForeverBrowser_AchievementLabel(
            heroPanel,
            GetQualityName(quality),
            14,
            qualityColor
        )

    qualityLabel:SetPoint(
        "TOPLEFT",
        nameLabel,
        "BOTTOMLEFT",
        0,
        -10
    )

    local typeLabel =
        ForeverBrowser_AchievementLabel(
            heroPanel,
            (itemSubtype and tostring(itemSubtype) ~= "" and tostring(itemSubtype) ~= tostring(itemType))
                and (tostring(itemType) .. "  |  " .. tostring(itemSubtype))
                or tostring(itemType),
            13,
            {
                0.75,
                0.76,
                0.82,
                1
            }
        )

    typeLabel:SetPoint(
        "TOPLEFT",
        qualityLabel,
        "BOTTOMLEFT",
        0,
        -8
    )

    --------------------------------------------------
    -- ITEM LEVEL
    --------------------------------------------------

    local levelText =
        "Item Level: "
        .. tostring(itemLevel)

    local levelLabel =
        ForeverBrowser_AchievementLabel(
            heroPanel,
            levelText,
            13,
            {
                0.78,
                0.79,
                0.84,
                1
            }
        )

    levelLabel:SetPoint(
        "TOPLEFT",
        typeLabel,
        "BOTTOMLEFT",
        0,
        -8
    )

    --------------------------------------------------
    -- DISCOVERY STATUS
    --------------------------------------------------

    local ownedText

    if owned then
        ownedText =
            "Discovered in your database"
    else
        ownedText =
            "World database item"
    end

    local ownedLabel =
        ForeverBrowser_AchievementLabel(
            heroPanel,
            ownedText,
            13,
            {
                0.45,
                0.85,
                0.45,
                1
            }
        )

    ownedLabel:SetPoint(
        "TOPLEFT",
        levelLabel,
        "BOTTOMLEFT",
        0,
        -9
    )

    --------------------------------------------------
    -- ITEM INFORMATION PANEL
    --------------------------------------------------

    -- v1.115: richer item detail presentation. We only display values that
    -- actually exist in the database/client API; no guessed item stats.
    local previewOffset=ForeverBrowser_P205Inline(itemID,PageContent,-248)
    local informationPanel = CreateFrame("Frame", nil, PageContent)
    informationPanel:SetSize(790, 560)
    informationPanel:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, -248-previewOffset)
    CreateSolidBackground(informationPanel, 0.045, 0.038, 0.029, 1)
    ForeverBrowser_AchievementBorder(informationPanel, true)

    local information = ForeverBrowser_AchievementLabel(
        informationPanel,
        "ITEM INFORMATION",
        18,
        {1, 0.82, 0.25, 1}
    )
    information:SetPoint("TOPLEFT", informationPanel, "TOPLEFT", 15, -10)

    local informationLine = informationPanel:CreateTexture(nil, "ARTWORK")
    informationLine:SetTexture("Interface\\Buttons\\WHITE8X8")
    informationLine:SetVertexColor(0.32, 0.26, 0.09, 0.8)
    informationLine:SetPoint("TOPLEFT", informationPanel, "TOPLEFT", 15, -35)
    informationLine:SetPoint("TOPRIGHT", informationPanel, "TOPRIGHT", -15, -35)
    informationLine:SetHeight(1)

    local function DetailSectionTitle(text, x, y, width)
        local label = ForeverBrowser_AchievementLabel(informationPanel, text, 11, {0.92, 0.76, 0.25, 1})
        label:SetPoint("TOPLEFT", informationPanel, "TOPLEFT", x, y)
        local line = informationPanel:CreateTexture(nil, "ARTWORK")
        line:SetTexture("Interface\\Buttons\\WHITE8X8")
        line:SetVertexColor(0.36, 0.28, 0.13, 0.75)
        line:SetPoint("TOPLEFT", informationPanel, "TOPLEFT", x, y - 20)
        line:SetSize(width, 1)
        return label
    end

    local function DetailValue(text, x, y, color)
        local label = ForeverBrowser_AchievementLabel(
            informationPanel,
            text,
            12,
            color or {0.78, 0.79, 0.84, 1}
        )
        label:SetPoint("TOPLEFT", informationPanel, "TOPLEFT", x, y)
        return label
    end

    -- Pull optional fields from generated/player/world records. Different
    -- Forever datasets use different field names, so accept known aliases.
    local equipSlot = GetItemField(
        item, "equipSlot", "EquipSlot", "inventoryType", "InventoryType", "slot"
    )
    local bindType = GetItemField(
        item, "bindType", "BindType", "bonding", "Bonding", "binding"
    )
    local durability = GetItemField(
        item, "durability", "Durability", "maxDurability", "MaxDurability"
    )
    local armorValue = GetItemField(
        item, "armor", "Armor", "armorValue", "ArmorValue"
    )

    DetailSectionTitle("EQUIPMENT", 15, -52, 360)
    DetailValue("Type", 15, -82, {0.58, 0.61, 0.68, 1})
    DetailValue(itemType .. " / " .. itemSubtype, 112, -82)
    DetailValue("Item Level", 15, -104, {0.58, 0.61, 0.68, 1})
    DetailValue(tostring(itemLevel), 112, -104, {1, 0.82, 0.25, 1})
    DetailValue("Required", 15, -126, {0.58, 0.61, 0.68, 1})
    DetailValue(
        tonumber(requiredLevel) and tonumber(requiredLevel) > 0
            and ("Level " .. tostring(requiredLevel))
            or "None",
        112,
        -126
    )

    if equipSlot and tostring(equipSlot) ~= "" then
        DetailValue("Equip Slot", 15, -148, {0.58, 0.61, 0.68, 1})
        DetailValue(tostring(equipSlot), 112, -148)
    end

    if bindType and tostring(bindType) ~= "" then
        DetailValue("Binding", 15, -170, {0.58, 0.61, 0.68, 1})
        DetailValue(tostring(bindType), 112, -170)
    end

    DetailSectionTitle("STATS", 405, -52, 370)

    local statRows = {}
    local seenStats = {}

    local statLabels = {
        ITEM_MOD_STRENGTH_SHORT = "Strength",
        ITEM_MOD_AGILITY_SHORT = "Agility",
        ITEM_MOD_STAMINA_SHORT = "Stamina",
        ITEM_MOD_INTELLECT_SHORT = "Intellect",
        ITEM_MOD_SPIRIT_SHORT = "Spirit",
        ITEM_MOD_ATTACK_POWER_SHORT = "Attack Power",
        ITEM_MOD_RANGED_ATTACK_POWER_SHORT = "Ranged Attack Power",
        ITEM_MOD_SPELL_POWER_SHORT = "Spell Power",
        ITEM_MOD_HIT_RATING_SHORT = "Hit Rating",
        ITEM_MOD_CRIT_RATING_SHORT = "Crit Rating",
        ITEM_MOD_HASTE_RATING_SHORT = "Haste Rating",
        ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "Defense Rating",
        ITEM_MOD_DODGE_RATING_SHORT = "Dodge Rating",
        ITEM_MOD_PARRY_RATING_SHORT = "Parry Rating",
        ITEM_MOD_BLOCK_RATING_SHORT = "Block Rating",
        ITEM_MOD_RESILIENCE_RATING_SHORT = "Resilience",
        ITEM_MOD_MASTERY_RATING_SHORT = "Mastery",
        ITEM_MOD_VERSATILITY = "Versatility",
        RESISTANCE0_NAME = "Armor",
        RESISTANCE1_NAME = "Holy Resistance",
        RESISTANCE2_NAME = "Fire Resistance",
        RESISTANCE3_NAME = "Nature Resistance",
        RESISTANCE4_NAME = "Frost Resistance",
        RESISTANCE5_NAME = "Shadow Resistance",
        RESISTANCE6_NAME = "Arcane Resistance",
    }

    local statOrder = {
        "RESISTANCE0_NAME",
        "ITEM_MOD_STRENGTH_SHORT",
        "ITEM_MOD_AGILITY_SHORT",
        "ITEM_MOD_STAMINA_SHORT",
        "ITEM_MOD_INTELLECT_SHORT",
        "ITEM_MOD_SPIRIT_SHORT",
        "ITEM_MOD_ATTACK_POWER_SHORT",
        "ITEM_MOD_RANGED_ATTACK_POWER_SHORT",
        "ITEM_MOD_SPELL_POWER_SHORT",
        "ITEM_MOD_HIT_RATING_SHORT",
        "ITEM_MOD_CRIT_RATING_SHORT",
        "ITEM_MOD_HASTE_RATING_SHORT",
        "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT",
        "ITEM_MOD_DODGE_RATING_SHORT",
        "ITEM_MOD_PARRY_RATING_SHORT",
        "ITEM_MOD_BLOCK_RATING_SHORT",
        "ITEM_MOD_RESILIENCE_RATING_SHORT",
        "ITEM_MOD_MASTERY_RATING_SHORT",
        "ITEM_MOD_VERSATILITY",
        "RESISTANCE1_NAME",
        "RESISTANCE2_NAME",
        "RESISTANCE3_NAME",
        "RESISTANCE4_NAME",
        "RESISTANCE5_NAME",
        "RESISTANCE6_NAME",
    }

    local function AddResolvedStat(key, value, forcedLabel)
        local numericValue = tonumber(value)
        if not numericValue or numericValue == 0 then
            return
        end

        local label =
            forcedLabel
            or statLabels[key]
            or (_G and _G[key])

        if not label or tostring(label) == tostring(key) then
            local cleanKey = tostring(key or "")
            cleanKey = string.gsub(cleanKey, "^ITEM_MOD_", "")
            cleanKey = string.gsub(cleanKey, "_SHORT$", "")
            cleanKey = string.gsub(cleanKey, "_", " ")
            cleanKey = string.lower(cleanKey)
            cleanKey = string.gsub(
                cleanKey,
                "(%a)([%w']*)",
                function(first, rest)
                    return string.upper(first) .. rest
                end
            )
            label = cleanKey ~= "" and cleanKey or tostring(key)
        end

        local identity = tostring(label)
        if seenStats[identity] then
            return
        end

        seenStats[identity] = true
        table.insert(statRows, {
            label = identity,
            value = numericValue,
            key = key,
        })
    end

    --------------------------------------------------
    -- CLIENT ITEM STATS
    --
    -- WoW Forever exposes C_Item.GetItemStats on supported builds.
    -- This returns structured item stats and does NOT read protected
    -- GameTooltip FontStrings, avoiding the secret-string issue.
    --------------------------------------------------

    local clientStats = nil
    local statItemLink = "item:" .. tostring(itemID)

    if C_Item and C_Item.GetItemStats then
        local ok, result = pcall(
            C_Item.GetItemStats,
            statItemLink
        )

        if ok and type(result) == "table" then
            clientStats = result
        end
    end

    -- Compatibility fallback for clients that still expose the older
    -- global GetItemStats API.
    if not clientStats and GetItemStats then
        local ok, result = pcall(
            GetItemStats,
            statItemLink
        )

        if ok and type(result) == "table" then
            clientStats = result
        end
    end

    if clientStats then
        for _, statKey in ipairs(statOrder) do
            AddResolvedStat(
                statKey,
                clientStats[statKey]
            )
        end

        -- Preserve any client-provided stat keys that are not in our
        -- preferred ordering table.
        for statKey, statValue in pairs(clientStats) do
            AddResolvedStat(
                statKey,
                statValue
            )
        end
    end

    --------------------------------------------------
    -- DATABASE FALLBACK
    --------------------------------------------------

    local function AddDatabaseStat(label, ...)
        local value = GetItemField(item, ...)
        if value ~= nil
            and tostring(value) ~= ""
            and tonumber(value) ~= 0 then

            AddResolvedStat(
                "DB_" .. tostring(label),
                value,
                label
            )
        end
    end

    AddDatabaseStat("Armor", "armor", "Armor", "armorValue", "ArmorValue")
    AddDatabaseStat("Strength", "strength", "Strength", "str", "STR")
    AddDatabaseStat("Agility", "agility", "Agility", "agi", "AGI")
    AddDatabaseStat("Stamina", "stamina", "Stamina", "sta", "STA")
    AddDatabaseStat("Intellect", "intellect", "Intellect", "int", "INT")
    AddDatabaseStat("Spirit", "spirit", "Spirit", "spi", "SPI")
    AddDatabaseStat("Attack Power", "attackPower", "AttackPower", "ap")
    AddDatabaseStat("Spell Power", "spellPower", "SpellPower", "spellDamage")
    AddDatabaseStat("Hit Rating", "hitRating", "HitRating", "hit")
    AddDatabaseStat("Crit Rating", "critRating", "CritRating", "criticalStrikeRating", "crit")
    AddDatabaseStat("Haste Rating", "hasteRating", "HasteRating", "haste")
    AddDatabaseStat("Defense Rating", "defenseRating", "DefenseRating", "defense")
    AddDatabaseStat("Dodge Rating", "dodgeRating", "DodgeRating", "dodge")
    AddDatabaseStat("Parry Rating", "parryRating", "ParryRating", "parry")
    AddDatabaseStat("Block Rating", "blockRating", "BlockRating", "block")
    AddDatabaseStat("Resilience", "resilienceRating", "ResilienceRating", "resilience")

    if #statRows == 0 then
        DetailValue(
            "No structured stats are available",
            405,
            -82,
            {0.58, 0.61, 0.68, 1}
        )
        DetailValue(
            "from the client or current database.",
            405,
            -101,
            {0.58, 0.61, 0.68, 1}
        )
    else
        -- Two compact stat columns. Each label has a fixed width and its
        -- value is right-aligned inside the same column, preventing long
        -- client stat names from running underneath the value.
        local visibleStats = math.min(#statRows, 10)

        for i = 1, visibleStats do
            local stat = statRows[i]
            local column = ((i - 1) % 2)
            local rowIndex = math.floor((i - 1) / 2)
            local baseX = column == 0 and 405 or 585
            local sy = -82 - (rowIndex * 28)

            local labelText = ForeverBrowser_AchievementLabel(
                informationPanel,
                stat.label,
                10,
                {0.62, 0.65, 0.72, 1}
            )
            labelText:SetWidth(112)
            labelText:SetJustifyH("LEFT")
            labelText:SetPoint(
                "TOPLEFT",
                informationPanel,
                "TOPLEFT",
                baseX,
                sy
            )

            local statText = tostring(stat.value)
            if stat.value > 0 and stat.label ~= "Armor" then
                statText = "+" .. statText
            end

            local valueText = ForeverBrowser_AchievementLabel(
                informationPanel,
                statText,
                10,
                {0.45, 0.85, 0.45, 1}
            )
            valueText:SetWidth(42)
            valueText:SetJustifyH("LEFT")
            valueText:SetPoint(
                "TOPLEFT",
                informationPanel,
                "TOPLEFT",
                baseX + 114,
                sy
            )
        end

        if #statRows > 10 then
            DetailValue(
                "+" .. tostring(#statRows - 10) .. " more stats",
                595,
                -222,
                {0.58, 0.61, 0.68, 1}
            )
        end
    end

    DetailSectionTitle("DATABASE DETAILS", 15, -210, 760)
    DetailValue("Item ID", 15, -240, {0.58, 0.61, 0.68, 1})
    DetailValue(tostring(itemID), 92, -240)
    DetailValue("Max Stack", 205, -240, {0.58, 0.61, 0.68, 1})
    DetailValue(tostring(maxStack), 292, -240)
    DetailValue("Sell Price", 385, -240, {0.58, 0.61, 0.68, 1})
    DetailValue(FormatMoney(sellPrice), 472, -240)
    DetailValue(
        owned and "DISCOVERED" or "WORLD DATABASE",
        635,
        -240,
        owned and {0.45, 0.85, 0.45, 1} or {0.58, 0.61, 0.68, 1}
    )

    if durability and tostring(durability) ~= "" then
        DetailValue(
            "Durability: " .. tostring(durability),
            15,
            -264,
            {0.65, 0.68, 0.75, 1}
        )
    end

    --------------------------------------------------
    -- EFFECTS / SPECIAL PROPERTIES
    --------------------------------------------------

    DetailSectionTitle("EFFECTS & SPECIAL", 15, -292, 360)

    local effectLines = {}
    local function AddEffectLine(prefix, ...)
        local value = GetItemField(item, ...)
        if value ~= nil and tostring(value) ~= "" then
            table.insert(effectLines, {
                prefix,
                tostring(value)
            })
        end
    end

    AddEffectLine("Equip", "equipEffect", "EquipEffect", "equipText", "EquipText")
    AddEffectLine("Use", "useEffect", "UseEffect", "useText", "UseText")
    AddEffectLine("Effect", "effect", "Effect", "effectText", "EffectText")
    AddEffectLine("Proc", "proc", "Proc", "procText", "ProcText")
    AddEffectLine("Set", "setBonus", "SetBonus", "setText", "SetText")
    AddEffectLine("Socket", "socketBonus", "SocketBonus")
    AddEffectLine("Description", "description", "Description", "desc", "flavorText", "FlavorText")

    if #effectLines == 0 then
        -- Empty optional section: no filler text.
    else
        for i = 1, math.min(#effectLines, 4) do
            local e = effectLines[i]
            local ey = -322 - ((i - 1) * 22)
            local effectColor = {0.45, 0.85, 0.45, 1}
            local effectTextColor = {0.78, 0.90, 0.78, 1}
            if e[1] == "Use" then
                effectColor = {0.45, 0.75, 1.00, 1}
                effectTextColor = {0.72, 0.84, 1.00, 1}
            elseif e[1] == "Proc" or e[1] == "Effect" then
                effectColor = {1.00, 0.66, 0.24, 1}
                effectTextColor = {0.95, 0.78, 0.52, 1}
            elseif e[1] == "Set" then
                effectColor = {0.72, 0.52, 1.00, 1}
                effectTextColor = {0.82, 0.72, 1.00, 1}
            elseif e[1] == "Description" then
                effectColor = {0.62, 0.64, 0.70, 1}
                effectTextColor = {0.62, 0.64, 0.70, 1}
            end
            DetailValue(e[1] .. ":", 15, ey, effectColor)
            local effectValue = ForeverBrowser_AchievementLabel(
                informationPanel,
                e[2],
                11,
                effectTextColor
            )
            effectValue:SetWidth(285)
            effectValue:SetJustifyH("LEFT")
            effectValue:SetPoint("TOPLEFT", informationPanel, "TOPLEFT", 85, ey)
        end
    end

    --------------------------------------------------
    -- SOURCE / RECORD DATA
    --------------------------------------------------

    DetailSectionTitle("SOURCE DATA", 405, -292, 370)

    local dataSource = GetItemField(
        item,
        "dataSource", "DataSource", "source", "Source"
    )
    local foreverStatus = GetItemField(
        item,
        "foreverStatus", "ForeverStatus"
    )
    local sourceNPC = GetItemField(
        item,
        "npcName", "NPCName", "sourceNPCName", "SourceNPCName"
    )
    local sourceQuest = GetItemField(
        item,
        "questName", "QuestName", "sourceQuestName", "SourceQuestName"
    )
    local dropChance = GetItemField(
        item,
        "dropChance", "DropChance", "dropRate", "DropRate", "chance"
    )

    local sourceY = -322
    local sourceCount = 0

    local function AddSourceValue(label, value)
        if value == nil or tostring(value) == "" then return end
        DetailValue(label, 405, sourceY, {0.58, 0.61, 0.68, 1})
        local v = ForeverBrowser_AchievementLabel(
            informationPanel,
            tostring(value),
            11,
            {0.78, 0.79, 0.84, 1}
        )
        v:SetWidth(210)
        v:SetJustifyH("LEFT")
        v:SetPoint("TOPLEFT", informationPanel, "TOPLEFT", 505, sourceY)
        sourceY = sourceY - 22
        sourceCount = sourceCount + 1
    end

    AddSourceValue("Database", dataSource)
    AddSourceValue("Status", foreverStatus)
    AddSourceValue("NPC", sourceNPC)
    AddSourceValue("Quest", sourceQuest)

    if dropChance ~= nil and tostring(dropChance) ~= "" then
        local chanceText = tostring(dropChance)
        if not string.find(chanceText, "%%", 1, false) then
            chanceText = chanceText .. "%"
        end
        AddSourceValue("Drop Chance", chanceText)
    end

    if sourceCount == 0 then
        DetailValue(
            "Detailed source records appear below",
            405,
            -322,
            {0.58, 0.61, 0.68, 1}
        )
        DetailValue(
            "in WHERE TO OBTAIN when available.",
            405,
            -341,
            {0.58, 0.61, 0.68, 1}
        )
    end

    --------------------------------------------------
    -- COMBAT / WEAPON DATA
    --------------------------------------------------

    DetailSectionTitle("COMBAT DETAILS", 15, -430, 360)

    local minDamage = GetItemField(
        item, "minDamage", "MinDamage", "damageMin", "DamageMin"
    )
    local maxDamage = GetItemField(
        item, "maxDamage", "MaxDamage", "damageMax", "DamageMax"
    )
    local weaponSpeed = GetItemField(
        item, "speed", "Speed", "weaponSpeed", "WeaponSpeed", "delay", "Delay"
    )
    local dps = GetItemField(
        item, "dps", "DPS", "damagePerSecond", "DamagePerSecond"
    )
    local blockValue = GetItemField(
        item, "blockValue", "BlockValue", "shieldBlock", "ShieldBlock"
    )

    local combatY = -460
    local combatCount = 0

    local function AddCombatValue(label, value, green)
        if value == nil or tostring(value) == "" then return end
        DetailValue(label, 15, combatY, {0.62, 0.65, 0.72, 1})
        DetailValue(
            tostring(value),
            112,
            combatY,
            green and {0.45, 0.85, 0.45, 1} or {0.78, 0.79, 0.84, 1}
        )
        combatY = combatY - 21
        combatCount = combatCount + 1
    end

    if minDamage ~= nil or maxDamage ~= nil then
        local damageText =
            tostring(minDamage or "?")
            .. " - "
            .. tostring(maxDamage or "?")
        AddCombatValue("Damage", damageText, false)
    end

    AddCombatValue("Speed", weaponSpeed, false)
    AddCombatValue("DPS", dps, true)
    AddCombatValue("Block Value", blockValue, false)

    local damageType = GetItemField(
        item, "damageType", "DamageType", "school", "School"
    )
    AddCombatValue("Damage Type", damageType, false)

    if combatCount == 0 then
        -- Empty optional section: no filler text.
    end

    --------------------------------------------------
    -- SOCKETS / SET / REQUIREMENTS
    --------------------------------------------------

    DetailSectionTitle("SOCKETS & REQUIREMENTS", 405, -430, 370)

    local reqClass = GetItemField(
        item, "requiredClass", "RequiredClass", "classes", "Classes"
    )
    local reqRace = GetItemField(
        item, "requiredRace", "RequiredRace", "races", "Races"
    )
    local reqSkill = GetItemField(
        item, "requiredSkill", "RequiredSkill", "skill", "Skill"
    )
    local reqSkillRank = GetItemField(
        item, "requiredSkillRank", "RequiredSkillRank", "skillRank", "SkillRank"
    )
    local setName = GetItemField(
        item, "setName", "SetName", "itemSet", "ItemSet"
    )
    local socket1 = GetItemField(
        item, "socket1", "Socket1", "socketColor1", "SocketColor1"
    )
    local socket2 = GetItemField(
        item, "socket2", "Socket2", "socketColor2", "SocketColor2"
    )
    local socket3 = GetItemField(
        item, "socket3", "Socket3", "socketColor3", "SocketColor3"
    )

    local reqY = -460
    local reqCount = 0

    local function AddRequirement(label, value, special)
        if value == nil or tostring(value) == "" then return end
        DetailValue(label, 405, reqY, {0.58, 0.61, 0.68, 1})
        local v = ForeverBrowser_AchievementLabel(
            informationPanel,
            tostring(value),
            11,
            special and {0.45, 0.85, 0.45, 1} or {0.78, 0.79, 0.84, 1}
        )
        v:SetWidth(205)
        v:SetJustifyH("LEFT")
        v:SetPoint("TOPLEFT", informationPanel, "TOPLEFT", 535, reqY)
        reqY = reqY - 21
        reqCount = reqCount + 1
    end

    AddRequirement("Class", reqClass, false)
    AddRequirement("Race", reqRace, false)

    if reqSkill ~= nil then
        local skillText = tostring(reqSkill)
        if reqSkillRank ~= nil and tostring(reqSkillRank) ~= "" then
            skillText = skillText .. " (" .. tostring(reqSkillRank) .. ")"
        end
        AddRequirement("Skill", skillText, false)
    end

    if setName ~= nil and tostring(setName) ~= "" then
        AddRequirement("Item Set", "|cffb98cff" .. tostring(setName) .. "|r", true)
    end
    if socket1 ~= nil and tostring(socket1) ~= "" then
        AddRequirement("Socket", tostring(socket1) .. " Socket", true)
    end
    if socket2 ~= nil and tostring(socket2) ~= "" then
        AddRequirement("Socket", tostring(socket2) .. " Socket", true)
    end
    if socket3 ~= nil and tostring(socket3) ~= "" then
        AddRequirement("Socket", tostring(socket3) .. " Socket", true)
    end

    local socketBonusValue = GetItemField(item, "socketBonus", "SocketBonus")
    if socketBonusValue ~= nil and tostring(socketBonusValue) ~= "" then
        AddRequirement("Socket Bonus", tostring(socketBonusValue), true)
    end

    if reqCount == 0 then
        -- Empty optional section: no filler text.
    end

    --------------------------------------------------
    -- NOTES AND TAGS
    --------------------------------------------------

    local personalPanel = CreateFrame("Frame", nil, PageContent)
    personalPanel:SetSize(790, 280)
    personalPanel:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, -825-previewOffset)
    CreateSolidBackground(personalPanel, 0.045, 0.038, 0.029, 1)
    ForeverBrowser_AchievementBorder(personalPanel, true)

    local personalHeading =
        ForeverBrowser_AchievementLabel(
            personalPanel,
            "PERSONAL NOTES & TAGS",
            16,
            {
                1,
                0.82,
                0.25,
                1
            }
        )

    personalHeading:SetPoint(
        "TOPLEFT",
        personalPanel,
        "TOPLEFT",
        15,
        -12
    )

    local personalLine = personalPanel:CreateTexture(nil, "ARTWORK")
    personalLine:SetTexture("Interface\\Buttons\\WHITE8X8")
    personalLine:SetVertexColor(0.32, 0.26, 0.09, 0.8)
    personalLine:SetPoint("TOPLEFT", personalPanel, "TOPLEFT", 15, -38)
    personalLine:SetPoint("TOPRIGHT", personalPanel, "TOPRIGHT", -15, -38)
    personalLine:SetHeight(1)

    local tagsLabel =
        ForeverBrowser_AchievementLabel(
            personalPanel,
            "Tags",
            13,
            {
                0.72,
                0.75,
                0.82,
                1
            }
        )

    tagsLabel:SetPoint(
        "TOPLEFT",
        personalHeading,
        "BOTTOMLEFT",
        0,
        -12
    )

    local tagsBox =
        CreateFrame(
            "EditBox",
            nil,
            personalPanel
        )

    tagsBox:SetSize(
        740,
        30
    )

    tagsBox:SetPoint(
        "TOPLEFT",
        tagsLabel,
        "BOTTOMLEFT",
        0,
        -6
    )

    tagsBox:SetAutoFocus(
        false
    )

    if tagsBox.SetFontObject then
        tagsBox:SetFontObject(
            "GameFontHighlight"
        )
    end

    tagsBox:SetTextInsets(
        10,
        10,
        0,
        0
    )

    tagsBox:SetText(
        GetSavedItemTags(itemID)
    )

    CreateSolidBackground(
        tagsBox,
        0.025,
        0.022,
        0.017,
        1
    )

    ForeverBrowser_AchievementBorder(tagsBox, false)

    local noteLabel =
        ForeverBrowser_AchievementLabel(
            personalPanel,
            "Personal Note",
            13,
            {
                0.72,
                0.75,
                0.82,
                1
            }
        )

    noteLabel:SetPoint(
        "TOPLEFT",
        tagsBox,
        "BOTTOMLEFT",
        0,
        -14
    )

    local noteBox =
        CreateFrame(
            "EditBox",
            nil,
            personalPanel
        )

    noteBox:SetSize(
        740,
        76
    )

    noteBox:SetPoint(
        "TOPLEFT",
        noteLabel,
        "BOTTOMLEFT",
        0,
        -6
    )

    noteBox:SetAutoFocus(
        false
    )

    noteBox:SetMultiLine(
        true
    )

    if noteBox.SetFontObject then
        noteBox:SetFontObject(
            "GameFontHighlight"
        )
    end

    noteBox:SetTextInsets(
        10,
        10,
        8,
        8
    )

    noteBox:SetText(
        GetSavedItemNote(itemID)
    )

    CreateSolidBackground(
        noteBox,
        0.025,
        0.022,
        0.017,
        1
    )

    ForeverBrowser_AchievementBorder(noteBox, false)

    local saveButton =
        ForeverBrowser_ItemButton190(
            personalPanel,
            "SAVE NOTES",
            120,
            30
        )

    saveButton:SetPoint(
        "TOPLEFT",
        noteBox,
        "BOTTOMLEFT",
        0,
        -10
    )

    local savedLabel =
        ForeverBrowser_AchievementLabel(
            personalPanel,
            "",
            12,
            {
                0.45,
                0.85,
                0.45,
                1
            }
        )

    savedLabel:SetPoint(
        "LEFT",
        saveButton,
        "RIGHT",
        10,
        0
    )

    local function SavePersonalData()

        SaveItemTags(
            itemID,
            tagsBox:GetText()
        )

        SaveItemNote(
            itemID,
            noteBox:GetText()
        )

        savedLabel:SetText(
            "Saved"
        )
    end

    saveButton:SetScript(
        "OnClick",
        SavePersonalData
    )

    tagsBox:SetScript(
        "OnEnterPressed",
        function(self)

            self:ClearFocus()
            SavePersonalData()

        end
    )

    tagsBox:SetScript(
        "OnEscapePressed",
        function(self)

            self:ClearFocus()

        end
    )

    noteBox:SetScript(
        "OnEscapePressed",
        function(self)

            self:ClearFocus()

        end
    )

    --------------------------------------------------
    -- COMPACT DATABASE FOOTER
    --------------------------------------------------

    local footer = ForeverBrowser_AchievementLabel(
        PageContent,
        "Item ID " .. tostring(itemID)
            .. "   |   "
            .. (owned and "Discovered" or "World Database")
            .. "   |   ForeverBrowser",
        10,
        {0.44, 0.47, 0.54, 1}
    )
    footer:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 32, -1115-previewOffset)

    --------------------------------------------------
    -- WHERE TO OBTAIN
    --------------------------------------------------

    local whereStartY =
        -825-previewOffset

    local whereHeight =
        CreateWhereToObtainSection(
            PageContent,
            itemID,
            whereStartY
        )

    ItemActionsAnchor = personalPanel
    -- FOREVER_ITEM_NOTES_BOTTOM_250
    -- Position personal data after the complete, variable-height source list.
    local personalTopY = whereStartY - whereHeight - 18
    personalPanel:ClearAllPoints()
    personalPanel:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, personalTopY)
    footer:ClearAllPoints()
    footer:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 32,
        personalTopY - personalPanel:GetHeight() - 78)
    PageContent:SetHeight(math.max(1150,
        math.abs(personalTopY) + personalPanel:GetHeight() + 145))

end


--------------------------------------------------
-- SEARCH RESULTS
--------------------------------------------------

local SearchState = {

    text = "",

    category = nil,

    quality = nil,

    sort = "name",

    showUnobtainable = false,

}


--------------------------------------------------
-- SEARCH DATABASE
--------------------------------------------------

local function CollectSearchItems()

    local combined = {}


    --------------------------------------------------
    -- WORLD ITEMS
    --------------------------------------------------

    for id, item
        in pairs(
            GetWorldItems()
        ) do

        local numericID =
            tonumber(id)


        if numericID
            and item then

            combined[numericID] =
                item

        end

    end


    --------------------------------------------------
    -- FOREVER SOURCE ITEMS
    --------------------------------------------------
    -- ForeverSourceData contains generated Classic + Forever-specific item
    -- records. Include these directly in the searchable universe so items
    -- that are server-supplied and not present in the client/world cache
    -- (for example Corpse Chopper) can still be found by name or Item ID.

    if ForeverSourceData
        and ForeverSourceData.items then

        for id, item
            in pairs(ForeverSourceData.items) do

            local numericID = tonumber(id)

            if numericID and item then
                if not combined[numericID] then
                    combined[numericID] = item
                else
                    local existing = combined[numericID]
                    for key, value in pairs(item) do
                        if existing[key] == nil then
                            existing[key] = value
                        end
                    end
                end
            end
        end
    end


    --------------------------------------------------
    -- PLAYER ITEMS
    --------------------------------------------------

    for id, item
        in pairs(
            GetPlayerItems()
        ) do

        local numericID =
            tonumber(id)


        if numericID then

            if not combined[numericID] then

                combined[numericID] =
                    item

            else

                local existing =
                    combined[numericID]


                for key, value
                    in pairs(item) do

                    if existing[key] == nil then

                        existing[key] =
                            value

                    end

                end

            end

        end

    end


    return combined
end


local function IsItemObtainable(itemID)

    itemID = tonumber(itemID)

    if not itemID then
        return false
    end

    if ForeverSourceData
        and ForeverSourceData.items then

        local sourceItem =
            ForeverSourceData.items[itemID]
            or ForeverSourceData.items[tostring(itemID)]

        if sourceItem then
            -- Generated Forever-specific items are valid searchable records
            -- even when we have not imported their acquisition source yet.
            if sourceItem.dataSource == "forever" then
                return true
            end

            if sourceItem.sources
                and #sourceItem.sources > 0 then

                return true
            end
        end
    end

    return false
end


local function SearchDatabase()
    local results = {}


    local allItems =
        CollectSearchItems()


    local searchText =
        string.lower(
            tostring(
                SearchState.text
                    or ""
            )
        )


    for id, item
        in pairs(allItems) do

        local itemID =
            tonumber(id)


        if itemID then

            local name =
                GetItemField(
                    item,
                    "name",
                    "itemName"
                )


            if not name then

                name =
                    GetItemName(
                        itemID
                    )

            end


            name =
                tostring(
                    name or ""
                )

            -- Some imported Forever records store the item level as a numeric
            -- prefix in the raw name (for example "63 Green Warrior Ring").
            -- Search results read that raw field directly, so strip the prefix
            -- when it exactly matches this item's displayed item level.
            local searchItemLevel =
                GetItemLevel(
                    itemID,
                    item
                )

            local namePrefix,
                nameRemainder =
                string.match(
                    name,
                    "^(%d+)%s+(.+)$"
                )

            if namePrefix
                and nameRemainder
                and (
                    (
                        namePrefix == "63"
                        and string.sub(nameRemainder, 1, 6) == "Green "
                    )
                    or tonumber(namePrefix)
                        == tonumber(searchItemLevel)
                ) then

                name = nameRemainder

            else

                name =
                    CleanItemDisplayName(
                        itemID,
                        item,
                        name
                    )

            end


            local lowerName =
                string.lower(
                    name
                )


            --------------------------------------------------
            -- TEXT MATCH
            --------------------------------------------------

            local matchesText = true


            if searchText ~= "" then

                matchesText =

                    string.find(
                        lowerName,
                        searchText,
                        1,
                        true
                    )
                    ~= nil


                if not matchesText then

                    matchesText =
                        tostring(
                            itemID
                        )
                        ==
                        searchText

                end

                if not matchesText then

                    local savedTags =
                        string.lower(
                            GetSavedItemTags(
                                itemID
                            )
                        )

                    matchesText =
                        string.find(
                            savedTags,
                            searchText,
                            1,
                            true
                        )
                        ~= nil
                end

                if not matchesText then

                    local savedNote =
                        string.lower(
                            GetSavedItemNote(
                                itemID
                            )
                        )

                    matchesText =
                        string.find(
                            savedNote,
                            searchText,
                            1,
                            true
                        )
                        ~= nil
                end

            end


            --------------------------------------------------
            -- CATEGORY
            --------------------------------------------------

            local matchesCategory = true


            if SearchState.category
                ~= nil then

                local classID =
                    GetItemClass(
                        itemID,
                        item
                    )


                matchesCategory =
                    tonumber(
                        classID
                    )
                    ==
                    tonumber(
                        SearchState.category
                    )

            end


            --------------------------------------------------
            -- QUALITY
            --------------------------------------------------

            local matchesQuality = true


            if SearchState.quality
                ~= nil then

                local quality =
                    GetQuality(
                        itemID,
                        item
                    )


                matchesQuality =
                    tonumber(
                        quality
                    )
                    ==
                    tonumber(
                        SearchState.quality
                    )

            end


            local exactIDSearch =
                searchText ~= ""
                and tostring(itemID) == searchText

            -- Explicit searches should return generated database records even
            -- when acquisition/source data has not been imported yet. This is
            -- important for Forever server-supplied items such as Corpse Chopper.
            -- The Obtainable filter still applies to unfiltered/browse results.
            local explicitGeneratedMatch =
                searchText ~= ""
                and matchesText
                and ForeverSourceData
                and ForeverSourceData.items
                and (
                    ForeverSourceData.items[itemID]
                    or ForeverSourceData.items[tostring(itemID)]
                ) ~= nil

            local matchesObtainable =
                SearchState.showUnobtainable
                or exactIDSearch
                or explicitGeneratedMatch
                or IsItemObtainable(itemID)

            if matchesText
                and matchesCategory
                and matchesQuality
                and matchesObtainable then

                table.insert(
                    results,
                    {
                        id = itemID,
                        item = item,
                        name = name,
                        quality =
                            GetQuality(
                                itemID,
                                item
                            ),
                        itemLevel =
                            searchItemLevel,
                    }
                )

            end

        end

    end


    --------------------------------------------------
    -- SORT
    --------------------------------------------------

    if SearchState.sort == "level" then

        table.sort(
            results,
            function(a, b)

                if a.itemLevel
                    == b.itemLevel then

                    return string.lower(
                        a.name
                    )
                    <
                    string.lower(
                        b.name
                    )

                end


                return a.itemLevel
                    >
                    b.itemLevel

            end
        )


    elseif SearchState.sort == "id" then

        table.sort(
            results,
            function(a, b)

                return a.id < b.id

            end
        )


    else

        table.sort(
            results,
            function(a, b)

                local an =
                    string.lower(
                        a.name
                    )

                local bn =
                    string.lower(
                        b.name
                    )


                if an == bn then

                    return a.id < b.id

                end


                return an < bn

            end
        )

    end


    return results
end


--------------------------------------------------
-- SEARCH RESULT ROW
--------------------------------------------------

local function CreateSearchResult(
    parent,
    result,
    y
)

    local row =
        CreateFrame(
            "Button",
            nil,
            parent
        )


    row:SetSize(
        760,
        72
    )


    row:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        0,
        y
    )


    local bg =
        CreateSolidBackground(
            row,
            0.032,
            0.024,
            0.016,
            0.92
        )


    --------------------------------------------------
    -- ICON
    --------------------------------------------------

    local icon =
        row:CreateTexture(
            nil,
            "ARTWORK"
        )


    icon:SetSize(
        54,
        54
    )


    icon:SetPoint(
        "LEFT",
        row,
        "LEFT",
        10,
        0
    )


    icon:SetTexture(
        GetItemIcon(
            result.id,
            result.item
        )
    )


    --------------------------------------------------
    -- NAME
    --------------------------------------------------

    local displayName =
        tostring(
            result.name or ""
        )

    local displayPrefix,
        displayRemainder =
        string.match(
            displayName,
            "^(%d+)%s+(.+)$"
        )

    local greenPosition =
        string.find(
            displayName,
            "Green ",
            1,
            true
        )

    if greenPosition then
        local beforeGreen =
            string.sub(
                displayName,
                1,
                greenPosition - 1
            )

        if string.find(
            beforeGreen,
            "63",
            1,
            true
        ) then
            displayName =
                string.sub(
                    displayName,
                    greenPosition
                )
        end

    elseif displayPrefix
        and displayRemainder
        and tonumber(displayPrefix)
            == tonumber(result.itemLevel) then

        displayName = displayRemainder
    end

    local name =
        CreateLabel(
            row,
            displayName,
            15,
            {
                1,
                0.82,
                0.25,
                1
            }
        )


    name:SetPoint(
        "TOPLEFT",
        icon,
        "TOPRIGHT",
        15,
        -2
    )


    --------------------------------------------------
    -- DETAILS
    --------------------------------------------------

    local category =
        GetClassName(
            result.id,
            result.item
        )


    local detailsText =
        category
        .. "  •  "
        .. GetQualityName(
            result.quality
        )
        .. "  •  Item Level "
        .. tostring(
            result.itemLevel
        )


    local details =
        CreateLabel(
            row,
            detailsText,
            12,
            {
                0.65,
                0.68,
                0.75,
                1
            }
        )


    details:SetPoint(
        "TOPLEFT",
        name,
        "BOTTOMLEFT",
        0,
        -7
    )


    --------------------------------------------------
    -- ID
    --------------------------------------------------

    local idLabel =
        CreateLabel(
            row,
            "ID "
            .. tostring(
                result.id
            ),
            11,
            {
                0.5,
                0.52,
                0.58,
                1
            }
        )


    idLabel:SetPoint(
        "RIGHT",
        row,
        "RIGHT",
        -15,
        0
    )


    --------------------------------------------------
    -- HOVER
    --------------------------------------------------

    row:SetScript(
        "OnEnter",
        function()

            bg:SetVertexColor(
                0.08,
                0.10,
                0.16,
                1
            )


            ShowItemTooltip(
                result.id,
                row
            )

        end
    )


    row:SetScript(
        "OnLeave",
        function()

            bg:SetVertexColor(unpack(WOW_THEME.row))


            if GameTooltip then

                GameTooltip:Hide()

            end

        end
    )


    --------------------------------------------------
    -- CLICK
    --------------------------------------------------

    row:SetScript(
        "OnClick",
        function()

            if IsShiftLinkClick() then

                LinkItemToChat(
                    result.id
                )

                return
            end

            Navigate(
                "forever://item/"
                .. tostring(
                    result.id
                )
            )

        end
    )


    return row
end


--------------------------------------------------
-- SEARCH PAGE
--------------------------------------------------

local function BuildSearchPage(
    initialText
)

    ClearPage()


    if initialText ~= nil then

        SearchState.text =
            tostring(
                initialText
            )

    end


    --------------------------------------------------
    -- TITLE
    --------------------------------------------------

    local title =
        CreateLabel(
            PageContent,
            "ITEM DATABASE",
            22,
            {
                1,
                0.82,
                0.25,
                1
            }
        )


    title:SetPoint(
        "TOPLEFT",
        PageContent,
        "TOPLEFT",
        25,
        -20
    )
    ForeverBrowser_CodexTitle196(title)


    --------------------------------------------------
    -- SEARCH BOX
    --------------------------------------------------

    local searchBox =
        CreateFrame(
            "EditBox",
            nil,
            PageContent
        )


    searchBox:SetSize(
        420,
        34
    )


    searchBox:SetPoint(
        "TOPLEFT",
        title,
        "BOTTOMLEFT",
        0,
        -18
    )


    searchBox:SetAutoFocus(
        false
    )


    searchBox:SetFontObject(
        "GameFontHighlight"
    )


    searchBox:SetText(
        SearchState.text
            or ""
    )


    local searchBG =
        CreateSolidBackground(
            searchBox,
            0.055,
            0.065,
            0.085,
            1
        )

    -- Brighter gold border so the clickable/typeable search field
    -- is clearly separated from the page background.
    local searchBorder = searchBox:CreateTexture(nil, "BORDER")
    searchBorder:SetTexture("Interface\\Buttons\\WHITE8X8")
    searchBorder:SetPoint("TOPLEFT", searchBox, "TOPLEFT", -1, 1)
    searchBorder:SetPoint("BOTTOMRIGHT", searchBox, "BOTTOMRIGHT", 1, -1)
    searchBorder:SetVertexColor(0.16, 0.19, 0.25, 0.95)

    local searchInner = searchBox:CreateTexture(nil, "BACKGROUND")
    searchInner:SetTexture("Interface\\Buttons\\WHITE8X8")
    searchInner:SetPoint("TOPLEFT", searchBox, "TOPLEFT", 1, -1)
    searchInner:SetPoint("BOTTOMRIGHT", searchBox, "BOTTOMRIGHT", -1, 1)
    searchInner:SetVertexColor(unpack(WOW_THEME.row))

    searchBox:SetTextColor(0.96, 0.94, 0.88, 1)

    searchBox:SetScript("OnEditFocusGained", function()
        searchBorder:SetVertexColor(0.28, 0.33, 0.42, 1)
        searchInner:SetVertexColor(unpack(WOW_THEME.row))
    end)

    searchBox:SetScript("OnEditFocusLost", function()
        searchBorder:SetVertexColor(0.16, 0.19, 0.25, 0.95)
        searchInner:SetVertexColor(unpack(WOW_THEME.row))
    end)


    searchBox:SetTextInsets(
        10,
        10,
        0,
        0
    )


    searchBox:SetScript(
        "OnEnterPressed",
        function(self)

            SearchState.text =
                self:GetText()

            BuildSearchPage()

        end
    )


    searchBox:SetScript(
        "OnEscapePressed",
        function(self)

            self:ClearFocus()

        end
    )


    --------------------------------------------------
    -- SEARCH BUTTON
    --------------------------------------------------

    local searchButton =
        CreateButton(
            PageContent,
            "SEARCH",
            100,
            34
        )


    searchButton:SetPoint(
        "LEFT",
        searchBox,
        "RIGHT",
        10,
        0
    )


    searchButton:SetScript(
        "OnClick",
        function()

            SearchState.text =
                searchBox:GetText()

            BuildSearchPage()

        end
    )


    --------------------------------------------------
    -- CLEAR
    --------------------------------------------------

    local clearButton =
        CreateButton(
            PageContent,
            "CLEAR",
            80,
            34
        )


    clearButton:SetPoint(
        "LEFT",
        searchButton,
        "RIGHT",
        8,
        0
    )


    clearButton:SetScript(
        "OnClick",
        function()

            SearchState.text = ""
            SearchState.category = nil
            SearchState.quality = nil

            BuildSearchPage()

        end
    )


    --------------------------------------------------
    -- OBTAINABLE FILTER
    --------------------------------------------------

    local obtainableButton =
        CreateButton(
            PageContent,
            SearchState.showUnobtainable
                and "HIDE UNOBTAINABLE"
                or "SHOW UNOBTAINABLE",
            150,
            26
        )

    obtainableButton:SetPoint(
        "TOPRIGHT",
        clearButton,
        "BOTTOMRIGHT",
        0,
        -8
    )

    obtainableButton:SetScript(
        "OnClick",
        function()

            SearchState.showUnobtainable =
                not SearchState.showUnobtainable

            BuildSearchPage()

        end
    )


    --------------------------------------------------
    -- CATEGORY LABEL
    --------------------------------------------------

    local categoryLabel =
        CreateLabel(
            PageContent,
            "CATEGORY",
            13,
            {
                0.7,
                0.72,
                0.78,
                1
            }
        )


    categoryLabel:SetPoint(
        "TOPLEFT",
        searchBox,
        "BOTTOMLEFT",
        0,
        -18
    )


    --------------------------------------------------
    -- CATEGORY BUTTONS
    --------------------------------------------------

    local categoryX = 0
    local categoryY = -22


    local categoryButtons = {}


    for _, category
        in ipairs(
            DatabaseCategories
        ) do

        local button =
            CreateButton(
                PageContent,
                category.name,
                110,
                28
            )


        button:SetPoint(
            "TOPLEFT",
            categoryLabel,
            "BOTTOMLEFT",
            categoryX,
            categoryY
        )


        button:SetScript(
            "OnClick",
            function()

                if SearchState.category
                    == category.id then

                    SearchState.category =
                        nil

                else

                    SearchState.category =
                        category.id

                end


                BuildSearchPage()

            end
        )


        table.insert(
            categoryButtons,
            button
        )


        categoryX =
            categoryX + 118


        if categoryX >= 700 then

            categoryX = 0
            categoryY =
                categoryY - 34

        end

    end


    --------------------------------------------------
    -- QUALITY FILTER
    --------------------------------------------------

    local qualityY =
        categoryY - 42


    local qualityLabel =
        CreateLabel(
            PageContent,
            "QUALITY",
            13,
            {
                0.7,
                0.72,
                0.78,
                1
            }
        )


    qualityLabel:SetPoint(
        "TOPLEFT",
        categoryLabel,
        "BOTTOMLEFT",
        0,
        qualityY
    )


    local qualityX = 0


    for quality = 0, 5 do

        local button =
            CreateButton(
                PageContent,
                QualityNames[quality],
                100,
                28
            )


        button:SetPoint(
            "TOPLEFT",
            qualityLabel,
            "BOTTOMLEFT",
            qualityX,
            -8
        )


        button:SetScript(
            "OnClick",
            function()

                if SearchState.quality
                    == quality then

                    SearchState.quality =
                        nil

                else

                    SearchState.quality =
                        quality

                end


                BuildSearchPage()

            end
        )


        qualityX =
            qualityX + 108

    end


    --------------------------------------------------
    -- SORT
    --------------------------------------------------

    local sortY =
        qualityY - 50


    local sortLabel =
        CreateLabel(
            PageContent,
            "SORT BY",
            13,
            {
                0.7,
                0.72,
                0.78,
                1
            }
        )


    sortLabel:SetPoint(
        "TOPLEFT",
        categoryLabel,
        "BOTTOMLEFT",
        0,
        sortY
    )


    local sortName =
        CreateButton(
            PageContent,
            "NAME",
            90,
            28
        )


    sortName:SetPoint(
        "TOPLEFT",
        sortLabel,
        "BOTTOMLEFT",
        0,
        -8
    )


    sortName:SetScript(
        "OnClick",
        function()

            SearchState.sort =
                "name"

            BuildSearchPage()

        end
    )


    local sortLevel =
        CreateButton(
            PageContent,
            "ITEM LEVEL",
            110,
            28
        )


    sortLevel:SetPoint(
        "LEFT",
        sortName,
        "RIGHT",
        8,
        0
    )


    sortLevel:SetScript(
        "OnClick",
        function()

            SearchState.sort =
                "level"

            BuildSearchPage()

        end
    )


    local sortID =
        CreateButton(
            PageContent,
            "ITEM ID",
            90,
            28
        )


    sortID:SetPoint(
        "LEFT",
        sortLevel,
        "RIGHT",
        8,
        0
    )


    sortID:SetScript(
        "OnClick",
        function()

            SearchState.sort =
                "id"

            BuildSearchPage()

        end
    )


    --------------------------------------------------
    -- RESULTS
    --------------------------------------------------

    local results =
        SearchDatabase()


    local resultHeaderY =
        sortY - 55


    local resultLabel =
        CreateLabel(
            PageContent,
            "SEARCH RESULTS: "
            .. tostring(
                #results
            ),
            16,
            {
                1,
                0.82,
                0.25,
                1
            }
        )


    resultLabel:SetPoint(
        "TOPLEFT",
        categoryLabel,
        "BOTTOMLEFT",
        0,
        resultHeaderY
    )


    --------------------------------------------------
    -- RESULT LIST
    --------------------------------------------------

    local resultContainer =
        CreateFrame(
            "Frame",
            nil,
            PageContent
        )


    resultContainer:SetWidth(
        760
    )


    local listTop =
        resultHeaderY - 35


    resultContainer:SetPoint(
        "TOPLEFT",
        PageContent,
        "TOPLEFT",
        25,
        listTop
    )


    local maxResults =
        math.min(
            #results,
            500
        )


    for i = 1,
        maxResults do

        CreateSearchResult(
            resultContainer,
            results[i],
            -((i - 1) * 78)
        )

    end


    local resultHeight =
        math.max(
            100,
            maxResults * 78
        )


    resultContainer:SetHeight(
        resultHeight
    )


    PageContent:SetHeight(
        math.max(
            600,
            math.abs(
                listTop
            )
            + resultHeight
            + 40
        )
    )

end


--------------------------------------------------
-- CATEGORY PAGE
--------------------------------------------------

local function BuildCategoryPage(
    categoryID
)

    ClearPage()


    categoryID =
        tonumber(categoryID)


    local categoryName =
        GetCategoryName(
            categoryID
        )


    local title =
        CreateLabel(
            PageContent,
            categoryName,
            22,
            {
                1,
                0.82,
                0.25,
                1
            }
        )


    title:SetPoint(
        "TOPLEFT",
        PageContent,
        "TOPLEFT",
        25,
        -25
    )
    ForeverBrowser_CodexTitle196(title)


    local searchButton =
        CreateButton(
            PageContent,
            "SEARCH DATABASE",
            145,
            32
        )


    searchButton:SetPoint(
        "TOPRIGHT",
        PageContent,
        "TOPRIGHT",
        -25,
        -20
    )


    searchButton:SetScript(
        "OnClick",
        function()

            Navigate(
                "forever://search/"
            )

        end
    )


    local results = {}


    for id, item
        in pairs(
            CollectSearchItems()
        ) do

        local numericID =
            tonumber(id)


        if numericID then

            local classID =
                GetItemClass(
                    numericID,
                    item
                )


            if tonumber(classID)
                == categoryID
                and (
                    SearchState.showUnobtainable
                    or IsItemObtainable(numericID)
                ) then

                table.insert(
                    results,
                    {
                        id = numericID,
                        item = item,
                        name =
                            CleanItemDisplayName(
                                numericID,
                                item,
                                GetItemField(
                                    item,
                                    "name",
                                    "itemName"
                                )
                                or GetItemName(
                                    numericID
                                )
                            ),
                    }
                )

            end

        end

    end


    table.sort(
        results,
        function(a, b)

            return string.lower(
                tostring(
                    a.name or ""
                )
            )
            <
            string.lower(
                tostring(
                    b.name or ""
                )
            )

        end
    )


    local count =
        CreateLabel(
            PageContent,
            tostring(
                #results
            )
            .. " items",
            13,
            {
                0.65,
                0.68,
                0.75,
                1
            }
        )


    count:SetPoint(
        "TOPLEFT",
        title,
        "BOTTOMLEFT",
        0,
        -8
    )

    local buildCheck =
        CreateLabel(
            PageContent,
            "BUILD 1.112",
            12,
            {
                1,
                0.35,
                0.35,
                1
            }
        )

    buildCheck:SetPoint(
        "LEFT",
        count,
        "RIGHT",
        14,
        0
    )


    local y = -90


    local maxResults =
        math.min(
            #results,
            500
        )


    for i = 1,
        maxResults do

        CreateSearchResult(
            PageContent,
            results[i],
            y
        )


        y =
            y - 78

    end


    PageContent:SetHeight(
        math.max(
            500,
            math.abs(y) + 50
        )
    )

end


--------------------------------------------------
-- WELCOME PAGE
--------------------------------------------------

local function BuildWelcomePage()

    ClearPage()

    local hero =
        CreateFrame(
            "Frame",
            nil,
            PageContent
        )

    -- The welcome page itself fills the entire content area.
    -- The wallpaper replaces the old solid background rather than sitting
    -- inside a shorter image panel.
    -- Slightly wider and shorter than v1.079 to better match the
    -- visible ForeverBrowser content pane.
    hero:SetSize(
        870,
        550
    )

    -- Slight rightward visual adjustment while keeping the wider background.
    hero:SetPoint(
        "TOPLEFT",
        PageContent,
        "TOPLEFT",
        -3,
        0
    )
    hero:SetPoint(
        "TOPRIGHT",
        PageContent,
        "TOPRIGHT",
        27,
        0
    )

    -- Full-area ForeverBrowser wallpaper.
    -- Explicit .tga extension is used for compatibility with this legacy client.
    local wallpaper = hero:CreateTexture(nil, "ARTWORK")
    wallpaper:SetPoint("TOPLEFT", hero, "TOPLEFT", 0, 0)
    wallpaper:SetPoint("BOTTOMRIGHT", hero, "BOTTOMRIGHT", 0, 0)
    wallpaper:SetTexture("Interface\\AddOns\\ForeverBrowser\\Media\\ForeverBrowserWallpaper.tga")
    wallpaper:SetAlpha(0.76)

    -- Readability veil, layered above the wallpaper but below the controls/text.
    local wallpaperShade = hero:CreateTexture(nil, "OVERLAY")
    wallpaperShade:SetPoint("TOPLEFT", hero, "TOPLEFT", 0, 0)
    wallpaperShade:SetPoint("BOTTOMRIGHT", hero, "BOTTOMRIGHT", 0, 0)
    wallpaperShade:SetTexture("Interface\\Buttons\\WHITE8X8")
    wallpaperShade:SetVertexColor(0.055,0.045,0.033,0.08)

    -- Wallpaper artwork supplies the welcome-page border.

    local icon =
        hero:CreateTexture(
            nil,
            "ARTWORK"
        )

    icon:SetSize(
        96,
        96
    )

    icon:SetPoint(
        "TOP",
        hero,
        "TOP",
        0,
        -48
    )

    icon:SetTexture(
        "Interface\\Icons\\INV_Misc_Book_09"
    )

    local title =
        CreateLabel(
            hero,
            "FOREVER BROWSER",
            32,
            {
                1,
                0.82,
                0.25,
                1
            }
        )

    title:SetPoint(
        "TOP",
        icon,
        "BOTTOM",
        0,
        -8
    )

    local subtitle =
        CreateLabel(
            hero,
            "Your in-game World of Warcraft Forever item database.",
            23,
            {
                0.72,
                0.75,
                0.82,
                1
            }
        )

    local subtitleBackdrop = hero:CreateTexture(nil, "OVERLAY")
    subtitleBackdrop:SetTexture("Interface\\Buttons\\WHITE8X8")
    subtitleBackdrop:SetVertexColor(0.055,0.045,0.033,0.40)
    subtitleBackdrop:SetPoint("TOPLEFT", subtitle, "TOPLEFT", -14, 5)
    subtitleBackdrop:SetPoint("BOTTOMRIGHT", subtitle, "BOTTOMRIGHT", 14, -5)

    subtitle:SetTextColor(0.96, 0.94, 0.88, 1)
    subtitle:SetFont(
        "Fonts\\FRIZQT__.TTF",
        21
    )
    subtitle:SetShadowColor(0, 0, 0, 1)
    subtitle:SetShadowOffset(2, -2)

    subtitle:SetPoint(
        "TOP",
        title,
        "BOTTOM",
        0,
        -8
    )

    local summary =
        CreateLabel(
            hero,
            "Browse and search thousands of items, inspect WoW tooltips, compare gear, save favorites and recent items, create custom collections, link items in chat, and keep your own searchable tags and notes.",
            18,
            {
                0.82,
                0.84,
                0.88,
                1
            }
        )

    summary:SetWidth(
        650
    )

    summary:SetJustifyH(
        "CENTER"
    )

    local summaryBackdrop = hero:CreateTexture(nil, "OVERLAY")
    summaryBackdrop:SetTexture("Interface\\Buttons\\WHITE8X8")
    summaryBackdrop:SetVertexColor(0.055,0.045,0.033,0.44)
    summaryBackdrop:SetPoint("TOPLEFT", summary, "TOPLEFT", -14, 6)
    summaryBackdrop:SetPoint("BOTTOMRIGHT", summary, "BOTTOMRIGHT", 14, -6)

    summary:SetTextColor(0.94, 0.93, 0.89, 1)
    summary:SetFont(
        "Fonts\\FRIZQT__.TTF",
        17
    )
    summary:SetShadowColor(0, 0, 0, 1)
    summary:SetShadowOffset(2, -2)

    summary:SetPoint(
        "TOP",
        subtitle,
        "BOTTOM",
        0,
        -18
    )

    local credit =
        CreateLabel(
            hero,
            "Made By Zyntrix Farheart",
            15,
            {
                1,
                0.72,
                0.20,
                1
            }
        )

    credit:SetFont(
        "Fonts\\FRIZQT__.TTF",
        22
    )
    credit:SetShadowColor(0, 0, 0, 1)
    credit:SetShadowOffset(2, -2)

    credit:SetTextColor(1.0, 0.82, 0.22, 1)
    credit:SetShadowColor(0, 0, 0, 1)
    credit:SetShadowOffset(2, -2)

    local creditBackdrop = hero:CreateTexture(nil, "OVERLAY")
    creditBackdrop:SetTexture("Interface\\Buttons\\WHITE8X8")
    creditBackdrop:SetVertexColor(0.055,0.045,0.033,0.46)
    creditBackdrop:SetPoint("TOPLEFT", credit, "TOPLEFT", -18, 7)
    creditBackdrop:SetPoint("BOTTOMRIGHT", credit, "BOTTOMRIGHT", 18, -7)

    credit:SetPoint(
        "TOP",
        summary,
        "BOTTOM",
        0,
        -18
    )

    local enterButton =
        CreateButton(
            hero,
            "ENTER FOREVERBROWSER",
            230,
            40
        )

    enterButton:SetPoint(
        "TOP",
        credit,
        "BOTTOM",
        0,
        -18
    )

    enterButton:SetScript(
        "OnClick",
        function()

            Navigate(
                "forever://home"
            )

        end
    )

    local footer =
        CreateLabel(
            hero,
            "Search. Organize. Compare. Discover.",
            12,
            {
                0.50,
                0.54,
                0.62,
                1
            }
        )

    footer:SetPoint(
        "BOTTOM",
        hero,
        "BOTTOM",
        0,
        24
    )

    PageContent:SetHeight(
        520
    )
end


--------------------------------------------------
-- HOME PAGE
--------------------------------------------------


local function BuildHomePage()
    local function CountRecords(t)
        local n=0
        if type(t)=="table" then for _ in pairs(t) do n=n+1 end end
        return n
    end
    local cards={
        {title="ITEM DATABASE",count=CountRecords(ForeverSourceData and ForeverSourceData.items).." ITEMS",
         desc="Search items, categories, favorites and discovered gear.",
         icon="Interface\\Icons\\INV_Misc_Book_09",url="forever://items"},
        {title="QUEST DATABASE",count=CountRecords(ForeverSourceData and ForeverSourceData.quests).." QUESTS",
         desc="Objectives, rewards, quest givers and turn-in locations.",
         icon="Interface\\Icons\\INV_Misc_Note_01",url="forever://quests"},
        {title="NPC DATABASE",count=CountRecords(ForeverSourceData and ForeverSourceData.npcs).." NPCS",
         desc="NPCs, vendors, trainers, relations and known locations.",
         icon="Interface\\Icons\\INV_Misc_Head_Dragon_01",url="forever://npcdatabase"},
        {title="PROFESSIONS",count=ForeverBrowser_ProfessionCount225().." PROFESSIONS",
         desc="Recipes, reagents, trainers, vendors and drop sources.",
         icon="Interface\\Icons\\Trade_BlackSmithing",url="forever://professions"},
        {title="DUNGEON DATABASE",count=CountRecords(ForeverSourceData and ForeverSourceData.foreverNPCs).." FOREVER BOSSES",
         desc="Forever dungeons, bosses and known boss loot.",
         icon="Interface\\Icons\\INV_Misc_Map_01",url="forever://dungeons"},
    }

    local hero=ForeverBrowser_CodexHome191("The Forever Codex",
        "Explore the people, quests, treasures and trades of Azeroth & Forever.",
        "Interface\\Icons\\INV_Misc_Book_09","","Search Codex",
        function(text) Navigate("forever://codex/search/all/1/"..text) end,
        {{CountRecords(ForeverSourceData and ForeverSourceData.items),"Item Records"},
         {CountRecords(ForeverSourceData and ForeverSourceData.quests),"Quest Records"},
         {CountRecords(ForeverSourceData and ForeverSourceData.npcs),"NPC Records"},
         {ForeverBrowser_ProfessionCount225(),"Professions"}},
        "Explore the Codex")
    for i,info in ipairs(cards) do
        ForeverBrowser_CodexCard191(hero,i,info.title,info.desc,info.count,info.icon,info.url)
    end
    local title=ForeverBrowser_AchievementLabel(PageContent,"Quick Access",18,{1,0.82,0.28,1})
    title:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",0,-474)
    local quickLinks={
        {"RECENT ITEMS","Recently viewed items","Interface\\Icons\\INV_Misc_PocketWatch_01","forever://recent"},
        {"FAVORITES","Your saved favorites","Interface\\Icons\\INV_Misc_Note_02","forever://favorites"},
        {"MY LISTS","Custom item collections","Interface\\Icons\\INV_Misc_Bag_10","forever://lists"},
    }

    for i,info in ipairs(quickLinks) do
        local card=CreateFrame("Button",nil,PageContent)
        card:SetSize(218,76) card:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",(i-1)*241,-508)
        ForeverBrowser_AchievementPaper(card,true)
        local icon=card:CreateTexture(nil,"ARTWORK") icon:SetSize(28,28)
        icon:SetPoint("TOPLEFT",card,"TOPLEFT",12,-12) icon:SetTexture(info[3])
        local name=ForeverBrowser_AchievementLabel(card,info[1],13,{0.31,0.18,0.03,1})
        name:SetPoint("TOPLEFT",card,"TOPLEFT",49,-14) name:SetWidth(157) name:SetJustifyH("LEFT")
        local desc=ForeverBrowser_AchievementLabel(card,info[2],10,{0.34,0.28,0.17,1})
        desc:SetPoint("BOTTOMLEFT",card,"BOTTOMLEFT",12,12) desc:SetWidth(194) desc:SetJustifyH("LEFT")
        card:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        card:SetScript("OnClick",function() Navigate(info[4]) end)
    end
    PageContent:SetHeight(850)
end


local function BuildItemDatabasePage()
    ForeverBrowser_DatabaseHome189("items")
end

local function BuildItemBrowsePage()

    ClearPage()

    local worldCount = 0
    for _ in pairs(GetWorldItems()) do
        worldCount = worldCount + 1
    end

    local playerCount = 0
    for _ in pairs(GetPlayerItems()) do
        playerCount = playerCount + 1
    end

    local favoriteIDs = {}
    for id, enabled in pairs(GetFavorites()) do
        local itemID = tonumber(id)
        if enabled and itemID and GetAnyItem(itemID) then
            table.insert(favoriteIDs, itemID)
        end
    end

    table.sort(favoriteIDs, function(a, b)
        return string.lower(GetItemName(a)) < string.lower(GetItemName(b))
    end)

    local listCount = 0
    for _ in pairs(GetCustomLists()) do
        listCount = listCount + 1
    end

    --------------------------------------------------
    -- HERO HEADER
    --------------------------------------------------

    local hero = CreateFrame("Frame", nil, PageContent)
    hero:SetSize(790, 92)
    hero:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 20, -18)
    CreateSolidBackground(hero, 0.025, 0.035, 0.06, 1)

    local heroIcon = hero:CreateTexture(nil, "ARTWORK")
    heroIcon:SetSize(58, 58)
    heroIcon:SetPoint("LEFT", hero, "LEFT", 18, 0)
    heroIcon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")

    local title = CreateLabel(hero, "ForeverDB", 26, {1, 0.82, 0.25, 1})
    title:SetPoint("TOPLEFT", heroIcon, "TOPRIGHT", 15, -3)

    local subtitle = CreateLabel(
        hero,
        "World of Warcraft Forever Item Database",
        13,
        {0.65, 0.68, 0.75, 1}
    )
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -7)

    local browseButton = CreateButton(hero, "BROWSE ALL ITEMS", 145, 32)
    browseButton:SetPoint("RIGHT", hero, "RIGHT", -18, 0)
    browseButton:SetScript("OnClick", function()
        Navigate("forever://search/")
    end)

    --------------------------------------------------
    -- STAT CARDS
    --------------------------------------------------

    local stats = {
        {"WORLD ITEMS", worldCount, "Interface\\Icons\\INV_Misc_Book_11", "forever://search/"},
        {"DISCOVERED", playerCount, "Interface\\Icons\\INV_Misc_Spyglass_03", "forever://search/"},
        {"FAVORITES", #favoriteIDs, "Interface\\COMMON\\ReputationStar", "forever://favorites"},
        {"MY LISTS", listCount, "Interface\\Icons\\INV_Misc_Note_05", "forever://lists"}
    }

    for i, info in ipairs(stats) do
        local card = CreateFrame("Button", nil, PageContent)
        card:SetSize(188, 72)
        card:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 20 + (i - 1) * 201, -124)

        local bg = CreateSolidBackground(card, 0.025, 0.03, 0.05, 1)

        local icon = card:CreateTexture(nil, "ARTWORK")
        icon:SetSize(34, 34)
        icon:SetPoint("LEFT", card, "LEFT", 10, 0)
        icon:SetTexture(info[3])

        local value = CreateLabel(card, tostring(info[2]), 18, {1, 0.82, 0.25, 1})
        value:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, 1)

        local label = CreateLabel(card, info[1], 11, {0.60, 0.63, 0.70, 1})
        label:SetPoint("TOPLEFT", value, "BOTTOMLEFT", 0, -4)

        card:SetScript("OnEnter", function()
            bg:SetVertexColor(0.08, 0.10, 0.16, 1)
        end)

        card:SetScript("OnLeave", function()
            bg:SetVertexColor(unpack(WOW_THEME.row))
        end)

        card:SetScript("OnClick", function()
            Navigate(info[4])
        end)
    end

    --------------------------------------------------
    -- QUICK SEARCH
    --------------------------------------------------

    local searchPanel = CreateFrame("Frame", nil, PageContent)
    searchPanel:SetSize(790, 82)
    searchPanel:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 20, -210)
    CreateSolidBackground(searchPanel, 0.018, 0.024, 0.042, 1)

    local searchTitle = CreateLabel(searchPanel, "QUICK ITEM SEARCH", 14, {1, 0.82, 0.25, 1})
    searchTitle:SetPoint("TOPLEFT", searchPanel, "TOPLEFT", 14, -12)

    local quickSearch = CreateFrame("EditBox", nil, searchPanel)
    quickSearch:SetSize(600, 30)
    quickSearch:SetPoint("TOPLEFT", searchTitle, "BOTTOMLEFT", 0, -8)
    quickSearch:SetAutoFocus(false)
    quickSearch:SetFontObject("GameFontHighlight")
    quickSearch:SetTextInsets(10, 10, 0, 0)
    CreateSolidBackground(quickSearch, 0.03, 0.04, 0.065, 1)

    local goButton = CreateButton(searchPanel, "SEARCH", 130, 30)
    goButton:SetPoint("LEFT", quickSearch, "RIGHT", 10, 0)

    local function RunQuickSearch()
        local text = quickSearch:GetText() or ""
        if text ~= "" then
            Navigate("forever://search/" .. text)
            quickSearch:ClearFocus()
        else
            Navigate("forever://search/")
        end
    end

    goButton:SetScript("OnClick", RunQuickSearch)
    quickSearch:SetScript("OnEnterPressed", RunQuickSearch)
    quickSearch:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    --------------------------------------------------
    -- CATEGORY HEADER
    --------------------------------------------------

    local categoryTitle = CreateLabel(PageContent, "BROWSE CATEGORIES", 16, {1, 0.82, 0.25, 1})
    categoryTitle:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 20, -316)

    local categoryLine = PageContent:CreateTexture(nil, "ARTWORK")
    categoryLine:SetTexture("Interface\\Buttons\\WHITE8X8")
    categoryLine:SetVertexColor(0.32, 0.26, 0.09, 0.8)
    categoryLine:SetPoint("LEFT", categoryTitle, "RIGHT", 12, 0)
    categoryLine:SetPoint("RIGHT", PageContent, "RIGHT", -30, 0)
    categoryLine:SetHeight(1)

    --------------------------------------------------
    -- CATEGORY GRID
    --------------------------------------------------

    local cardWidth = 250
    local cardHeight = 66
    local gapX = 13
    local gapY = 10

    for index, category in ipairs(DatabaseCategories) do
        local zero = index - 1
        local column = zero - math.floor(zero / 3) * 3
        local row = math.floor(zero / 3)

        local card = CreateFrame("Button", nil, PageContent)
        card:SetSize(cardWidth, cardHeight)
        card:SetPoint(
            "TOPLEFT",
            PageContent,
            "TOPLEFT",
            20 + column * (cardWidth + gapX),
            -346 - row * (cardHeight + gapY)
        )

        local bg = CreateSolidBackground(card, 0.025, 0.03, 0.05, 1)

        local icon = card:CreateTexture(nil, "ARTWORK")
        icon:SetSize(44, 44)
        icon:SetPoint("LEFT", card, "LEFT", 10, 0)
        icon:SetTexture(category.icon)

        local name = CreateLabel(card, category.name, 14, {1, 0.82, 0.25, 1})
        name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)

        local description = CreateLabel(card, category.description, 10, {0.58, 0.61, 0.68, 1})
        description:SetWidth(175)
        description:SetJustifyH("LEFT")
        description:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -5)

        card:SetScript("OnEnter", function()
            bg:SetVertexColor(0.08, 0.10, 0.16, 1)
        end)

        card:SetScript("OnLeave", function()
            bg:SetVertexColor(unpack(WOW_THEME.row))
        end)

        card:SetScript("OnClick", function()
            Navigate("forever://category/" .. tostring(category.id))
        end)
    end

    local categoryRows = math.ceil(#DatabaseCategories / 3)
    local collectionY = -346 - categoryRows * (cardHeight + gapY) - 12

    --------------------------------------------------
    -- YOUR COLLECTION
    --------------------------------------------------

    local collectionTitle = CreateLabel(PageContent, "YOUR COLLECTION", 16, {1, 0.82, 0.25, 1})
    collectionTitle:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 20, collectionY)

    local collectionLine = PageContent:CreateTexture(nil, "ARTWORK")
    collectionLine:SetTexture("Interface\\Buttons\\WHITE8X8")
    collectionLine:SetVertexColor(0.32, 0.26, 0.09, 0.8)
    collectionLine:SetPoint("LEFT", collectionTitle, "RIGHT", 12, 0)
    collectionLine:SetPoint("RIGHT", PageContent, "RIGHT", -30, 0)
    collectionLine:SetHeight(1)

    local favoritePanel = CreateFrame("Frame", nil, PageContent)
    favoritePanel:SetSize(385, 245)
    favoritePanel:SetPoint("TOPLEFT", collectionTitle, "BOTTOMLEFT", 0, -14)
    CreateSolidBackground(favoritePanel, 0.02, 0.027, 0.045, 1)

    local favIcon = favoritePanel:CreateTexture(nil, "ARTWORK")
    favIcon:SetSize(20, 20)
    favIcon:SetPoint("TOPLEFT", favoritePanel, "TOPLEFT", 12, -12)
    favIcon:SetTexture("Interface\\COMMON\\ReputationStar")

    local favTitle = CreateLabel(favoritePanel, "FAVORITES", 14, {1, 0.82, 0.25, 1})
    favTitle:SetPoint("LEFT", favIcon, "RIGHT", 7, 0)

    local recentPanel = CreateFrame("Frame", nil, PageContent)
    recentPanel:SetSize(385, 245)
    recentPanel:SetPoint("TOPLEFT", favoritePanel, "TOPRIGHT", 20, 0)
    CreateSolidBackground(recentPanel, 0.02, 0.027, 0.045, 1)

    local recentIcon = recentPanel:CreateTexture(nil, "ARTWORK")
    recentIcon:SetSize(20, 20)
    recentIcon:SetPoint("TOPLEFT", recentPanel, "TOPLEFT", 12, -12)
    recentIcon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")

    local recentTitle = CreateLabel(recentPanel, "RECENTLY VIEWED", 14, {1, 0.82, 0.25, 1})
    recentTitle:SetPoint("LEFT", recentIcon, "RIGHT", 7, 0)

    local function CreateMiniItem(parent, itemID, rowIndex)
        local item = GetAnyItem(itemID)
        if not item then return end

        local row = CreateFrame("Button", nil, parent)
        row:SetSize(360, 36)
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -42 - (rowIndex - 1) * 39)
        local bg = CreateSolidBackground(row, 0.03, 0.037, 0.06, 1)

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(28, 28)
        icon:SetPoint("LEFT", row, "LEFT", 4, 0)
        icon:SetTexture(GetItemIcon(itemID, item))

        local name = CreateLabel(row, GetItemName(itemID), 12, GetQualityColor(GetQuality(itemID, item)))
        name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        name:SetWidth(285)
        name:SetJustifyH("LEFT")

        row:SetScript("OnEnter", function()
            bg:SetVertexColor(0.08, 0.10, 0.16, 1)
            ShowItemTooltip(itemID, row)
        end)

        row:SetScript("OnLeave", function()
            bg:SetVertexColor(unpack(WOW_THEME.row))
            if GameTooltip then GameTooltip:Hide() end
        end)

        row:SetScript("OnClick", function()
            if IsShiftLinkClick() then
                LinkItemToChat(itemID)
                return
            end
            Navigate("forever://item/" .. tostring(itemID))
        end)
    end

    local favShown = math.min(#favoriteIDs, 4)
    if favShown == 0 then
        local empty = CreateLabel(favoritePanel, "No favorites yet.", 12, {0.68, 0.64, 0.56, 1})
        empty:SetPoint("TOPLEFT", favoritePanel, "TOPLEFT", 14, -52)
    else
        for i = 1, favShown do
            CreateMiniItem(favoritePanel, favoriteIDs[i], i)
        end
    end

    local recentIDs = {}
    for _, id in ipairs(GetRecentItems()) do
        local itemID = tonumber(id)
        if itemID and GetAnyItem(itemID) then
            table.insert(recentIDs, itemID)
        end
        if #recentIDs >= 4 then break end
    end

    if #recentIDs == 0 then
        local empty = CreateLabel(recentPanel, "Items you view will appear here.", 12, {0.68, 0.64, 0.56, 1})
        empty:SetPoint("TOPLEFT", recentPanel, "TOPLEFT", 14, -52)
    else
        for i = 1, #recentIDs do
            CreateMiniItem(recentPanel, recentIDs[i], i)
        end
    end

    local allFav = CreateButton(favoritePanel, "VIEW ALL", 90, 26)
    allFav:SetPoint("BOTTOMRIGHT", favoritePanel, "BOTTOMRIGHT", -10, 9)
    allFav:SetScript("OnClick", function()
        Navigate("forever://favorites")
    end)

    local allRecent = CreateButton(recentPanel, "VIEW ALL", 90, 26)
    allRecent:SetPoint("BOTTOMRIGHT", recentPanel, "BOTTOMRIGHT", -10, 9)
    allRecent:SetScript("OnClick", function()
        Navigate("forever://recent")
    end)

    PageContent:SetHeight(
        math.max(
            980,
            -collectionY + 320
        )
    )
end


--------------------------------------------------
-- SIDEBAR COLLECTION PAGES
--------------------------------------------------

local function BuildSidebarItemPage(titleText, ids, emptyText)
    ClearPage()

    local title = CreateLabel(PageContent, titleText, 24, {1, 0.82, 0.25, 1})
    title:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, -25)
    ForeverBrowser_CodexTitle196(title)

    if #ids == 0 then
        local empty = CreateLabel(PageContent, emptyText, 13, {0.68, 0.64, 0.56, 1})
        empty:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -22)
    end

    for i, itemID in ipairs(ids) do
        local item = GetAnyItem(itemID)
        if item then
            local row = CreateFrame("Button", nil, PageContent)
            row:SetSize(740, 48)
            row:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, -75 - (i - 1) * 54)
            local bg = CreateSolidBackground(row, 0.025, 0.03, 0.05, 1)

            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(36, 36)
            icon:SetPoint("LEFT", row, "LEFT", 6, 0)
            icon:SetTexture(GetItemIcon(itemID, item))

            local name = CreateLabel(
                row,
                GetItemName(itemID),
                14,
                GetQualityColor(GetQuality(itemID, item))
            )
            name:SetPoint("LEFT", icon, "RIGHT", 10, 0)

            local idText = CreateLabel(row, "ID: " .. tostring(itemID), 12, {0.68, 0.64, 0.56, 1})
            idText:SetPoint("RIGHT", row, "RIGHT", -12, 0)

            row:SetScript("OnEnter", function()
                bg:SetVertexColor(0.08, 0.10, 0.16, 1)
                ShowItemTooltip(itemID, row)
            end)

            row:SetScript("OnLeave", function()
                bg:SetVertexColor(unpack(WOW_THEME.row))
                if GameTooltip then GameTooltip:Hide() end
            end)

            row:SetScript("OnClick", function()
                if IsShiftLinkClick() then
                    LinkItemToChat(itemID)
                    return
                end
                Navigate("forever://item/" .. tostring(itemID))
            end)
        end
    end

    PageContent:SetHeight(math.max(500, 120 + #ids * 54))
end


local function BuildFavoritesPage()
    local ids = {}
    for id, enabled in pairs(GetFavorites()) do
        local itemID = tonumber(id)
        if enabled and itemID and GetAnyItem(itemID) then
            table.insert(ids, itemID)
        end
    end
    table.sort(ids, function(a, b)
        return string.lower(GetItemName(a)) < string.lower(GetItemName(b))
    end)
    BuildSidebarItemPage("Favorites", ids, "You have not favorited any items yet.")
end


local function BuildRecentPage()
    local ids = {}
    for _, id in ipairs(GetRecentItems()) do
        local itemID = tonumber(id)
        if itemID and GetAnyItem(itemID) then
            table.insert(ids, itemID)
        end
    end
    BuildSidebarItemPage("Recently Viewed", ids, "No recently viewed items yet.")
end


local function BuildTagsPage()
    local ids = {}
    local seen = {}

    for id, value in pairs(GetItemTags()) do
        local itemID = tonumber(id)
        if itemID and tostring(value or "") ~= "" and GetAnyItem(itemID) and not seen[itemID] then
            seen[itemID] = true
            table.insert(ids, itemID)
        end
    end

    for id, value in pairs(GetItemNotes()) do
        local itemID = tonumber(id)
        if itemID and tostring(value or "") ~= "" and GetAnyItem(itemID) and not seen[itemID] then
            seen[itemID] = true
            table.insert(ids, itemID)
        end
    end

    table.sort(ids, function(a, b)
        return string.lower(GetItemName(a)) < string.lower(GetItemName(b))
    end)

    BuildSidebarItemPage("Tags & Notes", ids, "No tagged or noted items yet.")
end


--------------------------------------------------
-- CUSTOM LIST PAGES
--------------------------------------------------

local function BuildListsPage()

    ClearPage()

    local title =
        CreateLabel(
            PageContent,
            "My Lists",
            24,
            {
                1,
                0.82,
                0.25,
                1
            }
        )

    title:SetPoint(
        "TOPLEFT",
        PageContent,
        "TOPLEFT",
        25,
        -25
    )
    ForeverBrowser_CodexTitle196(title)

    local help =
        CreateLabel(
            PageContent,
            "Create collections for gear, farming, crafting, guild needs, or anything else.",
            13,
            {
                0.62,
                0.65,
                0.72,
                1
            }
        )

    help:SetPoint(
        "TOPLEFT",
        title,
        "BOTTOMLEFT",
        0,
        -8
    )

    local nameBox =
        CreateFrame(
            "EditBox",
            nil,
            PageContent
        )

    nameBox:SetSize(
        300,
        30
    )

    nameBox:SetPoint(
        "TOPLEFT",
        help,
        "BOTTOMLEFT",
        0,
        -18
    )

    nameBox:SetAutoFocus(
        false
    )

    if nameBox.SetFontObject then
        nameBox:SetFontObject(
            "GameFontHighlight"
        )
    end

    nameBox:SetTextInsets(
        10,
        10,
        0,
        0
    )

    CreateSolidBackground(
        nameBox,
        0.03,
        0.04,
        0.065,
        1
    )

    local createButton =
        CreateButton(
            PageContent,
            "CREATE LIST",
            120,
            30
        )

    createButton:SetPoint(
        "LEFT",
        nameBox,
        "RIGHT",
        10,
        0
    )

    local function CreateFromBox()

        if CreateCustomList(
            nameBox:GetText()
        ) then

            Navigate(
                "forever://lists"
            )
        end
    end

    createButton:SetScript(
        "OnClick",
        CreateFromBox
    )

    nameBox:SetScript(
        "OnEnterPressed",
        function(self)

            self:ClearFocus()
            CreateFromBox()

        end
    )

    local names = {}

    for name
        in pairs(GetCustomLists()) do

        table.insert(
            names,
            name
        )
    end

    table.sort(names)

    if #names == 0 then

        local empty =
            CreateLabel(
                PageContent,
                "No custom lists yet. Type a name above to create your first one.",
                13,
                {
                    0.55,
                    0.58,
                    0.65,
                    1
                }
            )

        empty:SetPoint(
            "TOPLEFT",
            nameBox,
            "BOTTOMLEFT",
            0,
            -25
        )

    else

        for i, name
            in ipairs(names) do

            local list =
                GetCustomLists()[name]

            local count = 0

            for _, enabled
                in pairs(
                    list.items
                    or {}
                ) do

                if enabled then
                    count = count + 1
                end
            end

            local row =
                CreateFrame(
                    "Button",
                    nil,
                    PageContent
                )

            row:SetSize(
                740,
                48
            )

            row:SetPoint(
                "TOPLEFT",
                nameBox,
                "BOTTOMLEFT",
                0,
                -22 - (i - 1) * 54
            )

            local bg =
                CreateSolidBackground(
                    row,
                    0.025,
                    0.03,
                    0.05,
                    1
                )

            local label =
                CreateLabel(
                    row,
                    name,
                    15,
                    {
                        1,
                        0.82,
                        0.25,
                        1
                    }
                )

            label:SetPoint(
                "LEFT",
                row,
                "LEFT",
                14,
                0
            )

            local countLabel =
                CreateLabel(
                    row,
                    tostring(count)
                        .. " items",
                    12,
                    {
                        0.55,
                        0.58,
                        0.65,
                        1
                    }
                )

            countLabel:SetPoint(
                "RIGHT",
                row,
                "RIGHT",
                -14,
                0
            )

            row:SetScript(
                "OnEnter",
                function()

                    bg:SetVertexColor(
                        0.08,
                        0.10,
                        0.16,
                        1
                    )
                end
            )

            row:SetScript(
                "OnLeave",
                function()

                    bg:SetVertexColor(unpack(WOW_THEME.row))
                end
            )

            row:SetScript(
                "OnClick",
                function()

                    Navigate(
                        "forever://list/"
                        .. name
                    )
                end
            )
        end
    end

    PageContent:SetHeight(
        math.max(
            500,
            180 + #names * 54
        )
    )
end


local function BuildListPage(listName)

    ClearPage()

    local list =
        GetCustomLists()[listName]

    if not list then
        return
    end

    local title =
        CreateLabel(
            PageContent,
            listName,
            24,
            {
                1,
                0.82,
                0.25,
                1
            }
        )

    title:SetPoint(
        "TOPLEFT",
        PageContent,
        "TOPLEFT",
        25,
        -25
    )
    ForeverBrowser_CodexTitle196(title)

    local back =
        CreateButton(
            PageContent,
            "ALL LISTS",
            110,
            30
        )

    back:SetPoint(
        "TOPRIGHT",
        PageContent,
        "TOPRIGHT",
        -25,
        -25
    )

    back:SetScript(
        "OnClick",
        function()

            Navigate(
                "forever://lists"
            )
        end
    )

    local renameButton =
        CreateButton(
            PageContent,
            "RENAME",
            95,
            28
        )

    renameButton:SetPoint(
        "TOPRIGHT",
        back,
        "BOTTOMRIGHT",
        0,
        -8
    )

    local deleteButton =
        CreateButton(
            PageContent,
            "DELETE",
            95,
            28
        )

    deleteButton:SetPoint(
        "RIGHT",
        renameButton,
        "LEFT",
        -8,
        0
    )

    local renameBox =
        CreateFrame(
            "EditBox",
            nil,
            PageContent
        )

    renameBox:SetSize(
        220,
        28
    )

    renameBox:SetPoint(
        "RIGHT",
        deleteButton,
        "LEFT",
        -8,
        0
    )

    renameBox:SetAutoFocus(
        false
    )

    if renameBox.SetFontObject then
        renameBox:SetFontObject(
            "GameFontHighlight"
        )
    end

    renameBox:SetTextInsets(
        8,
        8,
        0,
        0
    )

    renameBox:SetText(
        listName
    )

    CreateSolidBackground(
        renameBox,
        0.03,
        0.04,
        0.065,
        1
    )

    renameBox:Hide()

    renameButton:SetScript(
        "OnClick",
        function()

            if renameBox:IsShown() then

                local newName =
                    renameBox:GetText()

                if RenameCustomList(
                    listName,
                    newName
                ) then

                    Navigate(
                        "forever://list/"
                        .. newName
                    )
                end

            else

                renameBox:Show()
                renameBox:SetText(
                    listName
                )
                renameBox:SetFocus()

                if renameButton.text then
                    renameButton.text:SetText(
                        "SAVE"
                    )
                end
            end
        end
    )

    renameBox:SetScript(
        "OnEnterPressed",
        function(self)

            self:ClearFocus()

            local newName =
                self:GetText()

            if RenameCustomList(
                listName,
                newName
            ) then

                Navigate(
                    "forever://list/"
                    .. newName
                )
            end
        end
    )

    renameBox:SetScript(
        "OnEscapePressed",
        function(self)

            self:ClearFocus()
            self:Hide()

            if renameButton.text then
                renameButton.text:SetText(
                    "RENAME"
                )
            end
        end
    )

    local deleteConfirm =
        false

    deleteButton:SetScript(
        "OnClick",
        function()

            if not deleteConfirm then

                deleteConfirm =
                    true

                if deleteButton.text then
                    deleteButton.text:SetText(
                        "CONFIRM?"
                    )
                end

                return
            end

            if DeleteCustomList(
                listName
            ) then

                Navigate(
                    "forever://lists"
                )
            end
        end
    )

    local ids = {}

    for id, enabled
        in pairs(
            list.items
            or {}
        ) do

        local numericID =
            tonumber(id)

        if enabled
            and numericID
            and GetAnyItem(numericID) then

            table.insert(
                ids,
                numericID
            )
        end
    end

    table.sort(
        ids,
        function(a, b)

            return string.lower(
                GetItemName(a)
            )
            < string.lower(
                GetItemName(b)
            )
        end
    )

    if #ids == 0 then

        local empty =
            CreateLabel(
                PageContent,
                "This list is empty. Open an item and click ADD TO LIST.",
                13,
                {
                    0.55,
                    0.58,
                    0.65,
                    1
                }
            )

        empty:SetPoint(
            "TOPLEFT",
            title,
            "BOTTOMLEFT",
            0,
            -25
        )

    else

        for i, itemID
            in ipairs(ids) do

            local item =
                GetAnyItem(itemID)

            local row =
                CreateFrame(
                    "Button",
                    nil,
                    PageContent
                )

            row:SetSize(
                740,
                48
            )

            row:SetPoint(
                "TOPLEFT",
                PageContent,
                "TOPLEFT",
                25,
                -80 - (i - 1) * 54
            )

            local bg =
                CreateSolidBackground(
                    row,
                    0.025,
                    0.03,
                    0.05,
                    1
                )

            local icon =
                row:CreateTexture(
                    nil,
                    "ARTWORK"
                )

            icon:SetSize(
                36,
                36
            )

            icon:SetPoint(
                "LEFT",
                row,
                "LEFT",
                6,
                0
            )

            icon:SetTexture(
                GetItemIcon(
                    itemID,
                    item
                )
            )

            local quality =
                GetQuality(
                    itemID,
                    item
                )

            local name =
                CreateLabel(
                    row,
                    GetItemName(itemID),
                    14,
                    GetQualityColor(quality)
                )

            name:SetPoint(
                "LEFT",
                icon,
                "RIGHT",
                10,
                0
            )

            local idLabel =
                CreateLabel(
                    row,
                    "ID: "
                        .. tostring(itemID),
                    12,
                    {
                        0.55,
                        0.58,
                        0.65,
                        1
                    }
                )

            idLabel:SetPoint(
                "RIGHT",
                row,
                "RIGHT",
                -12,
                0
            )

            row:SetScript(
                "OnEnter",
                function()

                    bg:SetVertexColor(
                        0.08,
                        0.10,
                        0.16,
                        1
                    )

                    ShowItemTooltip(
                        itemID,
                        row
                    )
                end
            )

            row:SetScript(
                "OnLeave",
                function()

                    bg:SetVertexColor(unpack(WOW_THEME.row))

                    if GameTooltip then
                        GameTooltip:Hide()
                    end
                end
            )

            row:SetScript(
                "OnClick",
                function()

                    if IsShiftLinkClick() then

                        LinkItemToChat(
                            itemID
                        )

                        return
                    end

                    Navigate(
                        "forever://item/"
                        .. tostring(itemID)
                    )
                end
            )
        end
    end

    PageContent:SetHeight(
        math.max(
            500,
            120 + #ids * 54
        )
    )
end


local function BuildAddToListPage(itemID)

    ClearPage()

    itemID =
        tonumber(itemID)

    local item =
        GetAnyItem(itemID)

    if not item then
        return
    end

    local title =
        CreateLabel(
            PageContent,
            "Add to List",
            24,
            {
                1,
                0.82,
                0.25,
                1
            }
        )

    title:SetPoint(
        "TOPLEFT",
        PageContent,
        "TOPLEFT",
        25,
        -25
    )
    ForeverBrowser_CodexTitle196(title)

    local itemName =
        CreateLabel(
            PageContent,
            GetItemName(itemID),
            16,
            GetQualityColor(
                GetQuality(
                    itemID,
                    item
                )
            )
        )

    itemName:SetPoint(
        "TOPLEFT",
        title,
        "BOTTOMLEFT",
        0,
        -10
    )

    local newBox =
        CreateFrame(
            "EditBox",
            nil,
            PageContent
        )

    newBox:SetSize(
        280,
        30
    )

    newBox:SetPoint(
        "TOPLEFT",
        itemName,
        "BOTTOMLEFT",
        0,
        -20
    )

    newBox:SetAutoFocus(
        false
    )

    if newBox.SetFontObject then
        newBox:SetFontObject(
            "GameFontHighlight"
        )
    end

    newBox:SetTextInsets(
        10,
        10,
        0,
        0
    )

    CreateSolidBackground(
        newBox,
        0.03,
        0.04,
        0.065,
        1
    )

    local create =
        CreateButton(
            PageContent,
            "NEW LIST",
            105,
            30
        )

    create:SetPoint(
        "LEFT",
        newBox,
        "RIGHT",
        10,
        0
    )

    create:SetScript(
        "OnClick",
        function()

            local name =
                newBox:GetText()

            if CreateCustomList(name) then

                ToggleItemInCustomList(
                    name,
                    itemID
                )

                Navigate(
                    "forever://lists/add/"
                    .. tostring(itemID)
                )
            end
        end
    )

    local names = {}

    for name
        in pairs(GetCustomLists()) do

        table.insert(
            names,
            name
        )
    end

    table.sort(names)

    local heading =
        CreateLabel(
            PageContent,
            "Your Lists",
            16,
            {
                0.85,
                0.85,
                0.90,
                1
            }
        )

    heading:SetPoint(
        "TOPLEFT",
        newBox,
        "BOTTOMLEFT",
        0,
        -25
    )

    for i, name
        in ipairs(names) do

        local active =
            IsItemInCustomList(
                name,
                itemID
            )

        local button =
            CreateButton(
                PageContent,
                (active
                    and "REMOVE  "
                    or "ADD  ")
                    .. name,
                360,
                34
            )

        button:SetPoint(
            "TOPLEFT",
            heading,
            "BOTTOMLEFT",
            0,
            -10 - (i - 1) * 40
        )

        button:SetScript(
            "OnClick",
            function()

                ToggleItemInCustomList(
                    name,
                    itemID
                )

                Navigate(
                    "forever://lists/add/"
                    .. tostring(itemID)
                )
            end
        )
    end

    PageContent:SetHeight(
        math.max(
            500,
            210 + #names * 40
        )
    )
end


--------------------------------------------------
-- COMPARE HELPERS
--------------------------------------------------

local function BuildCompareSelectPage(firstItemID)

    ClearPage()

    firstItemID =
        tonumber(firstItemID)

    if not firstItemID
        or not GetAnyItem(firstItemID) then

        Navigate(
            "forever://home"
        )

        return
    end

    CompareFirstItemID =
        firstItemID

    local title =
        CreateLabel(
            PageContent,
            "Compare Items",
            24,
            {
                1,
                0.82,
                0.25,
                1
            }
        )

    title:SetPoint(
        "TOPLEFT",
        PageContent,
        "TOPLEFT",
        25,
        -25
    )
    ForeverBrowser_CodexTitle196(title)

    local firstItem =
        GetAnyItem(firstItemID)

    local selected =
        CreateLabel(
            PageContent,
            "Comparing: "
                .. GetItemName(firstItemID)
                .. "  (ID "
                .. tostring(firstItemID)
                .. ")",
            14,
            GetQualityColor(
                GetQuality(
                    firstItemID,
                    firstItem
                )
            )
        )

    selected:SetPoint(
        "TOPLEFT",
        title,
        "BOTTOMLEFT",
        0,
        -12
    )

    local help =
        CreateLabel(
            PageContent,
            "Search for the second item by name or Item ID.",
            13,
            {
                0.65,
                0.68,
                0.75,
                1
            }
        )

    help:SetPoint(
        "TOPLEFT",
        selected,
        "BOTTOMLEFT",
        0,
        -12
    )

    local searchBox =
        CreateFrame(
            "EditBox",
            nil,
            PageContent
        )

    searchBox:SetSize(
        500,
        32
    )

    searchBox:SetPoint(
        "TOPLEFT",
        help,
        "BOTTOMLEFT",
        0,
        -15
    )

    searchBox:SetAutoFocus(
        false
    )

    if searchBox.SetFontObject then
        searchBox:SetFontObject(
            "GameFontHighlight"
        )
    end

    searchBox:SetTextInsets(
        10,
        10,
        0,
        0
    )

    CreateSolidBackground(
        searchBox,
        0.03,
        0.04,
        0.065,
        1
    )

    local resultRows = {}

    local function UpdateResults()

        for _, row
            in ipairs(resultRows) do

            row:Hide()
        end

        local query =
            string.lower(
                tostring(
                    searchBox:GetText()
                    or ""
                )
            )

        if query == "" then
            return
        end

        local numeric =
            tonumber(query)

        local found = {}
        local seen = {}

        local function Consider(
            itemID,
            item
        )

            itemID =
                tonumber(itemID)

            if not itemID
                or itemID == firstItemID
                or seen[itemID] then
                return
            end

            local name =
                GetItemName(itemID)

            local lowerName =
                string.lower(
                    tostring(name or "")
                )

            local match =
                (numeric and itemID == numeric)
                or string.find(
                    lowerName,
                    query,
                    1,
                    true
                )

            if match then

                seen[itemID] = true

                table.insert(
                    found,
                    {
                        id = itemID,
                        item = item,
                        name = name
                    }
                )

            end
        end

        for itemID, item
            in pairs(GetWorldItems()) do

            Consider(
                itemID,
                item
            )

            if #found >= 8 then
                break
            end
        end

        if #found < 8 then

            for itemID, item
                in pairs(GetPlayerItems()) do

                Consider(
                    itemID,
                    item
                )

                if #found >= 8 then
                    break
                end
            end
        end

        table.sort(
            found,
            function(a, b)

                return string.lower(a.name or "")
                    < string.lower(b.name or "")

            end
        )

        for i = 1, math.min(#found, 8) do

            local data =
                found[i]

            local row =
                resultRows[i]

            if not row then

                row =
                    CreateFrame(
                        "Button",
                        nil,
                        PageContent
                    )

                row:SetSize(
                    620,
                    42
                )

                resultRows[i] =
                    row

            end

            row:ClearAllPoints()

            row:SetPoint(
                "TOPLEFT",
                searchBox,
                "BOTTOMLEFT",
                0,
                -8 - (i - 1) * 46
            )

            if not row.bg then

                row.bg =
                    CreateSolidBackground(
                        row,
                        0.025,
                        0.03,
                        0.05,
                        1
                    )

            end

            if not row.icon then

                row.icon =
                    row:CreateTexture(
                        nil,
                        "ARTWORK"
                    )

                row.icon:SetSize(
                    32,
                    32
                )

                row.icon:SetPoint(
                    "LEFT",
                    row,
                    "LEFT",
                    6,
                    0
                )

            end

            if not row.nameLabel then

                row.nameLabel =
                    CreateLabel(
                        row,
                        "",
                        14,
                        {
                            1,
                            1,
                            1,
                            1
                        }
                    )

                row.nameLabel:SetPoint(
                    "LEFT",
                    row.icon,
                    "RIGHT",
                    10,
                    0
                )

            end

            if not row.idLabel then

                row.idLabel =
                    CreateLabel(
                        row,
                        "",
                        12,
                        {
                            0.55,
                            0.58,
                            0.65,
                            1
                        }
                    )

                row.idLabel:SetPoint(
                    "RIGHT",
                    row,
                    "RIGHT",
                    -12,
                    0
                )

            end

            row.itemID =
                data.id

            row.icon:SetTexture(
                GetItemIcon(
                    data.id,
                    data.item
                )
            )

            local qc =
                GetQualityColor(
                    GetQuality(
                        data.id,
                        data.item
                    )
                )

            row.nameLabel:SetText(
                data.name
            )

            row.nameLabel:SetTextColor(
                qc[1] or 1,
                qc[2] or 1,
                qc[3] or 1,
                1
            )

            row.idLabel:SetText(
                "ID: "
                .. tostring(data.id)
            )

            row:SetScript(
                "OnClick",
                function(self)

                    Navigate(
                        "forever://compare/"
                        .. tostring(firstItemID)
                        .. "/"
                        .. tostring(self.itemID)
                    )

                end
            )

            row:Show()
        end
    end

    searchBox:SetScript(
        "OnTextChanged",
        function()
            UpdateResults()
        end
    )

    searchBox:SetScript(
        "OnEscapePressed",
        function(self)
            self:ClearFocus()
        end
    )

    searchBox:SetFocus()

    PageContent:SetHeight(
        620
    )
end


local function BuildComparePage(
    firstItemID,
    secondItemID
)

    ClearPage()

    firstItemID =
        tonumber(firstItemID)

    secondItemID =
        tonumber(secondItemID)

    local first =
        GetAnyItem(firstItemID)

    local second =
        GetAnyItem(secondItemID)

    if not first
        or not second then

        return
    end

    local title =
        CreateLabel(
            PageContent,
            "Item Comparison",
            24,
            {
                1,
                0.82,
                0.25,
                1
            }
        )

    title:SetPoint(
        "TOPLEFT",
        PageContent,
        "TOPLEFT",
        25,
        -25
    )
    ForeverBrowser_CodexTitle196(title)

    local subtitle =
        CreateLabel(
            PageContent,
            "WoW tooltips shown side-by-side",
            13,
            {
                0.62,
                0.65,
                0.72,
                1
            }
        )

    subtitle:SetPoint(
        "TOPLEFT",
        title,
        "BOTTOMLEFT",
        0,
        -7
    )

    local change =
        CreateButton(
            PageContent,
            "CHANGE ITEM",
            125,
            30
        )

    change:SetPoint(
        "TOPRIGHT",
        PageContent,
        "TOPRIGHT",
        -25,
        -25
    )

    change:SetScript(
        "OnClick",
        function()

            Navigate(
                "forever://compare-select/"
                .. tostring(firstItemID)
            )

        end
    )

    --------------------------------------------------
    -- TOOLTIP PANELS
    --------------------------------------------------

    local leftPanel =
        CreateFrame(
            "Frame",
            nil,
            PageContent
        )

    leftPanel:SetSize(
        370,
        470
    )

    leftPanel:SetPoint(
        "TOPLEFT",
        PageContent,
        "TOPLEFT",
        25,
        -90
    )

    CreateSolidBackground(
        leftPanel,
        0.018,
        0.022,
        0.035,
        1
    )

    local rightPanel =
        CreateFrame(
            "Frame",
            nil,
            PageContent
        )

    rightPanel:SetSize(
        370,
        470
    )

    rightPanel:SetPoint(
        "TOPRIGHT",
        PageContent,
        "TOPRIGHT",
        -25,
        -90
    )

    CreateSolidBackground(
        rightPanel,
        0.018,
        0.022,
        0.035,
        1
    )

    --------------------------------------------------
    -- PERMANENT WOW TOOLTIPS
    --------------------------------------------------

    local leftTooltip =
        CreateFrame(
            "GameTooltip",
            "ForeverBrowserCompareTooltipLeft",
            PageContent,
            "GameTooltipTemplate"
        )

    leftTooltip:SetOwner(
        leftPanel,
        "ANCHOR_NONE"
    )


    leftTooltip:ClearAllPoints()

    leftTooltip:SetPoint(
        "TOPLEFT",
        leftPanel,
        "TOPLEFT",
        8,
        -8
    )

    local rightTooltip =
        CreateFrame(
            "GameTooltip",
            "ForeverBrowserCompareTooltipRight",
            PageContent,
            "GameTooltipTemplate"
        )

    rightTooltip:SetOwner(
        rightPanel,
        "ANCHOR_NONE"
    )


    rightTooltip:ClearAllPoints()

    rightTooltip:SetPoint(
        "TOPLEFT",
        rightPanel,
        "TOPLEFT",
        8,
        -8
    )

    local function SetComparisonTooltip(
        tooltip,
        itemID
    )

        tooltip:ClearLines()

        if tooltip.ForeverCleanTitle then
            tooltip.ForeverCleanTitle:Hide()
        end

        local link = nil

        if C_Item
            and C_Item.GetItemInfo then

            local ok,
                itemName,
                itemLink =
                pcall(
                    C_Item.GetItemInfo,
                    itemID
                )

            if ok then
                link = itemLink
            end
        end

        if not link
            and GetItemInfo then

            local ok,
                itemName,
                itemLink =
                pcall(
                    GetItemInfo,
                    itemID
                )

            if ok then
                link = itemLink
            end
        end

        if link
            and tooltip.SetHyperlink then

            tooltip:SetHyperlink(
                link
            )

        elseif tooltip.SetHyperlink then

            pcall(
                tooltip.SetHyperlink,
                tooltip,
                "item:"
                    .. tostring(itemID)
            )

        end

        tooltip:Show()

        -- Native tooltip text may be protected/secret on this client.
        -- Do not read or rewrite its FontStrings here.

    end

    SetComparisonTooltip(
        leftTooltip,
        firstItemID
    )

    SetComparisonTooltip(
        rightTooltip,
        secondItemID
    )

    --------------------------------------------------
    -- ITEM ID LABELS
    --------------------------------------------------

    local leftID =
        CreateLabel(
            PageContent,
            "Item ID: "
                .. tostring(firstItemID),
            12,
            {
                0.55,
                0.58,
                0.65,
                1
            }
        )

    leftID:SetPoint(
        "TOPLEFT",
        leftPanel,
        "BOTTOMLEFT",
        8,
        -10
    )

    local rightID =
        CreateLabel(
            PageContent,
            "Item ID: "
                .. tostring(secondItemID),
            12,
            {
                0.55,
                0.58,
                0.65,
                1
            }
        )

    rightID:SetPoint(
        "TOPLEFT",
        rightPanel,
        "BOTTOMLEFT",
        8,
        -10
    )

    PageContent:SetHeight(
        620
    )
end


--------------------------------------------------
-- DEBUG PAGE
--------------------------------------------------

local DebugPageRefreshFrame = nil
local DebugPageLastCount = -1
local DebugPageLastEnabled = nil

local function GetDebugCategory(message)
    local upper = string.upper(tostring(message or ""))

    if string.find(upper, "ERROR", 1, true)
        or string.find(upper, "FAILED", 1, true)
        or string.find(upper, "MISSING", 1, true)
        or string.find(upper, "COULD NOT", 1, true) then
        return "ERROR"
    end

    if string.find(upper, "SOURCE", 1, true) then
        return "SOURCE"
    end

    if string.find(upper, "LOOT", 1, true) then
        return "LOOT"
    end

    if string.find(upper, "SCAN", 1, true)
        or string.find(upper, "BAG", 1, true)
        or string.find(upper, "BANK", 1, true) then
        return "SCAN"
    end

    return "DEBUG"
end

local function StopDebugAutoRefresh()
    if DebugPageRefreshFrame then
        DebugPageRefreshFrame:SetScript("OnUpdate", nil)
        DebugPageRefreshFrame:Hide()
        DebugPageRefreshFrame = nil
    end
end

--------------------------------------------------
-- SETTINGS PAGE
--------------------------------------------------


--------------------------------------------------
-- DUNGEON DATABASE
--------------------------------------------------

local function GetForeverDungeonIndex()
    local source=ForeverSourceData or {} local groups={}
    for _,r in pairs(source.dungeons or {}) do if type(r)=="table" and r.name then
        local k=string.lower(tostring(r.name))
        groups[k]=groups[k] or {name=tostring(r.name),bosses={},seen={}}
        local d=groups[k] d.minLevel=d.minLevel or r.minLevel d.maxLevel=d.maxLevel or r.maxLevel
        d.isForever=d.isForever or r.isForever==true
        for _,boss in pairs(type(r.bosses)=="table" and r.bosses or {}) do
            local id=tonumber(type(boss)=="table" and boss.id or boss)
            if id and not d.seen[id] then
                d.bosses[#d.bosses+1]={id=id,name=type(boss)=="table" and boss.name or ("NPC "..id),role=type(boss)=="table" and tostring(boss.role or "Dungeon Boss") or "Dungeon Boss"}
                d.bosses[#d.bosses].name=d.bosses[#d.bosses].name or ("NPC "..id)
                d.seen[id]=true
            end
        end
    end end
    for rawID,npc in pairs(source.foreverNPCs or {}) do if type(npc)=="table" and npc.dungeonName then
        local id=tonumber(rawID) or tonumber(npc.id) local k=string.lower(npc.dungeonName)
        if id and k~="" then groups[k]=groups[k] or {name=npc.dungeonName,bosses={},seen={},isForever=true}
            if not groups[k].seen[id] then groups[k].seen[id]=true groups[k].bosses[#groups[k].bosses+1]={id=id,name=npc.name or ("NPC "..id),role=tostring(npc.role or "Dungeon Boss")} end
        end
    end end
    local out={} for _,d in pairs(groups) do table.sort(d.bosses,function(a,b) return a.name<b.name end) out[#out+1]=d end
    table.sort(out,function(a,b) return a.name<b.name end) return out
end


function ForeverBrowser_LootIndex211(force)
    local source=ForeverSourceData and ForeverSourceData.items or {} local now=type(GetTime)=="function" and GetTime() or 0
    local cache=ForeverBrowserLootCache211
    if not force and cache and cache.source==source and now-cache.time<60 then return cache.bosses end
    local bosses,seen={},{}
    for key,item in pairs(source) do if type(item)=="table" then local id=tonumber(key) or tonumber(item.id)
        if id then for _,r in pairs(type(item.sources)=="table" and item.sources or {}) do if type(r)=="table" and (r.type=="drop" or r.type=="pickpocket" or r.type=="skinning") then
            local npc=tonumber(r.id or r.npcID) if npc then
                bosses[npc]=bosses[npc] or {} seen[npc]=seen[npc] or {}
                if not seen[npc][id] then seen[npc][id]=true bosses[npc][#bosses[npc]+1]={id=id,name=tostring(item.name or GetItemName(id)),chance=tonumber(r.chance),sourceType=r.type} end
            end
        end end end
    end end
    for _,loot in pairs(bosses) do table.sort(loot,function(a,b) if a.chance and b.chance and a.chance~=b.chance then return a.chance>b.chance end if a.name==b.name then return a.id<b.id end return string.lower(a.name)<string.lower(b.name) end) end
    ForeverBrowserLootCache211={source=source,time=now,bosses=bosses} return bosses
end
local function GetForeverBossLoot(npcID)
    local result={} for _,r in ipairs(ForeverBrowser_LootIndex211()[tonumber(npcID)] or {}) do local copy={} for k,v in pairs(r) do copy[k]=v end result[#result+1]=copy end return result
end


ForeverBrowserBuildFarmingListPage = function()
    ClearPage()
    ScanForeverOwnedItems()

    local title=CreateLabel(PageContent,"FARMING LIST / WISHLIST",24,WOW_THEME.gold)
    title:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,-25)
    local subtitle=CreateLabel(PageContent,
        "Tracked dungeon drops, grouped by dungeon and boss.",
        12,WOW_THEME.muted)
    subtitle:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-7)

    local wishlist=GetForeverWishlist()
    local groups={}
    local total=0
    local missing=0

    if ForeverSourceData and type(ForeverSourceData.items)=="table" then
        for rawID,flag in pairs(wishlist) do
            if flag then
                local itemID=tonumber(rawID)
                local item=itemID and (ForeverSourceData.items[itemID] or ForeverSourceData.items[tostring(itemID)])
                if item then
                    local itemName=tostring(item.name or ("Item "..tostring(itemID)))
                    local found=false
                    if type(item.sources)=="table" then
                        for _,source in pairs(item.sources) do
                            local sourceID=tonumber(source.id or source.npcID)
                            local npc=sourceID and ForeverSourceData.foreverNPCs
                                and (ForeverSourceData.foreverNPCs[sourceID] or ForeverSourceData.foreverNPCs[tostring(sourceID)])
                            if npc and npc.dungeonName then
                                local dungeonName=tostring(npc.dungeonName)
                                local bossName=tostring(npc.name or "Unknown Boss")
                                groups[dungeonName]=groups[dungeonName] or {}
                                groups[dungeonName][bossName]=groups[dungeonName][bossName] or {}
                                table.insert(groups[dungeonName][bossName],{
                                    id=itemID,name=itemName,collected=IsForeverItemCollected(itemID)
                                })
                                found=true
                                break
                            end
                        end
                    end
                    if found then
                        total=total+1
                        if not IsForeverItemCollected(itemID) then missing=missing+1 end
                    end
                end
            end
        end
    end

    local summary=CreateLabel(PageContent,
        tostring(total).." TRACKED  |  "..tostring(missing).." MISSING  |  "..tostring(total-missing).." COLLECTED",
        11,WOW_THEME.goldSoft)
    summary:SetPoint("TOPLEFT",subtitle,"BOTTOMLEFT",0,-16)

    local y=-112
    if total==0 then
        local none=CreateLabel(PageContent,
            "Your Farming List is empty. Open a dungeon and press TRACK beside loot you want to farm.",
            13,WOW_THEME.muted)
        none:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,y)
        PageContent:SetHeight(600)
        return
    end

    local dungeonNames={}
    for dungeonName in pairs(groups) do table.insert(dungeonNames,dungeonName) end
    table.sort(dungeonNames,function(a,b) return string.lower(a)<string.lower(b) end)

    for _,dungeonName in ipairs(dungeonNames) do
        local heading=CreateLabel(PageContent,string.upper(dungeonName),15,WOW_THEME.gold)
        heading:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,y)
        y=y-28

        local bossNames={}
        for bossName in pairs(groups[dungeonName]) do table.insert(bossNames,bossName) end
        table.sort(bossNames,function(a,b) return string.lower(a)<string.lower(b) end)

        for _,bossName in ipairs(bossNames) do
            local bossLabel=CreateLabel(PageContent,bossName,11,WOW_THEME.goldSoft)
            bossLabel:SetPoint("TOPLEFT",PageContent,"TOPLEFT",37,y)
            y=y-23

            local items=groups[dungeonName][bossName]
            table.sort(items,function(a,b) return string.lower(a.name)<string.lower(b.name) end)
            for _,entry in ipairs(items) do
                local row=CreateFrame("Frame",nil,PageContent)
                row:SetSize(766,42)
                row:SetPoint("TOPLEFT",PageContent,"TOPLEFT",37,y)
                local bg=row:CreateTexture(nil,"BACKGROUND")
                bg:SetTexture("Interface\\Buttons\\WHITE8X8")
                bg:SetAllPoints(row)
                local c=WOW_THEME.inset
                bg:SetVertexColor(c[1],c[2],c[3],0.94)

                -- Use Blizzard checkbox textures instead of Unicode glyphs/text.
                local checkBox=row:CreateTexture(nil,"ARTWORK")
                checkBox:SetSize(20,20)
                checkBox:SetPoint("LEFT",row,"LEFT",10,0)
                checkBox:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")

                if entry.collected then
                    local check=row:CreateTexture(nil,"OVERLAY")
                    check:SetSize(20,20)
                    check:SetPoint("CENTER",checkBox,"CENTER",0,0)
                    check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
                end

                local name=CreateLabel(row,entry.name,12,WOW_THEME.text)
                name:SetPoint("LEFT",checkBox,"RIGHT",6,0)

                local view=CreateButton(row,"VIEW ITEM",92,24)
                view:SetPoint("RIGHT",row,"RIGHT",-92,0)
                local itemID=entry.id
                view:SetScript("OnClick",function()
                    Navigate("forever://item/"..tostring(itemID))
                end)

                local remove=CreateButton(row,"REMOVE",78,24)
                remove:SetPoint("RIGHT",row,"RIGHT",-8,0)
                remove:SetScript("OnClick",function()
                    SetForeverItemTracked(itemID,false)
                    ForeverBrowserBuildFarmingListPage()
                end)

                y=y-48
            end
            y=y-7
        end
        y=y-13
    end

    PageContent:SetHeight(math.max(600,math.abs(y)+80))
end


ForeverBrowserBuildDungeonDatabasePage = function(searchText, alphaFilter)
    ForeverBrowser_DungeonHome191(searchText, alphaFilter)
end


-- Matching Codex title and parchment record summary for dungeon loot.
function ForeverBrowser_DungeonLootBanner194(title,subtitle)
    local hero=ForeverBrowser_QuestBanner193(title,subtitle,"Interface\\Icons\\INV_Misc_Map_01")
    hero:SetHeight(132)
    title:SetWidth(660) title:SetHeight(36) title:SetJustifyH("LEFT") title:SetJustifyV("TOP")
    ForeverBrowser_QuestSummary193(subtitle)
end

function ForeverBrowser_D220OverviewData(name)
    local source=ForeverSourceData or {} local record={} local quests,entrances={},{}
    for _,d in pairs(source.dungeons or {}) do if type(d)=="table" and string.lower(tostring(d.name or d.dungeonName or ""))==string.lower(name) then record=d break end end
    for _,p in pairs(type(record.entranceLocations or record.entrances)=="table" and (record.entranceLocations or record.entrances) or {}) do
        if type(p)=="table" and tonumber(p.uiMapID) and tonumber(p.x) and tonumber(p.y) then entrances[#entrances+1]={mapID=tonumber(p.uiMapID),x=tonumber(p.x),y=tonumber(p.y)} end
    end
    local _,_,related=ForeverBrowser_C198DungeonData(name)
    for _,q in ipairs(related or {}) do if tonumber(q.id) then
        local r=ForeverBrowser_FindQuestSourceData(q.id) or {} local prerequisite=ForeverBrowser_C201IDs(r.previousQuests or r.prerequisites or r.previousQuestID)
        local status=ForeverBrowser_QuestStatusText225(q.id)
        quests[#quests+1]={id=q.id,name=q.name,detail=status.." • "..ForeverBrowser_CountRecords(prerequisite).." recorded prerequisites",url="forever://quest/"..q.id}
    end end
    return record,quests,entrances
end
function ForeverBrowser_D220Overview(selected,lootCount,collected)
    local r,quests,entrances=ForeverBrowser_D220OverviewData(selected.name)
    local panel=CreateFrame("Frame",nil,PageContent) panel:SetSize(790,278) panel:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,-212)
    ForeverBrowser_AchievementPaper(panel,false) ForeverBrowser_AchievementBorder(panel,true)
    local function label(text,size,x,y,width)
        local t=ForeverBrowser_AchievementLabel(panel,text,size,WOW_THEME.muted) t:SetPoint("TOPLEFT",panel,"TOPLEFT",x,y) t:SetWidth(width or 750) t:SetHeight(size>13 and 24 or 32) t:SetJustifyH("LEFT") return t
    end
    label("DUNGEON OVERVIEW",16,16,-12)
    label("Recommended levels: "..tostring(r.minLevel or selected.minLevel or "unknown").."–"..tostring(r.maxLevel or selected.maxLevel or "unknown").."   •   "..tostring(r.locationDescription or "Location not recorded"),12,16,-43)
    label(#selected.bosses.." boss records   •   "..lootCount.." loot items   •   "..#quests.." related quests   •   "..collected.." / "..lootCount.." items collected",11,16,-76)
    local function button(text,width,x,fn)
        local b=CreateButton(panel,text,width,28) b:SetPoint("TOPLEFT",panel,"TOPLEFT",x,-112) b:SetScript("OnClick",fn) return b
    end
    local entrance=button("Show Entrance",140,16,function() local p=entrances[1] if p then ShowForeverBrowserMapMarker(p.mapID,p.x,p.y,selected.name.." Entrance") end end)
    if #entrances==0 then entrance:Disable() label("Entrance coordinates not recorded",10,16,-146,240)
    elseif #entrances>1 then label(#entrances.." recorded entrances • first shown; see Guide for all",10,16,-146,300) end
    button("Dungeon Quests",145,166,function() Navigate("forever://codex/dungeon-quests/"..selected.name.."/1") end)
    button("Prepare Run",125,321,function() Navigate("forever://codex/prep/"..selected.name.."/1") end)
    button("Full Guide",120,456,function() Navigate("forever://codex/guide/"..selected.name.."/1") end)
    button("Notes & Tags",140,586,function() Navigate("forever://codex/notes/dungeon/"..selected.name) end)
    label("QUEST HIGHLIGHTS",13,16,-179)
    for i=1,math.min(2,#quests) do local q=quests[i]
        local b=CreateButton(panel,q.name,350,26) b:SetPoint("TOPLEFT",panel,"TOPLEFT",16+(i-1)*380,-211)
        b:SetScript("OnClick",function() Navigate(q.url) end)
    end
    if #quests==0 then label("No related quests are recorded in the loaded database.",11,16,-211) end
    label("Collection progress counts obtained items. Boss kills and dungeon clears are not tracked.",10,16,-246)
    return -520
end
function ForeverBrowser_D220Quests(name,page)
    local _,quests=ForeverBrowser_D220OverviewData(name)
    ForeverBrowser_C201List(name.." — Dungeon Quests","Open a quest for prerequisites, giver locations, required items and rewards. Recorded associations do not imply current eligibility.",quests,page,"forever://codex/dungeon-quests/"..name.."/")
    local back=CreateButton(PageContent,"Return to Dungeon",150,28) back:SetPoint("TOPLEFT",PageContent,"TOPLEFT",160,-20) back:SetScript("OnClick",function() Navigate("forever://dungeon/"..name) end)
end

ForeverBrowserBuildDungeonPage = function(dungeonName, lootSearch, lootFilter, lootSort, slotFilter, bossFilter, collectionFilter)
    ClearPage()

    local settings=ForeverBrowser_S222() settings.dungeonFilters=settings.dungeonFilters or {}
    local saved=settings.rememberFilters and settings.dungeonFilters[tostring(dungeonName)]
    if lootSearch==nil and saved then lootSearch=saved.query lootFilter=saved.filter lootSort=saved.sort slotFilter=saved.slot bossFilter=saved.boss collectionFilter=saved.collection end
    lootSort=lootSort or settings.lootSort collectionFilter=collectionFilter or (settings.showCollected and "ALL" or "MISSING")
    dungeonName = tostring(dungeonName or "")
    lootSearch = tostring(lootSearch or "")
    lootFilter = tostring(lootFilter or "ALL")
    lootSort = tostring(lootSort or "NAME")
    slotFilter = tostring(slotFilter or "ALL")
    bossFilter = tostring(bossFilter or "ALL")
    collectionFilter = tostring(collectionFilter or "ALL")
    if settings.rememberFilters then settings.dungeonFilters[dungeonName]={query=lootSearch,filter=lootFilter,sort=lootSort,slot=slotFilter,boss=bossFilter,collection=collectionFilter} end
    ScanForeverOwnedItems()

    local selected = nil
    for _, dungeon in ipairs(GetForeverDungeonIndex()) do
        if string.lower(dungeon.name) == string.lower(dungeonName) then
            selected = dungeon
            break
        end
    end

    local back = ForeverBrowser_ItemButton190(PageContent, "< DUNGEONS", 125, 28)
    back:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, -22)
    back:SetScript("OnClick", function()
        Navigate("forever://dungeons")
    end)

    if not selected then
        local missing = ForeverBrowser_AchievementLabel(PageContent, "Dungeon not found in the loaded ForeverDB data.", 14, WOW_THEME.muted)
        missing:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, -72)
        PageContent:SetHeight(600)
        return
    end

    local function GetDungeonLootSlot(itemID, item)
        local equipLoc =
            (item and (item.equipLoc or item.EquipLoc or item.inventoryType or item.InventoryType))
            or nil

        equipLoc = tostring(equipLoc or "")

        local slots = {
            INVTYPE_HEAD="HEAD",
            INVTYPE_NECK="NECK",
            INVTYPE_SHOULDER="SHOULDERS",
            INVTYPE_CLOAK="BACK",
            INVTYPE_CHEST="CHEST",
            INVTYPE_ROBE="CHEST",
            INVTYPE_WRIST="WRISTS",
            INVTYPE_HAND="HANDS",
            INVTYPE_WAIST="WAIST",
            INVTYPE_LEGS="LEGS",
            INVTYPE_FEET="FEET",
            INVTYPE_FINGER="RINGS",
            INVTYPE_TRINKET="TRINKETS",
            INVTYPE_WEAPONMAINHAND="MAIN_HAND",
            INVTYPE_2HWEAPON="MAIN_HAND",
            INVTYPE_WEAPON="MAIN_HAND",
            INVTYPE_WEAPONOFFHAND="OFF_HAND",
            INVTYPE_HOLDABLE="OFF_HAND",
            INVTYPE_SHIELD="OFF_HAND",
            INVTYPE_RANGED="RANGED",
            INVTYPE_RANGEDRIGHT="RANGED",
            INVTYPE_THROWN="RANGED",
            INVTYPE_RELIC="RANGED",
        }

        return slots[equipLoc] or "OTHER"
    end

    -- Build one de-duplicated loot list for the whole dungeon.
    local allLoot = {}
    local seen = {}
    for _, boss in ipairs(selected.bosses) do
        for _, item in ipairs(GetForeverBossLoot(boss.id)) do
            if not seen[item.id] then
                seen[item.id] = true
                item.bossName = boss.name
                item.bossID = boss.id
                table.insert(allLoot, item)
            end
        end
    end

    local title = ForeverBrowser_AchievementLabel(PageContent, string.upper(selected.name), 24, WOW_THEME.gold)
    title:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, -70)

    local collectedCount = 0
    for _, lootEntry in ipairs(allLoot) do
        if IsForeverItemCollected(lootEntry.id) then collectedCount = collectedCount + 1 end
    end

    local subtitle = ForeverBrowser_AchievementLabel(
        PageContent,
        tostring(#selected.bosses) .. " known bosses  |  " ..
        tostring(#allLoot) .. " known loot items  |  Collected: " ..
        tostring(collectedCount) .. " / " .. tostring(#allLoot),
        12,
        WOW_THEME.muted
    )
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -7)
    ForeverBrowser_DungeonLootBanner194(title,subtitle)

    --------------------------------------------------
    -- ALL DUNGEON LOOT
    --------------------------------------------------
    local y = ForeverBrowser_D220Overview(selected,#allLoot,collectedCount)

    local lootTitle = ForeverBrowser_AchievementLabel(PageContent, "ALL DUNGEON LOOT", 14, WOW_THEME.goldSoft)
    lootTitle:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
    y = y - 34

    local searchBox = CreateFrame("EditBox", nil, PageContent)
    searchBox:SetSize(360, 28)
    searchBox:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
    searchBox:SetAutoFocus(false)
    searchBox:SetFontObject(GameFontHighlight)
    searchBox:SetText(lootSearch)
    searchBox:SetTextInsets(8,8,0,0)

    local searchBG = searchBox:CreateTexture(nil, "BACKGROUND")
    searchBG:SetTexture("Interface\\Buttons\\WHITE8X8")
    searchBG:SetAllPoints(searchBox)
    searchBG:SetVertexColor(0.025,0.022,0.017,1)
    ForeverBrowser_AchievementBorder(searchBox,false)

    local function RefreshDungeonLoot(newFilter, newSort, newSlot, newBoss, newCollection)
        ForeverBrowserBuildDungeonPage(
            selected.name,
            searchBox:GetText() or "",
            newFilter or lootFilter,
            newSort or lootSort,
            newSlot or slotFilter,
            newBoss or bossFilter,
            newCollection or collectionFilter
        )
    end

    local searchButton = ForeverBrowser_ItemButton190(PageContent, "SEARCH", 90, 28)
    searchButton:SetPoint("LEFT", searchBox, "RIGHT", 8, 0)
    searchButton:SetScript("OnClick", function() RefreshDungeonLoot() end)
    searchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        RefreshDungeonLoot()
    end)

    local sortName = ForeverBrowser_ItemButton190(PageContent, lootSort == "NAME" and "NAME *" or "NAME", 92, 28)
    sortName:SetPoint("LEFT", searchButton, "RIGHT", 16, 0)
    sortName:SetScript("OnClick", function() RefreshDungeonLoot(nil, "NAME") end)

    local sortChance = ForeverBrowser_ItemButton190(PageContent, lootSort == "CHANCE" and "DROP % *" or "DROP %", 92, 28)
    sortChance:SetPoint("LEFT", sortName, "RIGHT", 6, 0)
    sortChance:SetScript("OnClick", function() RefreshDungeonLoot(nil, "CHANCE") end)

    y = y - 38

    -- Filters use the item class/subclass data already available in ForeverDB/client cache.
    -- Compact filter panel. Each category opens a scrollable checklist instead
    -- of filling the page with individual buttons.
    local filterPanel = CreateFrame("Frame", nil, PageContent)
    filterPanel:SetSize(790, 92)
    filterPanel:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)

    local fpbg = filterPanel:CreateTexture(nil, "BACKGROUND")
    fpbg:SetTexture("Interface\\Buttons\\WHITE8X8")
    fpbg:SetAllPoints(filterPanel)
    local fc = WOW_THEME.inset
    fpbg:SetVertexColor(unpack(WOW_THEME.row))
    ForeverBrowser_AchievementPaper(filterPanel,true)

    local filterTitle = ForeverBrowser_AchievementLabel(filterPanel, "FILTERS", 11, {0.38,0.25,0.08,1})
    filterTitle:SetPoint("LEFT", filterPanel, "LEFT", 12, 0)

    local function MakeFilterMenu(anchorButton, width, options, currentValue, onChoose)
        local menu = CreateFrame("Frame", nil, PageContent)
        menu:SetSize(width, 190)
        menu:SetFrameStrata("DIALOG")
        menu:SetFrameLevel((PageContent:GetFrameLevel() or 1) + 40)
        menu:SetPoint("TOPLEFT", anchorButton, "BOTTOMLEFT", 0, -3)
        menu:Hide()

        local bg = menu:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetAllPoints(menu)
        bg:SetVertexColor(0.045,0.038,0.029,1)
        ForeverBrowser_AchievementBorder(menu,true)
        if AddWoWBorder then AddWoWBorder(menu,1,0.82) end

        local scroll = CreateFrame("ScrollFrame", nil, menu, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", menu, "TOPLEFT", 7, -7)
        scroll:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -27, 7)

        local child = CreateFrame("Frame", nil, scroll)
        child:SetWidth(width - 38)
        scroll:SetScrollChild(child)

        local cy = -3
        for _, option in ipairs(options) do
            local value, label = option[1], option[2]
            local row = CreateFrame("Button", nil, child)
            row:SetSize(width - 42, 25)
            row:SetPoint("TOPLEFT", child, "TOPLEFT", 2, cy)

            local check = row:CreateTexture(nil, "ARTWORK")
            check:SetSize(16,16)
            check:SetPoint("LEFT", row, "LEFT", 3, 0)
            check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
            check:SetAlpha(value == currentValue and 1 or 0)

            local box = row:CreateTexture(nil, "BACKGROUND")
            box:SetSize(18,18)
            box:SetPoint("CENTER", check, "CENTER", 0, 0)
            box:SetTexture("Interface\\Buttons\\WHITE8X8")
            box:SetVertexColor(0.20,0.16,0.05,0.9)

            local text = ForeverBrowser_AchievementLabel(row, label, 11, WOW_THEME.text)
            text:SetPoint("LEFT", check, "RIGHT", 7, 0)

            row:SetScript("OnClick", function()
                menu:Hide()
                onChoose(value)
            end)
            cy = cy - 27
        end

        child:SetHeight(math.max(176, math.abs(cy) + 4))

        anchorButton:SetScript("OnClick", function()
            if menu:IsShown() then menu:Hide() else menu:Show() end
        end)
        return menu
    end

    local typeLabels = {ALL="ALL",WEAPON="WEAPONS",ARMOR="ARMOR",OTHER="OTHER"}
    local slotLabels = {
        ALL="ALL SLOTS",HEAD="HEAD",NECK="NECK",SHOULDERS="SHOULDERS",BACK="BACK",
        CHEST="CHEST",WRISTS="WRISTS",HANDS="HANDS",WAIST="WAIST",LEGS="LEGS",
        FEET="FEET",RINGS="RINGS",TRINKETS="TRINKETS",MAIN_HAND="MAIN HAND",
        OFF_HAND="OFF HAND",RANGED="RANGED"
    }

    local selectedBossName = "ALL BOSSES"
    if bossFilter ~= "ALL" then
        for _, boss in ipairs(selected.bosses) do
            if tostring(boss.id) == bossFilter then selectedBossName = boss.name break end
        end
    end

    local typeButton = ForeverBrowser_ItemButton190(filterPanel, "TYPE: "..(typeLabels[lootFilter] or "ALL").."  v", 180, 28)
    typeButton:SetPoint("TOPLEFT", filterPanel, "TOPLEFT", 88, -9)

    local slotButton = ForeverBrowser_ItemButton190(filterPanel, "SLOT: "..(slotLabels[slotFilter] or "ALL SLOTS").."  v", 190, 28)
    slotButton:SetPoint("LEFT", typeButton, "RIGHT", 8, 0)

    local bossButtonFilter = ForeverBrowser_ItemButton190(filterPanel, "BOSS: "..selectedBossName.."  v", 245, 28)
    bossButtonFilter:SetPoint("LEFT", slotButton, "RIGHT", 8, 0)

    local collectionLabels = {ALL="ALL",COLLECTED="COLLECTED",MISSING="MISSING"}
    local collectionButton = ForeverBrowser_ItemButton190(
        filterPanel,
        "COLLECTION: "..(collectionLabels[collectionFilter] or "ALL").."  v",
        220,
        28
    )
    collectionButton:SetPoint("TOPLEFT", filterPanel, "TOPLEFT", 88, -53)

    MakeFilterMenu(typeButton, 180, {
        {"ALL","ALL"}, {"WEAPON","WEAPONS"}, {"ARMOR","ARMOR"}, {"OTHER","OTHER"}
    }, lootFilter, function(value)
        RefreshDungeonLoot(value,nil,nil,nil)
    end)

    MakeFilterMenu(slotButton, 190, {
        {"ALL","ALL SLOTS"},{"HEAD","HEAD"},{"NECK","NECK"},{"SHOULDERS","SHOULDERS"},
        {"BACK","BACK"},{"CHEST","CHEST"},{"WRISTS","WRISTS"},{"HANDS","HANDS"},
        {"WAIST","WAIST"},{"LEGS","LEGS"},{"FEET","FEET"},{"RINGS","RINGS"},
        {"TRINKETS","TRINKETS"},{"MAIN_HAND","MAIN HAND"},{"OFF_HAND","OFF HAND"},
        {"RANGED","RANGED"}
    }, slotFilter, function(value)
        RefreshDungeonLoot(nil,nil,value,nil)
    end)

    local bossOptions = {{"ALL","ALL BOSSES"}}
    for _, boss in ipairs(selected.bosses) do
        table.insert(bossOptions,{tostring(boss.id),boss.name})
    end
    MakeFilterMenu(bossButtonFilter,245,bossOptions,bossFilter,function(value)
        RefreshDungeonLoot(nil,nil,nil,value,nil)
    end)

    MakeFilterMenu(collectionButton,220,{
        {"ALL","ALL LOOT"},
        {"COLLECTED","COLLECTED"},
        {"MISSING","MISSING"}
    },collectionFilter,function(value)
        RefreshDungeonLoot(nil,nil,nil,nil,value)
    end)

    y = y - 104

    local filtered = {}
    local query = string.lower(lootSearch)

    for _, entry in ipairs(allLoot) do
        local item = GetAnyItem(entry.id)
        local className = item and (item.itemType or item.className or item.type)
        local subclassName = item and (item.itemSubtype or item.subclassName or item.subType)
        local classLower = string.lower(tostring(className or ""))
        local category = "OTHER"

        if string.find(classLower, "weapon", 1, true) then
            category = "WEAPON"
        elseif string.find(classLower, "armor", 1, true) then
            category = "ARMOR"
        end

        local searchOK = query == ""
            or string.find(string.lower(entry.name or ""), query, 1, true)
            or string.find(string.lower(entry.bossName or ""), query, 1, true)
            or string.find(string.lower(tostring(subclassName or "")), query, 1, true)

        local filterOK = lootFilter == "ALL" or lootFilter == category
        local entrySlot = GetDungeonLootSlot(entry.id, item)
        local slotOK = slotFilter == "ALL" or slotFilter == entrySlot
        local bossOK = bossFilter == "ALL" or bossFilter == tostring(entry.bossID)
        local collected = IsForeverItemCollected(entry.id)
        local collectionOK =
            collectionFilter == "ALL"
            or (collectionFilter == "COLLECTED" and collected)
            or (collectionFilter == "MISSING" and not collected)

        if searchOK and filterOK and slotOK and bossOK and collectionOK then
            entry.collected = collected
            entry.category = category
            entry.className = className
            entry.subclassName = subclassName
            entry.equipmentSlot = entrySlot
            table.insert(filtered, entry)
        end
    end

    table.sort(filtered, function(a,b)
        if ForeverBrowser_S222().wishlistFirst and IsForeverItemTracked(a.id)~=IsForeverItemTracked(b.id) then return IsForeverItemTracked(a.id) end
        if lootSort == "CHANCE" then
            local ac = tonumber(a.chance) or -1
            local bc = tonumber(b.chance) or -1
            if ac ~= bc then return ac > bc end
        end
        return string.lower(a.name or "") < string.lower(b.name or "")
    end)

    local resultLabel = ForeverBrowser_AchievementLabel(
        PageContent,
        tostring(#filtered) .. " OF " .. tostring(#allLoot) .. " ITEMS",
        10,
        WOW_THEME.muted
    )
    resultLabel:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
    y = y - 24

    if #filtered == 0 then
        local none = ForeverBrowser_AchievementLabel(PageContent, "No loot matched the current search/filter.", 12, WOW_THEME.muted)
        none:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
        y = y - 40
    else
        for _, entry in ipairs(filtered) do
            local item = GetAnyItem(entry.id)

            local row = CreateFrame("Button", nil, PageContent)
            row:SetSize(790, 56)
            row:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)

            local bg = row:CreateTexture(nil, "BACKGROUND")
            bg:SetTexture("Interface\\Buttons\\WHITE8X8")
            bg:SetAllPoints(row)
            local c = WOW_THEME.inset
            bg:SetVertexColor(unpack(WOW_THEME.row))
        ForeverBrowser_AchievementBorder(row,true)

            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(38,38)
            icon:SetPoint("LEFT",row,"LEFT",10,0)
            icon:SetTexture(GetItemIcon(entry.id,item))

            local statusText = entry.collected and "|cff55ff55✓|r" or "|cff888888□|r"
            local name = ForeverBrowser_AchievementLabel(row, statusText .. "  " .. entry.name, 13, GetQualityColor(tonumber(item and (item.quality or item.Quality)) or 0))
            name:SetPoint("TOPLEFT",icon,"TOPRIGHT",12,-2)

            name:SetWidth(535)
            name:SetHeight(18)
            name:SetJustifyH("LEFT")

            local collectionToggle = ForeverBrowser_ItemButton190(
                row,
                entry.collected and "REMOVE" or "ADD",
                78,
                24
            )
            collectionToggle:SetPoint("RIGHT", row, "RIGHT", -94, 0)
            collectionToggle:SetScript("OnClick", function()
                SetForeverItemCollected(entry.id, not IsForeverItemCollected(entry.id))
                RefreshDungeonLoot(nil,nil,nil,nil,nil)
            end)

            local trackToggle = ForeverBrowser_ItemButton190(
                row,
                IsForeverItemTracked(entry.id) and "UNTRACK" or "TRACK",
                78,
                24
            )
            trackToggle:SetPoint("RIGHT", row, "RIGHT", -10, 0)
            trackToggle:SetScript("OnClick", function()
                SetForeverItemTracked(entry.id, not IsForeverItemTracked(entry.id))
                RefreshDungeonLoot(nil,nil,nil,nil,nil)
            end)

            local details = tostring(entry.bossName or "Unknown Boss")
            if entry.subclassName and tostring(entry.subclassName) ~= "Other" then
                details = details .. "  |  " .. tostring(entry.subclassName)
            end
            if entry.equipmentSlot and entry.equipmentSlot ~= "OTHER" then
                details = details .. "  |  " .. string.gsub(entry.equipmentSlot, "_", " ")
            end
            if entry.chance then
                details = details .. "  |  " .. string.format("%.2f%%",entry.chance)
            end

            local detail = ForeverBrowser_AchievementLabel(row, details, 10, WOW_THEME.muted)
            detail:SetPoint("TOPLEFT",name,"BOTTOMLEFT",0,-5)
            detail:SetWidth(535)
            detail:SetHeight(12)
            detail:SetJustifyH("LEFT")

            row:SetScript("OnClick", function()
                Navigate("forever://item/" .. tostring(entry.id))
            end)
            row:SetScript("OnEnter", function(self)
                local a=WOW_THEME.accent
                bg:SetVertexColor(unpack(WOW_THEME.hover))
                ShowItemTooltip(entry.id,self)
            end)
            row:SetScript("OnLeave", function()
                local normal=WOW_THEME.inset
                bg:SetVertexColor(unpack(WOW_THEME.row))
                if GameTooltip then GameTooltip:Hide() end
            end)

            y = y - 64
        end
    end

    --------------------------------------------------
    -- BOSSES
    --------------------------------------------------
    y = y - 18

    local section = ForeverBrowser_AchievementLabel(PageContent, "DUNGEON BOSSES", 14, WOW_THEME.goldSoft)
    section:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
    y = y - 34

    for _, boss in ipairs(selected.bosses) do
        local loot = GetForeverBossLoot(boss.id)

        local row = CreateFrame("Frame", nil, PageContent)
        row:SetSize(790, 68)
        row:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)

        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetAllPoints(row)
        local c = WOW_THEME.inset
        bg:SetVertexColor(unpack(WOW_THEME.row))
        ForeverBrowser_AchievementBorder(row,true)

        local name = ForeverBrowser_AchievementLabel(row, boss.name, 15, WOW_THEME.gold)
        name:SetPoint("TOPLEFT", row, "TOPLEFT", 15, -12)

        local detail = ForeverBrowser_AchievementLabel(
            row,
            tostring(boss.role or "Dungeon Boss") .. "  |  " .. tostring(#loot) .. " known loot item" .. (#loot == 1 and "" or "s"),
            11,
            WOW_THEME.muted
        )
        detail:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -6)

        name:SetWidth(510)
        name:SetHeight(18)
        name:SetJustifyH("LEFT")
        detail:SetWidth(510)
        detail:SetJustifyH("LEFT")

        local bossButton = ForeverBrowser_ItemButton190(row, "VIEW BOSS", 105, 28)
        bossButton:SetPoint("RIGHT", row, "RIGHT", -126, 0)
        bossButton:SetScript("OnClick", function()
            Navigate("forever://npc/" .. tostring(boss.id))
        end)

        local lootButton = ForeverBrowser_ItemButton190(row, "VIEW LOOT", 105, 28)
        lootButton:SetPoint("RIGHT", row, "RIGHT", -12, 0)
        lootButton:SetScript("OnClick", function()
            Navigate("forever://dungeonboss/" .. tostring(boss.id))
        end)

        y = y - 78
    end

    PageContent:SetHeight(math.max(650, math.abs(y) + 80))
end


ForeverBrowserBuildDungeonBossLootPage = function(npcID)
    ClearPage()

    npcID = tonumber(npcID)
    local boss = nil
    local dungeonName = nil

    if npcID and ForeverSourceData and type(ForeverSourceData.foreverNPCs) == "table" then
        boss = ForeverSourceData.foreverNPCs[npcID]
            or ForeverSourceData.foreverNPCs[tostring(npcID)]
    end

    if boss then
        dungeonName = tostring(boss.dungeonName or "")
    end

    local back = ForeverBrowser_ItemButton190(PageContent, "< DUNGEON", 125, 28)
    back:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, -22)
    back:SetScript("OnClick", function()
        if dungeonName and dungeonName ~= "" then
            Navigate("forever://dungeon/" .. dungeonName)
        else
            Navigate("forever://dungeons")
        end
    end)

    if not boss then
        local missing = ForeverBrowser_AchievementLabel(PageContent, "Dungeon boss not found in the loaded ForeverDB data.", 14, WOW_THEME.muted)
        missing:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, -72)
        PageContent:SetHeight(600)
        return
    end

    local title = ForeverBrowser_AchievementLabel(PageContent, string.upper(tostring(boss.name or ("NPC " .. tostring(npcID)))), 24, WOW_THEME.gold)
    title:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, -70)

    local subtitle = ForeverBrowser_AchievementLabel(
        PageContent,
        tostring(boss.role or "Dungeon Boss") .. " - " .. tostring(boss.dungeonName or "Unknown Dungeon"),
        12,
        WOW_THEME.muted
    )
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -7)
    ForeverBrowser_DungeonLootBanner194(title,subtitle)

    local viewBoss = ForeverBrowser_ItemButton190(PageContent, "VIEW BOSS PAGE", 145, 28)
    viewBoss:SetPoint("TOPRIGHT", PageContent, "TOPRIGHT", -25, -22)
    viewBoss:SetScript("OnClick", function()
        Navigate("forever://npc/" .. tostring(npcID))
    end)

    local section = ForeverBrowser_AchievementLabel(PageContent, "KNOWN LOOT", 14, WOW_THEME.goldSoft)
    section:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, -220)
    

    local loot = GetForeverBossLoot(npcID)
    local y = -254

    if #loot == 0 then
        local none = ForeverBrowser_AchievementLabel(PageContent, "No boss loot is currently linked in the loaded database.", 13, WOW_THEME.muted)
        none:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
        PageContent:SetHeight(600)
        return
    end

    for _, item in ipairs(loot) do
        local row = CreateFrame("Button", nil, PageContent)
        row:SetSize(790, 54)
        row:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)

        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetAllPoints(row)
        local c = WOW_THEME.inset
        bg:SetVertexColor(unpack(WOW_THEME.row))
        ForeverBrowser_AchievementBorder(row,true)

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(36, 36)
        icon:SetPoint("LEFT", row, "LEFT", 10, 0)
        icon:SetTexture(GetItemIcon(item.id, ForeverSourceData.items[item.id]))

        local name = ForeverBrowser_AchievementLabel(row, item.name, 13, GetQualityColor(GetQuality(item.id,GetAnyItem(item.id))))
        name:SetPoint("LEFT", icon, "RIGHT", 12, 7)

        name:SetWidth(690)
        name:SetHeight(18)
        name:SetJustifyH("LEFT")

        local sourceText = "Boss Drop"
        if item.chance then
            sourceText = sourceText .. "  |  " .. string.format("%.2f%%", item.chance)
        end

        local detail = ForeverBrowser_AchievementLabel(row, sourceText, 10, WOW_THEME.muted)
        detail:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)

        local arrow = ForeverBrowser_AchievementLabel(row, ">", 16, WOW_THEME.gold)
        arrow:SetPoint("RIGHT", row, "RIGHT", -14, 0)

        row:SetScript("OnClick", function()
            Navigate("forever://item/" .. tostring(item.id))
        end)

        row:SetScript("OnEnter", function(self)
            local a = WOW_THEME.accent
            bg:SetVertexColor(unpack(WOW_THEME.hover))
            ShowItemTooltip(item.id, self)
        end)

        row:SetScript("OnLeave", function()
            local normal = WOW_THEME.inset
            bg:SetVertexColor(unpack(WOW_THEME.row))
            if GameTooltip then GameTooltip:Hide() end
        end)

        y = y - 62
    end

    PageContent:SetHeight(math.max(600, math.abs(y) + 70))
end


local function BuildSettingsPage()
    StopDebugAutoRefresh()
    ClearPage()

    local title = CreateLabel(
        PageContent,
        "FOREVERBROWSER SETTINGS",
        24,
        WOW_THEME.gold
    )
    title:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, -25)
    ForeverBrowser_CodexTitle196(title)

    local subtitle = CreateLabel(
        PageContent,
        "Customize the browser without leaving the addon.",
        12,
        WOW_THEME.muted
    )
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -7)

    local appearanceTitle = CreateLabel(
        PageContent,
        "APPEARANCE",
        15,
        WOW_THEME.goldSoft
    )
    appearanceTitle:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -25)

    local currentTheme = FOREVER_THEMES[ForeverBrowserTheme.GetName()] or FOREVER_THEMES.Classic
    local currentLabel = CreateLabel(
        PageContent,
        "Current Theme: " .. (currentTheme.displayName or ForeverBrowserTheme.GetName()),
        12,
        WOW_THEME.ivory
    )
    currentLabel:SetPoint("TOPLEFT", appearanceTitle, "BOTTOMLEFT", 0, -9)

    local themeButtons = {}
    local startY = -135

    for i, themeName in ipairs(FOREVER_THEME_ORDER) do
        local theme = FOREVER_THEMES[themeName]
        local column = (i - 1) % 3
        local row = math.floor((i - 1) / 3)

        local button = CreateButton(
            PageContent,
            theme.displayName or themeName,
            205,
            34
        )
        button:SetPoint(
            "TOPLEFT",
            PageContent,
            "TOPLEFT",
            25 + (column * 220),
            startY - (row * 46)
        )

        if button.navBackground then
            -- no-op: standard buttons do not use navBackground
        end

        button:SetScript(
            "OnClick",
            function()
                if ApplyForeverTheme then
                    ApplyForeverTheme(themeName)
                else
                    CopyThemeIntoActive(themeName)
                    SaveForeverTheme(themeName)
                    Navigate("forever://settings", true)
                end
            end
        )

        themeButtons[#themeButtons + 1] = button
    end

    local divider = PageContent:CreateTexture(nil, "ARTWORK")
    divider:SetTexture("Interface\\Buttons\\WHITE8X8")
    divider:SetVertexColor(
        WOW_THEME.goldDim[1],
        WOW_THEME.goldDim[2],
        WOW_THEME.goldDim[3],
        0.8
    )
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, -286)
    divider:SetPoint("TOPRIGHT", PageContent, "TOPRIGHT", -25, -286)

    local interfaceTitle = CreateLabel(
        PageContent,
        "CONTROLS",
        15,
        WOW_THEME.goldSoft
    )
    interfaceTitle:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, -310)

    local function CreateSettingToggle(labelText, settingKey, x, y, onChanged)
        local button = CreateFrame("Button", nil, PageContent)
        button:SetSize(310, 28)
        button:SetPoint("TOPLEFT", PageContent, "TOPLEFT", x, y)

        local box = button:CreateTexture(nil, "ARTWORK")
        box:SetTexture("Interface\\Buttons\\WHITE8X8")
        box:SetSize(18, 18)
        box:SetPoint("LEFT", button, "LEFT", 0, 0)

        local check = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        check:SetPoint("CENTER", box, "CENTER", 0, 0)

        local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("LEFT", box, "RIGHT", 9, 0)
        label:SetText(labelText)

        local function Refresh()
            local enabled = BrowserSettingEnabled(settingKey)
            if enabled then
                box:SetVertexColor(0.18, 0.52, 0.18, 1)
                check:SetText("|cffffffffX|r")
                label:SetTextColor(0.92, 0.86, 0.72, 1)
            else
                box:SetVertexColor(0.16, 0.16, 0.16, 1)
                check:SetText("")
                label:SetTextColor(0.55, 0.55, 0.55, 1)
            end
        end

        button:SetScript("OnClick", function()
            local enabled = not BrowserSettingEnabled(settingKey)
            SetBrowserSetting(settingKey, enabled)
            Refresh()

            if onChanged then
                onChanged(enabled)
            end
        end)

        Refresh()
        return button
    end

    CreateSettingToggle(
        "Show item tooltips",
        "showItemTooltips",
        25,
        -342
    )

    CreateSettingToggle(
        "Enable map markers",
        "enableMapMarkers",
        355,
        -342,
        function(enabled)
            if not enabled then
                if ClearForeverBrowserAllMapMarkers then
                    ClearForeverBrowserAllMapMarkers()
                end
                if ForeverBrowserMapMarker then
                    ForeverBrowserMapMarker:Hide()
                end
            end
        end
    )

    CreateSettingToggle(
        "Save recent searches",
        "saveRecentSearches",
        25,
        -378
    )

    local clearSearches = CreateButton(
        PageContent,
        "CLEAR SEARCH HISTORY",
        180,
        26
    )
    clearSearches:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 355, -378)
    clearSearches:SetScript("OnClick", function()
        local db = GetDatabase()
        if db then
            db.recentQuestSearches = {}
            db.recentNPCSearches = {}
        end
    end)

    local databaseTitle = CreateLabel(
        PageContent,
        "DATABASE",
        15,
        WOW_THEME.goldSoft
    )
    databaseTitle:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, -438)

    local function CountEntries(t)
        local count = 0
        if type(t) == "table" then
            for _ in pairs(t) do
                count = count + 1
            end
        end
        return count
    end

    local function CountForeverItems(items)
        local count = 0
        if type(items) == "table" then
            for _, item in pairs(items) do
                if type(item) == "table" then
                    local source = tostring(item.dataSource or ""):lower()
                    local status = item.foreverStatus
                    if source == "forever" or status ~= nil then
                        count = count + 1
                    end
                end
            end
        end
        return count
    end

    local sourceData = ForeverSourceData or {}
    local itemCount = CountEntries(sourceData.items)
    local foreverItemCount = CountForeverItems(sourceData.items)
    local questCount = CountEntries(sourceData.quests)
    local npcCount = CountEntries(sourceData.npcs)
    local recipeCount = CountEntries(sourceData.recipes)
    local professionCount = ForeverBrowser_ProfessionCount225()
    local foreverBossCount = CountEntries(sourceData.foreverNPCs)

    local statsText = CreateLabel(
        PageContent,
        "",
        12,
        WOW_THEME.text
    )
    statsText:SetPoint("TOPLEFT", databaseTitle, "BOTTOMLEFT", 0, -12)
    statsText:SetJustifyH("LEFT")
    statsText:SetText(
        "|cffffd36aForeverBrowser|r   " .. ForeverBrowserVersion .. "\n" ..
        "|cffffd36aForeverDB|r        " .. ((ForeverSourceData and "Loaded") or "Not Loaded") .. "\n\n" ..
        "Items              " .. itemCount .. "\n" ..
        "Forever Items      " .. foreverItemCount .. "\n" ..
        "Quests             " .. questCount .. "\n" ..
        "NPCs               " .. npcCount .. "\n" ..
        "Recipes            " .. recipeCount .. "\n" ..
        "Professions        " .. professionCount .. "\n" ..
        "Forever Bosses     " .. foreverBossCount
    )

    local refreshStats = CreateButton(
        PageContent,
        "REFRESH STATISTICS",
        180,
        26
    )
    refreshStats:SetPoint("TOPLEFT", statsText, "BOTTOMLEFT", 0, -12)
    refreshStats:SetScript("OnClick", function()
        BuildSettingsPage()
    end)

    local aboutTitle = CreateLabel(
        PageContent,
        "ABOUT",
        15,
        WOW_THEME.goldSoft
    )
    aboutTitle:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, -650)

    local versionText = CreateLabel(
        PageContent,
        "ForeverBrowser: " .. ForeverBrowserVersion,
        12,
        WOW_THEME.ivory
    )
    versionText:SetPoint("TOPLEFT", aboutTitle, "BOTTOMLEFT", 0, -9)

    local databaseText = CreateLabel(
        PageContent,
        "Database Backend: ForeverDB",
        12,
        WOW_THEME.muted
    )
    databaseText:SetPoint("TOPLEFT", versionText, "BOTTOMLEFT", 0, -7)

    local resetTheme = CreateButton(
        PageContent,
        "RESET THEME TO CLASSIC",
        190,
        28
    )
    resetTheme:SetPoint("TOPLEFT", databaseText, "BOTTOMLEFT", 0, -18)
    resetTheme:SetScript(
        "OnClick",
        function()
            if ApplyForeverTheme then
                ApplyForeverTheme("Classic")
            else
                CopyThemeIntoActive("Classic")
                SaveForeverTheme("Classic")
                Navigate("forever://settings", true)
            end
        end
    )

    PageContent:SetHeight(790)
end


local function BuildDebugPage()
    StopDebugAutoRefresh()
    ClearPage()

    local title = CreateLabel(
        PageContent,
        "DEBUG",
        24,
        {1, 0.82, 0.25, 1}
    )
    title:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, -25)
    ForeverBrowser_CodexTitle196(title)

    local log = _G.ForeverDBDebugLog or {}
    local enabled = _G.ForeverDBDebugEnabled ~= false

    local summary = CreateLabel(
        PageContent,
        "Stored messages: " .. tostring(#log)
            .. "   |   Auto Refresh: ON"
            .. "   |   Logging: " .. (enabled and "ON" or "OFF"),
        12,
        {0.65, 0.68, 0.75, 1}
    )
    summary:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -9)

    local toggle = CreateButton(
        PageContent,
        enabled and "DISABLE DEBUG" or "ENABLE DEBUG",
        130,
        26
    )
    toggle:SetPoint("TOPLEFT", summary, "BOTTOMLEFT", 0, -12)
    toggle:SetScript(
        "OnClick",
        function()
            _G.ForeverDBDebugEnabled =
                not (_G.ForeverDBDebugEnabled ~= false)

            Navigate("forever://debug")
        end
    )

    local clear = CreateButton(
        PageContent,
        "CLEAR LOG",
        100,
        26
    )
    clear:SetPoint("LEFT", toggle, "RIGHT", 10, 0)
    clear:SetScript(
        "OnClick",
        function()
            _G.ForeverDBDebugLog = {}
            Navigate("forever://debug")
        end
    )

    local refresh = CreateButton(
        PageContent,
        "REFRESH",
        90,
        26
    )
    refresh:SetPoint("LEFT", clear, "RIGHT", 10, 0)
    refresh:SetScript(
        "OnClick",
        function()
            Navigate("forever://debug")
        end
    )

    local categoryCounts = {
        LOOT = 0,
        SOURCE = 0,
        SCAN = 0,
        ERROR = 0,
        DEBUG = 0
    }

    for _, message in ipairs(log) do
        local category = GetDebugCategory(message)
        categoryCounts[category] =
            (categoryCounts[category] or 0) + 1
    end

    local counts = CreateLabel(
        PageContent,
        "LOOT " .. tostring(categoryCounts.LOOT)
            .. "   SOURCE " .. tostring(categoryCounts.SOURCE)
            .. "   SCAN " .. tostring(categoryCounts.SCAN)
            .. "   ERROR " .. tostring(categoryCounts.ERROR)
            .. "   OTHER " .. tostring(categoryCounts.DEBUG),
        11,
        {0.72, 0.72, 0.78, 1}
    )
    counts:SetPoint("TOPLEFT", toggle, "BOTTOMLEFT", 0, -13)

    local y = -145

    if #log == 0 then
        local empty = CreateLabel(
            PageContent,
            "No debug messages yet. Loot something and this page will update automatically.",
            13,
            {0.68, 0.64, 0.56, 1}
        )
        empty:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
        PageContent:SetHeight(500)
    else
        local first = math.max(1, #log - 199)

        for i = #log, first, -1 do
            local message = tostring(log[i] or "")
            local category = GetDebugCategory(message)

            local categoryColor = {
                LOOT = {0.35, 0.85, 1, 1},
                SOURCE = {0.45, 0.90, 0.45, 1},
                SCAN = {0.85, 0.72, 0.30, 1},
                ERROR = {1, 0.35, 0.35, 1},
                DEBUG = {0.68, 0.70, 0.78, 1}
            }

            local tag = CreateLabel(
                PageContent,
                "[" .. category .. "]",
                11,
                categoryColor[category] or categoryColor.DEBUG
            )
            tag:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
            tag:SetWidth(70)
            tag:SetJustifyH("LEFT")

            local line = CreateLabel(
                PageContent,
                message,
                11,
                {0.78, 0.80, 0.86, 1}
            )
            line:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 100, y)
            line:SetWidth(690)
            line:SetJustifyH("LEFT")
            line:SetWordWrap(true)

            y = y - 22
        end

        PageContent:SetHeight(
            math.max(500, math.abs(y) + 30)
        )
    end

    DebugPageLastCount = #log
    DebugPageLastEnabled = enabled

    DebugPageRefreshFrame = CreateFrame("Frame")
    DebugPageRefreshFrame.elapsed = 0
    DebugPageRefreshFrame:SetScript(
        "OnUpdate",
        function(self, elapsed)
            self.elapsed = self.elapsed + (elapsed or 0)

            if self.elapsed < 1 then
                return
            end

            self.elapsed = 0

            if CurrentURL ~= "forever://debug" then
                StopDebugAutoRefresh()
                return
            end

            local currentLog = _G.ForeverDBDebugLog or {}
            local currentEnabled = _G.ForeverDBDebugEnabled ~= false

            if #currentLog ~= DebugPageLastCount
                or currentEnabled ~= DebugPageLastEnabled then

                Navigate("forever://debug", true)
            end
        end
    )
    DebugPageRefreshFrame:Show()
end


--------------------------------------------------
-- NPC PAGE
--------------------------------------------------

local function FindNPCSourceData(npcID)
    npcID = tonumber(npcID)

    if not npcID
        or not ForeverSourceData then
        return nil
    end

    local completeNPC = nil
    if type(ForeverSourceData.npcs) == "table" then
        completeNPC =
            ForeverSourceData.npcs[npcID]
            or ForeverSourceData.npcs[tostring(npcID)]
    end

    local foreverNPC = nil
    if type(ForeverSourceData.foreverNPCs) == "table" then
        foreverNPC =
            ForeverSourceData.foreverNPCs[npcID]
            or ForeverSourceData.foreverNPCs[tostring(npcID)]
    end

    local result = {
        id = npcID,
        name =
            foreverNPC
            and foreverNPC.name
            or (
                completeNPC
                and completeNPC.name
                or nil
            ),
        subName =
            completeNPC
            and completeNPC.subName
            or nil,
        levelMin =
            completeNPC
            and tonumber(completeNPC.levelMin)
            or nil,
        levelMax =
            completeNPC
            and tonumber(completeNPC.levelMax)
            or nil,
        locations = {},
        quests = {},
        involvedQuests = {},
        drops = {},
        pickpocket = {},
        skinning = {},
        vendor = {},
        isForeverNPC = foreverNPC ~= nil,
        role = foreverNPC and foreverNPC.role or nil,
        dungeonName = foreverNPC and foreverNPC.dungeonName or nil,
        dungeonSlug = foreverNPC and foreverNPC.dungeonSlug or nil,
        dataSource = foreverNPC and foreverNPC.dataSource or nil,
    }

    local locationKeys = {}
    local questKeys = {}
    local itemSourceKeys = {}

    local function AddLocation(location)
        if type(location) ~= "table" then
            return
        end

        local mapID = tonumber(location.uiMapID)
        local x = tonumber(location.x)
        local y = tonumber(location.y)

        if not mapID or not x or not y then
            return
        end

        local key =
            tostring(mapID)
            .. ":"
            .. string.format("%.3f", x)
            .. ":"
            .. string.format("%.3f", y)

        if locationKeys[key] then
            return
        end

        locationKeys[key] = true

        table.insert(
            result.locations,
            {
                uiMapID = mapID,
                x = x,
                y = y,
                zone = location.zone,
            }
        )
    end

    local function AddLocations(locations)
        if type(locations) ~= "table" then
            return
        end

        for _, location in ipairs(locations) do
            AddLocation(location)
        end
    end

    if type(ForeverSourceData.npcLocations) == "table" then
        local generatedLocations =
            ForeverSourceData.npcLocations[npcID]
            or ForeverSourceData.npcLocations[tostring(npcID)]

        AddLocations(generatedLocations)
    end

    local function AddAssociatedItem(
        bucket,
        sourceType,
        itemID,
        itemData,
        source
    )
        itemID = tonumber(itemID)

        if not itemID then
            return
        end

        local key =
            tostring(sourceType)
            .. ":"
            .. tostring(itemID)

        if itemSourceKeys[key] then
            return
        end

        itemSourceKeys[key] = true

        table.insert(
            bucket,
            {
                id = itemID,
                name =
                    itemData
                    and itemData.name
                    or GetItemName(itemID),
                chance = source.chance,
            }
        )
    end

    for rawItemID, itemData in pairs(ForeverSourceData.items or {}) do
        if itemData
            and type(itemData.sources) == "table" then

            local itemID =
                tonumber(rawItemID)
                or tonumber(itemData.id)

            for _, source in ipairs(itemData.sources) do
                if source then
                    local sourceType =
                        tostring(source.type or "")

                    local sourceNPCID = nil
                    local sourceNPCName = nil
                    local sourceLocations = nil

                    if sourceType == "quest" then
                        sourceNPCID =
                            tonumber(source.giverID)

                        sourceNPCName =
                            source.giverName

                        sourceLocations =
                            source.giverLocations
                    elseif sourceType == "drop"
                        or sourceType == "pickpocket"
                        or sourceType == "skinning"
                        or sourceType == "vendor" then

                        sourceNPCID =
                            tonumber(source.id)

                        sourceNPCName =
                            source.name

                        sourceLocations =
                            source.locations
                    end

                    if sourceNPCID == npcID then
                        if sourceNPCName
                            and tostring(sourceNPCName) ~= "" then

                            result.name =
                                tostring(sourceNPCName)
                        end

                        AddLocations(sourceLocations)

                        if source.uiMapID
                            and source.x ~= nil
                            and source.y ~= nil then

                            AddLocation(
                                {
                                    uiMapID = source.uiMapID,
                                    x = source.x,
                                    y = source.y,
                                    zone = source.zone,
                                }
                            )
                        end

                        if sourceType == "quest" then
                            local questID =
                                tonumber(source.id)

                            if questID
                                and not questKeys[questID] then

                                questKeys[questID] = true

                                table.insert(
                                    result.quests,
                                    {
                                        id = questID,
                                        name =
                                            tostring(
                                                source.name
                                                or ("Quest " .. tostring(questID))
                                            ),
                                        level = source.questLevel,
                                        faction = source.questFaction,
                                    }
                                )
                            end
                        elseif sourceType == "drop" then
                            AddAssociatedItem(
                                result.drops,
                                sourceType,
                                itemID,
                                itemData,
                                source
                            )
                        elseif sourceType == "pickpocket" then
                            AddAssociatedItem(
                                result.pickpocket,
                                sourceType,
                                itemID,
                                itemData,
                                source
                            )
                        elseif sourceType == "skinning" then
                            AddAssociatedItem(
                                result.skinning,
                                sourceType,
                                itemID,
                                itemData,
                                source
                            )
                        elseif sourceType == "vendor" then
                            AddAssociatedItem(
                                result.vendor,
                                sourceType,
                                itemID,
                                itemData,
                                source
                            )
                        end
                    end
                end
            end
        end
    end

    --------------------------------------------------
    -- QUESTS INVOLVED IN / NPC OBJECTIVES
    --------------------------------------------------

    local involvedQuestKeys = {}

    if type(ForeverSourceData.quests) == "table" then
        for rawQuestID, questData in pairs(ForeverSourceData.quests) do
            if questData
                and type(questData.objectiveNPCs) == "table" then

                local questID =
                    tonumber(rawQuestID)
                    or tonumber(questData.id)

                for _, objective in ipairs(questData.objectiveNPCs) do
                    if tonumber(objective.id) == npcID
                        and questID
                        and not involvedQuestKeys[questID] then

                        involvedQuestKeys[questID] = true

                        table.insert(
                            result.involvedQuests,
                            {
                                id = questID,
                                name =
                                    tostring(
                                        questData.name
                                        or ("Quest " .. tostring(questID))
                                    ),
                                level = questData.level,
                                count = tonumber(objective.count) or 0,
                                involvementType = "npcObjective",
                            }
                        )
                    end
                end
            end
        end
    end

    --------------------------------------------------
    -- QUEST REQUIRED ITEM -> NPC DROP RELATIONSHIPS
    --------------------------------------------------

    if type(ForeverSourceData.quests) == "table"
        and type(ForeverSourceData.items) == "table" then

        for rawQuestID, questData in pairs(ForeverSourceData.quests) do
            if questData
                and type(questData.requiredItems) == "table" then

                local questID =
                    tonumber(rawQuestID)
                    or tonumber(questData.id)

                if questID and not involvedQuestKeys[questID] then
                    local matchedItem = nil
                    local matchedCount = 0

                    for _, requiredItem in ipairs(questData.requiredItems) do
                        local requiredItemID = tonumber(requiredItem.id)
                        local itemData =
                            requiredItemID
                            and ForeverSourceData.items[requiredItemID]
                            or nil

                        if itemData
                            and type(itemData.sources) == "table" then

                            for _, itemSource in ipairs(itemData.sources) do
                                local sourceType =
                                    tostring(itemSource.type or "")

                                if tonumber(itemSource.id) == npcID
                                    and (
                                        sourceType == "drop"
                                        or sourceType == "pickpocket"
                                        or sourceType == "skinning"
                                    ) then

                                    matchedItem = {
                                        id = requiredItemID,
                                        name =
                                            tostring(
                                                requiredItem.name
                                                or itemData.name
                                                or ("Item " .. tostring(requiredItemID))
                                            ),
                                    }

                                    matchedCount =
                                        tonumber(requiredItem.count)
                                        or 0

                                    break
                                end
                            end
                        end

                        if matchedItem then
                            break
                        end
                    end

                    if matchedItem then
                        involvedQuestKeys[questID] = true

                        table.insert(
                            result.involvedQuests,
                            {
                                id = questID,
                                name =
                                    tostring(
                                        questData.name
                                        or ("Quest " .. tostring(questID))
                                    ),
                                level = questData.level,
                                count = matchedCount,
                                involvementType = "requiredItem",
                                requiredItemID = matchedItem.id,
                                requiredItemName = matchedItem.name,
                            }
                        )
                    end
                end
            end
        end
    end

    table.sort(
        result.involvedQuests,
        function(a, b)
            return tostring(a.name or "")
                < tostring(b.name or "")
        end
    )

    table.sort(
        result.locations,
        function(a, b)
            local mapA = tonumber(a.uiMapID) or 0
            local mapB = tonumber(b.uiMapID) or 0

            if mapA ~= mapB then
                return mapA < mapB
            end

            local xA = tonumber(a.x) or 0
            local xB = tonumber(b.x) or 0

            if xA ~= xB then
                return xA < xB
            end

            return (tonumber(a.y) or 0)
                < (tonumber(b.y) or 0)
        end
    )

    table.sort(
        result.quests,
        function(a, b)
            return tostring(a.name or "")
                < tostring(b.name or "")
        end
    )

    local function SortItems(bucket)
        table.sort(
            bucket,
            function(a, b)
                local chanceA = tonumber(a.chance) or -1
                local chanceB = tonumber(b.chance) or -1

                if chanceA ~= chanceB then
                    return chanceA > chanceB
                end

                return tostring(a.name or "")
                    < tostring(b.name or "")
            end
        )
    end

    SortItems(result.drops)
    SortItems(result.pickpocket)
    SortItems(result.skinning)
    SortItems(result.vendor)

    return result
end



--------------------------------------------------
-- QUEST COMPLETION ORDER
--------------------------------------------------

function ForeverBrowser_GetQuestCompletionHistory()
    ForeverDBDatabase = ForeverDBDatabase or {}

    -- Account-wide completion history. Keeping this inside the existing
    -- ForeverDBDatabase SavedVariables table avoids requiring a new TOC variable.
    ForeverDBDatabase.accountQuestCompletionHistory =
        ForeverDBDatabase.accountQuestCompletionHistory or {}

    -- Migrate/merge any completion history recorded by older builds.
    if ForeverDBDatabase.browserQuestCompletionHistory then
        for questID,completedAt in pairs(
            ForeverDBDatabase.browserQuestCompletionHistory
        ) do
            local old=ForeverDBDatabase.accountQuestCompletionHistory[questID]
            if old==nil
                or (tonumber(completedAt) or 0)>(tonumber(old) or 0) then
                ForeverDBDatabase.accountQuestCompletionHistory[questID]=completedAt
            end
        end
    end

    ForeverDBDatabase.browserQuestCompletionInitialized =
        ForeverDBDatabase.browserQuestCompletionInitialized or false

    return ForeverDBDatabase.accountQuestCompletionHistory
end

function ForeverBrowser_FormatQuestCompletionTime(timestamp)
    timestamp=tonumber(timestamp) or 0
    if timestamp<=0 then
        return "Completed before tracking"
    end

    if type(date)=="function" then
        return date("%b %d, %Y  %I:%M %p",timestamp)
    end

    return "Completion time recorded"
end

function ForeverBrowser_UpdateQuestCompletionHistory()
    local history = ForeverBrowser_GetQuestCompletionHistory()
    local quests = ForeverSourceData and ForeverSourceData.quests or {}
    local firstScan =
        ForeverDBDatabase.browserQuestCompletionInitialized ~= true

    for questKey,questData in pairs(quests) do
        local id =
            tonumber(questKey)
            or tonumber(questData and questData.id)

        if id then
            local done = false

            if C_QuestLog
                and type(C_QuestLog.IsQuestFlaggedCompleted) == "function" then
                local ok,value =
                    pcall(C_QuestLog.IsQuestFlaggedCompleted,id)
                if ok and value == true then done = true end
            end

            if not done
                and type(IsQuestFlaggedCompleted) == "function" then
                local ok,value =
                    pcall(IsQuestFlaggedCompleted,id)
                if ok and value == true then done = true end
            end

            if done and history[id] == nil then
                -- Existing completed quests cannot be given a truthful historical
                -- timestamp. Mark them as legacy (0). New completions after this
                -- feature is installed receive a real completion timestamp.
                if firstScan then
                    history[id] = 0
                else
                    history[id] =
                        type(time) == "function"
                        and time()
                        or 1
                end
            end
        end
    end

    ForeverDBDatabase.browserQuestCompletionInitialized = true
end

--------------------------------------------------
-- QUEST PLAYER STATUS
--------------------------------------------------

-- Live quest-log cache.  Forever uses the legacy GetQuestLogTitle return
-- layout, so scan the actual quest log rather than relying on lookup helpers.
ForeverBrowserQuestLogCache = ForeverBrowserQuestLogCache or {}
ForeverBrowserCompletedQuestPage = ForeverBrowserCompletedQuestPage or 1
ForeverBrowserCompletedQuestSort = ForeverBrowserCompletedQuestSort or "date"

function ForeverBrowser_ScanQuestLog(force)
    local now=type(GetTime)=="function" and GetTime()
    if not force and now and ForeverBrowserQuestLogScan225
        and now-ForeverBrowserQuestLogScan225>=0
        and now-ForeverBrowserQuestLogScan225<.25 then
        return ForeverBrowserQuestLogCache
    end
    local cache = {}
    local numEntries = 0

    if type(GetNumQuestLogEntries) == "function" then
        local ok, value = pcall(GetNumQuestLogEntries)
        if ok and tonumber(value) then numEntries = tonumber(value) end
    end

    if numEntries <= 0
        and C_QuestLog
        and type(C_QuestLog.GetNumQuestLogEntries) == "function" then
        local ok, value = pcall(C_QuestLog.GetNumQuestLogEntries)
        if ok and tonumber(value) then numEntries = tonumber(value) end
    end

    for index = 1, numEntries do
        local questID = nil
        local isHeader = false

        -- Legacy/Wrath-style signature:
        -- title, level, questTag, suggestedGroup, isHeader,
        -- isCollapsed, isComplete, frequency, questID
        if type(GetQuestLogTitle) == "function" then
            local ok, title, level, questTag, suggestedGroup,
                headerFlag, collapsed, complete, frequency, qid =
                pcall(GetQuestLogTitle, index)

            if ok then
                isHeader = headerFlag == true
                questID = tonumber(qid)
            end
        end

        -- Modern/private-client fallback.
        if not questID
            and C_QuestLog
            and type(C_QuestLog.GetInfo) == "function" then
            local ok, info = pcall(C_QuestLog.GetInfo, index)
            if ok and type(info) == "table" then
                isHeader = info.isHeader == true
                questID = tonumber(info.questID or info.questId or info.id)
            end
        end

        -- Last fallback: parse the ID from the quest link.
        if not questID and not isHeader and type(GetQuestLink) == "function" then
            local ok, link = pcall(GetQuestLink, index)
            if ok and type(link) == "string" then
                questID = tonumber(string.match(link, "quest:(%d+)"))
            end
        end

        if not isHeader and questID and questID > 0 then
            cache[questID] = true
        end
    end

    ForeverBrowserQuestLogCache = cache
    ForeverBrowserQuestLogScan225 = now
    return cache
end

function ForeverBrowser_GetQuestPlayerStatus(questID)
    questID = tonumber(questID)
    if not questID then return false, false end

    local completed = false

    if C_QuestLog and type(C_QuestLog.IsQuestFlaggedCompleted) == "function" then
        local ok, value = pcall(C_QuestLog.IsQuestFlaggedCompleted, questID)
        if ok and value == true then completed = true end
    end

    if not completed and type(IsQuestFlaggedCompleted) == "function" then
        local ok, value = pcall(IsQuestFlaggedCompleted, questID)
        if ok and value == true then completed = true end
    end

    -- Reuse one scan across a page; quest-log events force an immediate refresh.
    ForeverBrowser_ScanQuestLog()
    local inLog = ForeverBrowserQuestLogCache[questID] == true

    return completed, inLog
end

-- Keep the cache current when the player's quest log changes.
ForeverBrowserQuestLogWatcher = ForeverBrowserQuestLogWatcher
    or CreateFrame("Frame")

ForeverBrowserQuestLogWatcher:RegisterEvent("QUEST_LOG_UPDATE")
ForeverBrowserQuestLogWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
ForeverBrowserQuestLogWatcher:SetScript("OnEvent", function()
    local previousLog={}
    for questID in pairs(ForeverBrowserQuestLogCache or {}) do
        previousLog[questID]=true
    end

    ForeverBrowser_ScanQuestLog(true)

    -- A quest that was active and has now left the log may have just been
    -- turned in. If the completion API confirms it, record the exact moment.
    local history=ForeverBrowser_GetQuestCompletionHistory()
    for questID in pairs(previousLog) do
        if not ForeverBrowserQuestLogCache[questID] then
            local done=false

            if C_QuestLog
                and type(C_QuestLog.IsQuestFlaggedCompleted)=="function" then
                local ok,value=
                    pcall(C_QuestLog.IsQuestFlaggedCompleted,questID)
                if ok and value==true then done=true end
            end

            if not done
                and type(IsQuestFlaggedCompleted)=="function" then
                local ok,value=
                    pcall(IsQuestFlaggedCompleted,questID)
                if ok and value==true then done=true end
            end

            if done and (tonumber(history[questID]) or 0)<=0 then
                history[questID]=
                    type(time)=="function"
                    and time()
                    or 1
            end
        end
    end

    ForeverBrowser_UpdateQuestCompletionHistory()
    ForeverBrowserRelationshipProgressCache=nil

    if type(ForeverBrowserRelationshipRefresh)=="function" then
        ForeverBrowserRelationshipRefresh()
    end

    -- If the live IN PROGRESS view is currently open, redraw it immediately.
    -- QUEST_LOG_UPDATE fires when quests are accepted, abandoned, completed,
    -- or otherwise change in the player's log.
    if ForeverBrowserCurrentQuestBrowseFilter == "inprogress"
        and type(ForeverBrowser_RefreshQuestBrowsePage) == "function" then
        ForeverBrowser_RefreshQuestBrowsePage("")
    end
end)


function ForeverBrowser_AddQuestStatusVisual(parent, questID, questLabel)
    local completed, inLog = ForeverBrowser_GetQuestPlayerStatus(questID)

    -- Status always occupies the same far-right column.
    -- Normal quests leave this column empty.
    if completed or inLog then
        local statusText = completed and "COMPLETED" or "IN PROGRESS"
        local statusColor =
            completed
            and {0.42, 0.82, 0.48, 1}
            or {0.38, 0.72, 1.00, 1}

        local badge = CreateLabel(parent, statusText, 12, statusColor)
        badge:SetWidth(145)
        badge:SetJustifyH("RIGHT")
        badge:SetPoint("RIGHT", parent, "RIGHT", -18, 0)

        -- Dark backing makes IN PROGRESS / COMPLETED read like a status badge
        -- instead of ordinary row text.
        local badgeBacking = parent:CreateTexture(nil, "ARTWORK")
        badgeBacking:SetTexture("Interface\\Buttons\\WHITE8X8")
        badgeBacking:SetVertexColor(0.055,0.045,0.033,0.92)
        badgeBacking:SetPoint("TOPLEFT", badge, "TOPLEFT", -8, 5)
        badgeBacking:SetPoint("BOTTOMRIGHT", badge, "BOTTOMRIGHT", 8, -5)
    end

    return completed, inLog
end

-- Parchment section bars for the lower NPC record, matching Codex cards.
function ForeverBrowser_NPCSection195(label)
    local point,relative,relativePoint,x,y=label:GetPoint(1)
    local bar=CreateFrame("Frame",nil,PageContent)
    bar:SetSize(790,26)
    bar:SetPoint(point,relative,relativePoint,x,(y or 0)+3)
    ForeverBrowser_AchievementPaper(bar,true)
    label:SetParent(bar) label:ClearAllPoints()
    label:SetPoint("LEFT",bar,"LEFT",12,0)
    label:SetWidth(766) label:SetHeight(18) label:SetJustifyH("LEFT")
    label:SetTextColor(0.31,0.22,0.10,1)
end

local function BuildNPCPage(npcID)
    if type(ForeverBrowser_N187Record)=="function" then ForeverBrowser_N187Record(npcID) end
    ClearPage()

    npcID = tonumber(npcID)

    if not npcID then
        return
    end

    local npc =
        FindNPCSourceData(npcID)

    local npcName =
        npc
        and npc.name
        or ("NPC " .. tostring(npcID))

    local back = ForeverBrowser_ItemButton190(PageContent, "NPC Codex", 110, 30)
    back:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, -20)
    back:SetScript("OnClick", function() Navigate("forever://npcdatabase") end)
    --------------------------------------------------
    -- NPC HERO
    --------------------------------------------------

    local hero = CreateFrame("Frame", nil, PageContent)
    hero:SetSize(790, 132)
    hero:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, -62)
    CreateSolidBackground(hero, 0.055, 0.045, 0.033, 1)
    ForeverBrowser_AchievementBorder(hero, true)

    local accent = hero:CreateTexture(nil, "ARTWORK")
    accent:SetTexture("Interface\\Buttons\\WHITE8X8")
    accent:SetVertexColor(0.90, 0.72, 0.29, 0.95)
    accent:SetPoint("TOPLEFT", hero, "TOPLEFT", 0, 0)
    accent:SetPoint("BOTTOMLEFT", hero, "BOTTOMLEFT", 0, 0)
    accent:SetWidth(4)

    local npcIcon = hero:CreateTexture(nil, "ARTWORK")
    npcIcon:SetSize(58, 58)
    npcIcon:SetPoint("TOPLEFT", hero, "TOPLEFT", 18, -18)
    npcIcon:SetTexture("Interface\\Icons\\INV_Misc_Head_Dragon_01")

    local heroName = ForeverBrowser_AchievementLabel(
        hero,
        tostring(npcName or ("NPC " .. tostring(npcID))),
        23,
        {1, 0.82, 0.28, 1}
    )
    heroName:SetPoint("TOPLEFT", hero, "TOPLEFT", 92, -18)
    heroName:SetWidth(540)
    heroName:SetJustifyH("LEFT")

    local heroMetaParts = {}
    local npcLevel = npc and (npc.level or npc.Level or npc.minLevel)
    local npcType = npc and (npc.type or npc.Type or npc.classification)
    local npcFaction = npc and (npc.faction or npc.Faction)
    local npcZone = npc and (npc.zone or npc.zoneName or npc.areaName)

    if npcLevel and tostring(npcLevel) ~= "" then
        table.insert(heroMetaParts, "Level " .. tostring(npcLevel))
    end
    if npcType and tostring(npcType) ~= "" then
        table.insert(heroMetaParts, tostring(npcType))
    end
    if npcZone and tostring(npcZone) ~= "" then
        table.insert(heroMetaParts, tostring(npcZone))
    end

    heroName:SetHeight(48)
    heroName:SetJustifyV("TOP")

    local heroMeta = ForeverBrowser_AchievementLabel(
        hero,
        #heroMetaParts > 0 and table.concat(heroMetaParts, "   |   ") or "NPC Database",
        12,
        {0.70, 0.73, 0.80, 1}
    )
    heroMeta:SetPoint("TOPLEFT", heroName, "BOTTOMLEFT", 0, -5)
    heroMeta:SetWidth(540)
    heroMeta:SetJustifyH("LEFT")

    if npcFaction and tostring(npcFaction) ~= "" then
        local factionText = ForeverBrowser_AchievementLabel(
            hero,
            tostring(npcFaction),
            10,
            {0.58, 0.64, 0.74, 1}
        )
        factionText:SetPoint("BOTTOMLEFT", hero, "BOTTOMLEFT", 92, 10)
    end

    local heroID = ForeverBrowser_AchievementLabel(
        hero,
        "NPC ID  " .. tostring(npcID),
        10,
        {0.45, 0.48, 0.56, 1}
    )
    heroID:SetPoint("BOTTOMRIGHT", hero, "BOTTOMRIGHT", -14, 10)
    local sourceNoticeText =
        npc and npc.isForeverNPC
        and "WoW Forever source data."
        or "Classic source data - may differ in WoW Forever."

    local sourceNotice =
        ForeverBrowser_AchievementLabel(
            PageContent,
            sourceNoticeText,
            11,
            npc and npc.isForeverNPC
                and {0.45, 0.85, 0.62, 1}
                or {0.75, 0.62, 0.32, 1}
        )

    sourceNotice:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, -204)

    local y = -225

    --------------------------------------------------
    -- OVERVIEW
    --------------------------------------------------

    local overviewTitle =
        ForeverBrowser_AchievementLabel(
            PageContent,
            "NPC INFORMATION",
            16,
            {0.92, 0.76, 0.25, 1}
        )

    overviewTitle:SetPoint(
        "TOPLEFT",
        PageContent,
        "TOPLEFT",
        25,
        y
    )

    y = y - 28

    local overview =
        CreateFrame(
            "Frame",
            nil,
            PageContent
        )

    overview:SetSize(790, 370)

    overview:SetPoint(
        "TOPLEFT",
        PageContent,
        "TOPLEFT",
        25,
        y
    )

    CreateSolidBackground(overview, 0.045, 0.038, 0.029, 1)
    ForeverBrowser_AchievementPaper(overview, true)

    local nameLabel =
        ForeverBrowser_AchievementLabel(
            overview,
            "NAME",
            10,
            {0.38, 0.25, 0.08, 1}
        )

    nameLabel:SetPoint(
        "TOPLEFT",
        overview,
        "TOPLEFT",
        16,
        -14
    )

    local nameValue =
        ForeverBrowser_AchievementLabel(
            overview,
            npcName,
            14,
            {0.25, 0.18, 0.10, 1}
        )

    nameValue:SetPoint(
        "TOPLEFT",
        nameLabel,
        "BOTTOMLEFT",
        0,
        -5
    )

    nameValue:SetWidth(310)
    nameValue:SetJustifyH("LEFT")

    local idLabel =
        ForeverBrowser_AchievementLabel(
            overview,
            "NPC ID",
            10,
            {0.38, 0.25, 0.08, 1}
        )

    idLabel:SetPoint(
        "TOPLEFT",
        overview,
        "TOPLEFT",
        16,
        -68
    )

    local idValue =
        ForeverBrowser_AchievementLabel(
            overview,
            tostring(npcID),
            14,
            {0.25, 0.18, 0.10, 1}
        )

    idValue:SetPoint(
        "TOPLEFT",
        idLabel,
        "BOTTOMLEFT",
        0,
        -5
    )

    local subNameText =
        npc
        and npc.subName
        and tostring(npc.subName)
        or ""

    local levelMin =
        npc
        and tonumber(npc.levelMin)
        or nil

    local levelMax =
        npc
        and tonumber(npc.levelMax)
        or nil

    local levelText = "Unknown"

    if levelMin and levelMax and levelMin > 0 and levelMax > 0 then
        if levelMin == levelMax then
            levelText = tostring(levelMin)
        else
            levelText =
                tostring(levelMin)
                .. " - "
                .. tostring(levelMax)
        end
    elseif levelMin and levelMin > 0 then
        levelText = tostring(levelMin)
    elseif levelMax and levelMax > 0 then
        levelText = tostring(levelMax)
    end

    local titleLabel =
        ForeverBrowser_AchievementLabel(
            overview,
            "TITLE / SUBNAME",
            10,
            {0.38, 0.25, 0.08, 1}
        )

    titleLabel:SetPoint(
        "TOPLEFT",
        overview,
        "TOPLEFT",
        16,
        -122
    )

    local titleValue =
        ForeverBrowser_AchievementLabel(
            overview,
            subNameText ~= "" and subNameText or "None",
            13,
            {0.25, 0.18, 0.10, 1}
        )

    titleValue:SetPoint(
        "TOPLEFT",
        titleLabel,
        "BOTTOMLEFT",
        0,
        -5
    )

    titleValue:SetWidth(310)
    titleValue:SetJustifyH("LEFT")

    local levelLabel =
        ForeverBrowser_AchievementLabel(
            overview,
            "LEVEL",
            10,
            {0.38, 0.25, 0.08, 1}
        )

    levelLabel:SetPoint(
        "TOPLEFT",
        overview,
        "TOPLEFT",
        16,
        -176
    )

    local levelValue =
        ForeverBrowser_AchievementLabel(
            overview,
            levelText,
            13,
            {0.25, 0.18, 0.10, 1}
        )

    levelValue:SetPoint(
        "TOPLEFT",
        levelLabel,
        "BOTTOMLEFT",
        0,
        -5
    )

    if npc and npc.isForeverNPC then
        local roleLabel = ForeverBrowser_AchievementLabel(overview, "ROLE", 10, {0.38, 0.25, 0.08, 1})
        roleLabel:SetPoint("TOPLEFT", overview, "TOPLEFT", 16, -230)
        local roleValue = ForeverBrowser_AchievementLabel(overview, tostring(npc.role or "Forever NPC"), 13, {0.25, 0.18, 0.10, 1})
        roleValue:SetWidth(310)
        roleValue:SetJustifyH("LEFT")
        roleValue:SetPoint("TOPLEFT", roleLabel, "BOTTOMLEFT", 0, -5)

        local dungeonLabel = ForeverBrowser_AchievementLabel(overview, "DUNGEON", 10, {0.38, 0.25, 0.08, 1})
        dungeonLabel:SetPoint("TOPLEFT", overview, "TOPLEFT", 16, -284)
        local dungeonValue = ForeverBrowser_AchievementLabel(overview, tostring(npc.dungeonName or "Unknown"), 13, {0.25, 0.18, 0.10, 1})
        dungeonValue:SetWidth(310)
        dungeonValue:SetJustifyH("LEFT")
        dungeonValue:SetPoint("TOPLEFT", dungeonLabel, "BOTTOMLEFT", 0, -5)
    end

    --------------------------------------------------
    -- 3D NPC MODEL - RIGHT SIDE OF NPC INFORMATION
    --------------------------------------------------

    local divider = overview:CreateTexture(nil, "ARTWORK")
    divider:SetTexture("Interface\\Buttons\\WHITE8X8")
    divider:SetVertexColor(0.52, 0.36, 0.15, 0.85)
    divider:SetSize(1, 338)
    divider:SetPoint("TOPLEFT", overview, "TOPLEFT", 350, -16)

    local modelPanel = CreateFrame("Frame", nil, overview)
    modelPanel:SetSize(420, 338)
    modelPanel:SetPoint("TOPRIGHT", overview, "TOPRIGHT", -10, -16)
    CreateSolidBackground(modelPanel, 0.045, 0.038, 0.029, 1)
    ForeverBrowser_AchievementBorder(modelPanel, true)

    local modelHeading = ForeverBrowser_AchievementLabel(modelPanel, "3D NPC MODEL", 13, {1,0.82,0.25,1})
    modelHeading:SetPoint("TOPLEFT", modelPanel, "TOPLEFT", 12, -10)

    local modelFrame = nil
    local frameTypes = {"PlayerModel", "DressUpModel"}

    for _, frameType in ipairs(frameTypes) do
        local ok, frame = pcall(CreateFrame, frameType, nil, modelPanel)
        if ok and frame and not modelFrame then
            modelFrame = frame
        elseif ok and frame then
            frame:Hide()
            frame:SetParent(nil)
        end
    end

    if modelFrame then
        modelFrame:SetSize(396, 200)
        modelFrame:SetPoint("TOP", modelPanel, "TOP", 0, -50)

        local rotation = 0
        local cameraScale = 1.65
        local defaultCameraScale = 1.65
        local minCameraScale = 0.65
        local maxCameraScale = 3.25

        local displayIDs = {}
        if ForeverSourceData
            and type(ForeverSourceData.npcModels) == "table"
            and type(ForeverSourceData.npcModels[npcID]) == "table" then

            for _, displayID in ipairs(ForeverSourceData.npcModels[npcID]) do
                displayID = tonumber(displayID)
                if displayID and displayID > 0 then
                    table.insert(displayIDs, displayID)
                end
            end
        end

        local modelIndex = 1
        local modelCount = #displayIDs

        local modelCounter = ForeverBrowser_AchievementLabel(
            modelPanel,
            modelCount > 1
                and ("MODEL 1 OF " .. tostring(modelCount))
                or (modelCount == 1 and "MODEL 1 OF 1" or "DEFAULT NPC MODEL"),
            11,
            {0.62,0.76,1,1}
        )
        modelCounter:SetPoint("TOPLEFT", modelPanel, "TOPLEFT", 12, -29)
        modelCounter:SetWidth(396)
        modelCounter:SetJustifyH("LEFT")

        local function ApplyModelView()
            if modelFrame.SetRotation then
                pcall(modelFrame.SetRotation, modelFrame, rotation)
            end
            if modelFrame.SetPortraitZoom then
                pcall(modelFrame.SetPortraitZoom, modelFrame, 0)
            end
            if modelFrame.SetCamDistanceScale then
                pcall(modelFrame.SetCamDistanceScale, modelFrame, cameraScale)
            end
        end

        local function LoadCurrentModel()
            local loaded = false

            if modelCount > 0 and modelFrame.SetDisplayInfo then
                local displayID = displayIDs[modelIndex]
                local ok = pcall(
                    modelFrame.SetDisplayInfo,
                    modelFrame,
                    displayID
                )
                loaded = ok and true or false

                modelCounter:SetText(
                    "MODEL "
                    .. tostring(modelIndex)
                    .. " OF "
                    .. tostring(modelCount)
                    .. "   |   DISPLAY ID "
                    .. tostring(displayID)
                )
            elseif modelFrame.SetCreature then
                local ok = pcall(
                    modelFrame.SetCreature,
                    modelFrame,
                    npcID
                )
                loaded = ok and true or false
                modelCounter:SetText("DEFAULT NPC MODEL")
            end

            rotation = 0
            cameraScale = defaultCameraScale
            ApplyModelView()
            modelFrame:Show()

            return loaded
        end

        local loaded = LoadCurrentModel()

        -- Drag left/right directly on the model to rotate it.
        modelFrame:EnableMouse(true)
        if modelFrame.RegisterForDrag then
            modelFrame:RegisterForDrag("LeftButton")
        end

        local dragging = false
        local lastX = 0

        modelFrame:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                dragging = true
                if GetCursorPosition then
                    lastX = GetCursorPosition()
                end
            end
        end)

        modelFrame:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" then
                dragging = false
            end
        end)

        modelFrame:SetScript("OnUpdate", function(self)
            if not dragging or not GetCursorPosition then
                return
            end

            local x = GetCursorPosition()
            local delta = x - lastX
            lastX = x

            if delta ~= 0 then
                rotation = rotation + (delta * 0.01)
                if modelFrame.SetRotation then
                    pcall(modelFrame.SetRotation, modelFrame, rotation)
                end
            end
        end)

        if modelFrame.EnableMouseWheel then
            modelFrame:EnableMouseWheel(true)
            modelFrame:SetScript("OnMouseWheel", function(self, delta)
                if delta > 0 then
                    cameraScale = cameraScale - 0.15
                else
                    cameraScale = cameraScale + 0.15
                end

                if cameraScale < minCameraScale then cameraScale = minCameraScale end
                if cameraScale > maxCameraScale then cameraScale = maxCameraScale end
                ApplyModelView()
            end)
        end

        -- Model variation dropdown. This is a custom old-client-safe dropdown
        -- rather than UIDropDownMenuTemplate, which varies between clients.
        local modelDropdown = ForeverBrowser_ItemButton190(modelPanel, "SELECT MODEL", 150, 28)
        modelDropdown:SetSize(136, 24)
        modelDropdown:SetPoint("BOTTOMLEFT", modelPanel, "BOTTOMLEFT", 10, 38)

        local modelMenu = CreateFrame("Frame", nil, modelPanel)
        modelMenu:SetSize(220, math.max(32, modelCount * 28 + 8))
        modelMenu:SetPoint("BOTTOMLEFT", modelDropdown, "TOPLEFT", 0, 4)
        modelMenu:SetFrameStrata("DIALOG")
        if modelMenu.SetFrameLevel and modelPanel.GetFrameLevel then
            modelMenu:SetFrameLevel(modelPanel:GetFrameLevel() + 30)
        end
        CreateSolidBackground(modelMenu, 0.045, 0.038, 0.029, 1)
    ForeverBrowser_AchievementBorder(modelMenu, true)
        modelMenu:Hide()

        local function UpdateModelDropdownText()
            if modelCount > 0 then
                modelDropdown:SetText(
                    "MODEL " .. tostring(modelIndex) .. " OF " .. tostring(modelCount)
                )
            else
                modelDropdown:SetText("DEFAULT MODEL")
            end
        end

        if modelCount > 0 then
            for dropdownIndex, dropdownDisplayID in ipairs(displayIDs) do
                local savedIndex = dropdownIndex
                local savedDisplayID = dropdownDisplayID
                local option = ForeverBrowser_ItemButton190(
                    modelMenu,
                    "Model " .. tostring(savedIndex) .. "   |   ID " .. tostring(savedDisplayID),
                    204,
                    24
                )
                option:SetPoint("TOPLEFT", modelMenu, "TOPLEFT", 8, -4 - ((savedIndex - 1) * 28))
                option:SetScript("OnClick", function()
                    modelIndex = savedIndex
                    LoadCurrentModel()
                    UpdateModelDropdownText()
                    modelMenu:Hide()
                end)
            end
        end

        UpdateModelDropdownText()

        modelDropdown:SetScript("OnClick", function()
            if modelCount <= 1 then
                return
            end
            if modelMenu:IsShown() then
                modelMenu:Hide()
            else
                modelMenu:Show()
            end
        end)

        if modelCount <= 1 and modelDropdown.Disable then
            modelDropdown:Disable()
        end

        local previousModel = ForeverBrowser_ItemButton190(modelPanel, "PREVIOUS", 82, 24)
        previousModel:SetPoint("LEFT", modelDropdown, "RIGHT", 8, 0)
        previousModel:SetScript("OnClick", function()
            if modelCount > 1 then
                modelIndex = modelIndex - 1
                if modelIndex < 1 then
                    modelIndex = modelCount
                end
                LoadCurrentModel()
                UpdateModelDropdownText()
            end
        end)

        local nextModel = ForeverBrowser_ItemButton190(modelPanel, "NEXT", 72, 24)
        nextModel:SetPoint("LEFT", previousModel, "RIGHT", 8, 0)
        nextModel:SetScript("OnClick", function()
            if modelCount > 1 then
                modelIndex = modelIndex + 1
                if modelIndex > modelCount then
                    modelIndex = 1
                end
                LoadCurrentModel()
                UpdateModelDropdownText()
            end
        end)

        if modelCount <= 1 then
            if previousModel.Disable then previousModel:Disable() end
            if nextModel.Disable then nextModel:Disable() end
        end

        local rotateLeft = ForeverBrowser_ItemButton190(modelPanel, "LEFT", 64, 24)
        rotateLeft:SetPoint("BOTTOMLEFT", modelPanel, "BOTTOMLEFT", 10, 8)
        rotateLeft:SetScript("OnClick", function()
            rotation = rotation - 0.35
            ApplyModelView()
        end)

        local rotateRight = ForeverBrowser_ItemButton190(modelPanel, "RIGHT", 64, 24)
        rotateRight:SetPoint("LEFT", rotateLeft, "RIGHT", 8, 0)
        rotateRight:SetScript("OnClick", function()
            rotation = rotation + 0.35
            ApplyModelView()
        end)

        local zoomIn = ForeverBrowser_ItemButton190(modelPanel, "ZOOM +", 68, 24)
        zoomIn:SetPoint("LEFT", rotateRight, "RIGHT", 8, 0)
        zoomIn:SetScript("OnClick", function()
            cameraScale = cameraScale - 0.20
            if cameraScale < minCameraScale then cameraScale = minCameraScale end
            ApplyModelView()
        end)

        local zoomOut = ForeverBrowser_ItemButton190(modelPanel, "ZOOM -", 68, 24)
        zoomOut:SetPoint("LEFT", zoomIn, "RIGHT", 8, 0)
        zoomOut:SetScript("OnClick", function()
            cameraScale = cameraScale + 0.20
            if cameraScale > maxCameraScale then cameraScale = maxCameraScale end
            ApplyModelView()
        end)

        local resetView = ForeverBrowser_ItemButton190(modelPanel, "RESET", 72, 24)
        resetView:SetPoint("LEFT", zoomOut, "RIGHT", 12, 0)
        resetView:SetScript("OnClick", function()
            rotation = 0
            cameraScale = defaultCameraScale
            ApplyModelView()
        end)

        if not loaded then
            local unavailable = ForeverBrowser_AchievementLabel(modelPanel, "Model unavailable for this NPC.", 12, {0.75,0.62,0.32,1})
            unavailable:SetPoint("TOPLEFT", modelPanel, "TOPLEFT", 14, -14)
        end
    else
        local unavailable = ForeverBrowser_AchievementLabel(modelPanel, "3D models are not available through this client.", 12, {0.75,0.62,0.32,1})
        unavailable:SetPoint("CENTER", modelPanel, "CENTER", 0, 0)
    end

    y = y - 390

    --------------------------------------------------
    -- LOCATIONS - COMPACT ZONE LIST + POPUP
    --------------------------------------------------

    local locations =
        npc
        and npc.locations
        or {}

    local locationsTitle =
        ForeverBrowser_AchievementLabel(
            PageContent,
            "LOCATIONS  (" .. tostring(#locations) .. ")",
            16,
            {0.92, 0.76, 0.25, 1}
        )

    locationsTitle:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
    ForeverBrowser_NPCSection195(locationsTitle)

    if #locations > 1 then
        local allButton = ForeverBrowser_ItemButton190(PageContent, "SHOW ALL ON MAP", 140, 24)
        allButton:SetPoint("TOPRIGHT", PageContent, "TOPRIGHT", -25, y + 5)
        allButton:SetScript("OnClick", function()
            ShowAllForeverBrowserLocations(locations, nil, npcName)
        end)
    end

    y = y - 30

    if #locations == 0 then
        local none = ForeverBrowser_AchievementLabel(
            PageContent,
            "No known location data for this NPC.",
            12,
            {0.68, 0.64, 0.56, 1}
        )
        none:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 27, y)
        y = y - 32
    else
        local zones = {}
        local zoneOrder = {}

        for _, location in ipairs(locations) do
            local mapID = tonumber(location.uiMapID)
            local mapName = GetAutomaticMapName(mapID)
                or ("Map " .. tostring(mapID or "?"))
            local key = tostring(mapID or "?") .. ":" .. tostring(mapName)

            if not zones[key] then
                zones[key] = {mapID=mapID, mapName=mapName, locations={}}
                table.insert(zoneOrder, key)
            end
            table.insert(zones[key].locations, location)
        end

        table.sort(zoneOrder, function(a,b)
            return tostring(zones[a].mapName or "") < tostring(zones[b].mapName or "")
        end)

        for _, key in ipairs(zoneOrder) do
            local zone = zones[key]
            local zoneLocations = zone.locations or {}

            local header = CreateFrame("Frame", nil, PageContent)
            header:SetSize(790, 34)
            header:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
            CreateSolidBackground(header, 0.045, 0.038, 0.029, 1)
    ForeverBrowser_AchievementBorder(header, true)

            local zoneText = ForeverBrowser_AchievementLabel(
                header,
                tostring(zone.mapName) .. "  -  " .. tostring(#zoneLocations)
                    .. " location" .. (#zoneLocations == 1 and "" or "s"),
                12,
                {0.88,0.88,0.92,1}
            )
            zoneText:SetPoint("LEFT", header, "LEFT", 12, 0)

            local viewButton = ForeverBrowser_ItemButton190(header, "VIEW LOCATIONS", 130, 22)
            viewButton:SetPoint("RIGHT", header, "RIGHT", -8, 0)

            viewButton:SetScript("OnClick", function()
                local popup = CreateFrame("Frame", nil, UIParent)
                popup:SetSize(520, 500)
                popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                popup:SetFrameStrata("TOOLTIP")
                popup:SetClampedToScreen(true)
                CreateSolidBackground(popup, 0.045, 0.038, 0.029, 0.99)
    ForeverBrowser_AchievementBorder(popup, true)

                local close = ForeverBrowser_ItemButton190(popup, "CLOSE", 70, 22)
                close:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -14, -12)
                close:SetScript("OnClick", function() popup:Hide() end)

                local zoneMapButton = ForeverBrowser_ItemButton190(popup, "SHOW ZONE MAP", 140, 22)
                zoneMapButton:SetPoint("TOPLEFT", popup, "TOPLEFT", 14, -12)
                zoneMapButton:SetScript("OnClick", function()
                    popup:Hide()
                    ShowAllForeverBrowserLocations(zoneLocations, zone.mapID, npcName)
                end)

                local scroll = CreateFrame("ScrollFrame", nil, popup)
                scroll:SetPoint("TOPLEFT", popup, "TOPLEFT", 14, -48)
                scroll:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -30, 14)
                scroll:EnableMouseWheel(true)

                local child = CreateFrame("Frame", nil, scroll)
                child:SetWidth(460)
                child:SetHeight(math.max(420, #zoneLocations * 34 + 10))
                scroll:SetScrollChild(child)

                local maxScroll = math.max(0, #zoneLocations * 34 + 10 - 420)
                scroll:SetScript("OnMouseWheel", function(self, delta)
                    local current = self:GetVerticalScroll() or 0
                    current = current - delta * 45
                    if current < 0 then current = 0 end
                    if current > maxScroll then current = maxScroll end
                    self:SetVerticalScroll(current)
                end)

                local rowY = -4
                for _, location in ipairs(zoneLocations) do
                    local mapID = tonumber(location.uiMapID)
                    local x = tonumber(location.x)
                    local yy = tonumber(location.y)
                    local displayX = x or 0
                    local displayY = yy or 0
                    if displayX <= 1 then displayX = displayX * 100 end
                    if displayY <= 1 then displayY = displayY * 100 end

                    local row = CreateFrame("Frame", nil, child)
                    row:SetSize(455, 30)
                    row:SetPoint("TOPLEFT", child, "TOPLEFT", 2, rowY)
                    CreateSolidBackground(row, 0.045, 0.038, 0.029, 1)
    ForeverBrowser_AchievementBorder(row, true)

        local rowAccent = row:CreateTexture(nil, "ARTWORK")
        rowAccent:SetTexture("Interface\\Buttons\\WHITE8X8")
        rowAccent:SetVertexColor(0.90, 0.72, 0.29, 0.88)
        rowAccent:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        rowAccent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
        rowAccent:SetWidth(3)

                    local coords = ForeverBrowser_AchievementLabel(
                        row,
                        string.format("%.1f, %.1f", displayX, displayY),
                        11,
                        {0.58,0.72,0.62,1}
                    )
                    coords:SetPoint("LEFT", row, "LEFT", 12, 0)

                    local mapButton = ForeverBrowser_ItemButton190(row, "MAP", 82, 21)
                    mapButton:SetPoint("RIGHT", row, "RIGHT", -8, 0)
                    mapButton:SetScript("OnClick", function()
                        popup:Hide()
                        ShowForeverBrowserMapMarker(mapID, x, yy, npcName)
                    end)

                    rowY = rowY - 34
                end
            end)

            y = y - 39
        end
    end

    y = y - 15
    --------------------------------------------------
    -- QUESTS GIVEN
    --------------------------------------------------

    local quests = {}
    local questKeys = {}

    local function AddNPCQuest(list, questData)
        if type(questData) ~= "table" then return end

        local questID = tonumber(questData.id)
        if not questID or questKeys[questID] then return end

        questKeys[questID] = true
        table.insert(list, {
            id = questID,
            name = questData.name or ("Quest " .. tostring(questID)),
            level = questData.level,
            faction = questData.faction,
        })
    end

    -- Preserve older NPC-side quest data.
    if npc and type(npc.quests) == "table" then
        for _, questInfo in ipairs(npc.quests) do
            AddNPCQuest(quests, questInfo)
        end
    end

    -- Authoritative reverse lookup from generated quest starter relations.
    if ForeverSourceData and type(ForeverSourceData.quests) == "table" then
        for rawQuestID, questData in pairs(ForeverSourceData.quests) do
            if type(questData) == "table" then
                local isStarter = false

                if type(questData.npcStarters) == "table" then
                    for _, starter in ipairs(questData.npcStarters) do
                        if tonumber(starter.id) == npcID then
                            isStarter = true
                            break
                        end
                    end
                end

                -- Compatibility with older generated giver fields.
                if not isStarter
                    and tonumber(questData.giverID) == npcID then
                    isStarter = true
                end

                if isStarter then
                    local normalized = {
                        id = tonumber(questData.id) or tonumber(rawQuestID),
                        name = questData.name,
                        level = questData.level,
                        faction = questData.faction,
                    }
                    AddNPCQuest(quests, normalized)
                end
            end
        end
    end

    table.sort(
        quests,
        function(a, b)
            local aLevel = tonumber(a.level) or 0
            local bLevel = tonumber(b.level) or 0
            if aLevel ~= bLevel then
                return aLevel < bLevel
            end
            return tostring(a.name or "") < tostring(b.name or "")
        end
    )

    local questsTitle =
        ForeverBrowser_AchievementLabel(
            PageContent,
            "QUESTS GIVEN  ("
                .. tostring(#quests)
                .. ")",
            16,
            {0.92, 0.76, 0.25, 1}
        )

    questsTitle:SetPoint(
        "TOPLEFT",
        PageContent,
        "TOPLEFT",
        25,
        y
    )
    ForeverBrowser_NPCSection195(questsTitle)

    y = y - 30

    if #quests == 0 then
        local none =
            ForeverBrowser_AchievementLabel(
                PageContent,
                "No quests from this NPC are currently in the source database.",
                12,
                {0.68, 0.64, 0.56, 1}
            )

        none:SetPoint(
            "TOPLEFT",
            PageContent,
            "TOPLEFT",
            27,
            y
        )

        y = y - 32
    else
        for _, quest in ipairs(quests) do
            local row =
                CreateFrame(
                    "Button",
                    nil,
                    PageContent
                )

            row:SetSize(790, 38)

            row:SetPoint(
                "TOPLEFT",
                PageContent,
                "TOPLEFT",
                25,
                y
            )

            CreateSolidBackground(row, 0.045, 0.038, 0.029, 1)
    ForeverBrowser_AchievementBorder(row, true)

            local questText =
                ForeverBrowser_AchievementLabel(
                    row,
                    "|cffffd100["
                        .. tostring(quest.name or "Unknown Quest")
                        .. "]|r",
                    13,
                    {1, 1, 1, 1}
                )

            questText:SetPoint(
                "TOPLEFT",
                row,
                "TOPLEFT",
                12,
                -7
            )

            local detail =
                "Quest ID: "
                .. tostring(quest.id or "?")

            if quest.level
                and tostring(quest.level) ~= "" then

                detail =
                    detail
                    .. "    Level: "
                    .. tostring(quest.level)
            end

            local questDetail =
                ForeverBrowser_AchievementLabel(
                    row,
                    detail,
                    10,
                    {0.68, 0.64, 0.56, 1}
                )

            questDetail:SetPoint(
                "TOPRIGHT",
                row,
                "TOPRIGHT",
                -12,
                -10
            )

            local questID =
                tonumber(quest.id)

            if questID then
                -- Subtle full-row hover highlight.
            local hoverTexture=row:CreateTexture(nil,"BACKGROUND")
            hoverTexture:SetAllPoints(row)
            hoverTexture:SetTexture("Interface\\Buttons\\WHITE8X8")
            hoverTexture:SetVertexColor(0.65,0.46,0.16,0.18)
            hoverTexture:Hide()

            row:EnableMouse(true)

            row:HookScript("OnEnter",function(self)
                hoverTexture:Show()
            end)

            row:HookScript("OnLeave",function(self)
                hoverTexture:Hide()
            end)

                row:SetScript(
                    "OnClick",
                    function()
                        Navigate(
                            "forever://quest/"
                            .. tostring(questID)
                        )
                    end
                )

                row:SetScript(
                    "OnEnter",
                    function()
                        questText:SetTextColor(
                            1,
                            1,
                            1,
                            1
                        )
                    end
                )

                row:SetScript(
                    "OnLeave",
                    function()
                        questText:SetTextColor(
                            1,
                            1,
                            1,
                            1
                        )
                    end
                )
            end

            y = y - 43
        end
    end

    y = y - 15

    --------------------------------------------------
    -- QUESTS TURNED IN
    --------------------------------------------------

    local finishQuests = {}
    local finishQuestKeys = {}

    if ForeverSourceData and type(ForeverSourceData.quests) == "table" then
        for rawQuestID, questData in pairs(ForeverSourceData.quests) do
            if type(questData) == "table"
                and type(questData.npcFinishers) == "table" then

                for _, finisher in ipairs(questData.npcFinishers) do
                    if tonumber(finisher.id) == npcID then
                        local questID =
                            tonumber(questData.id)
                            or tonumber(rawQuestID)

                        if questID and not finishQuestKeys[questID] then
                            finishQuestKeys[questID] = true
                            table.insert(finishQuests, {
                                id = questID,
                                name = questData.name
                                    or ("Quest " .. tostring(questID)),
                                level = questData.level,
                            })
                        end
                        break
                    end
                end
            end
        end
    end

    table.sort(
        finishQuests,
        function(a, b)
            local aLevel = tonumber(a.level) or 0
            local bLevel = tonumber(b.level) or 0
            if aLevel ~= bLevel then
                return aLevel < bLevel
            end
            return tostring(a.name or "") < tostring(b.name or "")
        end
    )

    local finishTitle = ForeverBrowser_AchievementLabel(
        PageContent,
        "QUESTS TURNED IN  (" .. tostring(#finishQuests) .. ")",
        16,
        {0.92, 0.76, 0.25, 1}
    )
    finishTitle:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
    ForeverBrowser_NPCSection195(finishTitle)
    y = y - 30

    if #finishQuests == 0 then
        local none = ForeverBrowser_AchievementLabel(
            PageContent,
            "No known quests are turned in to this NPC.",
            12,
            {0.68, 0.64, 0.56, 1}
        )
        none:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 27, y)
        y = y - 32
    else
        for _, questInfo in ipairs(finishQuests) do
            local row = CreateFrame("Button", nil, PageContent)
            row:SetSize(790, 38)
            row:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
            CreateSolidBackground(row, 0.045, 0.038, 0.029, 1)
    ForeverBrowser_AchievementBorder(row, true)

        local rowAccent = row:CreateTexture(nil, "ARTWORK")
        rowAccent:SetTexture("Interface\\Buttons\\WHITE8X8")
        rowAccent:SetVertexColor(0.90, 0.72, 0.29, 0.88)
        rowAccent:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        rowAccent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
        rowAccent:SetWidth(3)

            local questText = ForeverBrowser_AchievementLabel(
                row,
                "|cffffd100["
                    .. tostring(questInfo.name or "Unknown Quest")
                    .. "]|r",
                13,
                {1, 1, 1, 1}
            )
            questText:SetPoint("TOPLEFT", row, "TOPLEFT", 12, -7)

            local detail =
                "Quest ID: " .. tostring(questInfo.id or "?")

            if questInfo.level and tostring(questInfo.level) ~= "" then
                detail =
                    detail
                    .. "    Level: "
                    .. tostring(questInfo.level)
            end

            local questDetail = ForeverBrowser_AchievementLabel(
                row,
                detail,
                10,
                {0.68, 0.64, 0.56, 1}
            )
            questDetail:SetPoint("TOPRIGHT", row, "TOPRIGHT", -12, -10)

            local questID = tonumber(questInfo.id)
            if questID then
                row:SetScript(
                    "OnClick",
                    function()
                        Navigate("forever://quest/" .. tostring(questID))
                    end
                )
            end

            y = y - 43
        end
    end

    y = y - 15

    --------------------------------------------------
    -- QUESTS INVOLVED IN
    --------------------------------------------------

    local involvedQuests =
        npc
        and npc.involvedQuests
        or {}

    local involvedTitle =
        ForeverBrowser_AchievementLabel(
            PageContent,
            "QUESTS INVOLVED IN  ("
                .. tostring(#involvedQuests)
                .. ")",
            16,
            {0.92, 0.76, 0.25, 1}
        )

    involvedTitle:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
    ForeverBrowser_NPCSection195(involvedTitle)
    y = y - 30

    local function FillInvolvedQuestRow(row, questInfo)
        local questID = tonumber(questInfo.id)
        local questText = ForeverBrowser_AchievementLabel(
            row,
            "|cffffd100[" .. tostring(questInfo.name or "Unknown Quest") .. "]|r",
            12,
            {1, 1, 1, 1}
        )
        questText:SetPoint("TOPLEFT", row, "TOPLEFT", 12, -6)
        questText:SetWidth(610)
        questText:SetJustifyH("LEFT")

        local objectiveText = "Objective: NPC"
        if questInfo.involvementType == "requiredItem" then
            objectiveText =
                "Drops required item: "
                .. tostring(
                    questInfo.requiredItemName
                    or ("Item " .. tostring(questInfo.requiredItemID or "?"))
                )
            if tonumber(questInfo.count) and tonumber(questInfo.count) > 0 then
                objectiveText = objectiveText .. " x" .. tostring(questInfo.count)
            end
        elseif tonumber(questInfo.count) and tonumber(questInfo.count) > 0 then
            objectiveText = objectiveText .. " x" .. tostring(questInfo.count)
        end

        local objectiveLabel = ForeverBrowser_AchievementLabel(
            row, objectiveText, 10, {0.58, 0.61, 0.68, 1}
        )
        objectiveLabel:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 12, 6)

        if questID then
            ForeverBrowser_AddQuestStatusVisual(row, questID, questText)
            row:SetScript("OnClick", function()
                Navigate("forever://quest/" .. tostring(questID))
            end)
        end
    end

    if #involvedQuests == 0 then
        local none = ForeverBrowser_AchievementLabel(
            PageContent,
            "This NPC is not currently involved in any known quest.",
            12,
            {0.68, 0.64, 0.56, 1}
        )
        none:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 27, y)
        y = y - 32

    elseif #involvedQuests == 1 then
        local row = CreateFrame("Button", nil, PageContent)
        row:SetSize(790, 42)
        row:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
        CreateSolidBackground(row, 0.045, 0.038, 0.029, 1)
    ForeverBrowser_AchievementBorder(row, true)
        FillInvolvedQuestRow(row, involvedQuests[1])
        y = y - 47

    else
        -- Multiple quests use a compact drop-down instead of permanently
        -- consuming a large part of the NPC page.
        local dropdownButton = CreateFrame("Button", nil, PageContent)
        dropdownButton:SetSize(790, 38)
        dropdownButton:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
        ForeverBrowser_AchievementPaper(dropdownButton,true)
        dropdownButton:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")

        local dropdownText = ForeverBrowser_AchievementLabel(
            dropdownButton,
            "SHOW QUESTS   (" .. tostring(#involvedQuests) .. ")",
            12,
            {0.31,0.22,0.10,1}
        )
        dropdownText:SetPoint("LEFT", dropdownButton, "LEFT", 12, 0)

        local arrow = ForeverBrowser_AchievementLabel(
            dropdownButton,
            "v",
            13,
            {0.92, 0.76, 0.25, 1}
        )
        arrow:SetPoint("RIGHT", dropdownButton, "RIGHT", -12, 0)
        arrow:SetTextColor(0.38,0.25,0.08,1)

        local dropdown = CreateFrame("Frame", nil, dropdownButton)
        dropdown:SetSize(790, (#involvedQuests * 43) + 6)
        dropdown:SetPoint("TOPLEFT", dropdownButton, "BOTTOMLEFT", 0, -2)
        dropdown:SetFrameStrata("DIALOG")
        dropdown:SetFrameLevel((dropdownButton:GetFrameLevel() or 1) + 20)
        CreateSolidBackground(dropdown, 0.045,0.038,0.029,1)
        ForeverBrowser_AchievementBorder(dropdown,true)
        dropdown:Hide()

        for index, questInfo in ipairs(involvedQuests) do
            local row = CreateFrame("Button", nil, dropdown)
            row:SetSize(780, 40)
            row:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 5, -3 - ((index - 1) * 43))
            CreateSolidBackground(row, 0.045,0.038,0.029,1)
            ForeverBrowser_AchievementBorder(row,true)
            FillInvolvedQuestRow(row, questInfo)
        end

        local open = false
        dropdownButton:SetScript("OnClick", function()
            open = not open
            if open then
                dropdown:Show()
                dropdownText:SetText("HIDE QUESTS   (" .. tostring(#involvedQuests) .. ")")
                arrow:SetText("^")
            else
                dropdown:Hide()
                dropdownText:SetText("SHOW QUESTS   (" .. tostring(#involvedQuests) .. ")")
                arrow:SetText("v")
            end
        end)

        y = y - 43
    end

    y = y - 15

    --------------------------------------------------
    --------------------------------------------------
    -- ASSOCIATED ITEM SECTIONS
    --------------------------------------------------

    local function CreateNPCItemSection(
        heading,
        items,
        emptyText
    )
        local sectionTitle =
            ForeverBrowser_AchievementLabel(
                PageContent,
                heading
                    .. "  ("
                    .. tostring(#items)
                    .. ")",
                16,
                {0.92, 0.76, 0.25, 1}
            )

        sectionTitle:SetPoint(
            "TOPLEFT",
            PageContent,
            "TOPLEFT",
            25,
            y
        )
    ForeverBrowser_NPCSection195(sectionTitle)

        y = y - 30

        if #items == 0 then
            local none =
                ForeverBrowser_AchievementLabel(
                    PageContent,
                    emptyText,
                    12,
                    {0.68, 0.64, 0.56, 1}
                )

            none:SetPoint(
                "TOPLEFT",
                PageContent,
                "TOPLEFT",
                27,
                y
            )

            y = y - 32
            return
        end

        local maxItems =
            npc and npc.isForeverNPC
            and #items
            or 40

        for index, entry in ipairs(items) do
            if index > maxItems then
                break
            end

            local itemID =
                tonumber(entry.id)

            local item =
                GetAnyItem(itemID)

            local quality =
                GetQuality(
                    itemID,
                    item
                )

            local color =
                QualityColors
                and QualityColors[quality]
                or {0.92, 0.92, 0.96, 1}

            local row =
                CreateFrame(
                    "Button",
                    nil,
                    PageContent
                )

            row:SetSize(790, 42)

            row:SetPoint(
                "TOPLEFT",
                PageContent,
                "TOPLEFT",
                25,
                y
            )

            CreateSolidBackground(row, 0.045, 0.038, 0.029, 1)
    ForeverBrowser_AchievementBorder(row, true)

            local icon =
                row:CreateTexture(
                    nil,
                    "ARTWORK"
                )

            icon:SetSize(30, 30)

            icon:SetPoint(
                "LEFT",
                row,
                "LEFT",
                7,
                0
            )

            icon:SetTexture(
                GetItemIcon(
                    itemID,
                    item
                )
            )

            local itemName =
                ForeverBrowser_AchievementLabel(
                    row,
                    tostring(
                        entry.name
                        or GetItemName(itemID)
                    ),
                    13,
                    color
                )

            itemName:SetPoint(
                "LEFT",
                icon,
                "RIGHT",
                9,
                0
            )

            local rightText =
                "Item ID: "
                .. tostring(itemID or "?")

            local chance =
                FormatSourceChance(
                    entry.chance
                )

            if chance then
                rightText =
                    rightText
                    .. "    DROP CHANCE: "
                    .. chance
            end

            local detail =
                ForeverBrowser_AchievementLabel(
                    row,
                    rightText,
                    10,
                    {0.58, 0.61, 0.68, 1}
                )

            detail:SetPoint(
                "RIGHT",
                row,
                "RIGHT",
                -12,
                0
            )

            row:SetScript(
                "OnClick",
                function()
                    if IsShiftLinkClick() then
                        LinkItemToChat(itemID)
                    else
                        Navigate(
                            "forever://item/"
                            .. tostring(itemID)
                        )
                    end
                end
            )

            row:SetScript(
                "OnEnter",
                function(self)
                    ShowItemTooltip(
                        itemID,
                        self
                    )
                end
            )

            row:SetScript(
                "OnLeave",
                function()
                    if GameTooltip then
                        GameTooltip:Hide()
                    end
                end
            )

            y = y - 47
        end

        if #items > maxItems then
            local more =
                ForeverBrowser_AchievementLabel(
                    PageContent,
                    "+"
                        .. tostring(#items - maxItems)
                        .. " more items not shown.",
                    11,
                    {0.68, 0.64, 0.56, 1}
                )

            more:SetPoint(
                "TOPLEFT",
                PageContent,
                "TOPLEFT",
                27,
                y
            )

            y = y - 28
        end
    end

    --------------------------------------------------
    -- LOOT / DROPS
    --------------------------------------------------

    local lootHint =
        ForeverBrowser_AchievementLabel(
            PageContent,
            "Click an item to open it. Shift-click to link it in chat.",
            11,
            {0.68, 0.64, 0.56, 1}
        )

    lootHint:SetPoint(
        "TOPLEFT",
        PageContent,
        "TOPLEFT",
        27,
        y
    )

    y = y - 24

    CreateNPCItemSection(
        "LOOT / DROPS",
        npc and npc.drops or {},
        "No loot or drop items are currently known for this NPC."
    )

    y = y - 15

    CreateNPCItemSection(
        "PICKPOCKET ITEMS",
        npc and npc.pickpocket or {},
        "No pickpocket items are currently known for this NPC."
    )

    y = y - 15

    CreateNPCItemSection(
        "SKINNING ITEMS",
        npc and npc.skinning or {},
        "No skinning items are currently known for this NPC."
    )

    y = y - 15

    --------------------------------------------------
    -- FULL VENDOR INVENTORY
    --------------------------------------------------

    local vendorItems = {}

    if ForeverSourceData
        and type(ForeverSourceData.vendors) == "table" then

        vendorItems =
            ForeverSourceData.vendors[npcID]
            or ForeverSourceData.vendors[tostring(npcID)]
            or {}
    end

    -- Backward compatibility with older source data.
    if #vendorItems == 0
        and npc
        and type(npc.vendor) == "table" then

        for _, oldVendorItem in ipairs(npc.vendor) do
            table.insert(
                vendorItems,
                {
                    itemID = tonumber(oldVendorItem.id),
                    name = oldVendorItem.name,
                    quality = nil,
                    buyCount = 1,
                    buyPrice = 0,
                    maxCount = 0,
                    restockSeconds = 0,
                    extendedCost = 0,
                }
            )
        end
    end

    local vendorTitle =
        ForeverBrowser_AchievementLabel(
            PageContent,
            "VENDOR ITEMS  (" .. tostring(#vendorItems) .. ")",
            16,
            {0.92, 0.76, 0.25, 1}
        )

    vendorTitle:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
    ForeverBrowser_NPCSection195(vendorTitle)
    y = y - 30

    if #vendorItems == 0 then
        local none =
            ForeverBrowser_AchievementLabel(
                PageContent,
                "This NPC has no known vendor inventory.",
                12,
                {0.68, 0.64, 0.56, 1}
            )

        none:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 27, y)
        y = y - 32
    else
        local function FormatVendorMoney(copper)
            copper = tonumber(copper) or 0
            if copper <= 0 then
                return "No coin cost"
            end

            local gold = math.floor(copper / 10000)
            local silver = math.floor((copper - gold * 10000) / 100)
            local bronze = copper - gold * 10000 - silver * 100

            local parts = {}
            if gold > 0 then table.insert(parts, tostring(gold) .. "g") end
            if silver > 0 then table.insert(parts, tostring(silver) .. "s") end
            if bronze > 0 or #parts == 0 then
                table.insert(parts, tostring(bronze) .. "c")
            end
            return table.concat(parts, " ")
        end

        local function FormatRestock(seconds)
            seconds = tonumber(seconds) or 0
            if seconds <= 0 then
                return ""
            end
            if seconds >= 3600 then
                local hours = math.floor(seconds / 3600)
                local minutes = math.floor((seconds - hours * 3600) / 60)
                if minutes > 0 then
                    return tostring(hours) .. "h " .. tostring(minutes) .. "m"
                end
                return tostring(hours) .. "h"
            end
            if seconds >= 60 then
                local minutes = math.floor(seconds / 60)
                local remain = seconds - minutes * 60
                if remain > 0 then
                    return tostring(minutes) .. "m " .. tostring(remain) .. "s"
                end
                return tostring(minutes) .. "m"
            end
            return tostring(seconds) .. "s"
        end

        for _, entry in ipairs(vendorItems) do
            local itemID = tonumber(entry.itemID or entry.id)
            local item = GetAnyItem(itemID)

            local quality = tonumber(entry.quality)
            if quality == nil then
                quality = GetQuality(itemID, item)
            end

            local color =
                QualityColors
                and QualityColors[quality]
                or {0.92, 0.92, 0.96, 1}

            local row = CreateFrame("Button", nil, PageContent)
            row:SetSize(790, 54)
            row:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
            CreateSolidBackground(row, 0.045, 0.038, 0.029, 1)
    ForeverBrowser_AchievementBorder(row, true)

        local rowAccent = row:CreateTexture(nil, "ARTWORK")
        rowAccent:SetTexture("Interface\\Buttons\\WHITE8X8")
        rowAccent:SetVertexColor(0.90, 0.72, 0.29, 0.88)
        rowAccent:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        rowAccent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
        rowAccent:SetWidth(3)

            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(38, 38)
            icon:SetPoint("LEFT", row, "LEFT", 8, 0)
            icon:SetTexture(GetItemIcon(itemID, item))

            local itemName =
                ForeverBrowser_AchievementLabel(
                    row,
                    tostring(entry.name or GetItemName(itemID) or ("Item " .. tostring(itemID or "?"))),
                    13,
                    color
                )
            itemName:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)

            local itemIDText =
                ForeverBrowser_AchievementLabel(
                    row,
                    "Item ID: " .. tostring(itemID or "?"),
                    10,
                    {0.55,0.58,0.65,1}
                )
            itemIDText:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 10, 2)

            local buyCount = math.max(1, tonumber(entry.buyCount) or 1)
            local buyPrice = math.max(0, tonumber(entry.buyPrice) or 0)
            local maxCount = math.max(0, tonumber(entry.maxCount) or 0)
            local restock = math.max(0, tonumber(entry.restockSeconds) or 0)
            local extendedCost = math.max(0, tonumber(entry.extendedCost) or 0)

            local priceText = FormatVendorMoney(buyPrice)
            if entry.currencyAmount and entry.currencyName then
                priceText = tostring(entry.currencyAmount).." "..entry.currencyName
            end
            if buyCount > 1 then
                priceText = priceText .. " / " .. tostring(buyCount)
            end

            local price =
                ForeverBrowser_AchievementLabel(
                    row,
                    "BUY: " .. priceText,
                    11,
                    {0.95,0.82,0.42,1}
                )
            price:SetPoint("TOPRIGHT", row, "TOPRIGHT", -12, -8)

            local stockText
            if maxCount > 0 then
                stockText = "Stock: " .. tostring(maxCount)
                if restock > 0 then
                    stockText =
                        stockText
                        .. "    Restock: "
                        .. FormatRestock(restock)
                end
            else
                stockText = "Stock: Unlimited"
            end

            if entry.stockUnknown and entry.maxCount == nil then stockText = "Stock: Not recorded" end
            if entry.evidenceStatus then stockText = stockText.." - "..entry.evidenceStatus end
            if extendedCost > 0 then
                stockText =
                    stockText
                    .. "    Extended Cost ID: "
                    .. tostring(extendedCost)
            end

            local stock =
                ForeverBrowser_AchievementLabel(
                    row,
                    stockText,
                    10,
                    {0.58,0.61,0.68,1}
                )
            stock:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -12, 7)

            row:SetScript(
                "OnClick",
                function()
                    if IsShiftLinkClick() then
                        LinkItemToChat(itemID)
                    else
                        Navigate("forever://item/" .. tostring(itemID))
                    end
                end
            )

            row:SetScript(
                "OnEnter",
                function(self)
                    ShowItemTooltip(itemID, self)
                    if entry.requiredProfessionSkill and GameTooltip and type(GameTooltip.AddLine)=="function" then
                        GameTooltip:AddLine("Reported learning skill: "..tostring(entry.reportedProfession or "Profession").." "..entry.requiredProfessionSkill,1,.82,.28,true)
                        if entry.guideSkill and entry.guideSkill~=entry.requiredProfessionSkill then GameTooltip:AddLine("Guide lists skill "..entry.guideSkill,1,.82,.28,true) end
                        if entry.reportedReputationRank then GameTooltip:AddLine("Reported reputation: "..entry.reportedReputationRank,1,.82,.28,true) end
                        GameTooltip:Show()
                    end
                end
            )

            row:SetScript(
                "OnLeave",
                function()
                    if GameTooltip then
                        GameTooltip:Hide()
                    end
                end
            )

            y = y - 59
        end
    end

    --------------------------------------------------
    -- TRAINER / TRAINED SPELLS & RECIPES
    --------------------------------------------------

    local trainerRows = {}

    if ForeverSourceData
        and type(ForeverSourceData.trainers) == "table" then

        trainerRows =
            ForeverSourceData.trainers[npcID]
            or ForeverSourceData.trainers[tostring(npcID)]
            or {}
    end

    if #trainerRows > 0 then
        y = y - 8

        local trainerTitle =
            ForeverBrowser_AchievementLabel(
                PageContent,
                "TRAINER  (" .. tostring(#trainerRows) .. ")",
                16,
                {0.92, 0.76, 0.25, 1}
            )

        trainerTitle:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
    ForeverBrowser_NPCSection195(trainerTitle)
        y = y - 30

        local trainerType =
            npc
            and npc.subName
            or nil

        if trainerType
            and tostring(trainerType) ~= "" then

            local typeText =
                ForeverBrowser_AchievementLabel(
                    PageContent,
                    tostring(trainerType),
                    12,
                    {0.55, 0.75, 1, 1}
                )

            typeText:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 27, y)
            y = y - 24
        end

        local function FormatTrainerMoney(copper)
            copper = tonumber(copper) or 0

            if copper <= 0 then
                return "Free"
            end

            local gold = math.floor(copper / 10000)
            local silver = math.floor((copper - gold * 10000) / 100)
            local bronze = copper - gold * 10000 - silver * 100
            local parts = {}

            if gold > 0 then
                table.insert(parts, tostring(gold) .. "g")
            end

            if silver > 0 then
                table.insert(parts, tostring(silver) .. "s")
            end

            if bronze > 0 or #parts == 0 then
                table.insert(parts, tostring(bronze) .. "c")
            end

            return table.concat(parts, " ")
        end

        for _, trainerEntry in ipairs(trainerRows) do
            local spellID = tonumber(trainerEntry.spellID) or 0
            local spellName = trainerEntry.name
            local spellIcon = nil
            local needsAsyncSpellName =
                not spellName or spellName == ""

            -- First try already-cached Forever spell data.
            if spellID > 0 then
                local foreverName, foreverIcon =
                    ResolveForeverSpellData(spellID)

                if needsAsyncSpellName
                    and foreverName
                    and tostring(foreverName) ~= "" then
                    spellName = foreverName
                    needsAsyncSpellName = false
                end

                if foreverIcon then
                    spellIcon = foreverIcon
                end
            end

            -- Old API remains as a compatibility fallback.
            if (not spellName or spellName == "") and GetSpellInfo then
                local ok, name, _, icon =
                    pcall(GetSpellInfo, spellID)

                if ok then
                    spellName = name
                    spellIcon = spellIcon or icon

                    if spellName and spellName ~= "" then
                        needsAsyncSpellName = false
                    end
                end
            end

            if not spellName or spellName == "" then
                spellName = "Spell " .. tostring(spellID)
            end

            local row = CreateFrame("Frame", nil, PageContent)
            row:SetSize(790, 58)
            row:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
            CreateSolidBackground(row, 0.045, 0.038, 0.029, 1)
    ForeverBrowser_AchievementBorder(row, true)

        local rowAccent = row:CreateTexture(nil, "ARTWORK")
        rowAccent:SetTexture("Interface\\Buttons\\WHITE8X8")
        rowAccent:SetVertexColor(0.90, 0.72, 0.29, 0.88)
        rowAccent:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        rowAccent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
        rowAccent:SetWidth(3)

            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(40, 40)
            icon:SetPoint("LEFT", row, "LEFT", 8, 0)

            if spellIcon then
                icon:SetTexture(spellIcon)
            else
                icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
            end

            local nameText =
                ForeverBrowser_AchievementLabel(
                    row,
                    tostring(spellName),
                    13,
                    {0.95, 0.95, 1, 1}
                )

            nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -3)

            -- If Forever had not cached this spell yet, request it now and
            -- update this row as soon as SPELL_DATA_LOAD_RESULT succeeds.
            if spellID > 0 and needsAsyncSpellName then
                ResolveForeverSpellData(
                    spellID,
                    function(loadedName, loadedIcon)
                        if loadedName
                            and tostring(loadedName) ~= ""
                            and nameText
                            and nameText.SetText then
                            nameText:SetText(tostring(loadedName))
                        end

                        if loadedIcon
                            and icon
                            and icon.SetTexture then
                            icon:SetTexture(loadedIcon)
                        end
                    end
                )
            end

            local spellIDText =
                ForeverBrowser_AchievementLabel(
                    row,
                    "Spell ID: " .. tostring(spellID),
                    10,
                    {0.68, 0.64, 0.56, 1}
                )

            spellIDText:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 10, 3)

            local cost =
                math.max(
                    0,
                    tonumber(trainerEntry.cost)
                    or 0
                )

            local rightTop =
                ForeverBrowser_AchievementLabel(
                    row,
                    "TRAIN: " .. FormatTrainerMoney(cost),
                    11,
                    {0.95, 0.82, 0.42, 1}
                )

            rightTop:SetPoint("TOPRIGHT", row, "TOPRIGHT", -12, -8)

            local requirements = {}

            local requiredLevel =
                tonumber(trainerEntry.requiredLevel)
                or 0

            local requiredSkillID =
                tonumber(trainerEntry.requiredSkillID)
                or 0

            local requiredSkillValue =
                tonumber(trainerEntry.requiredSkillValue)
                or 0

            if requiredLevel > 0 then
                table.insert(
                    requirements,
                    "Level " .. tostring(requiredLevel)
                )
            end

            if requiredSkillID > 0 then
                local requiredSkillName =
                    tostring(trainerEntry.requiredSkillName or "")

                local skillText

                if requiredSkillName ~= "" then
                    skillText = requiredSkillName
                else
                    skillText =
                        "Skill "
                        .. tostring(requiredSkillID)
                end

                if requiredSkillValue > 0 then
                    skillText =
                        skillText
                        .. ": "
                        .. tostring(requiredSkillValue)
                end

                table.insert(requirements, skillText)
            end

            local requirementText =
                #requirements > 0
                and table.concat(requirements, "    ")
                or "No additional requirements"

            local rightBottom =
                ForeverBrowser_AchievementLabel(
                    row,
                    requirementText,
                    10,
                    {0.58, 0.61, 0.68, 1}
                )

            rightBottom:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -12, 8)

            if spellID > 0 then
                row:EnableMouse(true)

                row:SetScript(
                    "OnEnter",
                    function(self)
                        if GameTooltip
                            and GameTooltip.SetHyperlink then

                            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

                            pcall(
                                GameTooltip.SetHyperlink,
                                GameTooltip,
                                "spell:" .. tostring(spellID)
                            )

                            GameTooltip:Show()
                        end
                    end
                )

                row:SetScript(
                    "OnLeave",
                    function()
                        if GameTooltip then
                            GameTooltip:Hide()
                        end
                    end
                )
            end

            y = y - 63
        end
    end

    --------------------------------------------------
    -- QUEST REWARD CURRENCY
    --------------------------------------------------

    local rewardMoney =
        quest
        and tonumber(quest.rewardMoney)
        or 0

    local rewardMoneyMaxLevel =
        quest
        and tonumber(quest.rewardMoneyMaxLevel)
        or 0

    if rewardMoney > 0
        or rewardMoneyMaxLevel > 0 then

        y = y - 8

        local currencyTitle =
            ForeverBrowser_AchievementLabel(
                PageContent,
                "QUEST REWARDS",
                16,
                {0.92, 0.76, 0.25, 1}
            )

        currencyTitle:SetPoint(
            "TOPLEFT",
            PageContent,
            "TOPLEFT",
            25,
            y
        )

        y = y - 28

        if rewardMoney > 0 then
            local moneyText =
                ForeverBrowser_AchievementLabel(
                    PageContent,
                    "|cff73bfffMONEY:|r  |cffffd100"
                        .. tostring(FormatQuestMoney(rewardMoney))
                        .. "|r",
                    12,
                    {1, 1, 1, 1}
                )

            moneyText:SetPoint(
                "TOPLEFT",
                PageContent,
                "TOPLEFT",
                27,
                y
            )

            y = y - 22
        end

        if rewardMoneyMaxLevel > 0 then
            local maxLevelText =
                ForeverBrowser_AchievementLabel(
                    PageContent,
                    "|cff73bfffMAX-LEVEL BONUS:|r  |cffffd100"
                        .. tostring(
                            FormatQuestMoney(
                                rewardMoneyMaxLevel
                            )
                        )
                        .. "|r",
                    12,
                    {1, 1, 1, 1}
                )

            maxLevelText:SetPoint(
                "TOPLEFT",
                PageContent,
                "TOPLEFT",
                27,
                y
            )

            y = y - 22
        end
    end

    
    --------------------------------------------------
    -- DATABASE FOOTER
    --------------------------------------------------

    local footer = ForeverBrowser_AchievementLabel(
        PageContent,
        "NPC ID " .. tostring(npcID)
            .. "   |   ForeverSourceData   |   ForeverBrowser",
        10,
        {0.44, 0.47, 0.54, 1}
    )
    footer:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
    y = y - 28

PageContent:SetHeight(
        math.max(
            650,
            math.abs(y) + 80
        )
    )
end


--------------------------------------------------
-- QUEST PAGE
--------------------------------------------------

local function FindQuestSourceData(questID)
    questID = tonumber(questID)

    if not questID or not ForeverSourceData then
        return nil
    end

    local result = {
        id = questID,
        name = nil,
        level = nil,
        faction = nil,
        giverID = nil,
        giverName = nil,
        giverLocations = {},
        npcStarters = {},
        npcFinishers = {},
        objectStarters = {},
        objectFinishers = {},
        previousQuests = {},
        nextQuests = {},
        rewards = {},
        choiceRewards = {},
        rewardMoney = 0,
        rewardMoneyMaxLevel = 0,
        rewardXP = 0,
        description = nil,
        objectivesText = nil,
        zone = nil,
        requiredItems = {},
        providedItems = {},
        reputationRewards = {},
        dataSource = nil,
    }

    local locationKeys = {}
    local rewardKeys = {}
    local choiceRewardKeys = {}

    local function AddLocation(location)
        if type(location) ~= "table" then return end
        local mapID = tonumber(location.uiMapID)
        local x = tonumber(location.x)
        local y = tonumber(location.y)
        if not mapID or not x or not y then return end
        local key = tostring(mapID) .. ":" .. string.format("%.3f", x) .. ":" .. string.format("%.3f", y)
        if locationKeys[key] then return end
        locationKeys[key] = true
        table.insert(result.giverLocations, {
            uiMapID = mapID,
            x = x,
            y = y,
            zone = location.zone,
        })
    end

    --------------------------------------------------
    -- PRIMARY QUEST DATABASE
    --------------------------------------------------
    -- The generator now writes every parsed quest to
    -- ForeverSourceData.quests. Use that first so a quest page does
    -- not depend on the quest appearing as an item reward source.
    local questData = nil

    if ForeverSourceData.quests then
        questData = ForeverSourceData.quests[questID]
            or ForeverSourceData.quests[tostring(questID)]
    end

    if questData then
        result.name = questData.name
        result.level = questData.level
        result.faction = questData.faction
        result.giverID = tonumber(questData.giverID)
        result.giverName = questData.giverName
        result.rewardMoney = tonumber(questData.rewardMoney) or 0
        result.rewardMoneyMaxLevel =
            tonumber(questData.rewardMoneyMaxLevel) or 0
        result.rewardXP =
            tonumber(questData.rewardXP) or 0

        result.description =
            questData.description
            or questData.details
            or questData.questDescription
            or questData.Description

        result.objectivesText =
            questData.objectivesText
            or questData.objectives
            or questData.objectiveText
            or questData.objective
            or questData.Objectives

        result.zone =
            questData.zone
            or questData.zoneName
            or questData.areaName
            or questData.Zone

        result.dataSource =
            questData.dataSource
            or questData.source
            or questData.DataSource

        local function CopyQuestItems(sourceTable, destination)
            if type(sourceTable) ~= "table" then return end
            for _, entry in ipairs(sourceTable) do
                local iid = tonumber(type(entry) == "table" and (entry.id or entry.itemID) or entry)
                if iid and iid > 0 then
                    table.insert(destination, {
                        id = iid,
                        name = type(entry) == "table" and entry.name or GetItemName(iid),
                        count = type(entry) == "table" and (tonumber(entry.count) or 1) or 1,
                    })
                end
            end
        end

        CopyQuestItems(
            questData.requiredItems
                or questData.requireItems
                or questData.objectiveItems,
            result.requiredItems
        )

        CopyQuestItems(
            questData.providedItems
                or questData.sourceItems
                or questData.givenItems,
            result.providedItems
        )

        local repData =
            questData.reputationRewards
            or questData.reputation
            or questData.repRewards

        if type(repData) == "table" then
            for _, rep in ipairs(repData) do
                if type(rep) == "table" then
                    table.insert(result.reputationRewards, rep)
                end
            end
        end

        if type(questData.npcStarters) == "table" then
            for _, entry in ipairs(questData.npcStarters) do
                table.insert(result.npcStarters, entry)
            end
        end

        if type(questData.npcFinishers) == "table" then
            for _, entry in ipairs(questData.npcFinishers) do
                table.insert(result.npcFinishers, entry)
            end
        end

        if type(questData.objectStarters) == "table" then
            for _, entry in ipairs(questData.objectStarters) do
                table.insert(result.objectStarters, entry)
            end
        end

        if type(questData.objectFinishers) == "table" then
            for _, entry in ipairs(questData.objectFinishers) do
                table.insert(result.objectFinishers, entry)
            end
        end

        -- Explicit quest rewards generated directly from Classic-DB.
        if type(questData.rewardItems) == "table" then
            for _, reward in ipairs(questData.rewardItems) do
                local itemID = tonumber(reward.id)
                if itemID and itemID > 0 and not rewardKeys[itemID] then
                    rewardKeys[itemID] = true
                    table.insert(result.rewards, {
                        id = itemID,
                        name = reward.name or GetItemName(itemID),
                        count = tonumber(reward.count) or 1,
                    })
                end
            end
        end

        if type(questData.choiceRewardItems) == "table" then
            for _, reward in ipairs(questData.choiceRewardItems) do
                local itemID = tonumber(reward.id)
                if itemID and itemID > 0 and not choiceRewardKeys[itemID] then
                    choiceRewardKeys[itemID] = true
                    table.insert(result.choiceRewards, {
                        id = itemID,
                        name = reward.name or GetItemName(itemID),
                        count = tonumber(reward.count) or 1,
                    })
                end
            end
        end

        if type(questData.giverLocations) == "table" then
            for _, location in ipairs(questData.giverLocations) do
                AddLocation(location)
            end
        end

        if type(questData.previousQuests) == "table" then
            for _, related in ipairs(questData.previousQuests) do
                local entry=ForeverBrowser_QuestRelation225(related)
                if entry then table.insert(result.previousQuests,entry) end
            end
        end

        if type(questData.nextQuests) == "table" then
            for _, related in ipairs(questData.nextQuests) do
                local entry=ForeverBrowser_QuestRelation225(related)
                if entry then table.insert(result.nextQuests,entry) end
            end
        end
    end

    --------------------------------------------------
    -- ITEM REWARD SOURCES
    --------------------------------------------------
    -- Keep scanning item sources for reward items and as a fallback
    -- for older generated source files.
    if ForeverSourceData.items and #result.rewards == 0 then
        for _,match in ipairs(ForeverBrowser_QuestRewardSources225(questID)) do
            local rawItemID,itemData=match.id,match.item
            if itemData and type(itemData.sources) == "table" then
                local itemID = tonumber(rawItemID) or tonumber(itemData.id)

                for _, source in ipairs(itemData.sources) do
                    if type(source)=="table"
                        and tostring(source.type or "") == "quest"
                        and tonumber(source.id) == questID then

                        result.name = result.name or source.name
                        result.level = result.level or source.questLevel
                        result.faction = result.faction or source.questFaction
                        result.giverID = result.giverID or tonumber(source.giverID)
                        result.giverName = result.giverName or source.giverName

                        if type(source.giverLocations) == "table" then
                            for _, location in ipairs(source.giverLocations) do
                                AddLocation(location)
                            end
                        end

                        if source.uiMapID and source.x ~= nil and source.y ~= nil then
                            AddLocation({
                                uiMapID = source.uiMapID,
                                x = source.x,
                                y = source.y,
                                zone = source.zone,
                            })
                        end

                        if #result.previousQuests == 0
                            and type(source.previousQuests) == "table" then
                            for _, related in ipairs(source.previousQuests) do
                                local entry=ForeverBrowser_QuestRelation225(related)
                                if entry then table.insert(result.previousQuests,entry) end
                            end
                        end

                        if #result.nextQuests == 0
                            and type(source.nextQuests) == "table" then
                            for _, related in ipairs(source.nextQuests) do
                                local entry=ForeverBrowser_QuestRelation225(related)
                                if entry then table.insert(result.nextQuests,entry) end
                            end
                        end

                        -- Respect explicit choices when using item sources as a fallback.
                        if itemID then
                            local isChoice = source.choiceReward == true or choiceRewardKeys[itemID]
                            local keys = isChoice and choiceRewardKeys or rewardKeys
                            local list = isChoice and result.choiceRewards or result.rewards
                            if not keys[itemID] then
                                keys[itemID] = true
                                table.insert(list, {
                                    id = itemID,
                                    name = itemData.name or GetItemName(itemID),
                                })
                            end
                        end
                    end
                end
            end
        end
    end

    if not result.name or tostring(result.name) == "" then
        result.name = "Quest " .. tostring(questID)
    end

    table.sort(result.rewards, function(a, b)
        return tostring(a.name or "") < tostring(b.name or "")
    end)

    table.sort(result.choiceRewards, function(a, b)
        return tostring(a.name or "") < tostring(b.name or "")
    end)

    return result
end

-- Expose the scoped lookup for earlier dungeon overview builders.
ForeverBrowser_FindQuestSourceData = FindQuestSourceData

local function FormatQuestMoney(copper)
    copper = math.floor(tonumber(copper) or 0)

    if copper <= 0 then
        return nil
    end

    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper - (gold * 10000)) / 100)
    local copperOnly =
        copper - (gold * 10000) - (silver * 100)

    local parts = {}

    if gold > 0 then
        table.insert(parts, tostring(gold) .. " Gold")
    end

    if silver > 0 then
        table.insert(parts, tostring(silver) .. " Silver")
    end

    if copperOnly > 0 or #parts == 0 then
        table.insert(parts, tostring(copperOnly) .. " Copper")
    end

    return table.concat(parts, "  ")
end

local function BuildQuestPage(questID)
    if type(ForeverBrowser_QuestRecent189)=="function" then ForeverBrowser_QuestRecent189(questID) end
    ForeverBrowserCurrentQuestBrowseFilter = nil
    ClearPage()

    questID = tonumber(questID)

    if not questID then
        return
    end

    local quest =
        FindQuestSourceData(questID)

    local questName =
        quest
        and quest.name
        or ("Quest " .. tostring(questID))

    --------------------------------------------------
    -- QUEST HERO
    --------------------------------------------------

    local hero = CreateFrame("Frame", nil, PageContent)
    hero:SetSize(790, 128)
    hero:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, -22)
    CreateSolidBackground(hero, 0.022, 0.028, 0.045, 1)

    local accent = hero:CreateTexture(nil, "ARTWORK")
    accent:SetTexture("Interface\\Buttons\\WHITE8X8")
    accent:SetVertexColor(0.82, 0.62, 0.18, 0.95)
    accent:SetPoint("TOPLEFT", hero, "TOPLEFT", 0, 0)
    accent:SetPoint("BOTTOMLEFT", hero, "BOTTOMLEFT", 0, 0)
    accent:SetWidth(4)

    local questIcon = hero:CreateTexture(nil, "ARTWORK")
    questIcon:SetSize(58, 58)
    questIcon:SetPoint("TOPLEFT", hero, "TOPLEFT", 18, -18)
    questIcon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")

    local title = CreateLabel(
        hero,
        questName,
        23,
        {1, 0.82, 0.25, 1}
    )
    title:SetPoint("TOPLEFT", hero, "TOPLEFT", 92, -18)
    title:SetWidth(545)
    title:SetJustifyH("LEFT")

    local metaParts = {}
    if quest and quest.level and tostring(quest.level) ~= "" then
        table.insert(metaParts, "Level " .. tostring(quest.level))
    end
    if quest and quest.zone and tostring(quest.zone) ~= "" then
        table.insert(metaParts, tostring(quest.zone))
    end
    if quest and quest.faction and tostring(quest.faction) ~= "" then
        table.insert(metaParts, tostring(quest.faction))
    end

    local meta = CreateLabel(
        hero,
        #metaParts > 0 and table.concat(metaParts, "   |   ") or "Quest Database",
        12,
        {0.70, 0.73, 0.80, 1}
    )
    meta:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -9)

    local idText = CreateLabel(
        hero,
        "QUEST ID  " .. tostring(questID),
        10,
        {0.45, 0.48, 0.56, 1}
    )
    idText:SetPoint("BOTTOMRIGHT", hero, "BOTTOMRIGHT", -14, 10)

    local questCompleted, questInLog =
        ForeverBrowser_GetQuestPlayerStatus(questID)

    if questCompleted then
        local statusBadge = CreateLabel(
            hero, "COMPLETED", 13, {0.42, 0.90, 0.50, 1}
        )
        statusBadge:SetPoint("TOPRIGHT", hero, "TOPRIGHT", -14, -18)

    elseif questInLog then
        local statusBadge = CreateLabel(
            hero, "IN PROGRESS", 13, {0.38, 0.78, 1.00, 1}
        )
        statusBadge:SetPoint("TOPRIGHT", hero, "TOPRIGHT", -14, -18)
    end

    local sourceText =
        quest and quest.dataSource and tostring(quest.dataSource) or "Source not recorded"
    local source = CreateLabel(
        hero,
        sourceText,
        10,
        {0.64, 0.55, 0.35, 1}
    )
    source:SetPoint("BOTTOMLEFT", hero, "BOTTOMLEFT", 92, 10)

    local y = -170

    --------------------------------------------------
    -- QUEST OVERVIEW
    --------------------------------------------------

    local infoTitle = CreateLabel(
        PageContent,
        "QUEST OVERVIEW",
        14,
        {0.92, 0.76, 0.25, 1}
    )
    infoTitle:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
    y = y - 26

    local info = CreateFrame("Frame", nil, PageContent)
    info:SetSize(790, 64)
    info:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
    CreateSolidBackground(info, 0.025, 0.03, 0.05, 1)

    local overview = {}
    table.insert(overview, "ID: " .. tostring(questID))
    if quest and quest.level and tostring(quest.level) ~= "" then
        table.insert(overview, "Level: " .. tostring(quest.level))
    end
    if quest and quest.zone and tostring(quest.zone) ~= "" then
        table.insert(overview, "Zone: " .. tostring(quest.zone))
    end
    if quest and quest.faction and tostring(quest.faction) ~= "" then
        table.insert(overview, "Faction: " .. tostring(quest.faction))
    end

    local overviewText = CreateLabel(
        info,
        table.concat(overview, "    |    "),
        12,
        {0.82, 0.83, 0.88, 1}
    )
    overviewText:SetPoint("TOPLEFT", info, "TOPLEFT", 14, -13)
    overviewText:SetWidth(750)
    overviewText:SetJustifyH("LEFT")

    local relationSummary = CreateLabel(
        info,
        "Starters: " .. tostring(#(quest and quest.npcStarters or {}))
            .. "    Turn-ins: " .. tostring(#(quest and quest.npcFinishers or {}))
            .. "    Rewards: " .. tostring(#(quest and quest.rewards or {})),
        10,
        {0.52, 0.58, 0.70, 1}
    )
    relationSummary:SetPoint("TOPLEFT", overviewText, "BOTTOMLEFT", 0, -10)

    y = y - 82

    --------------------------------------------------
    -- DESCRIPTION / OBJECTIVES
    --------------------------------------------------

    local function AddQuestTextSection(sectionTitle, bodyText)
        if not bodyText or tostring(bodyText) == "" then return end

        local heading = CreateLabel(
            PageContent,
            sectionTitle,
            14,
            {0.92, 0.76, 0.25, 1}
        )
        heading:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
        y = y - 25

        local panel = CreateFrame("Frame", nil, PageContent)
        panel:SetSize(790, 82)
        panel:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
        CreateSolidBackground(panel, 0.022, 0.027, 0.042, 1)

        local body = CreateLabel(
            panel,
            tostring(bodyText),
            12,
            {0.82, 0.83, 0.88, 1}
        )
        body:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -12)
        body:SetWidth(758)
        body:SetJustifyH("LEFT")
        body:SetJustifyV("TOP")

        y = y - 96
    end

    AddQuestTextSection("OBJECTIVES", quest and quest.objectivesText)
    AddQuestTextSection("DESCRIPTION", quest and quest.description)

    --------------------------------------------------
    -- REQUIRED / PROVIDED ITEMS
    --------------------------------------------------

    local function AddQuestItemStrip(sectionTitle, items)
        if type(items) ~= "table" or #items == 0 then return end

        local heading = CreateLabel(
            PageContent,
            sectionTitle,
            14,
            {0.92, 0.76, 0.25, 1}
        )
        heading:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
        y = y - 26

        for _, entry in ipairs(items) do
            local iid = tonumber(entry.id)
            if iid then
                local row = CreateFrame("Button", nil, PageContent)
                row:SetSize(380, 38)
                row:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
                CreateSolidBackground(row, 0.025, 0.03, 0.05, 1)

                local icon = row:CreateTexture(nil, "ARTWORK")
                icon:SetSize(30, 30)
                icon:SetPoint("LEFT", row, "LEFT", 4, 0)
                icon:SetTexture(GetItemIcon(iid, GetAnyItem(iid)))

                local label = CreateLabel(
                    row,
                    tostring(entry.name or GetItemName(iid) or ("Item " .. tostring(iid)))
                        .. ((tonumber(entry.count) or 1) > 1 and ("  x" .. tostring(entry.count)) or ""),
                    12,
                    {0.82, 0.86, 0.94, 1}
                )
                label:SetPoint("LEFT", icon, "RIGHT", 9, 0)

                row:SetScript("OnClick", function()
                    Navigate("forever://item/" .. tostring(iid))
                end)
                row:SetScript("OnEnter", function(self) ShowItemTooltip(iid, self) end)
                row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

                y = y - 43
            end
        end
        y = y - 5
    end

    AddQuestItemStrip("REQUIRED ITEMS", quest and quest.requiredItems)
    AddQuestItemStrip("PROVIDED ITEMS", quest and quest.providedItems)

    --------------------------------------------------
    -- QUEST START / TURN-IN RELATIONSHIPS
    --------------------------------------------------

    local npcStarters = quest and quest.npcStarters or {}
    local npcFinishers = quest and quest.npcFinishers or {}
    local objectStarters = quest and quest.objectStarters or {}
    local objectFinishers = quest and quest.objectFinishers or {}

    -- Compatibility with older source files.
    if #npcStarters == 0 and quest and quest.giverID then
        table.insert(npcStarters, {
            id = quest.giverID,
            name = quest.giverName,
            locations = quest.giverLocations,
        })
    end

    local function AddRelationHeading(text)
        local heading = CreateLabel(
            PageContent,
            text,
            14,
            {0.92, 0.76, 0.25, 1}
        )
        heading:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
        y = y - 30
    end

    local function AddNPCLocationRows(entry, label)
        local locations = entry and entry.locations or {}
        if type(locations) ~= "table" or #locations == 0 then
            return
        end

        if #locations > 1 then
            local showAll = CreateButton(
                PageContent,
                "SHOW LOCATIONS",
                135,
                24
            )
            showAll:SetPoint(
                "TOPRIGHT",
                PageContent,
                "TOPRIGHT",
                -25,
                y + 5
            )
            showAll:SetScript(
                "OnClick",
                function()
                    ShowAllForeverBrowserLocations(locations)
                end
            )
        end

        local locationTitle = CreateLabel(
            PageContent,
            tostring(label) .. " LOCATIONS  (" .. tostring(#locations) .. ")",
            13,
            {0.85, 0.72, 0.32, 1}
        )
        locationTitle:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 27, y)
        y = y - 26

        for _, location in ipairs(locations) do
            local mapID = tonumber(location.uiMapID)
            local x = tonumber(location.x)
            local mapY = tonumber(location.y)

            if mapID and x and mapY then
                local displayX = x
                local displayY = mapY

                if displayX <= 1 then displayX = displayX * 100 end
                if displayY <= 1 then displayY = displayY * 100 end

                local row = CreateFrame("Frame", nil, PageContent)
                row:SetSize(790, 32)
                row:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
                CreateSolidBackground(row, 0.025, 0.03, 0.05, 1)

                local zoneName =
                    GetAutomaticMapName(mapID)
                    or ("Map " .. tostring(mapID))

                local locationText = CreateLabel(
                    row,
                    zoneName
                        .. "  "
                        .. string.format("%.1f, %.1f", displayX, displayY),
                    12,
                    {0.88, 0.88, 0.92, 1}
                )
                locationText:SetPoint("LEFT", row, "LEFT", 12, 0)

                local mapButton = CreateButton(
                    row,
                    "MAP",
                    82,
                    22
                )
                mapButton:SetPoint("RIGHT", row, "RIGHT", -8, 0)
                mapButton:SetScript(
                    "OnClick",
                    function()
                        ShowForeverBrowserMapMarker(
                            mapID,
                            x,
                            mapY,
                            entry.name or questName
                        )
                    end
                )

                y = y - 37
            end
        end

        y = y - 8
    end

    local function AddNPCRelation(entry, locationLabel)
        local npcID = tonumber(entry and entry.id)
        if not npcID then return end

        local row = CreateFrame("Button", nil, PageContent)
        row:SetSize(790, 42)
        row:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
        CreateSolidBackground(row, 0.025, 0.03, 0.05, 1)

        local relationAccent = row:CreateTexture(nil, "ARTWORK")
        relationAccent:SetTexture("Interface\\Buttons\\WHITE8X8")
        relationAccent:SetVertexColor(0.30, 0.62, 0.92, 0.95)
        relationAccent:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        relationAccent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
        relationAccent:SetWidth(3)

        local name = CreateLabel(
            row,
            tostring(entry.name or ("NPC " .. tostring(npcID))),
            13,
            {0.45, 0.75, 1, 1}
        )
        name:SetPoint("LEFT", row, "LEFT", 12, 0)

        local idText = CreateLabel(
            row,
            "NPC ID: " .. tostring(npcID),
            10,
            {0.68, 0.64, 0.56, 1}
        )
        idText:SetPoint("RIGHT", row, "RIGHT", -12, 0)

        row:SetScript(
            "OnClick",
            function()
                Navigate("forever://npc/" .. tostring(npcID))
            end
        )

        y = y - 50
        AddNPCLocationRows(entry, locationLabel)
    end

    local function AddObjectRelation(entry)
        local objectID = tonumber(entry and entry.id)
        if not objectID then return end

        local row = CreateFrame("Frame", nil, PageContent)
        row:SetSize(790, 38)
        row:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
        CreateSolidBackground(row, 0.025, 0.03, 0.05, 1)

        local name = CreateLabel(
            row,
            tostring(entry.name or ("Object " .. tostring(objectID))),
            13,
            {0.75, 0.85, 1, 1}
        )
        name:SetPoint("LEFT", row, "LEFT", 12, 0)

        local idText = CreateLabel(
            row,
            "OBJECT ID: " .. tostring(objectID),
            10,
            {0.68, 0.64, 0.56, 1}
        )
        idText:SetPoint("RIGHT", row, "RIGHT", -12, 0)

        y = y - 46
    end

    AddRelationHeading("|cffc79a3b◆|r  QUEST STARTS FROM")

    if #npcStarters == 0 and #objectStarters == 0 then
        local none = CreateLabel(
            PageContent,
            "No known quest starter.",
            12,
            {0.68, 0.64, 0.56, 1}
        )
        none:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 27, y)
        y = y - 34
    else
        for _, entry in ipairs(npcStarters) do
            AddNPCRelation(entry, "STARTER")
        end
        for _, entry in ipairs(objectStarters) do
            AddObjectRelation(entry)
        end
    end

    y = y - 10
    AddRelationHeading("|cffc79a3b◆|r  QUEST TURN-IN")

    if #npcFinishers == 0 and #objectFinishers == 0 then
        local none = CreateLabel(
            PageContent,
            "No known quest turn-in.",
            12,
            {0.68, 0.64, 0.56, 1}
        )
        none:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 27, y)
        y = y - 34
    else
        for _, entry in ipairs(npcFinishers) do
            AddNPCRelation(entry, "TURN-IN")
        end
        for _, entry in ipairs(objectFinishers) do
            AddObjectRelation(entry)
        end
    end

    y = y - 15

    --------------------------------------------------
    -- QUEST CHAIN
    --------------------------------------------------

    local chainTitle = CreateLabel(
        PageContent,
        "QUEST CHAIN",
        14,
        {0.92, 0.76, 0.25, 1}
    )
    chainTitle:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
    y = y - 28

    local currentChain = CreateFrame("Frame", nil, PageContent)
    currentChain:SetSize(790, 38)
    currentChain:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
    CreateSolidBackground(currentChain, 0.045, 0.038, 0.022, 1)

    local currentChainText = CreateLabel(
        currentChain,
        "CURRENT  >  " .. tostring(questName),
        12,
        {1, 0.82, 0.25, 1}
    )
    currentChainText:SetPoint("LEFT", currentChain, "LEFT", 12, 0)
    y = y - 48


    local chainTitle =
        CreateLabel(
            PageContent,
            "QUEST CHAIN",
            14,
            {0.92, 0.76, 0.25, 1}
        )

    chainTitle:SetPoint(
        "TOPLEFT",
        PageContent,
        "TOPLEFT",
        25,
        y
    )

    y = y - 30

    local function CreateChainSection(labelText, chain)
        local label =
            CreateLabel(
                PageContent,
                labelText,
                11,
                {0.78, 0.71, 0.58, 1}
            )

        label:SetPoint(
            "TOPLEFT",
            PageContent,
            "TOPLEFT",
            27,
            y
        )

        y = y - 20

        if not chain
            or #chain == 0 then

            local none =
                CreateLabel(
                    PageContent,
                    "None known",
                    12,
                    {0.68, 0.64, 0.56, 1}
                )

            none:SetPoint(
                "TOPLEFT",
                PageContent,
                "TOPLEFT",
                40,
                y
            )

            y = y - 24
            return
        end

        for _, related in ipairs(chain) do
            local relatedID =
                tonumber(related.id)

            local button =
                CreateFrame(
                    "Button",
                    nil,
                    PageContent
                )

            button:SetSize(760, 24)
            button:SetPoint(
                "TOPLEFT",
                PageContent,
                "TOPLEFT",
                35,
                y
            )

            local relatedText =
                CreateLabel(
                    button,
                    "|cffffd100["
                        .. tostring(
                            related.name
                            or ("Quest " .. tostring(relatedID or "?"))
                        )
                        .. "]|r"
                        .. "  |cff73bfff["
                        .. tostring(relatedID or "?")
                        .. "]|r",
                    12,
                    {1, 1, 1, 1}
                )

            relatedText:SetPoint(
                "LEFT",
                button,
                "LEFT",
                0,
                0
            )

            if relatedID then
                -- Keep a dedicated ID for this row so every quest-chain
                -- button always navigates to its own quest.
                local savedRelatedID = relatedID

                button:EnableMouse(true)
                button:RegisterForClicks("LeftButtonUp")

                if button.SetFrameLevel
                    and PageContent.GetFrameLevel then
                    button:SetFrameLevel(
                        PageContent:GetFrameLevel() + 20
                    )
                end

                button:SetScript(
                    "OnClick",
                    function()
                        Navigate(
                            "forever://quest/"
                            .. tostring(savedRelatedID)
                        )
                    end
                )

                button:SetScript(
                    "OnEnter",
                    function()
                        relatedText:SetTextColor(1, 1, 1, 1)
                    end
                )

                button:SetScript(
                    "OnLeave",
                    function()
                        relatedText:SetTextColor(1, 1, 1, 1)
                    end
                )
            end

            y = y - 26
        end
    end

    CreateChainSection(
        "PREVIOUS QUEST",
        quest and quest.previousQuests or {}
    )

    y = y - 6

    CreateChainSection(
        "NEXT QUEST",
        quest and quest.nextQuests or {}
    )

    y = y - 15

    --------------------------------------------------
    -- WOW-STYLE QUEST REWARDS
    --------------------------------------------------

    local rewards = quest and quest.rewards or {}
    local choiceRewards = quest and quest.choiceRewards or {}
    local rewardMoney = quest and tonumber(quest.rewardMoney) or 0
    local rewardMoneyMaxLevel = quest and tonumber(quest.rewardMoneyMaxLevel) or 0
    local rewardXP = quest and tonumber(quest.rewardXP) or 0

    -- Direct source-data fallback for XP. This intentionally bypasses
    -- normalization/fallback quest paths because generated Classic quest
    -- records contain the authoritative rewardXP value.
    if rewardXP <= 0
        and ForeverSourceData
        and ForeverSourceData.quests then

        local directQuest =
            ForeverSourceData.quests[questID]
            or ForeverSourceData.quests[tostring(questID)]

        if directQuest then
            rewardXP = tonumber(directQuest.rewardXP) or 0
        end
    end

    local function AddRewardHeading(text)
        local heading = CreateLabel(
            PageContent,
            text,
            13,
            {0.92, 0.76, 0.25, 1}
        )
        heading:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
        y = y - 24
    end

    local function AddRewardBox(reward)
        local itemID = tonumber(reward and reward.id)
        if not itemID then
            return
        end

        local item = GetAnyItem(itemID)
        local quality = GetQuality(itemID, item)
        local color = QualityColors and QualityColors[quality] or {0.92, 0.92, 0.96, 1}
        local count = tonumber(reward.count) or 1
        local displayName = reward.name or GetItemName(itemID) or ("Item " .. tostring(itemID))

        local row = CreateFrame("Button", nil, PageContent)
        row:SetSize(360, 44)
        row:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
        CreateSolidBackground(row, 0.055, 0.045, 0.03, 0.98)

        local iconFrame = CreateFrame("Frame", nil, row)
        iconFrame:SetSize(38, 38)
        iconFrame:SetPoint("LEFT", row, "LEFT", 3, 0)
        CreateSolidBackground(iconFrame, 0, 0, 0, 1)

        local icon = iconFrame:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 2, -2)
        icon:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -2, 2)
        icon:SetTexture(GetItemIcon(itemID, item))

        if count > 1 then
            local countText = CreateLabel(
                iconFrame,
                tostring(count),
                12,
                {1, 1, 1, 1}
            )
            countText:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -3, 2)
        end

        local itemName = CreateLabel(
            row,
            tostring(displayName),
            13,
            color
        )
        itemName:SetPoint("LEFT", iconFrame, "RIGHT", 10, 0)
        itemName:SetPoint("RIGHT", row, "RIGHT", -10, 0)

        if itemName.SetJustifyH then
            itemName:SetJustifyH("LEFT")
        end

        row:SetScript(
            "OnClick",
            function()
                if IsShiftLinkClick() then
                    LinkItemToChat(itemID)
                else
                    Navigate("forever://item/" .. tostring(itemID))
                end
            end
        )

        row:SetScript(
            "OnEnter",
            function(self)
                ShowItemTooltip(itemID, self)
            end
        )

        row:SetScript(
            "OnLeave",
            function()
                if GameTooltip then
                    GameTooltip:Hide()
                end
            end
        )

        y = y - 49
    end

    local function FormatRewardNumber(value)
        local number = math.floor(tonumber(value) or 0)
        local text = tostring(number)

        while true do
            local changed
            text, changed = string.gsub(
                text,
                "^(-?%d+)(%d%d%d)",
                "%1,%2"
            )

            if changed == 0 then
                break
            end
        end

        return text
    end

    local function AddXPBox(xp)
        xp = math.floor(tonumber(xp) or 0)

        if xp <= 0 then
            return
        end

        local row = CreateFrame("Frame", nil, PageContent)
        row:SetSize(360, 44)
        row:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
        CreateSolidBackground(row, 0.055, 0.045, 0.03, 0.98)

        local iconFrame = CreateFrame("Frame", nil, row)
        iconFrame:SetSize(38, 38)
        iconFrame:SetPoint("LEFT", row, "LEFT", 3, 0)
        CreateSolidBackground(iconFrame, 0, 0, 0, 1)

        local icon = iconFrame:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 2, -2)
        icon:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -2, 2)
        icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")

        local xpText = CreateLabel(
            row,
            "|cffb58cff" .. FormatRewardNumber(xp) .. " XP|r",
            13,
            {1, 1, 1, 1}
        )
        xpText:SetPoint("LEFT", iconFrame, "RIGHT", 10, 0)

        y = y - 49
    end

    local function AddMoneyBox(label, copper)
        copper = tonumber(copper) or 0

        if copper <= 0 then
            return
        end

        local row = CreateFrame("Frame", nil, PageContent)
        row:SetSize(360, 38)
        row:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
        CreateSolidBackground(row, 0.055, 0.045, 0.03, 0.98)

        local moneyText = CreateLabel(
            row,
            "|cff73bfff" .. tostring(label) .. ":|r  |cffffd100" .. tostring(FormatQuestMoney(copper)) .. "|r",
            12,
            {1, 1, 1, 1}
        )
        moneyText:SetPoint("LEFT", row, "LEFT", 10, 0)

        y = y - 43
    end

    if rewardXP > 0 or #rewards > 0 or rewardMoney > 0 then
        AddRewardHeading("YOU WILL RECEIVE:")

        if rewardXP > 0 then
            AddXPBox(rewardXP)
        end

        for _, reward in ipairs(rewards) do
            AddRewardBox(reward)
        end

        if rewardMoney > 0 then
            AddMoneyBox("Money", rewardMoney)
        end

        y = y - 8
    end

    if #choiceRewards > 0 then
        AddRewardHeading("YOU WILL ALSO BE ABLE TO CHOOSE ONE OF:")

        for _, reward in ipairs(choiceRewards) do
            AddRewardBox(reward)
        end

        y = y - 8
    end

    if rewardMoneyMaxLevel > 0 then
        AddRewardHeading("AT MAX LEVEL:")
        AddMoneyBox("Bonus", rewardMoneyMaxLevel)
        y = y - 8
    end

    if quest
        and type(quest.reputationRewards) == "table"
        and #quest.reputationRewards > 0 then

        AddRewardHeading("REPUTATION")

        for _, repEntry in ipairs(quest.reputationRewards) do
            local repName =
                repEntry.name
                or repEntry.factionName
                or repEntry.faction
                or "Reputation"
            local amount =
                repEntry.amount
                or repEntry.value
                or repEntry.points

            local row = CreateFrame("Frame", nil, PageContent)
            row:SetSize(360, 36)
            row:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
            CreateSolidBackground(row, 0.04, 0.035, 0.055, 0.98)

            local text = CreateLabel(
                row,
                tostring(repName)
                    .. (amount and ("  +" .. tostring(amount)) or ""),
                12,
                {0.76, 0.62, 1.00, 1}
            )
            text:SetPoint("LEFT", row, "LEFT", 10, 0)
            y = y - 41
        end
        y = y - 8
    end

    --------------------------------------------------
    -- DATABASE FOOTER
    --------------------------------------------------

    local footer = CreateLabel(
        PageContent,
        "Quest ID " .. tostring(questID)
            .. "   |   "
            .. (quest and quest.dataSource and tostring(quest.dataSource) or "ForeverSourceData")
            .. "   |   ForeverBrowser",
        10,
        {0.44, 0.47, 0.54, 1}
    )
    footer:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
    y = y - 28

    -- rewardXP is generated from the verified Classic quest reward data.

    PageContent:SetHeight(
        math.max(
            650,
            math.abs(y) + 80
        )
    )
end



--------------------------------------------------
-- QUEST DATABASE
--------------------------------------------------


-- Quest tools share the Codex banner without changing their data/render logic.
function ForeverBrowser_QuestSummary193(label)
    local paper=CreateFrame("Frame",nil,PageContent)
    paper:SetSize(735,32)
    local point,relative,relativePoint,x,y=label:GetPoint(1)
    paper:SetPoint(point,relative,relativePoint,x,(y or 0)+8)
    ForeverBrowser_AchievementPaper(paper,true)
    label:SetParent(paper)
    label:ClearAllPoints()
    label:SetPoint(point,paper,point,point=="TOPLEFT" and 12 or 0,-8)
    label:SetWidth(700)
    label:SetHeight(12)
    label:SetJustifyH(point=="TOPLEFT" and "LEFT" or "CENTER")
    label:SetTextColor(0.31,0.22,0.10,1)
    return paper
end

function ForeverBrowser_QuestBanner193(title, subtitle, iconPath)
    local hero=CreateFrame("Frame",nil,PageContent)
    hero:SetSize(790,170) hero:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,-62)
    CreateSolidBackground(hero,0.035,0.025,0.014,1)
    ForeverBrowser_AchievementBorder(hero,true)
    local emblem=hero:CreateTexture(nil,"ARTWORK") emblem:SetSize(62,62)
    emblem:SetPoint("TOPLEFT",hero,"TOPLEFT",20,-23) emblem:SetTexture(iconPath)
    title:ClearAllPoints() title:SetPoint("TOPLEFT",hero,"TOPLEFT",98,-22)
    title:SetFont("Fonts\\FRIZQT__.TTF",26,"") title:SetTextColor(1,0.82,0.28,1)
    subtitle:ClearAllPoints() subtitle:SetPoint("TOPLEFT",hero,"TOPLEFT",98,-62)
    subtitle:SetWidth(660) subtitle:SetJustifyH("LEFT") subtitle:SetTextColor(0.87,0.81,0.67,1)
    return hero
end

function ForeverBrowser_BuildQuestRelationshipsPage()
    ClearPage()
    PageContent:SetHeight(900)

    ForeverBrowserRelationshipRecent = ForeverBrowserRelationshipRecent or {}
    ForeverBrowserRelationshipHistory = ForeverBrowserRelationshipHistory or {}
    ForeverBrowserRelationshipHistoryIndex = ForeverBrowserRelationshipHistoryIndex or 0
    ForeverBrowserRelationshipBrowsePage = ForeverBrowserRelationshipBrowsePage or 1

    local title=ForeverBrowser_AchievementLabel(PageContent,"QUEST RELATIONSHIPS",24,{0.95,0.68,0.26,1})
    title:SetPoint("TOP",PageContent,"TOP",0,-24)

    local subtitle=ForeverBrowser_AchievementLabel(
        PageContent,
        "Search a quest to explore its chain, progress, NPCs, and related quests.",
        11,{0.58,0.62,0.70,1}
    )
    subtitle:SetPoint("TOP",title,"BOTTOM",0,-7)

    local hero=ForeverBrowser_QuestBanner193(title,subtitle,"Interface\\Icons\\INV_Misc_Note_05")

    local searchBox=CreateFrame("EditBox",nil,PageContent,"InputBoxTemplate")
    searchBox:SetSize(315,28)
    searchBox:SetPoint("TOPLEFT",hero,"TOPLEFT",24,-106)
    searchBox:SetAutoFocus(false)
    searchBox:SetFontObject(ChatFontNormal)

    local searchButton=ForeverBrowser_ItemButton190(PageContent,"SEARCH",88,26)
    searchButton:SetPoint("LEFT",searchBox,"RIGHT",10,0)

    local browseChainsButton=ForeverBrowser_ItemButton190(PageContent,"BROWSE CHAINS",112,26)
    browseChainsButton:SetPoint("LEFT",searchButton,"RIGHT",8,0)

    local back=ForeverBrowser_ItemButton190(PageContent,"< QUEST DATABASE",145,25)
    back:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,-20)
    back:SetScript("OnClick",function() Navigate("forever://quests") end)

    local summary=ForeverBrowser_AchievementLabel(PageContent,"SEARCH FOR A QUEST TO BEGIN",10,{0.48,0.53,0.62,1})
    summary:SetPoint("TOP",hero,"BOTTOM",0,-14)

    local overview=ForeverBrowser_AchievementLabel(PageContent,"",9,{0.42,0.47,0.55,1})
    overview:SetPoint("TOP",summary,"BOTTOM",0,-5)
    local summaryPaper=ForeverBrowser_QuestSummary193(summary)
    overview:SetParent(summaryPaper)
    overview:SetTextColor(0.38,0.28,0.15,1)

    local results=CreateFrame("Frame",nil,PageContent)
    results:SetSize(700,410)
    results:SetPoint("TOP",overview,"BOTTOM",0,-12)
    results._children={}

    local function Wipe()
        PageContent:SetHeight(900)
        for _,child in ipairs(results._children) do
            if child and child.Hide then child:Hide() end
        end
        results._children={}
    end

    local function Keep(child)
        table.insert(results._children,child)
        return child
    end

    local function QuestRecord(id)
        id=tonumber(id)
        if not id then return nil,nil end
        local quests=ForeverSourceData and ForeverSourceData.quests or {}
        local q=quests[id] or quests[tostring(id)]
        if not q then return nil,nil end
        if type(q)=="table" then
            return q.name or q.title or ("Quest "..id),q
        end
        return tostring(q),q
    end

    local function FirstValue(q,fields)
        if type(q)~="table" then return nil end
        for _,field in ipairs(fields) do
            local value=q[field]
            if value~=nil and value~="" then return value end
        end
        return nil
    end

    local function DisplayValue(value)
        if type(value)=="string" or type(value)=="number" then
            return tostring(value)
        elseif type(value)=="table" then
            return tostring(value.name or value.title or value.zone or value.id or "")
        end
        return ""
    end

    local function AddIDs(out,value)
        if type(value)=="number" or type(value)=="string" then
            local n=tonumber(value)
            if n then table.insert(out,n) end
        elseif type(value)=="table" then
            for k,v in pairs(value) do
                local n=nil
                if type(v)=="number" or type(v)=="string" then
                    n=tonumber(v)
                elseif type(v)=="table" then
                    n=tonumber(v.id or v.questID or v.questId)
                end
                if not n and type(k)=="number" and v==true then n=k end
                if n then table.insert(out,n) end
            end
        end
    end

    local function Relations(q)
        local before,after={},{}
        if type(q)~="table" then return before,after end
        AddIDs(before,q.previousQuest)
        AddIDs(before,q.previousQuestID)
        AddIDs(before,q.prevQuest)
        AddIDs(before,q.prevQuestID)
        AddIDs(before,q.prerequisiteQuest)
        AddIDs(before,q.prerequisiteQuestID)
        AddIDs(before,q.requiredQuest)
        AddIDs(before,q.requiredQuestID)
        AddIDs(before,q.previousQuests)
        AddIDs(before,q.prerequisites)
        AddIDs(before,q.requires)
        AddIDs(after,q.nextQuest)
        AddIDs(after,q.nextQuestID)
        AddIDs(after,q.followupQuest)
        AddIDs(after,q.followupQuestID)
        AddIDs(after,q.nextQuests)
        AddIDs(after,q.followups)
        return before,after
    end

    local function Unique(list)
        local seen,out={},{}
        for _,id in ipairs(list) do
            id=tonumber(id)
            if id and not seen[id] then
                seen[id]=true
                table.insert(out,id)
            end
        end
        return out
    end

    local function InferRelations(id,q)
        local before,after=Relations(q)
        local quests=ForeverSourceData and ForeverSourceData.quests or {}
        for key,other in pairs(quests) do
            local otherID=tonumber(key)
            if not otherID and type(other)=="table" then otherID=tonumber(other.id) end
            if otherID and otherID~=id and type(other)=="table" then
                local ob,oa=Relations(other)
                for _,linked in ipairs(oa) do
                    if tonumber(linked)==id then table.insert(before,otherID) end
                end
                for _,linked in ipairs(ob) do
                    if tonumber(linked)==id then table.insert(after,otherID) end
                end
            end
        end
        return Unique(before),Unique(after)
    end

    local function QuestStatus(id)
        if type(ForeverBrowser_GetQuestPlayerStatus)=="function" then
            local ok,status=pcall(ForeverBrowser_GetQuestPlayerStatus,id)
            if ok then return status end
        end
        return nil
    end

    local function NPCName(value)
        if type(value)=="table" then
            if value.name then return tostring(value.name) end
            value=value.id or value.npcID or value.npcId
        end
        local id=tonumber(value)
        if id then
            local npcs=ForeverSourceData and ForeverSourceData.npcs or {}
            local npc=npcs[id] or npcs[tostring(id)]
            if type(npc)=="table" then return tostring(npc.name or ("NPC "..id)) end
            if type(npc)=="string" then return npc end
            return "NPC "..id
        end
        if value then return tostring(value) end
        return nil
    end

    local function QuestMeta(q)
        if type(q)~="table" then return "" end
        local pieces={}
        local level=FirstValue(q,{"level","questLevel","lvl"})
        local zone=FirstValue(q,{"zone","zoneName","area","areaName"})
        if level then table.insert(pieces,"Level "..DisplayValue(level)) end
        if zone then table.insert(pieces,DisplayValue(zone)) end
        return table.concat(pieces,"  •  ")
    end

    local function QuestNPCs(q)
        if type(q)~="table" then return nil end
        local starter=FirstValue(q,{
            "startNPC","starterNPC","startNpc","questGiver","giverNPC","startsFrom"
        })
        local finisher=FirstValue(q,{
            "endNPC","turnInNPC","endNpc","questEnder","endsAt","turnIn"
        })
        starter=NPCName(starter)
        finisher=NPCName(finisher)
        local parts={}
        if starter and starter~="" then table.insert(parts,"Starts: "..starter) end
        if finisher and finisher~="" then table.insert(parts,"Ends: "..finisher) end
        if #parts==0 then return nil end
        return table.concat(parts,"   •   ")
    end

    local function Connector(y1,y2,status)
        local line=Keep(results:CreateTexture(nil,"BACKGROUND"))
        line:SetTexture("Interface\\Buttons\\WHITE8X8")
        line:SetPoint("TOP",results,"TOP",0,y1)
        line:SetSize(2,math.max(8,y1-y2))
        if status=="COMPLETED" then
            line:SetVertexColor(0.20,0.72,0.36,0.65)
        elseif status=="IN PROGRESS" or status=="IN QUEST LOG" then
            line:SetVertexColor(0.24,0.55,0.95,0.65)
        else
            line:SetVertexColor(0.32,0.38,0.48,0.55)
        end
    end

    local Show
    local ResolveChainStart

    local function Card(id,y,kind,isSelected)
        local name,q=QuestRecord(id)
        if not name then return y,nil end
        local status=QuestStatus(id)

        local height=isSelected and 72 or 64
        local row=Keep(CreateFrame("Button",nil,results))
        row:SetSize(isSelected and 660 or 625,height)
        row:SetPoint("TOP",results,"TOP",0,y)

        local bg=row:CreateTexture(nil,"BACKGROUND")
        bg:SetAllPoints(row)
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetVertexColor(
            isSelected and 0.10 or 0.055,
            isSelected and 0.085 or 0.045,
            isSelected and 0.035 or 0.033,
            0.97
        )

        ForeverBrowser_AchievementBorder(row,true)

        if isSelected then
            local border=row:CreateTexture(nil,"ARTWORK")
            border:SetPoint("TOPLEFT",row,"TOPLEFT",0,0)
            border:SetPoint("TOPRIGHT",row,"TOPRIGHT",0,0)
            border:SetHeight(2)
            border:SetTexture("Interface\\Buttons\\WHITE8X8")
            border:SetVertexColor(0.95,0.68,0.26,0.95)
            local border2=row:CreateTexture(nil,"ARTWORK")
            border2:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",0,0)
            border2:SetPoint("BOTTOMRIGHT",row,"BOTTOMRIGHT",0,0)
            border2:SetHeight(2)
            border2:SetTexture("Interface\\Buttons\\WHITE8X8")
            border2:SetVertexColor(0.95,0.68,0.26,0.95)
        end

        local accent=row:CreateTexture(nil,"ARTWORK")
        accent:SetPoint("LEFT",row,"LEFT",0,0)
        accent:SetSize(isSelected and 5 or 3,height)
        accent:SetTexture("Interface\\Buttons\\WHITE8X8")
        if kind=="PREREQUISITE" then
            accent:SetVertexColor(0.72,0.52,1.00,1)
        elseif kind=="FOLLOW-UP" then
            accent:SetVertexColor(0.32,0.76,1.00,1)
        else
            accent:SetVertexColor(0.95,0.68,0.26,1)
        end

        local badge=ForeverBrowser_AchievementLabel(row,kind,9,
            kind=="CURRENT QUEST" and {0.95,0.68,0.26,1}
            or kind=="PREREQUISITE" and {0.72,0.60,0.92,1}
            or {0.42,0.72,0.95,1}
        )
        badge:SetPoint("TOPLEFT",row,"TOPLEFT",14,-8)

        local qname=ForeverBrowser_AchievementLabel(row,name,isSelected and 13 or 12,{0.94,0.94,0.97,1})
        qname:SetPoint("TOPLEFT",badge,"BOTTOMLEFT",0,-3)

        local meta=QuestMeta(q)
        if meta~="" then
            local metaText=ForeverBrowser_AchievementLabel(row,meta,9,{0.52,0.57,0.65,1})
            metaText:SetPoint("TOPLEFT",qname,"BOTTOMLEFT",0,-3)
        end

        local npcs=QuestNPCs(q)
        if npcs and isSelected then
            local npcText=ForeverBrowser_AchievementLabel(row,npcs,9,{0.58,0.62,0.68,1})
            npcText:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",14,7)
        end

        local qid=ForeverBrowser_AchievementLabel(row,"ID "..tostring(id),9,{0.42,0.45,0.52,1})
        qid:SetPoint("TOPRIGHT",row,"TOPRIGHT",-14,-9)

        if status=="COMPLETED" then
            local st=ForeverBrowser_AchievementLabel(row,"COMPLETED",10,{0.28,0.88,0.46,1})
            st:SetPoint("RIGHT",row,"RIGHT",-14,-8)
        elseif status=="IN PROGRESS" or status=="IN QUEST LOG" then
            local st=ForeverBrowser_AchievementLabel(row,"IN PROGRESS",10,{0.35,0.66,1.00,1})
            st:SetPoint("RIGHT",row,"RIGHT",-14,-8)
        end

        local hover=row:CreateTexture(nil,"BACKGROUND")
        hover:SetAllPoints(row)
        hover:SetTexture("Interface\\Buttons\\WHITE8X8")
        hover:SetVertexColor(0.65,0.46,0.16,0.18)
        hover:Hide()
        row:SetScript("OnEnter",function() hover:Show() end)
        row:SetScript("OnLeave",function() hover:Hide() end)
        row:SetScript("OnClick",function()
            local focusName,focusQuest=QuestRecord(id)
            if focusName then Show(id,focusQuest) end
        end)

        PageContent:SetHeight(math.max(PageContent:GetHeight() or 900, 400 + math.abs(y) + height))
        return y-height-16,status
    end

    local function LinearPosition(id)
        local seen={}
        local first=id
        local cursor=id
        while cursor and not seen[cursor] do
            seen[cursor]=true
            local _,q=QuestRecord(cursor)
            local before=InferRelations(cursor,q)
            if #before==1 then first=before[1] cursor=before[1] else break end
        end

        seen={}
        local order={}
        cursor=first
        while cursor and not seen[cursor] do
            seen[cursor]=true
            table.insert(order,cursor)
            local _,q=QuestRecord(cursor)
            local _,after=InferRelations(cursor,q)
            if #after==1 then cursor=after[1] else break end
        end
        for i,qid in ipairs(order) do
            if qid==id then return i,#order end
        end
        return nil,nil
    end

    local function GetQuestChainOnlyList()
        local quests=ForeverSourceData and ForeverSourceData.quests or {}
        local linked={}
        local list={}

        -- One database pass only. Do NOT call InferRelations here:
        -- InferRelations scans every quest, and doing that once per quest
        -- causes the client to lock up on large databases.
        for key,q in pairs(quests) do
            local id=tonumber(key)
            if not id and type(q)=="table" then
                id=tonumber(q.id)
            end

            if id and type(q)=="table" then
                local before,after=Relations(q)

                if #before>0 or #after>0 then
                    linked[id]=true
                end

                for _,qid in ipairs(before) do
                    qid=tonumber(qid)
                    if qid then linked[qid]=true end
                end

                for _,qid in ipairs(after) do
                    qid=tonumber(qid)
                    if qid then linked[qid]=true end
                end
            end
        end

        for id in pairs(linked) do
            local name,q=QuestRecord(id)
            if name then
                table.insert(list,{
                    id=id,
                    name=name,
                    data=q
                })
            end
        end

        table.sort(list,function(a,b)
            local an=string.lower(tostring(a.name or ""))
            local bn=string.lower(tostring(b.name or ""))
            if an~=bn then return an<bn end
            return (tonumber(a.id) or 0)<(tonumber(b.id) or 0)
        end)

        return list
    end

    local function CountRelationshipData()
        local quests=ForeverSourceData and ForeverSourceData.quests or {}
        local related=0
        for key,q in pairs(quests) do
            local id=tonumber(key)
            if not id and type(q)=="table" then id=tonumber(q.id) end
            if id and type(q)=="table" then
                local before,after=Relations(q)
                if #before>0 or #after>0 then related=related+1 end
            end
        end
        return related
    end

    local function BuildFullChain(selectedID)
        local visited={}
        local nodes={}
        local partial=false

        local function Walk(id,depth)
            id=tonumber(id)
            if not id or visited[id] or depth>30 then return end
            visited[id]=true
            local name,q=QuestRecord(id)
            if not name then partial=true return end
            local before,after=InferRelations(id,q)
            for _,qid in ipairs(before) do Walk(qid,depth+1) end
            nodes[id]={id=id,name=name,data=q,before=before,after=after}
            for _,qid in ipairs(after) do Walk(qid,depth+1) end
        end

        Walk(selectedID,0)
        return nodes,partial
    end

    local function ChainProgress(nodes)
        local total,completed,inProgress=0,0,0
        for id in pairs(nodes) do
            total=total+1
            local status=QuestStatus(id)
            if status=="COMPLETED" then completed=completed+1
            elseif status=="IN PROGRESS" or status=="IN QUEST LOG" then
                inProgress=inProgress+1
            end
        end
        return completed,total,inProgress
    end

    local function AddHistory(id)
        id=tonumber(id)
        if not id then return end

        if ForeverBrowserRelationshipHistory[
            ForeverBrowserRelationshipHistoryIndex
        ]~=id then
            while #ForeverBrowserRelationshipHistory>
                ForeverBrowserRelationshipHistoryIndex do
                table.remove(
                    ForeverBrowserRelationshipHistory,
                    #ForeverBrowserRelationshipHistory
                )
            end
            table.insert(ForeverBrowserRelationshipHistory,id)
            ForeverBrowserRelationshipHistoryIndex=
                #ForeverBrowserRelationshipHistory
        end

        for i=#ForeverBrowserRelationshipRecent,1,-1 do
            if ForeverBrowserRelationshipRecent[i]==id then
                table.remove(ForeverBrowserRelationshipRecent,i)
            end
        end
        table.insert(ForeverBrowserRelationshipRecent,1,id)
        while #ForeverBrowserRelationshipRecent>5 do
            table.remove(ForeverBrowserRelationshipRecent)
        end
    end

    local function CopyQuestID(id)
        if ChatFrame1EditBox then
            ChatFrame1EditBox:Show()
            ChatFrame1EditBox:SetFocus()
            ChatFrame1EditBox:SetText(tostring(id))
            ChatFrame1EditBox:HighlightText()
        end
    end

    Show=function(id,q,skipHistory)
        Wipe()
        local name=QuestRecord(id)
        if not name then return end
        local before,after=InferRelations(id,q)
        local chainNodes,partial=BuildFullChain(id)
        local completed,totalKnown,inProgress=ChainProgress(chainNodes)

        if not skipHistory then
            AddHistory(id)

        end
        ForeverBrowserRelationshipCurrentQuest=id
        ForeverBrowserRelationshipRefresh=function()
            local n,q2=QuestRecord(ForeverBrowserRelationshipCurrentQuest)
            if n then Show(ForeverBrowserRelationshipCurrentQuest,q2,true) end
        end

        local pos,total=LinearPosition(id)
        local sum=tostring(#before).." Prerequisite"
            ..(#before==1 and "" or "s")
            .."  •  1 Current Quest  •  "
            ..tostring(#after).." Follow-Up"
            ..(#after==1 and "" or "s")
        if pos and total and total>1 then
            sum=sum.."  •  QUEST "..pos.." OF "..total
        end
        sum=sum.."  •  "..tostring(completed).."/"..tostring(totalKnown).." COMPLETED"
        if inProgress>0 then
            sum=sum.."  •  "..tostring(inProgress).." IN PROGRESS"
        end
        summary:SetText(sum)

        if partial then
            overview:SetText("PARTIAL CHAIN DATA  •  Some relationships may not be present in the database")
        else
            overview:SetText("FULL CHAIN VIEW  •  "..tostring(totalKnown).." KNOWN QUESTS")
        end

        local progress=Keep(CreateFrame("Frame",nil,results))
        progress:SetSize(360,12)
        progress:SetPoint("TOP",results,"TOP",0,2)

        local progressBG=progress:CreateTexture(nil,"BACKGROUND")
        progressBG:SetAllPoints(progress)
        progressBG:SetTexture("Interface\\Buttons\\WHITE8X8")
        progressBG:SetVertexColor(0.055,0.045,0.033,0.95)

        if totalKnown>0 then
            local fill=progress:CreateTexture(nil,"ARTWORK")
            fill:SetPoint("LEFT",progress,"LEFT",0,0)
            fill:SetSize(math.max(1,360*(completed/totalKnown)),12)
            fill:SetTexture("Interface\\Buttons\\WHITE8X8")
            fill:SetVertexColor(0.20,0.72,0.36,0.82)
        end

        local nav=Keep(CreateFrame("Frame",nil,results))
        nav:SetSize(430,26)
        nav:SetPoint("TOP",results,"TOP",0,-18)

        if ForeverBrowserRelationshipHistoryIndex>1 then
            local historyBack=ForeverBrowser_ItemButton190(nav,"BACK",58,22)
            historyBack:SetPoint("LEFT",nav,"LEFT",-115,0)
            historyBack:SetScript("OnClick",function()
                ForeverBrowserRelationshipHistoryIndex=
                    ForeverBrowserRelationshipHistoryIndex-1
                local target=
                    ForeverBrowserRelationshipHistory[
                        ForeverBrowserRelationshipHistoryIndex
                    ]
                local n,q2=QuestRecord(target)
                if n then Show(target,q2,true) end
            end)
        end

        if ForeverBrowserRelationshipHistoryIndex<
            #ForeverBrowserRelationshipHistory then
            local historyForward=ForeverBrowser_ItemButton190(nav,"FORWARD",72,22)
            historyForward:SetPoint("LEFT",nav,"LEFT",-52,0)
            historyForward:SetScript("OnClick",function()
                ForeverBrowserRelationshipHistoryIndex=
                    ForeverBrowserRelationshipHistoryIndex+1
                local target=
                    ForeverBrowserRelationshipHistory[
                        ForeverBrowserRelationshipHistoryIndex
                    ]
                local n,q2=QuestRecord(target)
                if n then Show(target,q2,true) end
            end)
        end

        local copyID=ForeverBrowser_ItemButton190(nav,"COPY ID",68,22)
        copyID:SetPoint("RIGHT",nav,"RIGHT",68,0)
        copyID:SetScript("OnClick",function() CopyQuestID(id) end)

        local details=ForeverBrowser_ItemButton190(nav,"VIEW QUEST",82,22)
        details:SetPoint("RIGHT",nav,"RIGHT",158,0)
        details:SetScript("OnClick",function()
            Navigate("forever://quest/"..tostring(id))
        end)

        if #before==1 then
            local prev=ForeverBrowser_ItemButton190(nav,"< PREVIOUS QUEST",130,24)
            prev:SetPoint("LEFT",nav,"LEFT",0,0)
            prev:SetScript("OnClick",function()
                local n,q2=QuestRecord(before[1])
                if n then Show(before[1],q2) end
            end)
        end
        if #after==1 then
            local nxt=ForeverBrowser_ItemButton190(nav,"NEXT QUEST >",130,24)
            nxt:SetPoint("RIGHT",nav,"RIGHT",0,0)
            nxt:SetScript("OnClick",function()
                local n,q2=QuestRecord(after[1])
                if n then Show(after[1],q2) end
            end)
        end

        local y=-64

        if #before==0 then
            local none=Keep(ForeverBrowser_AchievementLabel(results,"NO KNOWN PREREQUISITE",9,{0.43,0.47,0.54,1}))
            none:SetPoint("TOP",results,"TOP",0,y)
            y=y-24
        else
            for _,qid in ipairs(before) do
                local nextY,status=Card(qid,y,"PREREQUISITE",false)
                Connector(y-66,nextY+8,status)
                y=nextY
            end
        end

        local nextY,currentStatus=Card(id,y,"CURRENT QUEST",true)
        Connector(y-74,nextY+8,currentStatus)
        y=nextY

        local chainStartID,chainStartQ,starterNPCID,starterNPCName=
            ResolveChainStart(id,q)

        if starterNPCName and starterNPCName~="" then
            local starterRow=Keep(CreateFrame("Button",nil,results))
            starterRow:SetSize(625,24)
            starterRow:SetPoint("TOP",results,"TOP",0,y+4)

            local starterLabel=ForeverBrowser_AchievementLabel(
                starterRow,
                "CHAIN START NPC:",
                9,{0.48,0.53,0.61,1}
            )
            starterLabel:SetPoint("LEFT",starterRow,"LEFT",12,0)

            local starterLink=ForeverBrowser_AchievementLabel(
                starterRow,
                starterNPCName,
                10,{0.35,0.72,1.00,1}
            )
            starterLink:SetPoint("LEFT",starterLabel,"RIGHT",7,0)

            if starterNPCID then
                local hint=ForeverBrowser_AchievementLabel(
                    starterRow,
                    "CLICK TO VIEW NPC",
                    8,{0.40,0.45,0.53,1}
                )
                hint:SetPoint("RIGHT",starterRow,"RIGHT",-12,0)

                local hover=starterRow:CreateTexture(nil,"BACKGROUND")
                hover:SetAllPoints(starterRow)
                hover:SetTexture("Interface\\Buttons\\WHITE8X8")
                hover:SetVertexColor(0.12,0.28,0.44,0.22)
                hover:Hide()

                starterRow:SetScript("OnEnter",function()
                    hover:Show()
                    starterLink:SetTextColor(0.55,0.84,1.00,1)
                end)
                starterRow:SetScript("OnLeave",function()
                    hover:Hide()
                    starterLink:SetTextColor(0.35,0.72,1.00,1)
                end)
                starterRow:SetScript("OnClick",function()
                    Navigate("forever://npc/"..tostring(starterNPCID))
                end)
            end

            y=y-30
        end

        if #after==0 then
            local none=Keep(ForeverBrowser_AchievementLabel(results,"NO KNOWN FOLLOW-UP",9,{0.43,0.47,0.54,1}))
            none:SetPoint("TOP",results,"TOP",0,y)
        elseif #after==1 then
            Card(after[1],y,"FOLLOW-UP",false)
        else
            local branch=Keep(ForeverBrowser_AchievementLabel(
                results,
                "BRANCHES INTO "..tostring(#after).." FOLLOW-UP QUESTS",
                9,{0.38,0.68,0.92,1}
            ))
            branch:SetPoint("TOP",results,"TOP",0,y)
            y=y-22

            -- Branch layout: two columns when there is room.
            for i,qid in ipairs(after) do
                local name2,q2=QuestRecord(qid)
                if name2 then
                    local row=Keep(CreateFrame("Button",nil,results))
                    row:SetSize(300,58)
                    local column=(i-1)%2
                    local rowIndex=math.floor((i-1)/2)
                    row:SetPoint("TOP",results,"TOP",
                        column==0 and -158 or 158,
                        y-(rowIndex*66)
                    )
                    local bg=row:CreateTexture(nil,"BACKGROUND")
                    bg:SetAllPoints(row)
                    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
                    bg:SetVertexColor(0.055,0.045,0.033,0.96)
                    local accent=row:CreateTexture(nil,"ARTWORK")
                    accent:SetPoint("LEFT",row,"LEFT",0,0)
                    accent:SetSize(3,58)
                    accent:SetTexture("Interface\\Buttons\\WHITE8X8")
                    accent:SetVertexColor(0.32,0.76,1.00,1)
                    local lab=ForeverBrowser_AchievementLabel(row,"FOLLOW-UP",8,{0.42,0.72,0.95,1})
                    lab:SetPoint("TOPLEFT",row,"TOPLEFT",12,-7)
                    local nm=ForeverBrowser_AchievementLabel(row,name2,10,{0.92,0.92,0.95,1})
                    nm:SetPoint("TOPLEFT",lab,"BOTTOMLEFT",0,-3)
                    nm:SetWidth(220)
                    local meta=QuestMeta(q2)
                    if meta~="" then
                        local mt=ForeverBrowser_AchievementLabel(row,meta,8,{0.50,0.55,0.63,1})
                        mt:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",12,6)
                    end
                    local status=QuestStatus(qid)
                    if status=="COMPLETED" then
                        local st=ForeverBrowser_AchievementLabel(row,"COMPLETED",8,{0.28,0.88,0.46,1})
                        st:SetPoint("TOPRIGHT",row,"TOPRIGHT",-9,-8)
                    elseif status=="IN PROGRESS" or status=="IN QUEST LOG" then
                        local st=ForeverBrowser_AchievementLabel(row,"IN PROGRESS",8,{0.35,0.66,1.00,1})
                        st:SetPoint("TOPRIGHT",row,"TOPRIGHT",-9,-8)
                    end
                    local hover=row:CreateTexture(nil,"BACKGROUND")
                    hover:SetAllPoints(row)
                    hover:SetTexture("Interface\\Buttons\\WHITE8X8")
                    hover:SetVertexColor(0.65,0.46,0.16,0.18)
                    hover:Hide()
                    row:SetScript("OnEnter",function() hover:Show() end)
                    row:SetScript("OnLeave",function() hover:Hide() end)
                    row:SetScript("OnClick",function()
                        local focusName,focusQuest=QuestRecord(qid)
                        if focusName then Show(qid,focusQuest) end
                    end)
                end
            end
        end
    end

    local BrowseChainQuests

    local function BuildChainBrowseProgressCache(list)
        local cache={}
        local quests=ForeverSourceData and ForeverSourceData.quests or {}

        -- Lightweight direct-link graph. This deliberately avoids
        -- InferRelations(), which scans the whole quest database.
        local graph={}
        for key,q in pairs(quests) do
            local id=tonumber(key)
            if not id and type(q)=="table" then id=tonumber(q.id) end
            if id and type(q)=="table" then
                graph[id]=graph[id] or {}
                local before,after=Relations(q)
                for _,qid in ipairs(before) do
                    qid=tonumber(qid)
                    if qid then
                        graph[id][qid]=true
                        graph[qid]=graph[qid] or {}
                        graph[qid][id]=true
                    end
                end
                for _,qid in ipairs(after) do
                    qid=tonumber(qid)
                    if qid then
                        graph[id][qid]=true
                        graph[qid]=graph[qid] or {}
                        graph[qid][id]=true
                    end
                end
            end
        end

        local componentFor={}
        for _,entry in ipairs(list) do
            local id=entry.id
            if not componentFor[id] then
                local queue={id}
                local head=1
                local members={}
                componentFor[id]=members
                while head<=#queue do
                    local current=queue[head]
                    head=head+1
                    table.insert(members,current)
                    for neighbor in pairs(graph[current] or {}) do
                        if not componentFor[neighbor] then
                            componentFor[neighbor]=members
                            table.insert(queue,neighbor)
                        end
                    end
                end
            end
        end

        for _,entry in ipairs(list) do
            local members=componentFor[entry.id] or {entry.id}
            local completed=0
            for _,qid in ipairs(members) do
                if QuestStatus(qid)=="COMPLETED" then
                    completed=completed+1
                end
            end
            local total=#members
            local percent=0
            if total>0 then
                percent=math.floor((completed/total)*100+0.5)
            end
            cache[entry.id]={
                completed=completed,
                total=total,
                percent=percent
            }
        end

        return cache
    end

    local function ChainBrowseProgress(id)
        local info=ForeverBrowserRelationshipProgressCache
            and ForeverBrowserRelationshipProgressCache[id]
        if info then
            return info.completed,info.total,info.percent
        end
        return 0,1,0
    end

    ResolveChainStart=function(id,q)
        local seen={}
        local cursor=id
        local startID=id
        local startQ=q

        for step=1,30 do
            if not cursor or seen[cursor] then break end
            seen[cursor]=true
            local _,currentQ=QuestRecord(cursor)
            if not currentQ then break end
            local before=Relations(currentQ)
            if #before~=1 then
                startID=cursor
                startQ=currentQ
                break
            end
            local previousID=tonumber(before[1])
            if not previousID then break end
            local _,previousQ=QuestRecord(previousID)
            if not previousQ then break end
            startID=previousID
            startQ=previousQ
            cursor=previousID
        end

        local starterValue=nil
        if type(startQ)=="table" then
            starterValue=FirstValue(startQ,{
                "startNPC","starterNPC","startNpc",
                "questGiver","giverNPC","startsFrom",
                "giverID","npcStarters"
            })
        end

        local starterID=nil
        if type(starterValue)=="number" or type(starterValue)=="string" then
            starterID=tonumber(starterValue)
        elseif type(starterValue)=="table" then
            starterID=tonumber(
                starterValue.id or starterValue.npcID or starterValue.npcId
            )
            if not starterID then
                for k,v in pairs(starterValue) do
                    if type(v)=="number" or type(v)=="string" then
                        starterID=tonumber(v)
                    elseif type(v)=="table" then
                        starterID=tonumber(v.id or v.npcID or v.npcId)
                    end
                    if starterID then break end
                    if type(k)=="number" and v==true then
                        starterID=k
                        break
                    end
                end
            end
        end

        local starterName=NPCName(starterValue)
        if (not starterName or starterName=="") and type(startQ)=="table" then
            starterName=DisplayValue(
                FirstValue(startQ,{"giverName","starterName","startNPCName"})
            )
        end

        return startID,startQ,starterID,starterName
    end

    local function ChainStartInfo(id,q)
        local startID,startQ,starterID,starterName=ResolveChainStart(id,q)
        local startName=QuestRecord(startID)

        if startName and starterName and starterName~="" then
            return "STARTS: "..startName.."  •  "..starterName
        elseif startName then
            return "STARTS: "..startName
        end
        return nil
    end


    BrowseChainQuests=function(requestedPage)
        Wipe()
        searchBox:SetText("")

        ForeverBrowserRelationshipChainCatalog =
            ForeverBrowserRelationshipChainCatalog
            or GetQuestChainOnlyList()

        local list=ForeverBrowserRelationshipChainCatalog

        ForeverBrowserRelationshipProgressCache =
            ForeverBrowserRelationshipProgressCache
            or BuildChainBrowseProgressCache(list)

        local perPage=5
        local totalPages=math.max(1,math.ceil(#list/perPage))

        local page=tonumber(requestedPage)
            or tonumber(ForeverBrowserRelationshipBrowsePage)
            or 1
        if page<1 then page=1 end
        if page>totalPages then page=totalPages end
        ForeverBrowserRelationshipBrowsePage=page

        summary:SetText(tostring(#list).." QUESTS IN KNOWN CHAINS")
        overview:SetText(
            "QUEST CHAIN ONLY  •  PAGE "..tostring(page)..
            " OF "..tostring(totalPages)..
            "  •  Select a quest to explore its chain"
        )

        if #list==0 then
            local none=Keep(ForeverBrowser_AchievementLabel(
                results,
                "No quests with recorded chain relationships were found.",
                11,{0.58,0.60,0.66,1}
            ))
            none:SetPoint("TOP",results,"TOP",0,0)
            return
        end

        local pager=Keep(CreateFrame("Frame",nil,results))
        pager:SetSize(330,24)
        pager:SetPoint("TOP",results,"TOP",0,0)

        if page>1 then
            local prev=ForeverBrowser_ItemButton190(pager,"< PREV",72,22)
            prev:SetPoint("LEFT",pager,"LEFT",0,0)
            prev:SetScript("OnClick",function()
                BrowseChainQuests(page-1)
            end)
        end

        local pageText=ForeverBrowser_AchievementLabel(
            pager,
            "PAGE "..tostring(page).." OF "..tostring(totalPages),
            10,{0.66,0.70,0.77,1}
        )
        pageText:SetPoint("CENTER",pager,"CENTER",0,0)

        if page<totalPages then
            local nxt=ForeverBrowser_ItemButton190(pager,"NEXT >",72,22)
            nxt:SetPoint("RIGHT",pager,"RIGHT",0,0)
            nxt:SetScript("OnClick",function()
                BrowseChainQuests(page+1)
            end)
        end

        local first=((page-1)*perPage)+1
        local last=math.min(#list,first+perPage-1)
        local y=-34

        for i=first,last do
            local entry=list[i]
            local completed,total,percent=
                ChainBrowseProgress(entry.id)

            local row=Keep(CreateFrame("Button",nil,results))
            row:SetSize(625,62)
            row:SetPoint("TOP",results,"TOP",0,y)

            local bg=row:CreateTexture(nil,"BACKGROUND")
            bg:SetAllPoints(row)
            bg:SetTexture("Interface\\Buttons\\WHITE8X8")
            bg:SetVertexColor(0.055,0.045,0.033,0.96)

            local accent=row:CreateTexture(nil,"ARTWORK")
            accent:SetPoint("LEFT",row,"LEFT",0,0)
            accent:SetSize(3,62)
            accent:SetTexture("Interface\\Buttons\\WHITE8X8")
            if percent>=100 then
                accent:SetVertexColor(0.20,0.72,0.36,1)
            elseif percent>0 then
                accent:SetVertexColor(0.32,0.66,1.00,1)
            else
                accent:SetVertexColor(0.40,0.44,0.52,1)
            end

            local name=ForeverBrowser_AchievementLabel(row,entry.name,11,{0.94,0.94,0.97,1})
            name:ClearAllPoints()
            name:SetPoint("TOPLEFT",row,"TOPLEFT",14,-8)
            name:SetSize(385,16)
            name:SetJustifyH("LEFT")

            local meta=QuestMeta(entry.data)
            local metaText=ForeverBrowser_AchievementLabel(
                row,
                meta~="" and meta or ("Quest ID "..tostring(entry.id)),
                9,{0.48,0.53,0.61,1}
            )
            metaText:ClearAllPoints()
            metaText:SetPoint("TOPLEFT",name,"BOTTOMLEFT",0,-3)
            metaText:SetSize(385,12)
            metaText:SetJustifyH("LEFT")

            local startInfo=ChainStartInfo(entry.id,entry.data)
            if startInfo then
                local startText=ForeverBrowser_AchievementLabel(
                    row,startInfo,8,{0.56,0.62,0.70,1}
                )
                startText:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",14,7)
                startText:SetSize(430,11)
                startText:SetJustifyH("LEFT")
            end

            local pct=ForeverBrowser_AchievementLabel(
                row,
                tostring(percent).."% COMPLETE",
                10,
                percent>=100 and {0.28,0.88,0.46,1}
                    or percent>0 and {0.35,0.66,1.00,1}
                    or {0.55,0.58,0.64,1}
            )
            pct:ClearAllPoints()
            pct:SetPoint("TOPRIGHT",row,"TOPRIGHT",-14,-8)
            pct:SetSize(175,14)
            pct:SetJustifyH("RIGHT")

            local count=ForeverBrowser_AchievementLabel(
                row,
                tostring(completed).."/"..tostring(total).." QUESTS",
                8,{0.45,0.50,0.58,1}
            )
            count:ClearAllPoints()
            count:SetPoint("BOTTOMRIGHT",row,"BOTTOMRIGHT",-14,8)
            count:SetSize(175,12)
            count:SetJustifyH("RIGHT")

            local hover=row:CreateTexture(nil,"BACKGROUND")
            hover:SetAllPoints(row)
            hover:SetTexture("Interface\\Buttons\\WHITE8X8")
            hover:SetVertexColor(0.65,0.46,0.16,0.18)
            hover:Hide()

            row:SetScript("OnEnter",function() hover:Show() end)
            row:SetScript("OnLeave",function() hover:Hide() end)
            row:SetScript("OnClick",function()
                local focusName,focusQuest=QuestRecord(entry.id)
                if focusName then Show(entry.id,focusQuest) end
            end)

            y=y-70
        end
    end

    local function Search()
        local query=searchBox:GetText() or ""
        query=string.gsub(query,"^%s+","")
        query=string.gsub(query,"%s+$","")
        Wipe()
        if query=="" then
            summary:SetText("SEARCH FOR A QUEST TO BEGIN")
            return
        end

        local quests=ForeverSourceData and ForeverSourceData.quests or {}
        local numeric=tonumber(query)
        if numeric then
            local q=quests[numeric] or quests[tostring(numeric)]
            if q then Show(numeric,q) return end
        end

        local needle=string.lower(query)
        local matches={}
        for key,q in pairs(quests) do
            local id=tonumber(key)
            if not id and type(q)=="table" then id=tonumber(q.id) end
            local name=nil
            if type(q)=="table" then name=q.name or q.title
            elseif type(q)=="string" then name=q end
            if id and name and string.find(string.lower(tostring(name)),needle,1,true) then
                table.insert(matches,{id=id,name=tostring(name),data=q})
            end
        end
        table.sort(matches,function(a,b)
            return string.lower(a.name)<string.lower(b.name)
        end)

        if #matches==1 then Show(matches[1].id,matches[1].data) return end
        if #matches==0 then
            summary:SetText("NO MATCHING QUESTS")
            local none=Keep(ForeverBrowser_AchievementLabel(results,"No matching quests found.",11,{0.62,0.52,0.52,1}))
            none:SetPoint("TOP",results,"TOP",0,0)
            return
        end

        summary:SetText(tostring(#matches).." MATCHING QUESTS")
        local y=0
        for i=1,math.min(#matches,6) do
            local nextY=Card(matches[i].id,y,"SELECT QUEST",false)
            y=nextY
        end
    end

    do
        local relatedCount=CountRelationshipData()
        overview:SetText(
            tostring(relatedCount)..
            " QUESTS WITH DIRECTLY RECORDED RELATIONSHIPS"
        )
    end

    ForeverBrowserRelationshipBrowse198=BrowseChainQuests
    ForeverBrowserRelationshipOpen198=Show
    browseChainsButton:SetScript("OnClick",function()
        ForeverBrowserRelationshipBrowsePage=1
        BrowseChainQuests(1)
    end)
    searchButton:SetScript("OnClick",Search)
    searchBox:SetScript("OnEnterPressed",function(self)
        self:ClearFocus()
        Search()
    end)
end




--------------------------------------------------
-- Browser journal utilities are independent of achievement tracking.
function ForeverBrowser_CodexButton(parent,text,width)
    local button=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    button:SetSize(width or 100,25) button:SetText(text)
    button:EnableMouse(true) button:RegisterForClicks("LeftButtonUp")
    return button
end
function ForeverBrowser_IsForeverRecord(record)
    return type(record)=="table" and (record.isForever==true or record.foreverExclusive==true
        or string.lower(tostring(record.dataSource or ""))=="forever")
end
function ForeverBrowser_CountRecords(records)
    local count,seen=0,{} for key in pairs(type(records)=="table" and records or {}) do local id=tostring(key) if not seen[id] then seen[id]=true count=count+1 end end return count
end
function ForeverBrowser_JournalState()
    local db=GetDatabase() db.codexJournal=db.codexJournal or {characters185=(db.achievementStats and db.achievementStats.characters185) or {}}
    return db.codexJournal
end
function ForeverBrowser_JournalCharacter()
    local stats=ForeverBrowser_JournalState() local name=type(UnitName)=="function" and UnitName("player") or "Unknown" local realm=type(GetRealmName)=="function" and GetRealmName() or ""
    local key=name.."-"..realm stats.characters185[key]=stats.characters185[key] or {name=key,started=type(time)=="function" and time() or 0,items={},quests={},zones={}} return stats.characters185[key]
end
function ForeverBrowser_HomeRecords189(kind)
    local index={}
    local function add(records)
        for key,data in pairs(type(records)=="table" and records or {}) do
            local id=tonumber(key) or (type(data)=="table" and tonumber(data.id))
            if id and id>0 then
                local old=index[id] or {}
                index[id]={id=id,name=type(data)=="table" and tostring(data.name or data.title or old.name or (kind.." "..id)) or (old.name or kind.." "..id),
                    data=type(data)=="table" and data or old.data,
                    route="forever://"..(kind=="items" and "item/" or "quest/")..id}
            end
        end
    end
    if kind=="items" then add(GetWorldItems()) add(GetPlayerItems()) end
    add(ForeverSourceData and ForeverSourceData[kind])
    return index
end

function ForeverBrowser_QuestRecent189(id)
    id=tonumber(id) if not id then return end
    local db=GetDatabase() if not db then return end
    db.recentQuestViews189=db.recentQuestViews189 or {}
    for i=#db.recentQuestViews189,1,-1 do if db.recentQuestViews189[i]==id then table.remove(db.recentQuestViews189,i) end end
    table.insert(db.recentQuestViews189,1,id)
    while #db.recentQuestViews189>6 do table.remove(db.recentQuestViews189) end
end

function ForeverBrowser_HomeRow189(parent,record,y)
    local row=CreateFrame("Button",nil,parent) row:SetSize(700,48) row:SetPoint("TOPLEFT",parent,"TOPLEFT",0,y)
    ForeverBrowser_AchievementPaper(row,false)
    local title=ForeverBrowser_AchievementLabel(row,record.name,13,{0.25,0.16,0.06,1})
    title:SetPoint("TOPLEFT",row,"TOPLEFT",13,-7) title:SetSize(606,18) title:SetJustifyH("LEFT")
    local sub=ForeverBrowser_AchievementLabel(row,record.subtitle or "Open database record",10,{0.33,0.28,0.20,1})
    sub:SetPoint("TOPLEFT",row,"TOPLEFT",13,-28) sub:SetWidth(610) sub:SetJustifyH("LEFT")
    local id=ForeverBrowser_AchievementLabel(row,"#"..record.id,10,{0.35,0.26,0.12,1}) id:SetPoint("TOPRIGHT",row,"TOPRIGHT",-12,-11)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight") row:SetScript("OnClick",function() Navigate(record.route) end)
end

function ForeverBrowser_HomeConfig189(kind)
    local config={kind=kind,index=ForeverBrowser_HomeRecords189(kind),featured={},recent={}}
    local total,forever=0,0
    for _,record in pairs(config.index) do
        total=total+1
        if ForeverBrowser_IsForeverRecord(record.data) then config.featured[#config.featured+1]=record forever=forever+1 end
    end
    table.sort(config.featured,function(a,b) if a.name==b.name then return a.id<b.id end return a.name<b.name end)
    local db=GetDatabase() or {}
    if kind=="items" then
        local favoriteCount=ForeverBrowser_CountRecords(GetFavorites()) local lists=ForeverBrowser_CountRecords(GetCustomLists())
        local discovered=ForeverBrowser_CountRecords(GetPlayerItems())
        config.title="The Item Codex" config.icon="INV_Misc_Book_09" config.subtitle="Find, collect and organize the items of Azeroth & Forever."
        config.searchLabel="Search Items" config.hint="Search by item name or exact item ID"
        config.searchRoute="forever://search/" config.emptySearch="forever://search/"
        config.stats={{total,"Browse All Items","forever://itembrowse"},{favoriteCount,"Favorites","forever://favorites"},
            {discovered,"Discovered Items","forever://recent"},{lists,"My Lists","forever://lists"}}
        config.cards={
            {"Browse All Items","Explore the full item database and its categories.",total,"INV_Misc_Spyglass_03","forever://itembrowse"},
            {"Favorites","Return to the items you have saved as favorites.",favoriteCount,"INV_Misc_Note_02","forever://favorites"},
            {"Recent Items","Review recently viewed and discovered items.",discovered,"INV_Misc_PocketWatch_01","forever://recent"},
            {"My Lists","Open and manage your custom item collections.",lists,"INV_Misc_Note_05","forever://lists"},
            {"Tags & Notes","Organize item records with your own tags and notes.","Personal","INV_Inscription_Scroll","forever://tags"},
            {"Quick Search","Find an item by name or exact item ID.","Name / ID","INV_Misc_Spyglass_02","forever://search/"}}
        config.spotlight="Forever Item Spotlight" config.emptyFeatured="No explicitly marked Forever item records are loaded."
        for _,id in ipairs(GetRecentItems()) do
            id=tonumber(id) if id and config.index[id] then config.recent[#config.recent+1]=config.index[id] end
        end
    else
        ForeverBrowser_ScanQuestLog()
        local active,completed,rewards=0,0,0
        local seen={}
        for id,record in pairs(config.index) do
            if not seen[id] then
                seen[id]=true
                if (ForeverBrowserQuestLogCache or {})[id] then active=active+1 end
                local api=type(C_QuestLog)=="table" and C_QuestLog.IsQuestFlaggedCompleted or nil
                local done=false
                if type(api)=="function" then local ok,v=pcall(api,id) done=ok and v==true end
                if not done and type(IsQuestFlaggedCompleted)=="function" then local ok,v=pcall(IsQuestFlaggedCompleted,id) done=ok and v==true end
                if done then completed=completed+1 end
                local q=record.data or {}
                if ForeverBrowser_CountRecords(q.rewards)>0 or ForeverBrowser_CountRecords(q.rewardItems)>0
                    or ForeverBrowser_CountRecords(q.choiceRewards)>0 or ForeverBrowser_CountRecords(q.choiceRewardItems)>0
                    or (tonumber(q.rewardXP) or 0)>0 or (tonumber(q.rewardMoney) or 0)>0
                    or ForeverBrowser_CountRecords(q.reputationRewards)>0 then rewards=rewards+1 end
            end
        end
        config.title="The Quest Codex" config.icon="INV_Misc_Note_01" config.subtitle="Follow the stories, adventures and rewards of Azeroth & Forever."
        config.searchLabel="Search Quests" config.hint="Search by quest name or exact quest ID"
        config.searchRoute="forever://questbrowse/search/" config.emptySearch="forever://questbrowse"
        config.stats={{total,"Browse All Quests","forever://questbrowse/all"},{active,"In Progress","forever://questbrowse/inprogress"},
            {completed,"Completed","forever://questbrowse/completed"},{rewards,"With Rewards","forever://questrewards"}}
        config.cards={
            {"Browse All Quests","Explore all quests in the loaded database.",total,"INV_Misc_Note_01","forever://questbrowse/all"},
            {"In Progress","View quests currently in this character's quest log.",active,"INV_Misc_Book_09","forever://questbrowse/inprogress"},
            {"Completed","Review quests confirmed complete for this character.",completed,"INV_Misc_Ticket_Tarot_Madness","forever://questbrowse/completed"},
            {"Quest Rewards","Browse item, XP, money and reputation rewards.",rewards,"INV_Box_01","forever://questrewards"},
            {"Quest Relationships","Follow prerequisite quests and linked storylines.","Storylines","INV_Misc_Map_01","forever://questrelationships"},
            {"Quick Search","Find a quest by name or exact quest ID.","Name / ID","INV_Misc_Spyglass_02","forever://questbrowse"}}
        config.spotlight="Forever Quest Spotlight" config.emptyFeatured="No explicitly marked Forever quest records are loaded."
        for _,id in ipairs(db.recentQuestViews189 or {}) do if config.index[id] then config.recent[#config.recent+1]=config.index[id] end end
    end
    return config
end

function ForeverBrowser_DatabaseHome189(kind)
    if kind=="quests" then ForeverBrowserCurrentQuestBrowseFilter=nil ForeverBrowserQuestBrowseFilter=nil end
    local c=ForeverBrowser_HomeConfig189(kind)
    ClearPage() PageContent:SetHeight(1040)
    local hero=CreateFrame("Frame",nil,PageContent) hero:SetSize(700,170) hero:SetPoint("TOP",PageContent,"TOP",0,-16)
    CreateSolidBackground(hero,0.035,0.025,0.014,1) ForeverBrowser_AchievementBorder(hero,true)
    local emblem=hero:CreateTexture(nil,"ARTWORK") emblem:SetSize(62,62) emblem:SetPoint("TOPLEFT",hero,"TOPLEFT",20,-23)
    emblem:SetTexture("Interface\\Icons\\"..c.icon)
    local title=ForeverBrowser_AchievementLabel(hero,c.title,26,{1,0.82,0.28,1}) title:SetPoint("TOPLEFT",hero,"TOPLEFT",98,-22)
    local subtitle=ForeverBrowser_AchievementLabel(hero,c.subtitle,12,{0.87,0.81,0.67,1})
    subtitle:SetPoint("TOPLEFT",hero,"TOPLEFT",98,-62) subtitle:SetWidth(577) subtitle:SetJustifyH("LEFT")
    local search=CreateFrame("EditBox",nil,hero,"InputBoxTemplate") search:SetSize(450,30) search:SetPoint("TOPLEFT",hero,"TOPLEFT",24,-106)
    search:SetAutoFocus(false) search:SetFontObject("ChatFontNormal")
    local button=ForeverBrowser_CodexButton(hero,c.searchLabel,125) button:SetPoint("LEFT",search,"RIGHT",17,0)
    local function run()
        search:ClearFocus()
        local query=string.gsub(search:GetText() or "","^%s*(.-)%s*$","%1")
        Navigate(query=="" and c.emptySearch or c.searchRoute..query)
    end
    search:SetScript("OnEnterPressed",run) search:SetScript("OnEscapePressed",function(self) self:ClearFocus() end) button:SetScript("OnClick",run)
    local hint=ForeverBrowser_AchievementLabel(hero,c.hint,10,{0.67,0.61,0.47,1}) hint:SetPoint("BOTTOMLEFT",hero,"BOTTOMLEFT",24,12)
    for i,info in ipairs(c.stats) do
        local stat=CreateFrame("Button",nil,PageContent) stat:SetSize(166,62)
        stat:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",(i-1)*178,-12) ForeverBrowser_AchievementPaper(stat,true)
        local n=ForeverBrowser_AchievementLabel(stat,tostring(info[1]),22,{0.31,0.18,0.03,1}) n:SetPoint("TOP",stat,"TOP",0,-7)
        local label=ForeverBrowser_AchievementLabel(stat,info[2],10,{0.34,0.28,0.17,1}) label:SetPoint("BOTTOM",stat,"BOTTOM",0,9)
        stat:SetScript("OnClick",function() Navigate(info[3]) end)
    end
    local heading=ForeverBrowser_AchievementLabel(PageContent,"Explore the Database",18,{1,0.82,0.28,1}) heading:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",0,-94)
    for i,info in ipairs(c.cards) do
        local card=CreateFrame("Button",nil,PageContent) card:SetSize(338,100)
        card:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",i%2==1 and 0 or 362,-125-math.floor((i-1)/2)*112) ForeverBrowser_AchievementPaper(card,true)
        local icon=card:CreateTexture(nil,"ARTWORK") icon:SetSize(39,39) icon:SetPoint("TOPLEFT",card,"TOPLEFT",14,-14) icon:SetTexture("Interface\\Icons\\"..info[4])
        local title=ForeverBrowser_AchievementLabel(card,info[1],17,{0.29,0.16,0.03,1}) title:SetPoint("TOPLEFT",card,"TOPLEFT",67,-15)
        local desc=ForeverBrowser_AchievementLabel(card,info[2],11,{0.30,0.25,0.16,1}) desc:SetPoint("TOPLEFT",card,"TOPLEFT",67,-43)
        desc:SetSize(251,31) desc:SetJustifyH("LEFT") desc:SetJustifyV("TOP")
        local count=ForeverBrowser_AchievementLabel(card,tostring(info[3])..(type(info[3])=="number" and " records  >" or "  >"),10,{0.38,0.25,0.08,1}) count:SetPoint("BOTTOMLEFT",card,"BOTTOMLEFT",67,10)
        card:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight") card:SetScript("OnClick",function() Navigate(info[5]) end)
    end
    local featured=ForeverBrowser_AchievementLabel(PageContent,c.spotlight,18,{1,0.82,0.28,1}) featured:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",0,-474)
    local section=CreateFrame("Frame",nil,PageContent) section:SetSize(700,164) section:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",0,-508)
    for i=1,math.min(3,#c.featured) do ForeverBrowser_HomeRow189(section,c.featured[i],-(i-1)*54) end
    if #c.featured==0 then local empty=ForeverBrowser_AchievementLabel(section,c.emptyFeatured,12,{0.78,0.73,0.61,1}) empty:SetPoint("TOPLEFT",section,"TOPLEFT",8,-10) end
    local recentTitle=ForeverBrowser_AchievementLabel(PageContent,"Recently Viewed",18,{1,0.82,0.28,1}) recentTitle:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",0,-687)
    local recent=CreateFrame("Frame",nil,PageContent) recent:SetSize(700,110) recent:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",0,-720)
    for i=1,math.min(2,#c.recent) do ForeverBrowser_HomeRow189(recent,c.recent[i],-(i-1)*54) end
    if #c.recent==0 then local empty=ForeverBrowser_AchievementLabel(recent,"Open a record to start your browsing history.",12,{0.78,0.73,0.61,1}) empty:SetPoint("TOPLEFT",recent,"TOPLEFT",8,-10) end
end

ForeverBrowserNPC187={}

function ForeverBrowser_N187Index()
    local source=ForeverSourceData or {}
    if ForeverBrowserNPC187.source==source and ForeverBrowserNPC187.index then return ForeverBrowserNPC187.index end
    local index={}
    for _,field in ipairs({"npcs","foreverNPCs","vendors","trainers","npcLocations"}) do
        for key,data in pairs(type(source[field])=="table" and source[field] or {}) do
            local id=tonumber(key) or (type(data)=="table" and tonumber(data.id or data.npcID))
            if id and id>0 then
                index[id]=index[id] or {id=id,name="NPC "..id}
                local record=index[id]
                record[field]=true
                if type(data)=="table" then
                    if data.name and (field=="npcs" or field=="foreverNPCs") then record.name=tostring(data.name) end
                    if field=="foreverNPCs" then record.subtitle=tostring(data.role or data.dungeonName or "Forever NPC")
                    elseif field=="npcs" and not record.subtitle then record.subtitle=tostring(data.subName or "") end
                end
            end
        end
    end
    for _,q in pairs(source.quests or {}) do
        if type(q)=="table" then
            local ids={}
            for _,field in ipairs({"giverID","startNPC","starterNPC","questGiver"}) do
                if tonumber(q[field]) then ids[tonumber(q[field])]=true end
            end
            for key,v in pairs(type(q.npcStarters)=="table" and q.npcStarters or {}) do
                local id=tonumber(v) or (type(v)=="table" and tonumber(v.id or v.npcID or v.npcId)) or (v==true and tonumber(key))
                if id then ids[id]=true end
            end
            for id in pairs(ids) do if index[id] then index[id].questGiver=true end end
        end
    end
    ForeverBrowserNPC187.source=source ForeverBrowserNPC187.index=index ForeverBrowserNPC187.lists={}
    return index
end

function ForeverBrowser_N187List(mode,query)
    local out={}
    query=string.lower(tostring(query or ""))
    local index=ForeverBrowser_N187Index()
    if query=="" and ForeverBrowserNPC187.lists[mode or "all"] then return ForeverBrowserNPC187.lists[mode or "all"] end
    local fields={vendor="vendors",trainer="trainers",location="npcLocations",forever="foreverNPCs",quests="questGiver"}
    for id,npc in pairs(index) do
        if (not fields[mode] or npc[fields[mode]]) and
            (query=="" or tonumber(query)==id or (not tonumber(query) and string.find(string.lower(npc.name.." "..(npc.subtitle or "")),query,1,true))) then
            out[#out+1]=npc
        end
    end
    table.sort(out,function(a,b) if a.name==b.name then return a.id<b.id end return a.name<b.name end)
    if query=="" then ForeverBrowserNPC187.lists[mode or "all"]=out end
    return out
end

function ForeverBrowser_N187Record(id)
    id=tonumber(id) if not id then return end
    local db=GetDatabase() if not db then return end
    db.browserRecentNPC187=db.browserRecentNPC187 or {}
    for i=#db.browserRecentNPC187,1,-1 do if db.browserRecentNPC187[i]==id then table.remove(db.browserRecentNPC187,i) end end
    table.insert(db.browserRecentNPC187,1,id)
    while #db.browserRecentNPC187>6 do table.remove(db.browserRecentNPC187) end
end

function ForeverBrowser_N187Search(query,mode)
    query=string.gsub(tostring(query or ""),"^%s*(.-)%s*$","%1")
    if query=="" then ForeverBrowser_N187Browse(mode or "all", "",1) return end
    local db=GetDatabase()
    if db then
        db.recentNPCSearches=db.recentNPCSearches or {}
        for i=#db.recentNPCSearches,1,-1 do
            local old=db.recentNPCSearches[i]
            if type(old)=="table" then old=old.search or old.name end
            if string.lower(tostring(old or ""))==string.lower(query) then table.remove(db.recentNPCSearches,i) end
        end
        table.insert(db.recentNPCSearches,1,query)
        while #db.recentNPCSearches>10 do table.remove(db.recentNPCSearches) end
    end
    local id=tonumber(query)
    if id and ForeverBrowser_N187Index()[id] then Navigate("forever://npc/"..id)
    else ForeverBrowser_N187Browse(mode or "all",query,1) end
end

function ForeverBrowser_N187NPCRow(parent,npc,y,width)
    local row=CreateFrame("Button",nil,parent) row:SetSize(width or 700,48)
    row:SetPoint("TOPLEFT",parent,"TOPLEFT",0,y)
    ForeverBrowser_AchievementPaper(row,false)
    local label=ForeverBrowser_AchievementLabel(row,npc.name,13,{0.25,0.16,0.06,1})
    label:SetPoint("TOPLEFT",row,"TOPLEFT",13,-7) label:SetSize((width or 700)-94,18) label:SetJustifyH("LEFT")
    local sub=ForeverBrowser_AchievementLabel(row,npc.subtitle and npc.subtitle~="" and npc.subtitle or "NPC database record",10,{0.33,0.28,0.20,1})
    sub:SetPoint("TOPLEFT",row,"TOPLEFT",13,-28) sub:SetWidth((width or 700)-90) sub:SetJustifyH("LEFT")
    local id=ForeverBrowser_AchievementLabel(row,"#"..npc.id,10,{0.35,0.26,0.12,1})
    id:SetPoint("TOPRIGHT",row,"TOPRIGHT",-12,-11)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    row:SetScript("OnClick",function() Navigate("forever://npc/"..npc.id) end)
end

function ForeverBrowser_N187Browse(mode,query,page)
    ClearPage() PageContent:SetHeight(760)
    mode=mode or "all" query=query or ""
    local names={all="All NPCs",vendor="Vendors",trainer="Trainers",location="NPC Locations",forever="Forever NPCs",quests="Quest Givers"}
    local results=ForeverBrowser_N187List(mode,query)
    local title=ForeverBrowser_AchievementLabel(PageContent,names[mode] or "NPCs",23,{1,0.82,0.28,1})
    title:SetPoint("TOP",PageContent,"TOP",0,-23)
    local back=ForeverBrowser_CodexButton(PageContent,"NPC Home",110)
    back:SetPoint("TOPLEFT",PageContent,"TOPLEFT",18,-22) back:SetScript("OnClick",function() Navigate("forever://npcdatabase") end)
    local search=CreateFrame("EditBox",nil,PageContent,"InputBoxTemplate") search:SetSize(380,28)
    search:SetPoint("TOP",PageContent,"TOP",-50,-68) search:SetAutoFocus(false) search:SetFontObject("ChatFontNormal") search:SetText(query)
    local button=ForeverBrowser_CodexButton(PageContent,"Search",85) button:SetPoint("LEFT",search,"RIGHT",12,0)
    local function run() search:ClearFocus() ForeverBrowser_N187Search(search:GetText(),mode) end
    button:SetScript("OnClick",run) search:SetScript("OnEnterPressed",run) search:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    local count=ForeverBrowser_AchievementLabel(PageContent,#results.." records • "..(query~="" and "Search: "..query or "Browse the loaded database"),11,{0.85,0.78,0.61,1})
    count:SetPoint("TOP",PageContent,"TOP",0,-112) count:SetWidth(690)
    local rows=CreateFrame("Frame",nil,PageContent) rows:SetSize(700,520) rows:SetPoint("TOP",PageContent,"TOP",0,-146)
    local pages=math.max(1,math.ceil(#results/10)) page=math.max(1,math.min(page or 1,pages))
    for i=(page-1)*10+1,math.min(#results,page*10) do ForeverBrowser_N187NPCRow(rows,results[i],-(i-(page-1)*10-1)*52,700) end
    if #results==0 then
        local empty=ForeverBrowser_AchievementLabel(rows,"No matching NPCs. Try another name or ID.",14,{0.86,0.80,0.68,1})
        empty:SetPoint("TOP",rows,"TOP",0,-70)
    end
    local prev=ForeverBrowser_CodexButton(PageContent,"Previous",85) prev:SetPoint("TOPLEFT",rows,"BOTTOMLEFT",0,-8)
    prev:SetScript("OnClick",function() ForeverBrowser_N187Browse(mode,query,page-1) end)
    local next=ForeverBrowser_CodexButton(PageContent,"Next",85) next:SetPoint("TOPRIGHT",rows,"BOTTOMRIGHT",0,-8)
    next:SetScript("OnClick",function() ForeverBrowser_N187Browse(mode,query,page+1) end)
    local label=ForeverBrowser_AchievementLabel(PageContent,"Page "..page.." / "..pages,11,{0.86,0.75,0.51,1})
    label:SetPoint("TOP",rows,"BOTTOM",0,-14)
end

function ForeverBrowser_BuildNPCDatabasePage()
    ClearPage() PageContent:SetHeight(1040)
    local hero=CreateFrame("Frame",nil,PageContent) hero:SetSize(700,170) hero:SetPoint("TOP",PageContent,"TOP",0,-16)
    CreateSolidBackground(hero,0.035,0.025,0.014,1) ForeverBrowser_AchievementBorder(hero,true)
    local emblem=hero:CreateTexture(nil,"ARTWORK") emblem:SetSize(62,62) emblem:SetPoint("TOPLEFT",hero,"TOPLEFT",20,-23)
    emblem:SetTexture("Interface\\Icons\\Ability_Hunter_BeastCall")
    local title=ForeverBrowser_AchievementLabel(hero,"The NPC Codex",26,{1,0.82,0.28,1}) title:SetPoint("TOPLEFT",hero,"TOPLEFT",98,-22)
    local subtitle=ForeverBrowser_AchievementLabel(hero,"Find the people, creatures and encounters of Azeroth & Forever.",12,{0.87,0.81,0.67,1})
    subtitle:SetPoint("TOPLEFT",hero,"TOPLEFT",98,-62) subtitle:SetWidth(577) subtitle:SetJustifyH("LEFT")
    local search=CreateFrame("EditBox",nil,hero,"InputBoxTemplate") search:SetSize(450,30) search:SetPoint("TOPLEFT",hero,"TOPLEFT",24,-106)
    search:SetAutoFocus(false) search:SetFontObject("ChatFontNormal")
    local button=ForeverBrowser_CodexButton(hero,"Search NPCs",125) button:SetPoint("LEFT",search,"RIGHT",17,0)
    local function run() search:ClearFocus() ForeverBrowser_N187Search(search:GetText()) end
    search:SetScript("OnEnterPressed",run) search:SetScript("OnEscapePressed",function(self) self:ClearFocus() end) button:SetScript("OnClick",run)
    local hint=ForeverBrowser_AchievementLabel(hero,"Search by name or exact NPC ID",10,{0.67,0.61,0.47,1}) hint:SetPoint("BOTTOMLEFT",hero,"BOTTOMLEFT",24,12)
    local modes={"all","vendor","trainer","location","forever","quests"}
    local titles={all="Browse All NPCs",vendor="Vendors",trainer="Trainers",location="Locations",forever="Forever NPCs",quests="Quest Givers"}
    local descriptions={all="Open the complete database of known NPC records.",vendor="Find merchants with recorded vendor inventories.",trainer="Explore trainers recorded in the profession database.",location="Browse NPCs with recorded location data.",forever="Discover custom Forever NPCs and encounters.",quests="Find NPCs explicitly identified as quest starters."}
    local icons={all="Ability_Hunter_BeastCall",vendor="INV_Misc_Coin_01",trainer="Trade_BlackSmithing",location="INV_Misc_Map_01",forever="INV_Misc_Gem_Amethyst_02",quests="INV_Misc_Note_01"}
    local counts={} for _,mode in ipairs(modes) do counts[mode]=#ForeverBrowser_N187List(mode) end
    for i,mode in ipairs({"all","vendor","trainer","forever"}) do
        local stat=CreateFrame("Button",nil,PageContent) stat:SetSize(166,62)
        stat:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",(i-1)*178,-12) ForeverBrowser_AchievementPaper(stat,true)
        local number=ForeverBrowser_AchievementLabel(stat,tostring(counts[mode]),22,{0.31,0.18,0.03,1}) number:SetPoint("TOP",stat,"TOP",0,-7)
        local label=ForeverBrowser_AchievementLabel(stat,titles[mode],10,{0.34,0.28,0.17,1}) label:SetPoint("BOTTOM",stat,"BOTTOM",0,9)
        stat:SetScript("OnClick",function() Navigate("forever://npcbrowse/"..mode) end)
    end
    local heading=ForeverBrowser_AchievementLabel(PageContent,"Explore the Database",18,{1,0.82,0.28,1}) heading:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",0,-94)
    for i,mode in ipairs(modes) do
        local card=CreateFrame("Button",nil,PageContent) card:SetSize(338,100)
        card:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",i%2==1 and 0 or 362,-125-math.floor((i-1)/2)*112)
        ForeverBrowser_AchievementPaper(card,true)
        local icon=card:CreateTexture(nil,"ARTWORK") icon:SetSize(39,39) icon:SetPoint("TOPLEFT",card,"TOPLEFT",14,-14)
        icon:SetTexture("Interface\\Icons\\"..icons[mode])
        local title=ForeverBrowser_AchievementLabel(card,titles[mode],17,{0.29,0.16,0.03,1}) title:SetPoint("TOPLEFT",card,"TOPLEFT",67,-15)
        local desc=ForeverBrowser_AchievementLabel(card,descriptions[mode],11,{0.30,0.25,0.16,1}) desc:SetPoint("TOPLEFT",card,"TOPLEFT",67,-43)
        desc:SetSize(251,31) desc:SetJustifyH("LEFT") desc:SetJustifyV("TOP")
        local count=ForeverBrowser_AchievementLabel(card,counts[mode].." records  >",10,{0.38,0.25,0.08,1}) count:SetPoint("BOTTOMLEFT",card,"BOTTOMLEFT",67,10)
        card:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight") card:SetScript("OnClick",function() Navigate("forever://npcbrowse/"..mode) end)
    end
    local featured=ForeverBrowser_AchievementLabel(PageContent,"Forever Spotlight",18,{1,0.82,0.28,1}) featured:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",0,-474)
    local section=CreateFrame("Frame",nil,PageContent) section:SetSize(700,164) section:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",0,-508)
    local customs=ForeverBrowser_N187List("forever")
    for i=1,math.min(3,#customs) do ForeverBrowser_N187NPCRow(section,customs[i],-(i-1)*54,700) end
    if #customs==0 then
        local empty=ForeverBrowser_AchievementLabel(section,"No custom Forever NPC records are loaded.",12,{0.78,0.73,0.61,1}) empty:SetPoint("TOPLEFT",section,"TOPLEFT",8,-10)
    end
    local recentTitle=ForeverBrowser_AchievementLabel(PageContent,"Recently Viewed",18,{1,0.82,0.28,1}) recentTitle:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",0,-687)
    local recent=CreateFrame("Frame",nil,PageContent) recent:SetSize(700,110) recent:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",0,-720)
    local db=GetDatabase() or {} local index=ForeverBrowser_N187Index() local n=0
    for _,id in ipairs(db.browserRecentNPC187 or {}) do
        if index[id] and n<2 then ForeverBrowser_N187NPCRow(recent,index[id],-n*54,700) n=n+1 end
    end
    if n==0 then
        local empty=ForeverBrowser_AchievementLabel(recent,"Open an NPC record to start your browsing history.",12,{0.78,0.73,0.61,1}) empty:SetPoint("TOPLEFT",recent,"TOPLEFT",8,-10)
    end
end

function ForeverBrowser_BuildQuestRewardsPage()
    ClearPage()
    PageContent:SetHeight(820)

    ForeverBrowserQuestRewardPage=ForeverBrowserQuestRewardPage or 1
    ForeverBrowserQuestRewardFilter=ForeverBrowserQuestRewardFilter or "ALL"
    ForeverBrowserQuestRewardSort=ForeverBrowserQuestRewardSort or "LEVEL"
    ForeverBrowserQuestRewardExpanded=ForeverBrowserQuestRewardExpanded or {}

    local title=ForeverBrowser_AchievementLabel(PageContent,"QUEST REWARDS",24,{0.72,0.52,1.00,1})
    title:SetPoint("TOP",PageContent,"TOP",0,-24)

    local subtitle=ForeverBrowser_AchievementLabel(
        PageContent,
        "Find quests by reward item, XP, money, reputation, and character progress.",
        11,{0.58,0.62,0.70,1}
    )
    subtitle:SetPoint("TOP",title,"BOTTOM",0,-7)

    local hero=ForeverBrowser_QuestBanner193(title,subtitle,"Interface\\Icons\\INV_Misc_Gift_01")

    local back=ForeverBrowser_ItemButton190(PageContent,"< QUEST DATABASE",145,25)
    back:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,-20)
    back:SetScript("OnClick",function() Navigate("forever://quests") end)

    local searchBox=CreateFrame("EditBox",nil,PageContent,"InputBoxTemplate")
    searchBox:SetSize(450,30)
    searchBox:SetPoint("TOPLEFT",hero,"TOPLEFT",24,-106)
    searchBox:SetAutoFocus(false)
    searchBox:SetFontObject(ChatFontNormal)

    local searchButton=ForeverBrowser_ItemButton190(PageContent,"SEARCH",82,26)
    searchButton:SetPoint("LEFT",searchBox,"RIGHT",10,0)

    local summary=ForeverBrowser_AchievementLabel(PageContent,"BUILDING REWARD INDEX...",9,{0.48,0.53,0.62,1})
    summary:SetPoint("TOP",hero,"BOTTOM",0,-14)

    local progressText=ForeverBrowser_AchievementLabel(PageContent,"",9,{0.52,0.57,0.66,1})
    progressText:SetPoint("TOP",summary,"BOTTOM",0,-6)
    local summaryPaper=ForeverBrowser_QuestSummary193(summary)
    progressText:SetParent(summaryPaper)
    progressText:SetTextColor(0.38,0.28,0.15,1)

    local progressBar=CreateFrame("Frame",nil,PageContent)
    progressBar:SetSize(360,8)
    progressBar:SetPoint("TOP",progressText,"BOTTOM",0,-4)
    local progressBG=progressBar:CreateTexture(nil,"BACKGROUND")
    progressBG:SetAllPoints(progressBar)
    progressBG:SetTexture("Interface\\Buttons\\WHITE8X8")
    progressBG:SetVertexColor(0.055,0.045,0.033,0.95)
    local progressFill=progressBar:CreateTexture(nil,"ARTWORK")
    progressFill:SetPoint("LEFT",progressBar,"LEFT",0,0)
    progressFill:SetHeight(8)
    progressFill:SetTexture("Interface\\Buttons\\WHITE8X8")
    progressFill:SetVertexColor(0.20,0.72,0.36,0.85)

    local filterBar=CreateFrame("Frame",nil,PageContent)
    filterBar:SetSize(760,28)
    filterBar:SetPoint("TOP",progressBar,"BOTTOM",0,-9)

    local results=CreateFrame("Frame",nil,PageContent)
    results:SetSize(720,410)
    results:SetPoint("TOP",filterBar,"BOTTOM",0,-8)
    results._children={}

    local function Keep(x)
        table.insert(results._children,x)
        return x
    end

    local function Wipe()
        for _,x in ipairs(results._children) do
            if x and x.Hide then x:Hide() end
        end
        results._children={}
    end

    local function RewardItemList(q,fields)
        local out,seen={},{}
        if type(q)~="table" then return out end
        for _,field in ipairs(fields) do
            local data=q[field]
            if type(data)=="table" then
                for _,v in pairs(data) do
                    local id=nil
                    local count=1
                    if type(v)=="number" or type(v)=="string" then
                        id=tonumber(v)
                    elseif type(v)=="table" then
                        id=tonumber(v.id or v.itemID or v.itemId)
                        count=tonumber(v.count or v.amount) or 1
                    end
                    if id and not seen[id] then
                        seen[id]=true
                        table.insert(out,{id=id,count=count})
                    end
                end
            end
        end
        return out
    end

    local function QuestStarter(q)
        if type(q)~="table" then return nil,nil end
        local id=tonumber(q.giverID or q.startNPC or q.starterNPC or q.questGiver)
        local name=q.giverName or q.starterName or q.startNPCName
        if (not name or name=="") and id then
            local npcs=ForeverSourceData and ForeverSourceData.npcs or {}
            local npc=npcs[id] or npcs[tostring(id)]
            if type(npc)=="table" then name=npc.name end
        end
        if (not id) and type(q.npcStarters)=="table" then
            for _,v in pairs(q.npcStarters) do
                if type(v)=="table" then
                    id=tonumber(v.id or v.npcID or v.npcId)
                    name=name or v.name
                else
                    id=tonumber(v)
                end
                if id then break end
            end
        end
        return id,name
    end

    local function RepCount(q)
        if type(q)~="table" then return 0 end
        local r=q.reputationRewards or q.reputation or q.repRewards
        if type(r)~="table" then return 0 end
        local n=0
        for _ in pairs(r) do n=n+1 end
        return n
    end

    local function BuildIndex()
        local index={}
        local quests=ForeverSourceData and ForeverSourceData.quests or {}
        for key,q in pairs(quests) do
            local id=tonumber(key)
            if not id and type(q)=="table" then id=tonumber(q.id) end
            if id and type(q)=="table" then
                local guaranteed=RewardItemList(q,{"rewardItems","rewards"})
                local choices=RewardItemList(q,{"choiceRewardItems","choiceRewards"})
                local xp=tonumber(q.rewardXP) or 0
                local money=tonumber(q.rewardMoney) or 0
                local moneyMax=tonumber(q.rewardMoneyMaxLevel) or 0
                local repCount=RepCount(q)

                if #guaranteed>0 or #choices>0 or xp>0 or money>0
                    or moneyMax>0 or repCount>0 then

                    local itemSearch={}
                    local equipmentSlots={}
                    local function IndexRewardItem(r)
                        table.insert(itemSearch,string.lower(tostring(GetItemName(r.id) or "")))
                        local item=GetAnyItem(r.id)
                        if type(item)=="table" then
                            local slot=tostring(
                                item.equipSlot or item.inventoryType or item.slot or ""
                            )
                            if slot~="" then equipmentSlots[string.upper(slot)]=true end
                        end
                    end
                    for _,r in ipairs(guaranteed) do IndexRewardItem(r) end
                    for _,r in ipairs(choices) do IndexRewardItem(r) end

                    local starterID,starterName=QuestStarter(q)
                    table.insert(index,{
                        id=id,
                        q=q,
                        name=tostring(q.name or q.title or ("Quest "..id)),
                        level=tonumber(q.level or q.questLevel) or 0,
                        zone=tostring(q.zone or q.zoneName or q.areaName or ""),
                        guaranteed=guaranteed,
                        choices=choices,
                        xp=xp,
                        money=money,
                        moneyMax=moneyMax,
                        repCount=repCount,
                        itemSearch=table.concat(itemSearch," "),
                        starterID=starterID,
                        starterName=starterName,
                        equipmentSlots=equipmentSlots
                    })
                end
            end
        end
        return index
    end

    ForeverBrowserQuestRewardIndex=
        ForeverBrowserQuestRewardIndex or BuildIndex()

    local function MoneyText(copper)
        copper=tonumber(copper) or 0
        local g=math.floor(copper/10000)
        local s2=math.floor((copper%10000)/100)
        local c=copper%100
        local parts={}
        if g>0 then table.insert(parts,tostring(g).."g") end
        if s2>0 then table.insert(parts,tostring(s2).."s") end
        if c>0 or #parts==0 then table.insert(parts,tostring(c).."c") end
        return table.concat(parts," ")
    end

    local Render

    local function MatchesFilter(entry,filter,status)
        if filter=="ALL" then return true end
        if filter=="ITEMS" then return #entry.guaranteed>0 or #entry.choices>0 end
        if filter=="XP" then return entry.xp>0 end
        if filter=="MONEY" then return entry.money>0 or entry.moneyMax>0 end
        if filter=="REPUTATION" then return entry.repCount>0 end
        if filter=="EQUIPMENT" then
            for _ in pairs(entry.equipmentSlots or {}) do return true end
            return false
        end
        if filter=="IN PROGRESS" then
            return status=="IN PROGRESS" or status=="IN QUEST LOG"
        end
        if filter=="STILL AVAILABLE" then return status~="COMPLETED" end
        return true
    end

    local function CurrentList()
        local query=string.lower(searchBox:GetText() or "")
        query=string.gsub(query,"^%s+","")
        query=string.gsub(query,"%s+$","")
        local out={}
        for _,entry in ipairs(ForeverBrowserQuestRewardIndex) do
            local status=false
            if type(ForeverBrowser_GetQuestPlayerStatus)=="function" then
                local ok,v=pcall(ForeverBrowser_GetQuestPlayerStatus,entry.id)
                if ok then status=v end
            end
            local hay=string.lower(entry.name).." "..entry.itemSearch
            if (query=="" or string.find(hay,query,1,true))
                and MatchesFilter(entry,ForeverBrowserQuestRewardFilter,status) then
                entry._status=status
                table.insert(out,entry)
            end
        end

        local sort=ForeverBrowserQuestRewardSort
        table.sort(out,function(a,b)
            if sort=="NAME" then
                return string.lower(a.name)<string.lower(b.name)
            elseif sort=="XP" then
                if a.xp~=b.xp then return a.xp>b.xp end
            elseif sort=="REWARD VALUE" then
                local av=a.money+a.moneyMax+(a.xp or 0)
                local bv=b.money+b.moneyMax+(b.xp or 0)
                if av~=bv then return av>bv end
            else
                if a.level~=b.level then return a.level>b.level end
            end
            return string.lower(a.name)<string.lower(b.name)
        end)
        return out
    end

    local function AddItemChip(parent,item,x,y,label)
        local chip=CreateFrame("Button",nil,parent)
        chip:SetSize(185,24)
        chip:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)

        local bg=chip:CreateTexture(nil,"BACKGROUND")
        bg:SetAllPoints(chip)
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetVertexColor(0.055,0.045,0.033,0.96)

        local icon=chip:CreateTexture(nil,"ARTWORK")
        icon:SetSize(20,20)
        icon:SetPoint("LEFT",chip,"LEFT",2,0)
        icon:SetTexture(GetItemIcon(item.id,GetAnyItem(item.id)))

        local itemData=GetAnyItem(item.id)
        local itemName=GetItemName(item.id)
        if (tonumber(item.count) or 1)>1 then
            itemName=itemName.." x"..tostring(item.count)
        end
        local color={0.86,0.88,0.92,1}
        if type(itemData)=="table" then
            local quality=tonumber(itemData.quality or itemData.rarity)
            local qc={
                [0]={0.62,0.62,0.62,1},
                [1]={1.00,1.00,1.00,1},
                [2]={0.12,1.00,0.12,1},
                [3]={0.00,0.44,0.87,1},
                [4]={0.64,0.21,0.93,1},
                [5]={1.00,0.50,0.00,1}
            }
            if quality and qc[quality] then color=qc[quality] end
        end
        local nm=ForeverBrowser_AchievementLabel(chip,itemName,8,color)
        nm:SetPoint("LEFT",icon,"RIGHT",5,0)
        nm:SetWidth(150)
        nm:SetJustifyH("LEFT")

        chip:SetScript("OnEnter",function(self)
            if ForeverDBDatabase and ForeverDBDatabase.browserSettings
                and ForeverDBDatabase.browserSettings.showItemTooltips==false then
                return
            end
            if GameTooltip and item.id then
                GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
                pcall(function()
                    GameTooltip:SetHyperlink("item:"..tostring(item.id))
                end)
                GameTooltip:Show()
            end
        end)
        chip:SetScript("OnLeave",function()
            if GameTooltip then GameTooltip:Hide() end
        end)

        chip:SetScript("OnClick",function()
            Navigate("forever://item/"..tostring(item.id))
        end)
        return chip
    end

    local function RewardRow(entry,y)
        local row=Keep(CreateFrame("Frame",nil,results))
        row:SetSize(690,88)
        row:SetPoint("TOP",results,"TOP",0,y)

        local bg=row:CreateTexture(nil,"BACKGROUND")
        bg:SetAllPoints(row)
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetVertexColor(unpack(WOW_THEME.row))
        ForeverBrowser_AchievementBorder(row,true)

        local accent=row:CreateTexture(nil,"ARTWORK")
        accent:SetPoint("LEFT",row,"LEFT",0,0)
        accent:SetSize(3,88)
        accent:SetTexture("Interface\\Buttons\\WHITE8X8")
        if entry._status=="COMPLETED" then
            accent:SetVertexColor(0.20,0.72,0.36,1)
        elseif entry._status=="IN PROGRESS" or entry._status=="IN QUEST LOG" then
            accent:SetVertexColor(0.28,0.58,1.00,1)
        else
            accent:SetVertexColor(0.72,0.52,1.00,1)
        end

        local qbtn=CreateFrame("Button",nil,row)
        qbtn:SetSize(330,34)
        qbtn:SetPoint("TOPLEFT",row,"TOPLEFT",12,-7)

        local qname=ForeverBrowser_AchievementLabel(qbtn,entry.name,11,{0.95,0.95,0.98,1})
        qname:SetPoint("TOPLEFT",qbtn,"TOPLEFT",0,0)
        qname:SetWidth(325)
        qname:SetJustifyH("LEFT")

        local meta="Level "..tostring(entry.level)
        if entry.zone~="" then meta=meta.."  •  "..entry.zone end
        local mt=ForeverBrowser_AchievementLabel(qbtn,meta,8,{0.48,0.53,0.61,1})
        mt:SetPoint("TOPLEFT",qname,"BOTTOMLEFT",0,-3)

        qbtn:SetScript("OnClick",function()
            Navigate("forever://quest/"..tostring(entry.id))
        end)

        local types={}
        if #entry.guaranteed>0 or #entry.choices>0 then table.insert(types,"ITEMS") end
        if entry.xp>0 then table.insert(types,"XP") end
        if entry.money>0 or entry.moneyMax>0 then table.insert(types,"MONEY") end
        if entry.repCount>0 then table.insert(types,"REPUTATION") end
        local typeText=ForeverBrowser_AchievementLabel(
            row,
            table.concat(types," + ").." REWARDS",
            8,{0.72,0.52,1.00,1}
        )
        typeText:SetPoint("TOPLEFT",row,"TOPLEFT",355,-9)

        if entry._status=="COMPLETED" then
            local st=ForeverBrowser_AchievementLabel(row,"COMPLETED",9,{0.28,0.88,0.46,1})
            st:SetPoint("TOPRIGHT",row,"TOPRIGHT",-12,-9)
        elseif entry._status=="IN PROGRESS" or entry._status=="IN QUEST LOG" then
            local st=ForeverBrowser_AchievementLabel(row,"IN PROGRESS",9,{0.35,0.66,1.00,1})
            st:SetPoint("TOPRIGHT",row,"TOPRIGHT",-12,-9)
        end

        local rewardBits={}
        if entry.xp>0 then table.insert(rewardBits,tostring(entry.xp).." XP") end
        if entry.money>0 then table.insert(rewardBits,MoneyText(entry.money)) end
        if entry.repCount>0 then table.insert(rewardBits,tostring(entry.repCount).." REP REWARD") end
        local info=ForeverBrowser_AchievementLabel(row,table.concat(rewardBits,"  •  "),8,{0.80,0.67,0.30,1})
        info:SetPoint("TOPLEFT",row,"TOPLEFT",355,-31)

        local x=12
        local shown=0
        local expanded=ForeverBrowserQuestRewardExpanded[entry.id]==true
        local maxItems=expanded and 3 or 2

        if #entry.guaranteed>0 then
            local lab=ForeverBrowser_AchievementLabel(row,"YOU RECEIVE",7,{0.52,0.57,0.66,1})
            lab:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",12,35)
        elseif #entry.choices>0 then
            local lab=ForeverBrowser_AchievementLabel(row,"CHOOSE ONE",7,{0.52,0.57,0.66,1})
            lab:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",12,35)
        end

        for _,item in ipairs(entry.guaranteed) do
            if shown>=maxItems then break end
            Keep(AddItemChip(row,item,x,-60,"REWARD"))
            x=x+192
            shown=shown+1
        end
        for _,item in ipairs(entry.choices) do
            if shown>=maxItems then break end
            Keep(AddItemChip(row,item,x,-60,"CHOOSE"))
            x=x+192
            shown=shown+1
        end

        local totalItems=#entry.guaranteed+#entry.choices
        if totalItems>2 then
            local expand=ForeverBrowser_ItemButton190(
                row,
                expanded and "COLLAPSE" or ("MORE ("..tostring(totalItems)..")"),
                78,20
            )
            expand:SetPoint("RIGHT",row,"RIGHT",-10,0)
            expand:SetScript("OnClick",function()
                ForeverBrowserQuestRewardExpanded[entry.id]=not expanded
                Render(false)
            end)
        end

        if shown==0 then
            local text={}
            if entry.xp>0 then table.insert(text,tostring(entry.xp).." XP") end
            if entry.money>0 then table.insert(text,MoneyText(entry.money)) end
            if entry.moneyMax>0 then
                table.insert(text,"Max-level "..MoneyText(entry.moneyMax))
            end
            if entry.repCount>0 then
                table.insert(text,tostring(entry.repCount).." reputation reward(s)")
            end
            local r=ForeverBrowser_AchievementLabel(row,table.concat(text,"  •  "),9,{0.74,0.76,0.82,1})
            r:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",12,10)
        end

        if entry.starterName and entry.starterName~="" then
            local starter=CreateFrame("Button",nil,row)
            starter:SetSize(245,18)
            starter:SetPoint("TOPRIGHT",row,"TOPRIGHT",-10,-47)
            local t=ForeverBrowser_AchievementLabel(starter,"STARTS FROM  "..entry.starterName,8,{0.35,0.72,1.00,1})
            t:SetPoint("RIGHT",starter,"RIGHT",0,0)
            if entry.starterID then
                starter:SetScript("OnClick",function()
                    Navigate("forever://npc/"..tostring(entry.starterID))
                end)
            end
        end
    end

    Render=function(resetPage)
        Wipe()
        if resetPage then ForeverBrowserQuestRewardPage=1 end

        local list=CurrentList()
        local perPage=4
        local totalPages=math.max(1,math.ceil(#list/perPage))
        local page=ForeverBrowserQuestRewardPage
        if page<1 then page=1 end
        if page>totalPages then page=totalPages end
        ForeverBrowserQuestRewardPage=page

        local query=searchBox:GetText() or ""
        local firstResult=(#list>0) and (((page-1)*perPage)+1) or 0
        local lastResult=math.min(#list,firstResult+perPage-1)
        local summaryText=tostring(#list).." REWARD QUESTS  •  RESULTS "..
            tostring(firstResult).."-"..tostring(lastResult)..
            "  •  PAGE "..page.." OF "..totalPages..
            "  •  SORT: "..ForeverBrowserQuestRewardSort
        if query~="" then
            summaryText='SEARCH RESULTS FOR "'..query..'"  •  '..summaryText
        end
        summary:SetText(summaryText)

        local completed,totalReward=0,#ForeverBrowserQuestRewardIndex
        for _,entry in ipairs(ForeverBrowserQuestRewardIndex) do
            local status=false
            if type(ForeverBrowser_GetQuestPlayerStatus)=="function" then
                local ok,v=pcall(ForeverBrowser_GetQuestPlayerStatus,entry.id)
                if ok then status=v end
            end
            if status=="COMPLETED" then completed=completed+1 end
        end
        local pct=(totalReward>0) and math.floor((completed/totalReward)*100+0.5) or 0
        progressText:SetText(
            "REWARD QUESTS COMPLETED: "..tostring(completed).."/"..
            tostring(totalReward).."  •  "..tostring(pct).."%"
        )
        progressFill:SetWidth(math.max(1,360*(pct/100)))

        local pager=Keep(CreateFrame("Frame",nil,results))
        pager:SetSize(280,24)
        pager:SetPoint("TOP",results,"TOP",0,0)

        if page>1 then
            local p=ForeverBrowser_ItemButton190(pager,"< PREV",70,22)
            p:SetPoint("LEFT",pager,"LEFT",0,0)
            p:SetScript("OnClick",function()
                ForeverBrowserQuestRewardPage=page-1
                Render(false)
            end)
        end
        local pt=ForeverBrowser_AchievementLabel(pager,"PAGE "..page.." OF "..totalPages,9,{0.60,0.64,0.72,1})
        pt:SetPoint("CENTER",pager,"CENTER",0,0)
        if page<totalPages then
            local n=ForeverBrowser_ItemButton190(pager,"NEXT >",70,22)
            n:SetPoint("RIGHT",pager,"RIGHT",0,0)
            n:SetScript("OnClick",function()
                ForeverBrowserQuestRewardPage=page+1
                Render(false)
            end)
        end

        local first=((page-1)*perPage)+1
        local last=math.min(#list,first+perPage-1)
        local y=-32
        for i=first,last do
            RewardRow(list[i],y)
            y=y-96
        end

        if #list==0 then
            local none=Keep(ForeverBrowser_AchievementLabel(
                results,
                "No quests match the current reward search and filter.",
                11,{0.60,0.62,0.68,1}
            ))
            none:SetPoint("TOP",results,"TOP",0,-50)

            local clear=ForeverBrowser_ItemButton190(results,"CLEAR FILTERS",105,23)
            Keep(clear)
            clear:SetPoint("TOP",none,"BOTTOM",0,-12)
            clear:SetScript("OnClick",function()
                searchBox:SetText("")
                ForeverBrowserQuestRewardFilter="ALL"
                ForeverBrowserQuestRewardSort="LEVEL"
                Render(true)
            end)
        end
    end

    local filters={"ALL","ITEMS","EQUIPMENT","XP","MONEY","REPUTATION","IN PROGRESS","STILL AVAILABLE"}
    local filterButtons={}
    local x=0
    local function UpdateFilterLabels()
        for name,button in pairs(filterButtons) do
            if button.text then
                button.text:SetText(
                    name==ForeverBrowserQuestRewardFilter and ("["..name.."]") or name
                )
            end
        end
    end
    for _,filter in ipairs(filters) do
        local w=(filter=="STILL AVAILABLE" and 104)
            or (filter=="IN PROGRESS" and 88)
            or (filter=="REPUTATION" and 82)
            or (filter=="EQUIPMENT" and 82)
            or 58
        local b=ForeverBrowser_ItemButton190(filterBar,filter,w,22)
        b:SetPoint("LEFT",filterBar,"LEFT",x,0)
        filterButtons[filter]=b
        b:SetScript("OnClick",function()
            ForeverBrowserQuestRewardFilter=filter
            UpdateFilterLabels()
            Render(true)
        end)
        x=x+w+4
    end
    UpdateFilterLabels()

    local sortButton=ForeverBrowser_ItemButton190(
        filterBar,
        "SORT: "..ForeverBrowserQuestRewardSort,
        108,22
    )
    sortButton:SetPoint("RIGHT",filterBar,"RIGHT",0,0)
    sortButton:SetScript("OnClick",function()
        local order={"LEVEL","REWARD VALUE","XP","NAME"}
        local current=1
        for i,v in ipairs(order) do
            if v==ForeverBrowserQuestRewardSort then current=i break end
        end
        current=current+1
        if current>#order then current=1 end
        ForeverBrowserQuestRewardSort=order[current]
        if sortButton.text then
            sortButton.text:SetText("SORT: "..ForeverBrowserQuestRewardSort)
        end
        Render(true)
    end)

    searchButton:SetScript("OnClick",function() Render(true) end)
    searchBox:SetScript("OnEnterPressed",function(self)
        self:ClearFocus()
        Render(true)
    end)

    Render(false)
end


local function BuildQuestDatabasePage()
    ForeverBrowser_DatabaseHome189("quests")
end

local function BuildQuestBrowsePage(initialText)

    ForeverBrowserCurrentQuestBrowseFilter =
        ForeverBrowserQuestBrowseFilter

    ClearPage()

    local rawQuery=tostring(initialText or "")
    local query=string.lower(rawQuery)

    local function GetRecentQuestSearches()
        local db=GetDatabase()
        if not db then return {} end
        db.recentQuestSearches=db.recentQuestSearches or {}
        return db.recentQuestSearches
    end

    local function AddRecentQuestSearch(searchText)
        searchText=tostring(searchText or "")
        searchText=string.gsub(searchText,"^%s+","")
        searchText=string.gsub(searchText,"%s+$","")
        if searchText=="" then return end
        local recent=GetRecentQuestSearches()
        for i=#recent,1,-1 do
            if string.lower(tostring(recent[i]))==string.lower(searchText) then
                table.remove(recent,i)
            end
        end
        table.insert(recent,1,searchText)
        while #recent>8 do table.remove(recent) end
    end

    if rawQuery~="" and BrowserSettingEnabled("saveRecentSearches") then
        AddRecentQuestSearch(rawQuery)
    end

    local title =
        ForeverBrowser_AchievementLabel(
            PageContent,
            "QUEST DATABASE",
            22,
            {1, 0.82, 0.25, 1}
        )

    title:SetPoint(
        "TOPLEFT",
        PageContent,
        "TOPLEFT",
        25,
        -20
    )

    local subtitle =
        ForeverBrowser_AchievementLabel(
            PageContent,
            "Search quests by quest name or Quest ID.",
            12,
            {0.62, 0.66, 0.74, 1}
        )

    subtitle:SetPoint(
        "TOPLEFT",
        title,
        "BOTTOMLEFT",
        0,
        -8
    )

    title:SetText(ForeverBrowserQuestBrowseFilter == "inprogress" and "Quests in Progress"
        or ForeverBrowserQuestBrowseFilter == "completed" and "Completed Quests" or "Quick Quest Search")
    local hero=ForeverBrowser_QuestBanner193(title,subtitle,"Interface\\Icons\\INV_Misc_Note_01")
    local back=ForeverBrowser_ItemButton190(PageContent,"Quest Codex",120,30)
    back:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,-20)
    back:SetScript("OnClick",function() Navigate("forever://quests") end)

    local searchBox =
        CreateFrame(
            "EditBox",
            nil,
            PageContent
        )

    searchBox:SetSize(450, 30)
    searchBox:SetPoint("TOPLEFT",hero,"TOPLEFT",24,-106)
    searchBox:SetAutoFocus(false)

    if searchBox.SetFontObject then
        searchBox:SetFontObject(
            "GameFontHighlight"
        )
    end

    searchBox:SetTextInsets(10, 10, 0, 0)
    searchBox:SetText(initialText or "")

    CreateSolidBackground(
        searchBox,
        0.015,
        0.02,
        0.035,
        1
    )

    ForeverBrowser_AchievementBorder(searchBox,false)

    local function RunSearch()
        local value =
            tostring(
                searchBox:GetText()
                or ""
            )

        Navigate(
            "forever://questbrowse/search/"
            .. value
        )
    end

    searchBox:SetScript(
        "OnEnterPressed",
        function(self)
            RunSearch()
            self:ClearFocus()
        end
    )

    searchBox:SetScript(
        "OnEscapePressed",
        function(self)
            self:ClearFocus()
        end
    )

    local searchButton =
        ForeverBrowser_ItemButton190(
            PageContent,
            "SEARCH",
            100,
            34
        )

    searchButton:SetPoint(
        "LEFT",
        searchBox,
        "RIGHT",
        10,
        0
    )

    searchButton:SetScript(
        "OnClick",
        RunSearch
    )

    local clearButton =
        ForeverBrowser_ItemButton190(
            PageContent,
            "CLEAR",
            80,
            34
        )

    clearButton:SetPoint(
        "LEFT",
        searchButton,
        "RIGHT",
        8,
        0
    )

    clearButton:SetScript(
        "OnClick",
        function()
            Navigate("forever://questbrowse")
        end
    )

    local quests =
        ForeverSourceData
        and ForeverSourceData.quests
        or {}

    local found = {}
    local numeric = tonumber(query)

    if query ~= "" then
        for questID, questData
            in pairs(quests) do

            local id =
                tonumber(questID)
                or tonumber(
                    questData
                    and questData.id
                )

            local name =
                tostring(
                    questData
                    and questData.name
                    or ("Quest " .. tostring(id or questID))
                )

            local lowerName =
                string.lower(name)

            local matches =
                (numeric and id == numeric)
                or string.find(
                    lowerName,
                    query,
                    1,
                    true
                )

            if matches then
                table.insert(
                    found,
                    {
                        id = id,
                        name = name,
                        data = questData
                    }
                )
            end
        end

        table.sort(
            found,
            function(a, b)
                if numeric then
                    return (a.id or 0)
                        < (b.id or 0)
                end

                local an =
                    string.lower(
                        a.name or ""
                    )
                local bn =
                    string.lower(
                        b.name or ""
                    )

                local aStarts =
                    string.sub(an, 1, string.len(query))
                    == query

                local bStarts =
                    string.sub(bn, 1, string.len(query))
                    == query

                if aStarts ~= bStarts then
                    return aStarts
                end

                if an == bn then
                    return (a.id or 0)
                        < (b.id or 0)
                end

                return an < bn
            end
        )
    end

    if ForeverBrowserQuestBrowseFilter == "inprogress" then
        -- IN PROGRESS is driven directly by the player's CURRENT quest log.
        -- Rebuild the results every time this page opens/refreshes so accepted
        -- quests appear and abandoned/turned-in quests disappear.
        ForeverBrowser_ScanQuestLog()

        local liveResults = {}
        local questTable =
            ForeverSourceData
            and ForeverSourceData.quests
            or {}

        for liveQuestID in pairs(ForeverBrowserQuestLogCache or {}) do
            local id = tonumber(liveQuestID)
            local questData =
                questTable[id]
                or questTable[tostring(id)]

            if id then
                table.insert(
                    liveResults,
                    {
                        id = id,
                        name =
                            questData
                            and questData.name
                            or ("Quest " .. tostring(id)),
                        data = questData or {},
                    }
                )
            end
        end

        table.sort(
            liveResults,
            function(a,b)
                return string.lower(tostring(a.name))
                    < string.lower(tostring(b.name))
            end
        )

        found = liveResults
    elseif ForeverBrowserQuestBrowseFilter == "completed" then
        ForeverBrowser_UpdateQuestCompletionHistory()
        local completionHistory =
            ForeverBrowser_GetQuestCompletionHistory()

        -- COMPLETED is a dedicated character-aware view. Build it directly
        -- from the quest database and include only quests the client reports
        -- as completed for this character.
        local completedResults={}
        local questTable=
            ForeverSourceData
            and ForeverSourceData.quests
            or {}

        for questKey,questData in pairs(questTable) do
            local id=
                tonumber(questKey)
                or tonumber(questData and questData.id)

            if id then
                local done=false

                if C_QuestLog
                    and type(C_QuestLog.IsQuestFlaggedCompleted)=="function" then
                    local ok,value=
                        pcall(C_QuestLog.IsQuestFlaggedCompleted,id)
                    if ok and value==true then done=true end
                end

                if not done
                    and type(IsQuestFlaggedCompleted)=="function" then
                    local ok,value=
                        pcall(IsQuestFlaggedCompleted,id)
                    if ok and value==true then done=true end
                end

                if done then
                    table.insert(
                        completedResults,
                        {
                            id=id,
                            name=
                                questData
                                and questData.name
                                or ("Quest "..tostring(id)),
                            data=questData or {},
                            completedAt=
                                tonumber(completionHistory[id]) or 0,
                        }
                    )
                end
            end
        end


        -- Completed quests: newest tracked completion first.
        -- Quests completed before ForeverBrowser began tracking completion
        -- times have no recoverable historical order, so they remain below
        -- tracked completions in a stable alphabetical fallback order.
        table.sort(
            completedResults,
            function(a,b)
                local aTime=tonumber(a.completedAt) or 0
                local bTime=tonumber(b.completedAt) or 0

                if aTime~=bTime then
                    return aTime>bTime
                end

                local an=string.lower(tostring(a.name or ""))
                local bn=string.lower(tostring(b.name or ""))
                if an~=bn then return an<bn end
                return (tonumber(a.id) or 0)<(tonumber(b.id) or 0)
            end
        )

        local questsPerPage=10
        local totalCompleted=#completedResults
        local totalPages=math.max(1,math.ceil(totalCompleted/questsPerPage))

        ForeverBrowserCompletedQuestPage=
            math.max(
                1,
                math.min(
                    tonumber(ForeverBrowserCompletedQuestPage) or 1,
                    totalPages
                )
            )

        local pageStart=
            ((ForeverBrowserCompletedQuestPage-1)*questsPerPage)+1
        local pageEnd=
            math.min(pageStart+questsPerPage-1,totalCompleted)

        local pagedResults={}
        for index=pageStart,pageEnd do
            table.insert(pagedResults,completedResults[index])
        end
        found=pagedResults

        local pager=CreateFrame("Frame",nil,PageContent)
        pager:SetSize(360,32)
        pager:SetPoint("TOP",PageContent,"TOP",0,-295)

        local pageLabel=ForeverBrowser_AchievementLabel(
            pager,
            "PAGE "..tostring(ForeverBrowserCompletedQuestPage)
                .." OF "..tostring(totalPages),
            11,
            {0.72,0.76,0.84,1}
        )
        pageLabel:SetPoint("CENTER",pager,"CENTER",0,0)
        pageLabel:SetWidth(130)
        pageLabel:SetJustifyH("CENTER")

        local previousButton=ForeverBrowser_ItemButton190(pager,"< PREV",88,25)
        previousButton:SetPoint("RIGHT",pageLabel,"LEFT",-10,0)

        local nextButton=ForeverBrowser_ItemButton190(pager,"NEXT >",88,25)
        nextButton:SetPoint("LEFT",pageLabel,"RIGHT",10,0)

        if ForeverBrowserCompletedQuestPage<=1 then
            previousButton:Disable()
            previousButton:SetAlpha(0.35)
        else
            previousButton:SetScript("OnClick",function()
                ForeverBrowserCompletedQuestPage=
                    ForeverBrowserCompletedQuestPage-1
                BuildQuestBrowsePage("")
            end)
        end

        if ForeverBrowserCompletedQuestPage>=totalPages then
            nextButton:Disable()
            nextButton:SetAlpha(0.35)
        else
            nextButton:SetScript("OnClick",function()
                ForeverBrowserCompletedQuestPage=
                    ForeverBrowserCompletedQuestPage+1
                BuildQuestBrowsePage("")
            end)
        end
    end

    if ForeverBrowserQuestBrowseFilter == "inprogress" then
        local progressTitle=ForeverBrowser_AchievementLabel(
            PageContent,
            "QUESTS IN PROGRESS",
            18,
            {0.38,0.78,1.00,1}
        )
        progressTitle:SetPoint("TOP",PageContent,"TOP",0,-252)
        progressTitle:SetWidth(500)
        progressTitle:SetJustifyH("CENTER")
    elseif ForeverBrowserQuestBrowseFilter == "completed" then
        local completedTitle=ForeverBrowser_AchievementLabel(
            PageContent,
            "COMPLETED QUESTS",
            18,
            {0.42,0.90,0.50,1}
        )
        completedTitle:SetPoint("TOP",PageContent,"TOP",0,-252)
        completedTitle:SetWidth(500)
        completedTitle:SetJustifyH("CENTER")
    end

    local statusText

    if query == "" then
        statusText =
            "Enter a quest name or Quest ID to search the quest database."
    elseif #found == 0 then
        statusText =
            "No quests found for \""
            .. tostring(initialText or "")
            .. "\"."
    else
        statusText =
            tostring(#found)
            .. " quest"
            .. (#found == 1 and "" or "s")
            .. " found"
    end

    local status =
        ForeverBrowser_AchievementLabel(
            PageContent,
            statusText,
            12,
            {0.62, 0.66, 0.74, 1}
        )

    status:SetPoint(
        "TOPLEFT",
        searchBox,
        "BOTTOMLEFT",
        0,
        -15
    )

    ForeverBrowser_QuestSummary193(status)

    -- Results begin below the Recent Searches strip.
    -- This keeps recent-search buttons from being drawn behind quest result rows.
    local recentRows = 0
    if ForeverBrowserQuestBrowseFilter ~= "inprogress"
        and ForeverBrowserQuestBrowseFilter ~= "completed"
        and type(recentSearches) == "table"
        and #recentSearches > 0 then
        recentRows = math.ceil(math.min(#recentSearches, 8) / 3)
    end

    local y = -250 - (recentRows * 42)
    if ForeverBrowserQuestBrowseFilter == "inprogress" then
        y = -298
    elseif ForeverBrowserQuestBrowseFilter == "completed" then
        y = -342
    end
    local shown = 0
    local maxResults = 100

    for _, result
        in ipairs(found) do

        if shown >= maxResults then
            break
        end

        if result.id then
            shown = shown + 1

            local questData =
                result.data or {}

            local row =
                CreateFrame(
                    "Button",
                    nil,
                    PageContent
                )

            row:SetSize(735, 58)
            row:SetPoint(
                "TOPLEFT",
                PageContent,
                "TOPLEFT",
                25,
                y
            )

            local bg =
                CreateSolidBackground(
                    row,
                    0.055,0.045,0.033,1)
            ForeverBrowser_AchievementBorder(row,true)

            local questName =
                ForeverBrowser_AchievementLabel(
                    row,
                    "|cffffd100["
                    .. tostring(result.name)
                    .. "]|r",
                    14,
                    {1, 1, 1, 1}
                )

            questName:SetPoint(
                "TOPLEFT",
                row,
                "TOPLEFT",
                12,
                -9
            )

            questName:SetWidth(510)
            questName:SetHeight(18)
            questName:SetJustifyH("LEFT")

            local details =
                "Quest ID "
                .. tostring(result.id)

            if questData.level
                and tostring(questData.level) ~= "" then
                details =
                    details
                    .. "   |   Level "
                    .. tostring(questData.level)
            end

            if questData.faction
                and tostring(questData.faction) ~= "" then
                details =
                    details
                    .. "   |   "
                    .. tostring(questData.faction)
            end

            local detailLabel =
                ForeverBrowser_AchievementLabel(
                    row,
                    details,
                    11,
                    {0.45, 0.75, 1, 1}
                )

            detailLabel:SetPoint(
                "TOPLEFT",
                questName,
                "BOTTOMLEFT",
                0,
                -6
            )

            local savedQuestID =
                result.id

            -- Show the player's live quest status on every Quest Database
            -- browse/search result row, not only on the full quest page.
            ForeverBrowser_AddQuestStatusVisual(
                row,
                savedQuestID,
                questName
            )


            row:EnableMouse(true)
            row:RegisterForClicks(
                "LeftButtonUp"
            )

            row:SetScript(
                "OnClick",
                function()
                    Navigate(
                        "forever://quest/"
                        .. tostring(
                            savedQuestID
                        )
                    )
                end
            )

            row:SetScript(
                "OnEnter",
                function()
                    bg:SetVertexColor(
                        0.12,
                        0.09,
                        0.045,
                        1
                    )
                end
            )

            row:SetScript(
                "OnLeave",
                function()
                    bg:SetVertexColor(
                        0.055,
                        0.045,
                        0.033,
                        1
                    )
                end
            )

            y = y - 64
        end
    end

    if #found > maxResults then
        local more =
            ForeverBrowser_AchievementLabel(
                PageContent,
                "Showing the first "
                .. tostring(maxResults)
                .. " results. Refine your search to narrow the list.",
                11,
                {0.72, 0.72, 0.78, 1}
            )

        more:SetPoint(
            "TOPLEFT",
            PageContent,
            "TOPLEFT",
            25,
            y - 4
        )

        y = y - 30
    end

    PageContent:SetHeight(
        math.max(
            650,
            math.abs(y) + 60
        )
    )
    if rawQuery==""
        and ForeverBrowserQuestBrowseFilter ~= "inprogress"
        and ForeverBrowserQuestBrowseFilter ~= "completed" then
        local recent=GetRecentQuestSearches()
        if #recent>0 then
            local recentTitle=ForeverBrowser_AchievementLabel(PageContent,"RECENT SEARCHES",13,{1,0.82,0.25,1})
            recentTitle:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,-252)

            local rx=25
            local ry=-285
            for i,recentText in ipairs(recent) do
                local recentButton=CreateFrame("Button",nil,PageContent)
                recentButton:SetSize(225,34)
                recentButton:SetFrameStrata("HIGH")
                recentButton:SetFrameLevel((PageContent:GetFrameLevel() or 1) + 10)
                recentButton:SetPoint("TOPLEFT",PageContent,"TOPLEFT",rx,ry)
                CreateSolidBackground(recentButton,0.055,0.045,0.033,1)
            ForeverBrowser_AchievementBorder(recentButton,true)
                local recentLabel=ForeverBrowser_AchievementLabel(recentButton,tostring(recentText),11,{0.82,0.84,0.9,1})
                recentLabel:SetPoint("LEFT",recentButton,"LEFT",10,0)
                recentLabel:SetWidth(180)
                recentLabel:SetJustifyH("LEFT")
                recentButton:SetScript("OnClick",function()
                    Navigate("forever://quests/"..tostring(recentText))
                end)
                if i%3==0 then
                    rx=25
                    ry=ry-42
                else
                    rx=rx+245
                end
            end
        end
    end


end



--------------------------------------------------
-- NPC DATABASE
--------------------------------------------------


-- Global refresh bridge used by QUEST_LOG_UPDATE without adding another
-- upvalue to the quest-log watcher.
ForeverBrowser_RefreshQuestBrowsePage = BuildQuestBrowsePage

local function BuildNPCDatabasePage(initialText)

    ClearPage()

    local rawQuery =
        tostring(initialText or "")

    local query =
        string.lower(rawQuery)

    --------------------------------------------------
    -- RECENT NPC SEARCHES
    --------------------------------------------------

    local function GetRecentNPCSearches()
        local db = GetDatabase()

        if not db then
            return {}
        end

        db.recentNPCSearches =
            db.recentNPCSearches
            or {}

        return db.recentNPCSearches
    end

    local function AddRecentNPCSearch(searchText)
        searchText = tostring(searchText or "")

        searchText =
            string.gsub(
                searchText,
                "^%s+",
                ""
            )

        searchText =
            string.gsub(
                searchText,
                "%s+$",
                ""
            )

        if searchText == "" then
            return
        end

        local recent =
            GetRecentNPCSearches()

        for i = #recent, 1, -1 do
            local oldSearch = recent[i]

            if type(oldSearch) == "table" then
                oldSearch =
                    oldSearch.search
                    or oldSearch.name
                    or ""
            end

            if string.lower(tostring(oldSearch))
                == string.lower(searchText) then

                table.remove(recent, i)
            end
        end

        local displayName = searchText
        local numericSearch = tonumber(searchText)

        if numericSearch
            and ForeverSourceData
            and type(ForeverSourceData.npcs) == "table" then

            local npcData =
                ForeverSourceData.npcs[numericSearch]
                or ForeverSourceData.npcs[tostring(numericSearch)]

            if npcData
                and npcData.name
                and tostring(npcData.name) ~= "" then

                displayName = tostring(npcData.name)
            end
        end

        table.insert(
            recent,
            1,
            {
                search = searchText,
                name = displayName
            }
        )

        while #recent > 8 do
            table.remove(recent, #recent)
        end
    end

    if rawQuery ~= "" and BrowserSettingEnabled("saveRecentSearches") then
        AddRecentNPCSearch(rawQuery)
    end

    local title =
        CreateLabel(
            PageContent,
            "NPC DATABASE",
            22,
            {1, 0.82, 0.25, 1}
        )

    title:SetPoint(
        "TOPLEFT",
        PageContent,
        "TOPLEFT",
        25,
        -20
    )
    ForeverBrowser_CodexTitle196(title)

    local subtitle =
        CreateLabel(
            PageContent,
            "Search by NPC name or ID. Partial names show all matching NPCs.",
            12,
            {0.62, 0.66, 0.74, 1}
        )

    subtitle:SetPoint(
        "TOPLEFT",
        title,
        "BOTTOMLEFT",
        0,
        -8
    )

    local searchBox =
        CreateFrame(
            "EditBox",
            nil,
            PageContent
        )

    searchBox:SetSize(470, 34)
    searchBox:SetPoint(
        "TOPLEFT",
        subtitle,
        "BOTTOMLEFT",
        0,
        -16
    )
    searchBox:SetAutoFocus(false)

    if searchBox.SetFontObject then
        searchBox:SetFontObject(
            "GameFontHighlight"
        )
    end

    searchBox:SetTextInsets(10, 10, 0, 0)
    searchBox:SetText(rawQuery)

    CreateSolidBackground(
        searchBox,
        0.015,
        0.02,
        0.035,
        1
    )

    local function RunSearch()
        local value =
            tostring(
                searchBox:GetText()
                or ""
            )

        Navigate(
            "forever://npcs/"
            .. value
        )
    end

    searchBox:SetScript(
        "OnEnterPressed",
        function(self)
            RunSearch()
            self:ClearFocus()
        end
    )

    searchBox:SetScript(
        "OnEscapePressed",
        function(self)
            self:ClearFocus()
        end
    )

    local searchButton =
        CreateButton(
            PageContent,
            "SEARCH",
            100,
            34
        )

    searchButton:SetPoint(
        "LEFT",
        searchBox,
        "RIGHT",
        10,
        0
    )

    searchButton:SetScript(
        "OnClick",
        RunSearch
    )

    local clearButton =
        CreateButton(
            PageContent,
            "CLEAR",
            80,
            34
        )

    clearButton:SetPoint(
        "LEFT",
        searchButton,
        "RIGHT",
        8,
        0
    )

    clearButton:SetScript(
        "OnClick",
        function()
            Navigate("forever://npcs/")
        end
    )

    local npcIndex = {}

    local function EnsureNPC(npcID, name)
        npcID = tonumber(npcID)

        if not npcID then
            return
        end

        local entry =
            npcIndex[npcID]

        if not entry then
            entry = {
                id = npcID,
                name = nil
            }
            npcIndex[npcID] = entry
        end

        if name
            and tostring(name) ~= ""
            and not entry.name then
            entry.name = tostring(name)
        end
    end

    -- Seed the search index with EVERY NPC from the complete
    -- creature_template database. This makes trainers, vendors,
    -- civilians, quest NPCs, creatures, bosses, and other NPCs
    -- searchable even when they have no item/quest relationship.
    if ForeverSourceData
        and type(ForeverSourceData.npcs) == "table" then

        for rawNPCID, npcData
            in pairs(ForeverSourceData.npcs) do

            local npcID =
                tonumber(rawNPCID)
                or (
                    type(npcData) == "table"
                    and tonumber(npcData.id)
                )

            local npcName = nil

            if type(npcData) == "table" then
                npcName = npcData.name
            end

            EnsureNPC(
                npcID,
                npcName
            )
        end
    end

    -- Quest givers from the dedicated quest database.
    if ForeverSourceData
        and type(ForeverSourceData.quests) == "table" then

        for _, quest
            in pairs(ForeverSourceData.quests) do

            if quest then
                EnsureNPC(
                    quest.giverID,
                    quest.giverName
                )
            end
        end
    end

    -- NPCs referenced by item-source relationships.
    if ForeverSourceData
        and type(ForeverSourceData.items) == "table" then

        for _, item
            in pairs(ForeverSourceData.items) do

            if item
                and type(item.sources) == "table" then

                for _, source
                    in ipairs(item.sources) do

                    if source then
                        local sourceType =
                            string.lower(
                                tostring(
                                    source.type
                                    or ""
                                )
                            )

                        if sourceType == "drop"
                            or sourceType == "vendor"
                            or sourceType == "pickpocket"
                            or sourceType == "skinning" then

                            EnsureNPC(
                                source.id,
                                source.name
                            )

                        elseif sourceType == "quest" then

                            EnsureNPC(
                                source.giverID,
                                source.giverName
                            )
                        end
                    end
                end
            end
        end
    end

    -- Include NPC IDs that have location records even when no item
    -- currently points at them.
    if ForeverSourceData
        and type(ForeverSourceData.npcLocations) == "table" then

        for npcID, _
            in pairs(ForeverSourceData.npcLocations) do

            local completeNPC =
                ForeverSourceData.npcs
                and (
                    ForeverSourceData.npcs[npcID]
                    or ForeverSourceData.npcs[tostring(npcID)]
                )

            EnsureNPC(
                npcID,
                completeNPC
                    and completeNPC.name
                    or nil
            )
        end
    end

    --------------------------------------------------
    -- LIVE PARTIAL NPC SEARCH
    --------------------------------------------------

    local liveSearchTimer = nil

    searchBox:SetScript(
        "OnTextChanged",
        function(self, userInput)
            if not userInput then
                return
            end

            local value =
                tostring(
                    self:GetText()
                    or ""
                )

            value =
                string.gsub(
                    value,
                    "^%s+",
                    ""
                )

            value =
                string.gsub(
                    value,
                    "%s+$",
                    ""
                )

            -- Keep the blank page/recent searches stable until the
            -- player has typed at least two characters.
            if string.len(value) < 2 then
                return
            end

            -- Older clients may not have C_Timer.After. When available,
            -- use a tiny debounce so typing a name does not rebuild the
            -- browser on every single key instantly.
            if C_Timer
                and C_Timer.After then

                local expected = value

                C_Timer.After(
                    0.20,
                    function()
                        if searchBox
                            and tostring(searchBox:GetText() or "") == expected then

                            Navigate(
                                "forever://npcs/"
                                .. expected
                            )
                        end
                    end
                )
            end
        end
    )

    local numeric =
        tonumber(query)

    local found = {}

    if query ~= "" then
        for npcID, npc
            in pairs(npcIndex) do

            local name =
                tostring(
                    npc.name
                    or ("NPC " .. tostring(npcID))
                )

            local lowerName =
                string.lower(name)

            local matches =
                (numeric and npcID == numeric)
                or string.find(
                    lowerName,
                    query,
                    1,
                    true
                )

            if matches then
                table.insert(
                    found,
                    {
                        id = npcID,
                        name = name
                    }
                )
            end
        end

        if ForeverBrowserQuestBrowseFilter ~= "completed" then
        table.sort(
            found,
            function(a, b)
                if numeric then
                    return (a.id or 0)
                        < (b.id or 0)
                end

                local an =
                    string.lower(
                        a.name or ""
                    )
                local bn =
                    string.lower(
                        b.name or ""
                    )

                if an == bn then
                    return (a.id or 0)
                        < (b.id or 0)
                end

                return an < bn
            end
        )
    end

    local statusText

    if query == "" then
        statusText =
            "Enter an NPC name or NPC ID to search the NPC database."
    elseif #found == 0 then
        statusText =
            "No NPCs found for \""
            .. rawQuery
            .. "\"."
    else
        statusText =
            tostring(#found)
            .. " NPC"
            .. (#found == 1 and "" or "s")
            .. " found"
    end

    local status =
        CreateLabel(
            PageContent,
            statusText,
            12,
            {0.62, 0.66, 0.74, 1}
        )

    status:SetPoint(
        "TOPLEFT",
        searchBox,
        "BOTTOMLEFT",
        0,
        -15
    )
    end

    local y = -150
    local shown = 0
    local maxResults = 100

    if query == "" then
        local recent =
            GetRecentNPCSearches()

        if #recent > 0 then
            local recentTitle =
                CreateLabel(
                    PageContent,
                    "RECENT SEARCHES",
                    16,
                    {1, 0.82, 0.25, 1}
                )

            recentTitle:SetPoint(
                "TOPLEFT",
                PageContent,
                "TOPLEFT",
                25,
                y
            )

            local clearRecent =
                CreateButton(
                    PageContent,
                    "CLEAR RECENT",
                    110,
                    24
                )

            clearRecent:SetPoint(
                "LEFT",
                recentTitle,
                "RIGHT",
                18,
                0
            )

            clearRecent:SetScript(
                "OnClick",
                function()
                    local db = GetDatabase()

                    if db then
                        db.recentNPCSearches = {}
                    end

                    Navigate("forever://npcs/")
                end
            )

            y = y - 34

            for _, recentSearch
                in ipairs(recent) do

                local savedSearch
                local displaySearch

                if type(recentSearch) == "table" then
                    savedSearch =
                        tostring(
                            recentSearch.search
                            or recentSearch.name
                            or ""
                        )

                    displaySearch =
                        tostring(
                            recentSearch.name
                            or savedSearch
                        )
                else
                    savedSearch =
                        tostring(recentSearch)

                    displaySearch =
                        savedSearch

                    local numericSearch =
                        tonumber(savedSearch)

                    if numericSearch
                        and ForeverSourceData
                        and type(ForeverSourceData.npcs) == "table" then

                        local npcData =
                            ForeverSourceData.npcs[numericSearch]
                            or ForeverSourceData.npcs[tostring(numericSearch)]

                        if npcData
                            and npcData.name
                            and tostring(npcData.name) ~= "" then

                            displaySearch =
                                tostring(npcData.name)
                        end
                    end
                end

                local recentButton =
                    CreateButton(
                        PageContent,
                        displaySearch,
                        360,
                        30
                    )

                recentButton:SetPoint(
                    "TOPLEFT",
                    PageContent,
                    "TOPLEFT",
                    25,
                    y
                )

                recentButton.text:ClearAllPoints()
                recentButton.text:SetPoint(
                    "LEFT",
                    recentButton,
                    "LEFT",
                    12,
                    0
                )

                recentButton:SetScript(
                    "OnClick",
                    function()
                        Navigate(
                            "forever://npcs/"
                            .. savedSearch
                        )
                    end
                )

                y = y - 36
            end

            y = y - 14
        end
    end

    for _, result
        in ipairs(found) do

        if shown >= maxResults then
            break
        end

        shown = shown + 1

        local row =
            CreateFrame(
                "Button",
                nil,
                PageContent
            )

        row:SetSize(735, 52)
        row:SetPoint(
            "TOPLEFT",
            PageContent,
            "TOPLEFT",
            25,
            y
        )

        local bg =
            CreateSolidBackground(
                row,
                0.025,
                0.03,
                0.05,
                1
            )

        local npcName =
            CreateLabel(
                row,
                "|cffffd100["
                .. tostring(result.name)
                .. "]|r",
                14,
                {1, 1, 1, 1}
            )

        npcName:SetPoint(
            "TOPLEFT",
            row,
            "TOPLEFT",
            12,
            -8
        )

        local idLabel =
            CreateLabel(
                row,
                "NPC ID "
                .. tostring(result.id),
                11,
                {0.45, 0.75, 1, 1}
            )

        idLabel:SetPoint(
            "TOPLEFT",
            npcName,
            "BOTTOMLEFT",
            0,
            -5
        )

        local savedNPCID =
            result.id

        row:EnableMouse(true)
        row:RegisterForClicks(
            "LeftButtonUp"
        )

        row:SetScript(
            "OnClick",
            function()
                Navigate(
                    "forever://npc/"
                    .. tostring(
                        savedNPCID
                    )
                )
            end
        )

        row:SetScript(
            "OnEnter",
            function()
                bg:SetVertexColor(unpack(WOW_THEME.row))
            end
        )

        row:SetScript(
            "OnLeave",
            function()
                bg:SetVertexColor(unpack(WOW_THEME.row))
            end
        )

        y = y - 58
    end

    if #found > maxResults then
        local more =
            CreateLabel(
                PageContent,
                "Showing the first "
                .. tostring(maxResults)
                .. " results. Refine your search to narrow the list.",
                11,
                {0.72, 0.72, 0.78, 1}
            )

        more:SetPoint(
            "TOPLEFT",
            PageContent,
            "TOPLEFT",
            25,
            y - 4
        )

        y = y - 30
    end

    PageContent:SetHeight(
        math.max(
            650,
            math.abs(y) + 60
        )
    )
end



--------------------------------------------------
-- PROFESSION DATABASE
--------------------------------------------------

local ProfessionIcons = {
    ["Alchemy"] = "Interface\\Icons\\Trade_Alchemy",
    ["Blacksmithing"] = "Interface\\Icons\\Trade_BlackSmithing",
    ["Cooking"] = "Interface\\Icons\\INV_Misc_Food_15",
    ["Enchanting"] = "Interface\\Icons\\Trade_Engraving",
    ["Engineering"] = "Interface\\Icons\\Trade_Engineering",
    ["First Aid"] = "Interface\\Icons\\Spell_Holy_SealOfSacrifice",
    ["Leatherworking"] = "Interface\\Icons\\INV_Misc_ArmorKit_17",
    ["Mining"] = "Interface\\Icons\\Trade_Mining",
    ["Tailoring"] = "Interface\\Icons\\Trade_Tailoring",
}

local function GetProfessionData()
    local source = ForeverSourceData and ForeverSourceData.professions or {}
    local recipes = ForeverSourceData and ForeverSourceData.recipes or {}
    local cache=ForeverBrowserProfessionCache225
    if cache and cache.source==source and cache.recipes==recipes then return cache.records end
    local result, groups, aliases = {}, {}, {}
    local keys = {}
    for key in pairs(source) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)

    for _, key in ipairs(keys) do
        local data = source[key]
        if type(data) == "table" then
            local name = tostring(data.name or data.professionName
                or data.skillName or key):match("^%s*(.-)%s*$")
            local normalized = name:lower()
            local entry = groups[normalized]
            if not entry then
                entry = { data = {}, seen = {} }
                for field, value in pairs(data) do entry.data[field] = value end
                entry.data.name = name
                entry.data.recipes = {}
                groups[normalized] = entry
                result[name] = entry.data
            end

            local list = data.recipes or data.spells or data.recipeIDs or data
            if type(list) == "table" then
                for k, value in pairs(list) do
                    local id
                    if type(value) == "number" or type(value) == "string" then
                        id = tonumber(value)
                    elseif type(value) == "table" then
                        id = tonumber(value.spellID or value.id or value.recipeID)
                    end
                    if not id and (value == true or type(value) == "table") then
                        id = tonumber(k)
                    end
                    if id and (recipes[id] or recipes[tostring(id)])
                        and not entry.seen[id] then
                        entry.seen[id] = true
                        table.insert(entry.data.recipes, id)
                    end
                end
            end
            aliases[key] = entry.data
            aliases[tostring(key)] = entry.data
            aliases[name] = entry.data
        end
    end
    setmetatable(result, {
        __index = function(_, key) return aliases[key] end
    })
    ForeverBrowserProfessionCache225={source=source,recipes=recipes,records=result}
    return result
end

function ForeverBrowser_ProfessionCount225()
    local count = 0
    for _ in pairs(GetProfessionData()) do count = count + 1 end
    return count
end

local function GetRecipeData(spellID)
    if not ForeverSourceData or not ForeverSourceData.recipes then return nil end
    spellID = tonumber(spellID)
    if not spellID then return nil end
    return ForeverSourceData.recipes[spellID]
        or ForeverSourceData.recipes[tostring(spellID)]
end

local function GetProfessionName(data, fallback)
    if type(data) == "table" then
        return tostring(data.name or data.professionName or data.skillName or fallback or "Unknown Profession")
    end
    return tostring(fallback or "Unknown Profession")
end

local function GetProfessionRecipeIDs(data)
    local result = {}
    local seen = {}
    if type(data) ~= "table" then return result end
    local source = data.recipes or data.spells or data.recipeIDs or data
    if type(source) ~= "table" then return result end
    for k, v in pairs(source) do
        local id
        if type(v) == "number" or type(v) == "string" then id = tonumber(v) end
        if type(v) == "table" then id = tonumber(v.spellID or v.id or v.recipeID) end
        if not id and (v == true or type(v) == "table") then id = tonumber(k) end
        if id and GetRecipeData(id) and not seen[id] then
            seen[id] = true
            table.insert(result, id)
        end
    end
    table.sort(result, function(a,b)
        local ra, rb = GetRecipeData(a), GetRecipeData(b)
        local na = ra and (ra.name or GetItemName(ra.createdItemID or ra.itemID)) or tostring(a)
        local nb = rb and (rb.name or GetItemName(rb.createdItemID or rb.itemID)) or tostring(b)
        return tostring(na) < tostring(nb)
    end)
    return result
end

-- Shared Codex geometry for the profession and dungeon database homes.
function ForeverBrowser_CodexHome191(title, subtitle, iconPath, searchText, searchLabel, run, stats, heading)
    ClearPage()
    local hero=CreateFrame("Frame",nil,PageContent)
    hero:SetSize(700,170) hero:SetPoint("TOP",PageContent,"TOP",0,-16)
    CreateSolidBackground(hero,0.035,0.025,0.014,1) ForeverBrowser_AchievementBorder(hero,true)
    local icon=hero:CreateTexture(nil,"ARTWORK") icon:SetSize(62,62) icon:SetPoint("TOPLEFT",hero,"TOPLEFT",20,-23) icon:SetTexture(iconPath)
    local name=ForeverBrowser_AchievementLabel(hero,title,26,{1,0.82,0.28,1}) name:SetPoint("TOPLEFT",hero,"TOPLEFT",98,-22)
    local sub=ForeverBrowser_AchievementLabel(hero,subtitle,12,{0.87,0.81,0.67,1}) sub:SetPoint("TOPLEFT",hero,"TOPLEFT",98,-62) sub:SetWidth(577) sub:SetJustifyH("LEFT")
    local search=CreateFrame("EditBox",nil,hero,"InputBoxTemplate") search:SetSize(450,30) search:SetPoint("TOPLEFT",hero,"TOPLEFT",24,-106)
    search:SetAutoFocus(false) search:SetFontObject("ChatFontNormal") search:SetText(searchText or "")
    local button=ForeverBrowser_CodexButton(hero,searchLabel,125) button:SetPoint("LEFT",search,"RIGHT",17,0)
    local function submit() search:ClearFocus() run(search:GetText() or "") end
    search:SetScript("OnEnterPressed",submit) search:SetScript("OnEscapePressed",function(self) self:ClearFocus() end) button:SetScript("OnClick",submit)
    local hint=ForeverBrowser_AchievementLabel(hero,"Search the loaded database by name",10,{0.67,0.61,0.47,1}) hint:SetPoint("BOTTOMLEFT",hero,"BOTTOMLEFT",24,12)
    for i,entry in ipairs(stats) do
        local tile=CreateFrame("Frame",nil,PageContent) tile:SetSize(166,62) tile:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",(i-1)*178,-12)
        ForeverBrowser_AchievementPaper(tile,true)
        local value=ForeverBrowser_AchievementLabel(tile,tostring(entry[1]),22,{0.31,0.18,0.03,1}) value:SetPoint("TOP",tile,"TOP",0,-7)
        local label=ForeverBrowser_AchievementLabel(tile,entry[2],10,{0.34,0.28,0.17,1}) label:SetPoint("BOTTOM",tile,"BOTTOM",0,9)
    end
    local label=ForeverBrowser_AchievementLabel(PageContent,heading,18,{1,0.82,0.28,1}) label:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",0,#stats==0 and -32 or -94)
    return hero, search
end

function ForeverBrowser_CodexCard191(hero,index,name,description,count,iconPath,route,offset)
    local card=CreateFrame("Button",nil,PageContent) card:SetSize(338,100)
    card:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",index%2==1 and 0 or 362,-(offset or 125)-math.floor((index-1)/2)*112)
    ForeverBrowser_AchievementPaper(card,true)
    local icon=card:CreateTexture(nil,"ARTWORK") icon:SetSize(39,39) icon:SetPoint("TOPLEFT",card,"TOPLEFT",14,-14) icon:SetTexture(iconPath)
    local title=ForeverBrowser_AchievementLabel(card,name,17,{0.29,0.16,0.03,1}) title:SetPoint("TOPLEFT",card,"TOPLEFT",67,-13) title:SetSize(251,40) title:SetJustifyH("LEFT") title:SetJustifyV("TOP")
    local desc=ForeverBrowser_AchievementLabel(card,description,11,{0.30,0.25,0.16,1}) desc:SetPoint("TOPLEFT",card,"TOPLEFT",67,-55) desc:SetSize(251,24) desc:SetJustifyH("LEFT") desc:SetJustifyV("TOP")
    local footer=ForeverBrowser_AchievementLabel(card,count.."  >",10,{0.38,0.25,0.08,1}) footer:SetPoint("BOTTOMLEFT",card,"BOTTOMLEFT",67,10)
    card:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight") card:SetScript("OnClick",function() Navigate(route) end)
    return card
end

function ForeverBrowser_ProfessionHome191(searchText)
    local query=string.lower(tostring(searchText or "")) query=string.match(query,"^%s*(.-)%s*$")
    local entries,recipeIDs,crafted,trainers={},{},{},{}
    for key,data in pairs(GetProfessionData()) do
        local name=GetProfessionName(data,key)
        local recipes=GetProfessionRecipeIDs(data)
        if query=="" or string.find(string.lower(name),query,1,true) then entries[#entries+1]={name=name,key=key,recipes=recipes} end
        for _,id in ipairs(recipes) do
            recipeIDs[id]=true
            local recipe=GetRecipeData(id) or {}
            local itemID=tonumber(recipe.createsItemID or recipe.createdItemID or recipe.itemID or recipe.creates)
            if itemID then crafted[itemID]=true end
            for k,v in pairs(type(recipe.trainers or recipe.trainerNPCs)=="table" and (recipe.trainers or recipe.trainerNPCs) or {}) do
                local trainerID=type(v)=="table" and tonumber(v.id or v.npcID) or (type(v)=="number" and v or (v==true and tonumber(k)))
                if trainerID then trainers[trainerID]=true end
            end
        end
    end
    table.sort(entries,function(a,b) return string.lower(a.name)<string.lower(b.name) end)
    local total=0 for _ in pairs(GetProfessionData()) do total=total+1 end
    local hero=ForeverBrowser_CodexHome191("The Profession Codex","Explore trades, recipes, crafted items and their recorded sources.","Interface\\Icons\\Trade_Engineering",searchText,"Search Trades",ForeverBrowser_ProfessionHome191,
        {{total,"Professions"},{ForeverBrowser_CountRecords(recipeIDs),"Known Recipe Records"},{ForeverBrowser_CountRecords(crafted),"Crafted Item Records"},{ForeverBrowser_CountRecords(trainers),"Recorded Trainers"}},"Explore the Professions")
    -- Profession shopping shortcut225.
    local shopping=ForeverBrowser_CodexButton(PageContent,"Shopping List",155)
    shopping:SetSize(155,26)
    shopping:SetPoint("TOPRIGHT",hero,"BOTTOMRIGHT",0,-90)
    shopping:SetScript("OnClick",function() Navigate("forever://codex/shopping") end)
    for i,entry in ipairs(entries) do
        ForeverBrowser_CodexCard191(hero,i,entry.name,"Recipes, reagents & learning sources",#entry.recipes.." recipes",ProfessionIcons[entry.name] or "Interface\\Icons\\INV_Misc_Book_09","forever://profession/"..tostring(entry.key))
    end
    if #entries==0 then
        local empty=ForeverBrowser_AchievementLabel(PageContent,total==0 and "No profession records are loaded." or "No professions match this search.",13,{0.87,0.81,0.67,1}) empty:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",8,-135)
    end
    PageContent:SetHeight(math.max(650,186+125+math.ceil(#entries/2)*112+60))
end

function ForeverBrowser_DungeonHome191(searchText,alphaFilter)
    searchText=tostring(searchText or "") alphaFilter=tostring(alphaFilter or "ALL")
    local query=string.lower(searchText) query=string.match(query,"^%s*(.-)%s*$")
    local entries=GetForeverDungeonIndex()
    local filtered,bossIDs,lootIDs={},{},{}
    for _,dungeon in ipairs(entries) do
        local matched=query=="" or string.find(string.lower(dungeon.name),query,1,true)
        for _,boss in ipairs(dungeon.bosses) do
            bossIDs[boss.id]=true
            if string.find(string.lower(boss.name),query,1,true) then matched=true end
        end
        local first=string.upper(string.sub(dungeon.name,1,1))
        local lower,upper=string.match(alphaFilter,"^(%a)%-(%a)$")
        if matched and (not lower or (first>=lower and first<=upper)) then filtered[#filtered+1]=dungeon end
    end
    -- Scan sources once; these totals describe records, never kill completion.
    for rawID,item in pairs(ForeverSourceData and ForeverSourceData.items or {}) do
        if type(item)=="table" then
            for _,source in ipairs(type(item.sources)=="table" and item.sources or {}) do
                if type(source)=="table" and bossIDs[tonumber(source.id)] and (source.type=="drop" or source.type=="pickpocket" or source.type=="skinning") then
                    local id=tonumber(rawID) or tonumber(item.id) if id then lootIDs[id]=true end
                end
            end
        end
    end
    local hero,search=ForeverBrowser_CodexHome191("The Dungeon Codex","Explore recorded dungeons, entrances, bosses and their loot tables.","Interface\\Icons\\INV_Misc_Map_01",searchText,"Search Dungeons",function(text) ForeverBrowserBuildDungeonDatabasePage(text,"ALL") end,
        {{#entries,"Dungeons"},{ForeverBrowser_CountRecords(bossIDs),"Recorded Bosses"},{ForeverBrowser_CountRecords(lootIDs),"Loot Item Records"},{#filtered,"Matching Dungeons"}},"Explore the Dungeons")
    local guides=CreateButton(PageContent,"Dungeon Guides",140,28) guides:SetPoint("TOPRIGHT",hero,"TOPRIGHT",-14,-12) guides:SetScript("OnClick",function() Navigate("forever://codex/guides") end)
    for i,label in ipairs({"ALL","A-D","E-H","I-L","M-P","Q-T","U-Z"}) do
        local button=ForeverBrowser_CodexButton(PageContent,label,82) button:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",(i-1)*100,-123)
        if label==alphaFilter then button:Disable() end
        button:SetScript("OnClick",function() ForeverBrowserBuildDungeonDatabasePage(search:GetText() or "",label) end)
    end
    for i,dungeon in ipairs(filtered) do
        ForeverBrowser_CodexCard191(hero,i,dungeon.name,"Boss records & recorded loot",#dungeon.bosses.." bosses","Interface\\Icons\\INV_Misc_Map_01","forever://dungeon/"..dungeon.name,164)
    end
    if #filtered==0 then
        local empty=ForeverBrowser_AchievementLabel(PageContent,#entries==0 and "No dungeon records are loaded." or "No dungeon or boss matches these filters.",13,{0.87,0.81,0.67,1}) empty:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",8,-178)
    end
    PageContent:SetHeight(math.max(650,186+164+math.ceil(#filtered/2)*112+60))
end

local function BuildProfessionsPage()
    ForeverBrowser_ProfessionHome191("")
end


local function BuildProfessionPage(professionKey)
    ClearPage()
    local professions = GetProfessionData()
    local data = professions[professionKey] or professions[tonumber(professionKey)]
    if not data then
        local bad = CreateLabel(PageContent,"Profession not found.",18,{1,0.4,0.35,1})
        bad:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,-25)
        return
    end

    local name = GetProfessionName(data, professionKey)
    local ids = GetProfessionRecipeIDs(data)

    local title = CreateLabel(PageContent, string.upper(name), 22, {1,0.82,0.25,1})
    title:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,-25)
    ForeverBrowser_CodexTitle196(title)

    local sub = CreateLabel(PageContent, tostring(#ids).." generated create-item recipes", 12, {0.65,0.68,0.75,1})
    sub:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-8)

    local back = CreateButton(PageContent,"ALL PROFESSIONS",135,24)
    back:SetPoint("TOPRIGHT",PageContent,"TOPRIGHT",-25,-24)
    back:SetScript("OnClick",function() Navigate("forever://professions") end)

    -- Phase 4B: direct search/filter/sort controls.
    local searchLabel = CreateLabel(PageContent,"SEARCH RECIPES",10,{0.72,0.75,0.82,1})
    searchLabel:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,-76)

    local searchBox = CreateFrame("EditBox", nil, PageContent)
    searchBox:SetSize(500, 30)
    searchBox:SetPoint("TOPLEFT", searchLabel, "BOTTOMLEFT", 0, -5)
    searchBox:SetAutoFocus(false)
    if searchBox.SetFontObject then searchBox:SetFontObject("GameFontHighlight") end
    searchBox:SetTextInsets(10,10,0,0)
    CreateSolidBackground(searchBox,0.015,0.02,0.035,1)

    local searchHint = CreateLabel(PageContent,"Search recipe name...",11,{0.48,0.52,0.60,1})
    searchHint:SetPoint("LEFT",searchBox,"LEFT",10,0)

    local sourceLabel = CreateLabel(PageContent,"SOURCE",10,{0.72,0.75,0.82,1})
    sourceLabel:SetPoint("TOPLEFT",searchBox,"BOTTOMLEFT",0,-13)

    local sourceModes = {"All","Trainer","Vendor","Drop","Quest","Recipe Item"}
    local selectedSource = "All"
    local sourceButtons = {}
    local sourceWidths = {70,95,90,75,80,115}
    local previousSourceButton = nil
    for i, mode in ipairs(sourceModes) do
        local button = CreateButton(PageContent,string.upper(mode),sourceWidths[i],24)
        if i == 1 then
            button:SetPoint("TOPLEFT",sourceLabel,"BOTTOMLEFT",0,-5)
        else
            button:SetPoint("LEFT",previousSourceButton,"RIGHT",6,0)
        end
        sourceButtons[mode] = button
        previousSourceButton = button
    end

    local sortLabel = CreateLabel(PageContent,"SORT",10,{0.72,0.75,0.82,1})
    sortLabel:SetPoint("TOPLEFT",sourceButtons["All"],"BOTTOMLEFT",0,-13)

    local sortModes = {"Skill Up","Skill Down","Name"}
    local selectedSort = "Skill Up"
    local sortButtons = {}
    local sortLabels = { ["Skill Up"]="SKILL +", ["Skill Down"]="SKILL -", ["Name"]="NAME" }
    local previousSortButton = nil
    for i, mode in ipairs(sortModes) do
        local button = CreateButton(PageContent,sortLabels[mode],105,24)
        if i == 1 then
            button:SetPoint("TOPLEFT",sortLabel,"BOTTOMLEFT",0,-5)
        else
            button:SetPoint("LEFT",previousSortButton,"RIGHT",6,0)
        end
        sortButtons[mode] = button
        previousSortButton = button
    end

    local resultText = CreateLabel(PageContent,"",10,{0.58,0.62,0.70,1})
    resultText:SetPoint("LEFT",previousSortButton,"RIGHT",14,0)

    local function UpdateControlHighlights()
        for mode, button in pairs(sourceButtons) do
            if mode == selectedSource then
                button:SetAlpha(1.0)
                if button.LockHighlight then button:LockHighlight() end
            else
                button:SetAlpha(0.68)
                if button.UnlockHighlight then button:UnlockHighlight() end
            end
        end
        for mode, button in pairs(sortButtons) do
            if mode == selectedSort then
                button:SetAlpha(1.0)
                if button.LockHighlight then button:LockHighlight() end
            else
                button:SetAlpha(0.68)
                if button.UnlockHighlight then button:UnlockHighlight() end
            end
        end
    end

    local recipeRows = {}

    local function HasSource(recipe, mode)
        if mode == "All" then return true end
        local trainers = recipe.trainers or recipe.trainerNPCs or {}
        local recipeItems = recipe.recipeItems or {}

        if mode == "Trainer" then
            return next(trainers) ~= nil
        end

        if mode == "Recipe Item" then
            return next(recipeItems) ~= nil
        end

        for _, source in pairs(recipeItems) do
            if type(source) == "table" then
                if mode == "Vendor" and next(source.vendors or {}) ~= nil then return true end
                if mode == "Drop" and (next(source.drops or {}) ~= nil or next(source.objects or {}) ~= nil) then return true end
                if mode == "Quest" and next(source.quests or {}) ~= nil then return true end
            end
        end
        return false
    end

    for _, spellID in ipairs(ids) do
        local recipe = GetRecipeData(spellID)
        if recipe then
            local itemID = tonumber(recipe.createsItemID or recipe.createdItemID or recipe.itemID or recipe.creates)
            local recipeName = tostring(recipe.name or (itemID and GetItemName(itemID)) or ("Recipe "..spellID))
            local req = tonumber(recipe.requiredSkill or recipe.minSkill or recipe.skillRequired or 0) or 0

            local row = CreateFrame("Button",nil,PageContent)
            row:SetSize(790,48)
            local bg = CreateSolidBackground(row,0.025,0.03,0.05,1)

            local icon = row:CreateTexture(nil,"ARTWORK")
            icon:SetSize(32,32)
            icon:SetPoint("LEFT",row,"LEFT",10,0)
            icon:SetTexture(itemID and GetItemIcon(itemID,GetAnyItem(itemID)) or ProfessionIcons[name] or "Interface\\Icons\\INV_Misc_QuestionMark")

            local label = CreateLabel(row,recipeName,13,{0.92,0.92,0.95,1})
            label:SetPoint("LEFT",icon,"RIGHT",10,6)

            local info = CreateLabel(row,"Required skill: "..tostring(req).."   Spell ID: "..tostring(spellID),10,{0.58,0.62,0.70,1})
            info:SetPoint("LEFT",icon,"RIGHT",10,-10)

            local saved = spellID
            row:SetScript("OnClick",function() Navigate("forever://recipe/"..tostring(saved)) end)
            row:SetScript("OnEnter",function() bg:SetVertexColor(unpack(WOW_THEME.row)) end)
            row:SetScript("OnLeave",function() bg:SetVertexColor(unpack(WOW_THEME.row)) end)

            table.insert(recipeRows, {
                row=row,
                recipe=recipe,
                spellID=spellID,
                name=recipeName,
                lowerName=string.lower(recipeName),
                requiredSkill=req,
            })
        end
    end

    local function RefreshRecipeRows()
        ForeverBrowserProfessionViews226=ForeverBrowserProfessionViews226 or {}
        ForeverBrowserProfessionViews226[tostring(professionKey)]={query=searchBox:GetText() or "",source=selectedSource,sort=selectedSort}
        local query = string.lower(tostring(searchBox:GetText() or ""))
        local mode = selectedSource
        local visible = {}

        if query == "" then
            searchHint:Show()
        else
            searchHint:Hide()
        end

        for _, entry in ipairs(recipeRows) do
            entry.row:Hide()
            local nameMatches = query == "" or string.find(entry.lowerName, query, 1, true) ~= nil
            if nameMatches and HasSource(entry.recipe, mode) then
                table.insert(visible, entry)
            end
        end

        local sortMode = selectedSort
        table.sort(visible, function(a,b)
            if sortMode == "Skill Up" then
                if a.requiredSkill ~= b.requiredSkill then return a.requiredSkill < b.requiredSkill end
                return a.lowerName < b.lowerName
            elseif sortMode == "Skill Down" then
                if a.requiredSkill ~= b.requiredSkill then return a.requiredSkill > b.requiredSkill end
                return a.lowerName < b.lowerName
            else
                if a.lowerName ~= b.lowerName then return a.lowerName < b.lowerName end
                return a.requiredSkill < b.requiredSkill
            end
        end)

        local y = -225
        for _, entry in ipairs(visible) do
            entry.row:ClearAllPoints()
            entry.row:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,y)
            entry.row:Show()
            y = y - 54
        end

        resultText:SetText(tostring(#visible).." of "..tostring(#recipeRows).." recipes shown")
        PageContent:SetHeight(math.max(650,math.abs(y)+60))
    end

    searchBox:SetScript("OnTextChanged", RefreshRecipeRows)
    searchBox:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    searchBox:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)

    for mode, button in pairs(sourceButtons) do
        local savedMode = mode
        button:SetScript("OnClick",function()
            selectedSource = savedMode
            UpdateControlHighlights()
            RefreshRecipeRows()
        end)
    end

    for mode, button in pairs(sortButtons) do
        local savedMode = mode
        button:SetScript("OnClick",function()
            selectedSort = savedMode
            UpdateControlHighlights()
            RefreshRecipeRows()
        end)
    end

    local saved=ForeverBrowserProfessionViews226 and ForeverBrowserProfessionViews226[tostring(professionKey)]
    if saved then selectedSource=saved.source or "All" selectedSort=saved.sort or "Skill Up" searchBox:SetText(saved.query or "") end
    UpdateControlHighlights()
    RefreshRecipeRows()
end

local function BuildRecipePage(spellID)
    ClearPage()

    local recipe = GetRecipeData(spellID)
    if not recipe then
        local bad = CreateLabel(PageContent, "Recipe not found.", 18, {1,0.4,0.35,1})
        bad:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, -25)
        return
    end

    local itemID = tonumber(recipe.createsItemID or recipe.createdItemID or recipe.itemID or recipe.creates)
    local name = tostring(recipe.name or (itemID and GetItemName(itemID)) or ("Recipe "..tostring(spellID)))
    local profession = tostring(recipe.professionName or recipe.profession or recipe.skillName or "Profession")
    local requiredSkill = tonumber(recipe.requiredSkill or recipe.minSkill or recipe.skillRequired or 0) or 0

    -- Header icon + recipe title.
    local headerIcon = CreateFrame("Button", nil, PageContent)
    headerIcon:SetSize(52, 52)
    headerIcon:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, -24)
    local headerTexture = headerIcon:CreateTexture(nil, "ARTWORK")
    headerTexture:SetAllPoints(headerIcon)
    headerTexture:SetTexture(
        itemID and GetItemIcon(itemID, GetAnyItem(itemID))
        or ProfessionIcons[profession]
        or "Interface\\Icons\\INV_Misc_QuestionMark"
    )

    if itemID then
        headerIcon:SetScript("OnEnter", function(self) ShowItemTooltip(itemID, self) end)
        headerIcon:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        headerIcon:SetScript("OnClick", function() Navigate("forever://item/"..tostring(itemID)) end)
    end

    local title = CreateLabel(PageContent, name, 22, {1,0.82,0.25,1})
    title:SetPoint("TOPLEFT", headerIcon, "TOPRIGHT", 14, -2)

    local meta = CreateLabel(
        PageContent,
        profession.."   Required skill: "..tostring(requiredSkill).."   Spell ID: "..tostring(spellID),
        11,
        {0.65,0.68,0.75,1}
    )
    meta:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)

    local back = CreateButton(PageContent, "ALL PROFESSIONS", 135, 24)
    back:SetPoint("TOPRIGHT", PageContent, "TOPRIGHT", -25, -24)
    back:SetScript("OnClick", function() Navigate("forever://professions") end)

    local y = -100

    -- Created item.
    if itemID then
        local created = CreateLabel(PageContent, "CREATES", 15, {1,0.82,0.25,1})
        created:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
        y = y - 28

        local row = CreateFrame("Button", nil, PageContent)
        row:SetSize(520, 48)
        row:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
        local bg = CreateSolidBackground(row, 0.025,0.03,0.05,1)

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(34,34)
        icon:SetPoint("LEFT", row, "LEFT", 9, 0)
        icon:SetTexture(GetItemIcon(itemID, GetAnyItem(itemID)))

        local itemName = CreateLabel(row, GetItemName(itemID), 13, {0.95,0.95,1,1})
        itemName:SetPoint("LEFT", icon, "RIGHT", 10, 6)

        local itemMeta = CreateLabel(row, "Item ID: "..tostring(itemID).."   Click to open item", 10, {0.58,0.62,0.70,1})
        itemMeta:SetPoint("LEFT", icon, "RIGHT", 10, -10)

        row:SetScript("OnClick", function() Navigate("forever://item/"..tostring(itemID)) end)
        row:SetScript("OnEnter", function(self)
            bg:SetVertexColor(unpack(WOW_THEME.row))
            ShowItemTooltip(itemID, self)
        end)
        row:SetScript("OnLeave", function()
            bg:SetVertexColor(unpack(WOW_THEME.row))
            if GameTooltip then GameTooltip:Hide() end
        end)
        y = y - 62
    end

    -- Reagents.
    local rt = CreateLabel(PageContent, "REAGENTS", 15, {1,0.82,0.25,1})
    rt:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
    y = y - 28

    local reagents = recipe.reagents or recipe.materials or {}
    local reagentRows = {}

    for k, v in pairs(reagents) do
        local rid, count
        if type(v) == "table" then
            rid = tonumber(v.itemID or v.id or k)
            count = tonumber(v.count or v.quantity or v.amount or 1) or 1
        else
            rid = tonumber(k)
            count = tonumber(v) or 1
        end

        if rid and rid > 0 then
            table.insert(reagentRows, {itemID=rid, count=count})
        end
    end

    table.sort(reagentRows, function(a,b)
        return tostring(GetItemName(a.itemID)) < tostring(GetItemName(b.itemID))
    end)

    if #reagentRows == 0 then
        local none = CreateLabel(PageContent, "No reagent data available.", 12, {0.6,0.62,0.68,1})
        none:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
        y = y - 30
    else
        for _, reagent in ipairs(reagentRows) do
            local rid = reagent.itemID
            local count = reagent.count

            local row = CreateFrame("Button", nil, PageContent)
            row:SetSize(520, 42)
            row:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
            local bg = CreateSolidBackground(row, 0.025,0.03,0.05,1)

            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(30,30)
            icon:SetPoint("LEFT", row, "LEFT", 8, 0)
            icon:SetTexture(GetItemIcon(rid, GetAnyItem(rid)))

            local label = CreateLabel(row, tostring(count).."x  "..GetItemName(rid), 12, {0.92,0.92,0.96,1})
            label:SetPoint("LEFT", icon, "RIGHT", 10, 0)

            row:SetScript("OnClick", function() Navigate("forever://item/"..tostring(rid)) end)
            row:SetScript("OnEnter", function(self)
                bg:SetVertexColor(unpack(WOW_THEME.row))
                ShowItemTooltip(rid, self)
            end)
            row:SetScript("OnLeave", function()
                bg:SetVertexColor(unpack(WOW_THEME.row))
                if GameTooltip then GameTooltip:Hide() end
            end)

            y = y - 48
        end
    end

    y = y - 8

    -- Learned-from / acquisition section.
    local learned = CreateLabel(PageContent, "LEARNED FROM", 15, {1,0.82,0.25,1})
    learned:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
    y = y - 28

    local function GetNPCRecord(npcID)
        return ForeverSourceData
            and ForeverSourceData.npcs
            and (ForeverSourceData.npcs[npcID] or ForeverSourceData.npcs[tostring(npcID)])
    end

    local function GetNPCLocations(npcID)
        return ForeverSourceData
            and ForeverSourceData.npcLocations
            and (ForeverSourceData.npcLocations[npcID] or ForeverSourceData.npcLocations[tostring(npcID)])
    end

    local function AddNPCSourceRow(prefix, npcID, chance)
        npcID = tonumber(npcID)
        if not npcID then return end

        local npc = GetNPCRecord(npcID)
        local npcName = npc and npc.name or ("NPC "..tostring(npcID))
        local locations = GetNPCLocations(npcID)

        local row = CreateFrame("Frame", nil, PageContent)
        row:SetSize(790, 52)
        row:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
        CreateSolidBackground(row, 0.025,0.03,0.05,1)

        local labelText = prefix..": "..tostring(npcName)
        local npcButton = CreateButton(row, labelText, 330, 28)
        npcButton:SetPoint("LEFT", row, "LEFT", 10, 0)
        npcButton:SetScript("OnClick", function() Navigate("forever://npc/"..tostring(npcID)) end)

        local detailText = "NPC ID: "..tostring(npcID)
        if chance ~= nil then
            local chanceNumber = tonumber(chance)
            if chanceNumber then
                detailText = detailText.."   Chance: "..string.format("%.2f%%", chanceNumber)
            end
        end

        local detail = CreateLabel(row, detailText, 10, {0.55,0.59,0.67,1})
        detail:SetPoint("LEFT", npcButton, "RIGHT", 12, 0)

        if type(locations) == "table" and #locations > 0 then
            local first = locations[1]
            local zoneName = first and GetAutomaticMapName(first.uiMapID)
            if zoneName then
                local zone = CreateLabel(row, zoneName, 10, {0.68,0.70,0.76,1})
                zone:SetPoint("TOPLEFT", detail, "BOTTOMLEFT", 0, -4)
            end

            local mapButton = CreateButton(row, (#locations > 1 and "SHOW LOCATIONS" or "SHOW ON MAP"), 125, 26)
            mapButton:SetPoint("RIGHT", row, "RIGHT", -10, 0)
            mapButton:SetScript("OnClick", function()
                if #locations > 1 then
                    ShowAllForeverBrowserLocations(locations)
                else
                    local loc = locations[1]
                    ShowForeverBrowserMapMarker(loc.uiMapID, loc.x, loc.y, npcName)
                end
            end)
        end

        y = y - 58
    end

    local trainers = recipe.trainers or recipe.trainerNPCs or {}
    local trainerRows = {}
    local seenTrainers = {}

    for _, v in pairs(trainers) do
        local nid = tonumber(type(v)=="table" and (v.npcID or v.id) or v)
        if nid and not seenTrainers[nid] then
            seenTrainers[nid] = true
            local npc = GetNPCRecord(nid)
            table.insert(trainerRows, {npcID=nid, name=tostring(npc and npc.name or ("NPC "..tostring(nid)))})
        end
    end

    table.sort(trainerRows, function(a,b) return a.name < b.name end)

    if #trainerRows > 0 then
        local heading = CreateLabel(PageContent, "TRAINERS", 12, {0.82,0.84,0.90,1})
        heading:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
        y = y - 22
        for _, trainer in ipairs(trainerRows) do
            AddNPCSourceRow("Trainer", trainer.npcID, nil)
            -- FOREVER_TRAINER_REQUIREMENTS_UI_238
            local record=(recipe.trainerDetails or {})[trainer.npcID]
            if type(record)=="table" then
                local details={"Recorded inventory; not independently verified"}
                local cost=tonumber(record.cost)
                if cost then
                    cost=math.max(0,math.floor(cost))
                    details[#details+1]="Cost: "..math.floor(cost/10000).."g "..math.floor(cost%10000/100).."s "..(cost%100).."c"
                end
                local level=tonumber(record.requiredLevel)
                if level and level>0 then details[#details+1]="Level "..level end
                local skill=tonumber(record.requiredSkillValue)
                if skill and skill>0 then details[#details+1]=(record.requiredSkillName and record.requiredSkillName~="" and record.requiredSkillName or recipe.professionName or recipe.skillName or "Skill").." "..skill end
                y=ForeverBrowser_C198Row(y,"Recorded training requirements",table.concat(details," - "))
            end
        end
        y = y - 6
    end

    local recipeItems = recipe.recipeItems or {}
    local hasRecipeItems = false

    for _, source in pairs(recipeItems) do
        local recipeItemID = tonumber(source.itemID or source.id)
        if recipeItemID and recipeItemID > 0 then
            hasRecipeItems = true

            local itemName = tostring(source.itemName or GetItemName(recipeItemID) or ("Item "..tostring(recipeItemID)))
            local heading = CreateLabel(PageContent, "RECIPE ITEM", 12, {0.82,0.84,0.90,1})
            heading:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
            y = y - 22

            local itemRow = CreateFrame("Button", nil, PageContent)
            itemRow:SetSize(790, 48)
            itemRow:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
            local itemBG = CreateSolidBackground(itemRow, 0.025,0.03,0.05,1)

            local icon = itemRow:CreateTexture(nil, "ARTWORK")
            icon:SetSize(32,32)
            icon:SetPoint("LEFT", itemRow, "LEFT", 9, 0)
            icon:SetTexture(GetItemIcon(recipeItemID, GetAnyItem(recipeItemID)))

            local itemLabel = CreateLabel(itemRow, itemName, 12, {0.95,0.95,1,1})
            itemLabel:SetPoint("LEFT", icon, "RIGHT", 10, 6)
            local itemMeta = CreateLabel(itemRow, "Item ID: "..tostring(recipeItemID).."   Click to open item", 10, {0.58,0.62,0.70,1})
            itemMeta:SetPoint("LEFT", icon, "RIGHT", 10, -10)

            itemRow:SetScript("OnClick", function() Navigate("forever://item/"..tostring(recipeItemID)) end)
            itemRow:SetScript("OnEnter", function(self)
                itemBG:SetVertexColor(unpack(WOW_THEME.row))
                ShowItemTooltip(recipeItemID, self)
            end)
            itemRow:SetScript("OnLeave", function()
                itemBG:SetVertexColor(unpack(WOW_THEME.row))
                if GameTooltip then GameTooltip:Hide() end
            end)
            y = y - 56

            for _, vendor in pairs(source.vendors or {}) do
                AddNPCSourceRow("Sold by", vendor.npcID or vendor.id, nil)
            end

            for _, drop in pairs(source.drops or {}) do
                AddNPCSourceRow("Dropped by", drop.id or drop.npcID, drop.chance)
            end

            for _, object in pairs(source.objects or {}) do
                local objectID = tonumber(object.id or object.objectID)
                if objectID then
                    local row = CreateFrame("Frame", nil, PageContent)
                    row:SetSize(790, 42)
                    row:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
                    CreateSolidBackground(row, 0.025,0.03,0.05,1)
                    local text = "Object source   ID: "..tostring(objectID)
                    local chanceNumber = tonumber(object.chance)
                    if chanceNumber then text = text.."   Chance: "..string.format("%.2f%%", chanceNumber) end
                    local label = CreateLabel(row, text, 11, {0.82,0.84,0.90,1})
                    label:SetPoint("LEFT", row, "LEFT", 10, 0)
                    y = y - 48
                end
            end

            for _, questSource in pairs(source.quests or {}) do
                local questID = tonumber(questSource.id or questSource.questID)
                if questID then
                    local quest = ForeverSourceData and ForeverSourceData.quests
                        and (ForeverSourceData.quests[questID] or ForeverSourceData.quests[tostring(questID)])
                    local questName = quest and quest.name or ("Quest "..tostring(questID))

                    local row = CreateFrame("Frame", nil, PageContent)
                    row:SetSize(790, 46)
                    row:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
                    CreateSolidBackground(row, 0.025,0.03,0.05,1)

                    local questButton = CreateButton(row, "Quest: "..tostring(questName), 430, 28)
                    questButton:SetPoint("LEFT", row, "LEFT", 10, 0)
                    questButton:SetScript("OnClick", function() Navigate("forever://quest/"..tostring(questID)) end)

                    local qid = CreateLabel(row, "Quest ID: "..tostring(questID), 10, {0.55,0.59,0.67,1})
                    qid:SetPoint("LEFT", questButton, "RIGHT", 12, 0)
                    y = y - 52
                end
            end

            y = y - 8
        end
    end

    if #trainerRows == 0 and not hasRecipeItems then
        local none = CreateLabel(PageContent, "No acquisition source is available for this recipe.", 12, {0.6,0.62,0.68,1})
        none:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 25, y)
        y = y - 34
    end

    PageContent:SetHeight(math.max(650, math.abs(y)+80))
end


--------------------------------------------------
-- NAVIGATION VISUAL STATE
--------------------------------------------------

local function UpdateNavigationState(url)
    if not NavigationFrame then return end

    local key = "home"

    if url == "forever://welcome" then
        key = nil
    elseif string.sub(url, 1, 17) == "forever://search/"
        or url == "forever://items"
        or url == "forever://itembrowse"
        or string.sub(url, 1, 19) == "forever://category/" then
        key = "browse"
    elseif string.sub(url, 1, 17) == "forever://quests/"
        or string.sub(url, 1, 16) == "forever://quest/" then
        key = "quests"
    elseif url == "forever://npcdatabase"
        or string.sub(url,1,20)=="forever://npcbrowse/"
        or string.sub(url,1,20)=="forever://npcsearch/" then
        key="npc_home"
    elseif string.sub(url, 1, 15) == "forever://npcs/"
        or string.sub(url, 1, 14) == "forever://npc/" then
        key = "npcs"
    elseif url == "forever://professions"
        or string.sub(url, 1, 21) == "forever://profession/"
        or string.sub(url, 1, 17) == "forever://recipe/" then
        key = "professions"
    elseif url == "forever://farming" then
        key = "farming"
    elseif url == "forever://dungeons"
        or string.sub(url, 1, 19) == "forever://dungeons/"
        or string.sub(url, 1, 18) == "forever://dungeon/"
        or string.sub(url, 1, 22) == "forever://dungeonboss/" then
        key = "dungeons"
    elseif url == "forever://talents"
        or string.sub(url,1,18) == "forever://talents/" then
        key = "talents"
    elseif url == "forever://bis" then
        key = "bis"
    elseif url == "forever://favorites" then
        key = "favorites"
    elseif url == "forever://recent" then
        key = "recent"
    elseif url == "forever://lists"
        or string.sub(url, 1, 15) == "forever://list/"
        or string.sub(url, 1, 20) == "forever://lists/add/" then
        key = "lists"
    elseif url == "forever://tags" then
        key = "tags"
    elseif url == "forever://settings" then
        key = "settings"
    elseif url == "forever://debug" then
        key = "debug"
    end

    NavigationFrame.activeKey = key

    for buttonKey, button in pairs(NavigationButtons) do
        if buttonKey == key then
            button.navBackground:SetVertexColor(0.16, 0.12, 0.035, 1)
            button.navLabel:SetTextColor(1, 0.82, 0.25, 1)
        else
            button.navBackground:SetVertexColor(unpack(WOW_THEME.row))
            button.navLabel:SetTextColor(0.82, 0.84, 0.90, 1)
        end
    end
end


--------------------------------------------------
-- WARDROBE PREVIEW
-- Alt + Left Click on any item navigation opens this
-- instead of navigating to the item page.
--------------------------------------------------

local WardrobeFrame = nil

function ForeverBrowser_P204Support(item)
    if type(item)~="table" then return false end
    local path=item.modelPath or item.modelFile
    if type(path)=="string" and path:lower():match("%.m2$") then return true,"object",path end
    local slot=tostring(item.equipLoc or item.EquipLoc or item.equipSlot or item.inventoryType or "")
    if slot=="INVTYPE_BAG" or slot=="INVTYPE_TRINKET" or slot=="INVTYPE_FINGER" or slot=="INVTYPE_NECK" or slot=="INVTYPE_AMMO" then return false end
    if slot~="" and slot~="0" and slot~="INVTYPE_NON_EQUIP" and slot~="INVTYPE_BAG" and slot~="INVTYPE_TRINKET" and slot~="INVTYPE_FINGER" and slot~="INVTYPE_NECK" and slot~="INVTYPE_AMMO" then return true,"equipment" end
    local class=tonumber(item.classID or item.itemClass or item.ClassID)
    local kind=string.lower(tostring(item.itemType or item.type or item.className or ""))
    if class==2 or class==4 or kind=="weapon" or kind=="armor" then return true,"equipment" end
    return false
end
-- Standalone item preview: never loads a unit or dresses a character.
function ForeverBrowser_P205Inline(itemID,parent,y)
    if not ForeverBrowser_S222().models then return 0 end
    local item=GetAnyItem(itemID) or {} local supported,_,path=ForeverBrowser_P204Support(item)
    if not supported then return 0 end
    local frame=CreateFrame("Frame",nil,parent) frame:SetSize(790,370) frame:SetPoint("TOPLEFT",parent,"TOPLEFT",25,y)
    CreateSolidBackground(frame,.045,.038,.029,1) ForeverBrowser_AchievementBorder(frame,true)
    local title=ForeverBrowser_AchievementLabel(frame,"ITEM MODEL",18,{1,.82,.28,1}) title:SetPoint("TOPLEFT",frame,"TOPLEFT",15,-12)
    local fallback=frame:CreateTexture(nil,"ARTWORK") fallback:SetSize(104,104) fallback:SetPoint("CENTER",frame,"CENTER",0,12) fallback:SetTexture(GetItemIcon(itemID,item))
    local status=ForeverBrowser_AchievementLabel(frame,"Loading standalone preview...",11,{.87,.81,.67,1}) status:SetPoint("BOTTOM",frame,"BOTTOM",0,53) status:SetWidth(740)
    local ok,model=pcall(CreateFrame,"PlayerModel",nil,frame)
    if not ok then model=nil end
    local loaded,dragging,lastX,facing,zoom=false,false,0,0,ForeverBrowser_S222().modelZoom
    local function call(method,...)
        if not model or type(model[method])~="function" then return false end
        local good,result=pcall(model[method],model,...) return good and result~=false
    end
    local function position() call("SetFacing",facing) call("SetPosition",zoom,0,0) end
    local function idle(self,elapsed) if loaded and not dragging and ForeverBrowser_S222().rotateModels then facing=facing+(elapsed or 0)*.4 position() else self:SetScript("OnUpdate",nil) end end
    -- FOREVER_HIDE_UNAVAILABLE_MODELS_252
    local unavailable,layoutReserved=false,false
    local function collapse()
        if unavailable then return end
        unavailable=true
        frame:Hide()
        if not layoutReserved then return end
        -- Only move anchors tied directly to the page. Relative rows move with them.
        local function move(region)
            if region==frame or type(region.GetNumPoints)~="function"
                or type(region.GetPoint)~="function" or type(region.SetPoint)~="function"
                or type(region.ClearAllPoints)~="function" then return end
            local points={} local changed=false
            for index=1,region:GetNumPoints() do
                local point,relative,relativePoint,x,pointY=region:GetPoint(index)
                if relative==parent and type(pointY)=="number" and pointY<y then
                    pointY=pointY+386 changed=true
                end
                points[index]={point,relative,relativePoint,x,pointY}
            end
            if changed then
                region:ClearAllPoints()
                for _,point in ipairs(points) do
                    region:SetPoint(point[1],point[2],point[3],point[4],point[5])
                end
            end
        end
        if type(parent.GetChildren)=="function" then
            for _,child in ipairs({parent:GetChildren()}) do move(child) end
        end
        if type(parent.GetRegions)=="function" then
            for _,region in ipairs({parent:GetRegions()}) do move(region) end
        end
        if type(parent.GetHeight)=="function" and type(parent.SetHeight)=="function" then
            parent:SetHeight(math.max(0,parent:GetHeight()-386))
        end
    end
    local function fail()
        loaded=false if model then model:Hide() model:SetScript("OnUpdate",nil) end
        collapse()
    end
    if model then
        model:SetSize(750,240) model:SetPoint("TOP",frame,"TOP",0,-42) model:EnableMouse(true) if model.EnableMouseWheel then model:EnableMouseWheel(true) end
        -- Use one item/model request, never repeated cache requests or character TryOn.
        local elapsedTotal,attempted,verified=0,false,false
        model:SetScript("OnUpdate",function(self,elapsed)
            elapsedTotal=elapsedTotal+(elapsed or 0)
            if not attempted and elapsedTotal>=.1 then
                attempted=true
                if path then loaded=call("SetModel",path)
                elseif type(self.SetItem)=="function" then loaded=call("SetItem",itemID) end
                if not loaded then fail() return end
                position()
            end
            if loaded and not verified and elapsedTotal>=.6 then
                verified=true
                local getter=type(self.GetModel)=="function" and self.GetModel
                    or (type(self.GetModelFileID)=="function" and self.GetModelFileID)
                local good,value=false,nil
                if getter then good,value=pcall(getter,self) end
                if not good or value==nil or value=="" or value==0 or value==false then
                    if getter and elapsedTotal<3 then verified=false return end
                    fail() return
                end
                fallback:Hide() status:SetText("Drag to rotate • scroll to zoom • item only")
                self:SetScript("OnUpdate",ForeverBrowser_S222().rotateModels and idle or nil)
            end
            if loaded and dragging and type(GetCursorPosition)=="function" then local x=GetCursorPosition() facing=facing+(x-lastX)*.012 lastX=x position() end
        end)
        model:SetScript("OnMouseDown",function(_,button) if loaded and verified and button=="LeftButton" and type(GetCursorPosition)=="function" then dragging=true lastX=GetCursorPosition()
                model:SetScript("OnUpdate",function() if dragging then local x=GetCursorPosition() facing=facing+(x-lastX)*.012 lastX=x position() end end)
            end end)
        model:SetScript("OnMouseUp",function() dragging=false if loaded and verified then model:SetScript("OnUpdate",ForeverBrowser_S222().rotateModels and idle or nil) end end)
        model:SetScript("OnHide",function() dragging=false end)
        model:SetScript("OnMouseWheel",function(_,delta) if loaded then zoom=math.max(-1.2,math.min(1.2,zoom+delta*.12)) position() end end)
    else fail() end
    for i,label in ipairs({"Rotate Left","Rotate Right","Zoom In","Zoom Out","Reset","Show Icon"}) do local b=CreateButton(frame,label,105,26) b:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",55+(i-1)*114,15)
        b:SetScript("OnClick",function()
            if not loaded then return end
            if i==1 then facing=facing-.35 elseif i==2 then facing=facing+.35 elseif i==3 then zoom=math.min(1.2,zoom+.12) elseif i==4 then zoom=math.max(-1.2,zoom-.12) elseif i==5 then facing=0 zoom=ForeverBrowser_S222().modelZoom
            else dragging=false if model:IsShown() then model:Hide() fallback:Show() b.text:SetText("Show 3D") else model:Show() fallback:Hide() b.text:SetText("Show Icon") end end position()
        end)
    end
    frame:SetScript("OnHide",function() dragging=false if model then model:SetScript("OnUpdate",nil) end end)
    if unavailable then return 0 end
    layoutReserved=true
    return 386
end

local function OpenWardrobePreview(itemID)
    itemID=tonumber(itemID) if itemID then Navigate("forever://item/"..itemID) end
end

--------------------------------------------------
-- URL NAVIGATION
--------------------------------------------------

-- Codex tools: persistent organization over existing safe database records.
function ForeverBrowser_C198State()
    local db=GetDatabase()
    if not db then ForeverDBDatabase={} db=ForeverDBDatabase end
    db.codex198=db.codex198 or {bookmarks={},shopping={},goals={},nextGoal=1}
    db.codex198.bookmarks=db.codex198.bookmarks or {}
    db.codex198.shopping=db.codex198.shopping or {}
    db.codex198.goals=db.codex198.goals or {}
    db.codex198.nextGoal=db.codex198.nextGoal or 1
    return db.codex198
end
function ForeverBrowser_C198Source(record,discovered)
    if discovered then return "Character discovery" end
    if type(record)=="table" then
        local source=string.lower(tostring(record.dataSource or record.sourceDatabase or ""))
        if record.isForeverNPC or record.foreverNPCs or record.isForever or record.foreverExclusive or source=="forever" then return "Forever" end
        if source=="classic" then return "Classic" end
    end
    return "Database • provenance unspecified"
end
function ForeverBrowser_C211BuildIndex()
    local records,seen={},{}
    local function add(kind,id,name,data,discovered)
        if id==nil then return end
        local key=kind..":"..tostring(id)
        if seen[key] then
            if discovered then seen[key].source="Character discovery" end
            if type(data)=="table" then
                local merged={}
                for k,v in pairs(type(seen[key].data)=="table" and seen[key].data or {}) do merged[k]=v end
                for k,v in pairs(data) do if merged[k]==nil then merged[k]=v end end
                seen[key].data=merged
            end
            return
        end
        local route=({item="item",npc="npc",quest="quest",recipe="recipe",dungeon="dungeon"})[kind]
        local entry={kind=kind,id=id,name=tostring(name or (kind.." "..tostring(id))),data=data or {},url="forever://"..route.."/"..tostring(id),source=ForeverBrowser_C198Source(data,discovered)}
        seen[key]=entry records[#records+1]=entry
    end
    for id,r in pairs(GetPlayerItems() or {}) do add("item",tonumber(id) or id,type(r)=="table" and r.name,r,true) end
    for id,r in pairs(ForeverSourceData and ForeverSourceData.items or {}) do add("item",tonumber(id) or id,type(r)=="table" and r.name,r) end
    for id,r in pairs(GetWorldItems() or {}) do add("item",tonumber(id) or id,type(r)=="table" and r.name,r) end
    for id,r in pairs(ForeverBrowser_N187Index()) do add("npc",tonumber(id) or id,r.name,r) end
    for id,r in pairs(ForeverSourceData and ForeverSourceData.quests or {}) do add("quest",tonumber(id) or id,type(r)=="table" and (r.name or r.title) or r,r) end
    for id,r in pairs(ForeverSourceData and ForeverSourceData.recipes or {}) do add("recipe",tonumber(id) or id,type(r)=="table" and r.name,r) end
    for _,r in ipairs(GetForeverDungeonIndex()) do add("dungeon",r.name,r.name,r) end
    table.sort(records,function(a,b) if a.name~=b.name then return string.lower(a.name)<string.lower(b.name) end return a.kind..tostring(a.id)<b.kind..tostring(b.id) end)
    return records,seen
end
function ForeverBrowser_C198Index(force)
    if type(GetTime)~="function" then return ForeverBrowser_C211BuildIndex() end
    local now=GetTime() local source=ForeverSourceData local player=GetPlayerItems() local world=GetWorldItems()
    local c=ForeverBrowserIndexCache211
    if not force and c and c.source==source and c.player==player and c.world==world and now-c.time<3 then return c.records,c.lookup end
    local records,lookup=ForeverBrowser_C211BuildIndex()
    ForeverBrowserIndexCache211={source=source,player=player,world=world,time=now,records=records,lookup=lookup} return records,lookup
end
function ForeverBrowser_C198Head(title,description)
    ClearPage() PageContent:SetHeight(900)
    local back=CreateButton(PageContent,"Codex Tools",120,28) back:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,-20) back:SetScript("OnClick",function() Navigate("forever://codex") end)
    local label=ForeverBrowser_AchievementLabel(PageContent,title,24,{1,.82,.28,1}) label:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,-68) label:SetWidth(760) label:SetHeight(30) label:SetJustifyH("LEFT")
    local sub=ForeverBrowser_AchievementLabel(PageContent,description,12,{.87,.81,.67,1}) sub:SetPoint("TOPLEFT",label,"BOTTOMLEFT",0,-8)
    sub:SetWidth(760) sub:SetHeight(36) sub:SetJustifyH("LEFT")
    return -158
end
function ForeverBrowser_C198Row(y,title,detail,url,action,actionText)
    local settings=ForeverBrowser_C201State().settings
    local height=settings.compact and ((settings.font or 14)>16 and 56 or 48) or 58
    local row=CreateFrame("Button",nil,PageContent) row:SetSize(790,height) row:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,y)
    CreateSolidBackground(row,.045,.038,.029,1)
    local label=ForeverBrowser_AchievementLabel(row,title,settings.font or 14,{1,.82,.28,1}) label:SetPoint("TOPLEFT",row,"TOPLEFT",12,-8) label:SetWidth(action and 580 or 758) label:SetHeight(math.max(18,(settings.font or 14)+2)) label:SetJustifyH("LEFT")
    local info=ForeverBrowser_AchievementLabel(row,tostring(detail or ""):gsub("[\r\n]+"," "),10,{.82,.76,.64,1}) info:SetPoint("TOPLEFT",row,"TOPLEFT",12,settings.compact and ((settings.font or 14)>16 and -35 or -27) or -35) info:SetWidth(action and 580 or 758) info:SetHeight(16) info:SetJustifyH("LEFT")
    local titleHeight=math.max(18,(settings.font or 14)+2)
    local detailHeight=16
    if type(label.GetStringHeight)=="function" then
        local ok,h=pcall(label.GetStringHeight,label)
        if ok and type(h)=="number" then titleHeight=math.max(titleHeight,h) end
    end
    if type(info.GetStringHeight)=="function" then
        local ok,h=pcall(info.GetStringHeight,info)
        if ok and type(h)=="number" then detailHeight=math.max(detailHeight,h) end
    end
    local detailOffset=math.max(settings.compact and 27 or 35,titleHeight+12)
    label:SetHeight(titleHeight) info:ClearAllPoints()
    info:SetPoint("TOPLEFT",row,"TOPLEFT",12,-detailOffset) info:SetHeight(detailHeight)
    height=math.max(height,detailOffset+detailHeight+8) row:SetHeight(height)
    if url then row:SetScript("OnClick",function() Navigate(url) end) row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight") end
    if action then local button=CreateButton(row,actionText or "Open",150,26) button:SetPoint("RIGHT",row,"RIGHT",-12,0) if row.GetFrameLevel then button:SetFrameLevel(row:GetFrameLevel()+5) end button:Show() button:SetScript("OnClick",action) end
    PageContent:SetHeight(math.max(900,math.abs(y)+100))
    return y-height-8
end
function ForeverBrowser_C198Search(query,kind,page)
    query=tostring(query or "") kind=kind or "all" page=tonumber(page) or 1
    local y=ForeverBrowser_C198Head("Search the Codex","Items, NPCs, quests, recipes and dungeons • source badges describe recorded provenance.")
    local search=CreateFrame("EditBox",nil,PageContent,"InputBoxTemplate") search:SetSize(510,30) search:SetPoint("TOPLEFT",PageContent,"TOPLEFT",35,y) search:SetAutoFocus(false) search:SetFontObject("ChatFontNormal") search:SetText(query)
    local button=CreateButton(PageContent,"Search",120,30) button:SetPoint("LEFT",search,"RIGHT",12,0)
    local function run() search:ClearFocus() Navigate("forever://codex/search/"..kind.."/1/"..(search:GetText() or "")) end
    button:SetScript("OnClick",run) search:SetScript("OnEnterPressed",run) search:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    for i,k in ipairs({"all","item","npc","quest","recipe","dungeon"}) do
        local b=CreateButton(PageContent,k==kind and "["..k.."]" or k,112,26) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25+(i-1)*130,y-44)
        b:SetScript("OnClick",function() Navigate("forever://codex/search/"..k.."/1/"..(search:GetText() or "")) end)
    end
    local entries=ForeverBrowser_C198Index() local results={} local needle=string.lower(query):match("^%s*(.-)%s*$")
    for _,r in ipairs(entries) do if (kind=="all" or kind==r.kind) and (needle=="" or tostring(r.id)==needle or string.find(string.lower(r.name),needle,1,true)) then results[#results+1]=r end end
    local pages=math.max(1,math.ceil(#results/12)) page=math.max(1,math.min(page,pages)) y=y-86
    y=ForeverBrowser_C198Row(y,#results.." matching records","Page "..page.." / "..pages)
    local state=ForeverBrowser_C198State()
    for i=(page-1)*12+1,math.min(page*12,#results) do
        local r=results[i] local key=r.kind..":"..tostring(r.id)
        y=ForeverBrowser_C198Row(y,r.name,r.kind.." • "..r.source.." • "..tostring(r.id),r.url,function()
            if state.bookmarks[key] then state.bookmarks[key]=nil else state.bookmarks[key]={kind=r.kind,id=r.id,name=r.name,url=r.url} end
            ForeverBrowser_C198Search(query,kind,page)
        end,state.bookmarks[key] and "Unbookmark" or "Bookmark")
    end
    for i,text in ipairs({"Previous","Next"}) do local b=CreateButton(PageContent,text,110,28) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25+(i-1)*125,y)
        if (i==1 and page==1) or (i==2 and page==pages) then b:Disable() else b:SetScript("OnClick",function() Navigate("forever://codex/search/"..kind.."/"..(page+(i==1 and -1 or 1)).."/"..query) end) end
    end
end
function ForeverBrowser_C198Bookmarks()
    local y=ForeverBrowser_C198Head("Codex Bookmarks","Save any item, NPC, quest, recipe or dungeon from unified search or its details page.")
    local entries={} for _,r in pairs(ForeverBrowser_C198State().bookmarks) do entries[#entries+1]=r end
    table.sort(entries,function(a,b) return a.name<b.name end)
    if #entries==0 then ForeverBrowser_C198Row(y,"No bookmarks yet","Search the Codex to add your first bookmark.","forever://codex/search/all/1/") end
    for _,r in ipairs(entries) do y=ForeverBrowser_C198Row(y,r.name,r.kind,r.url,function() ForeverBrowser_C198State().bookmarks[r.kind..":"..tostring(r.id)]=nil ForeverBrowser_C198Bookmarks() end,"Remove") end
end
function ForeverBrowser_C198Progress()
    local y=ForeverBrowser_C198Head("Character Journal","Current character observations and reconstructable quest/recipe progress; collections are account-wide.")
    ForeverBrowser_ScanQuestLog()
    local c=ForeverBrowser_JournalCharacter()
    local quests,known=0,0
    local seenQuests,seenRecipes={},{}
    for key in pairs(ForeverSourceData and ForeverSourceData.quests or {}) do
        local id=tonumber(key)
        if id and not seenQuests[id] then seenQuests[id]=true if ForeverBrowser_GetQuestPlayerStatus(id)==true then quests=quests+1 end end
    end
    for key in pairs(ForeverSourceData and ForeverSourceData.recipes or {}) do
        local id=tonumber(key)
        if id and not seenRecipes[id] and type(IsSpellKnown)=="function" then seenRecipes[id]=true local ok,v=pcall(IsSpellKnown,id) if ok and v then known=known+1 end end
    end
    for _,row in ipairs({{c.name,"Tracking began: "..tostring(c.started or "unknown")},
        {"Completed database quests",tostring(quests).." • current character","forever://codex/chains"},
        {"Known database recipes",IsSpellKnown and tostring(known).." • current character" or "Client recipe knowledge API unavailable","forever://professions"},
        {"Observed unique items",tostring(ForeverBrowser_CountRecords(c.items)).." • since character tracking began"},
        {"Collected items",tostring(ForeverBrowser_CountRecords(GetForeverCollection())).." • account collection","forever://codex/goals"}}) do y=ForeverBrowser_C198Row(y,row[1],row[2],row[3]) end
end
function ForeverBrowser_ShoppingRecipes225()
    local shopping=ForeverBrowser_C198State().shopping
    local normalized={}
    for rawID,rawQuantity in pairs(shopping) do
        local id,q=tonumber(rawID),tonumber(rawQuantity)
        if id and id>0 and id==math.floor(id) and q and q==q and q>0 and q<math.huge then
            normalized[id]=(normalized[id] or 0)+math.min(9999,math.floor(q))
        end
    end
    for key in pairs(shopping) do shopping[key]=nil end
    local rows={}
    for id,q in pairs(normalized) do
        q=math.min(9999,q)
        if q>0 then
            shopping[id]=q
            local recipe=GetRecipeData(id)
            rows[#rows+1]={id=id,q=q,name=tostring(type(recipe)=="table" and recipe.name or ("Recipe "..id))}
        end
    end
    table.sort(rows,function(a,b) if a.name==b.name then return a.id<b.id end return string.lower(a.name)<string.lower(b.name) end)
    return rows
end
function ForeverBrowser_ShoppingSet225(id,quantity)
    id,quantity=tonumber(id),tonumber(quantity)
    if not id or id<=0 or id~=math.floor(id) or not quantity or quantity~=quantity or quantity<0 or quantity>9999 or quantity~=math.floor(quantity) then return false end
    ForeverBrowser_ShoppingRecipes225()
    ForeverBrowser_C198State().shopping[id]=quantity>0 and quantity or nil
    return true
end
function ForeverBrowser_C198Materials()
    local materials,unknown={},{}
    for _,entry in ipairs(ForeverBrowser_ShoppingRecipes225()) do
        local recipe=GetRecipeData(entry.id)
        local reagents=type(recipe)=="table" and (recipe.reagents or recipe.materials)
        local incomplete=type(reagents)~="table" or next(reagents)==nil
        if type(reagents)=="table" then
            for key,v in pairs(reagents) do
                local itemID
                if type(v)=="table" then itemID=tonumber(v.itemID or v.id) else itemID=tonumber(key) end
                local count=tonumber(type(v)=="table" and (v.count or v.quantity or v.amount) or v)
                -- Array entries require explicit item IDs; map entries may use numeric keys.
                if not itemID and type(v)=="table" and (v.count or v.quantity or v.amount) and (#reagents==0 or type(key)~="number" or key>#reagents) then itemID=tonumber(key) end
                if itemID and itemID>0 and itemID==math.floor(itemID) and count and count>0 and count<math.huge and count==math.floor(count) then
                    materials[itemID]=(materials[itemID] or 0)+count*entry.q
                else incomplete=true end
            end
        end
        if incomplete then unknown[#unknown+1]=entry.id end
    end
    return materials,unknown
end
function ForeverBrowser_C198Bags(id)
    local candidates={}
    if C_Item and type(C_Item.GetItemCount)=="function" then candidates[#candidates+1]=C_Item.GetItemCount end
    if type(GetItemCount)=="function" then candidates[#candidates+1]=GetItemCount end
    for _,fn in ipairs(candidates) do
        local ok,count=pcall(fn,id,false,false)
        if ok and type(count)=="number" and count==count and count>=0 and count<math.huge then return math.floor(count) end
    end
    return nil
end
function ForeverBrowser_ShoppingMaterials225(neededOnly)
    local materials,unknown=ForeverBrowser_C198Materials()
    local rows={}
    for id,required in pairs(materials) do
        local have=ForeverBrowser_C198Bags(id)
        local remaining=have and math.max(0,required-have) or nil
        if not neededOnly or remaining==nil or remaining>0 then rows[#rows+1]={id=id,name=tostring(GetItemName(id) or ("Item "..id)),required=required,have=have,remaining=remaining} end
    end
    table.sort(rows,function(a,b) if a.name==b.name then return a.id<b.id end return string.lower(a.name)<string.lower(b.name) end)
    return rows,unknown
end
function ForeverBrowser_ShoppingExport225()
    local lines={"Forever Codex • Profession Shopping List","Quantities are crafts. Counts use current-character bags; bank items are excluded.","","RECIPES"}
    local recipes=ForeverBrowser_ShoppingRecipes225()
    if #recipes==0 then lines[#lines+1]="No recipes selected." end
    for _,r in ipairs(recipes) do lines[#lines+1]=r.name.." (#"..r.id.."): "..r.q.." crafts" end
    lines[#lines+1]="" lines[#lines+1]="MATERIALS"
    local rows,unknown=ForeverBrowser_ShoppingMaterials225(false)
    for _,r in ipairs(rows) do lines[#lines+1]=r.name.." (#"..r.id.."): required "..r.required..", bags "..(r.have==nil and "unavailable" or r.have)..", remaining "..(r.remaining==nil and "unknown" or r.remaining) end
    if #unknown>0 then
        lines[#lines+1]="" lines[#lines+1]="INCOMPLETE REAGENT DATA — material totals may be incomplete:"
        for _,id in ipairs(unknown) do local r=GetRecipeData(id) lines[#lines+1]=tostring(type(r)=="table" and r.name or ("Recipe "..id)).." (#"..id..")" end
    end
    return table.concat(lines,"\n")
end
function ForeverBrowser_C198Shopping(page,editID)
    local state=ForeverBrowser_C198State()
    state.shoppingOptions225=state.shoppingOptions225 or {view="recipes",neededOnly=false}
    local options=state.shoppingOptions225
    local recipes=ForeverBrowser_ShoppingRecipes225()
    local materials,unknown=ForeverBrowser_ShoppingMaterials225(options.neededOnly)
    local view=options.view=="materials" and "materials" or "recipes"
    local entries=view=="materials" and materials or recipes
    local pages=math.max(1,math.ceil(#entries/12))
    page=math.max(1,math.min(pages,math.floor(tonumber(page) or 1)))
    local y=ForeverBrowser_C198Head("Profession Shopping List","Choose crafts, combine shared materials, and subtract current-character bag counts. Bank items are excluded.")
    local function button(text,x,atY,width,fn)
        local b=CreateButton(PageContent,text,width,28) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",x,atY) b:SetScript("OnClick",fn) return b
    end
    button("Find Recipes",160,-20,140,function() Navigate("forever://codex/search/recipe/1/") end)
    button("Copy List",310,-20,120,function() ForeverBrowser_C200Copy(ForeverBrowser_ShoppingExport225(),"Profession Shopping List") end)
    button("Refresh Bags",440,-20,140,function() if type(ForeverBrowser_C200TrackerRefresh)=="function" then ForeverBrowser_C200TrackerRefresh() end ForeverBrowser_C198Shopping(page,editID) end)
    button((view=="recipes" and "[Recipes]" or "Recipes").." ("..#recipes..")",25,y,180,function() options.view="recipes" ForeverBrowser_C198Shopping() end)
    button((view=="materials" and "[Materials]" or "Materials").." ("..#materials..")",215,y,180,function() options.view="materials" ForeverBrowser_C198Shopping() end)
    if view=="materials" then button(options.neededOnly and "Needed Only: On" or "Needed Only: Off",405,y,190,function() options.neededOnly=not options.neededOnly ForeverBrowser_C198Shopping() end) end
    y=y-42
    local total=0 for _,r in ipairs(recipes) do total=total+r.q end
    local summary=ForeverBrowser_AchievementLabel(PageContent,#recipes.." recipes • "..total.." crafts • page "..page.." / "..pages,12,{.87,.81,.67,1}) summary:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,y) summary:SetWidth(760) summary:SetHeight(24) summary:SetJustifyH("LEFT") y=y-32
    if #unknown>0 then
        y=ForeverBrowser_C198Row(y,"Incomplete reagent data",#unknown.." selected recipes have missing or invalid materials. Displayed totals may be incomplete; inspect the listed recipes.",nil,function() ForeverBrowser_C200Copy(ForeverBrowser_ShoppingExport225(),"Shopping List — Incomplete Recipes") end,"View Details")
    end
    if editID and view=="recipes" and state.shopping[tonumber(editID)] then
        editID=tonumber(editID)
        local edit=CreateFrame("EditBox",nil,PageContent,"InputBoxTemplate") edit:SetSize(70,28) edit:SetPoint("TOPLEFT",PageContent,"TOPLEFT",35,y) edit:SetAutoFocus(false) edit:SetFontObject("ChatFontNormal") edit:SetText(tostring(state.shopping[editID]))
        local hint=ForeverBrowser_AchievementLabel(PageContent,"Craft quantity: 0–9999 (0 removes recipe)",11,{.87,.81,.67,1}) hint:SetPoint("TOPLEFT",PageContent,"TOPLEFT",35,y-34) hint:SetWidth(500) hint:SetHeight(20)
        local function save()
            if ForeverBrowser_ShoppingSet225(editID,edit:GetText()) then edit:ClearFocus() ForeverBrowser_C198Shopping(page) else hint:SetText("Enter a whole craft quantity from 0 to 9999.") end
        end
        button("Set Quantity",120,y,140,save)
        button("Remove Recipe",270,y,150,function() ForeverBrowser_ShoppingSet225(editID,0) ForeverBrowser_C198Shopping(page) end)
        button("Cancel",430,y,100,function() ForeverBrowser_C198Shopping(page) end)
        edit:SetScript("OnEnterPressed",save) edit:SetScript("OnEscapePressed",function() edit:ClearFocus() ForeverBrowser_C198Shopping(page) end)
        y=y-64
    end
    if #entries==0 then
        local message=#recipes==0 and "Open a recipe and select Add Craft to start your shopping list." or options.neededOnly and "All recorded materials are already in your bags." or "No material quantities are available for these recipes."
        y=ForeverBrowser_C198Row(y,#recipes==0 and "Your shopping list is empty" or "No materials to show",message,#recipes==0 and "forever://codex/search/recipe/1/" or nil)
    end
    for i=(page-1)*12+1,math.min(#entries,page*12) do
        local r=entries[i]
        if view=="recipes" then
            y=ForeverBrowser_C198Row(y,r.name,r.q.." crafts • click the name to view recipe details","forever://recipe/"..r.id,function() ForeverBrowser_C198Shopping(page,r.id) end,"Edit Quantity")
        else
            y=ForeverBrowser_C198Row(y,r.name,"Required: "..r.required.." • in bags: "..(r.have==nil and "unavailable" or r.have).." • remaining: "..(r.remaining==nil and "unknown" or r.remaining),"forever://item/"..r.id)
        end
    end
    if pages>1 then
        local prev=button("Previous",25,y,120,function() ForeverBrowser_C198Shopping(page-1) end)
        local nextButton=button("Next",155,y,120,function() ForeverBrowser_C198Shopping(page+1) end)
        if page==1 then prev:Disable() end if page==pages then nextButton:Disable() end
        y=y-40
    end
    PageContent:SetHeight(math.max(700,math.abs(y)+80))
end

function ForeverBrowser_C198DungeonData(name)
    local selected,loot,quests,seen=nil,{},{},{}
    for _,d in ipairs(GetForeverDungeonIndex()) do if d.name==name then selected=d break end end
    if not selected then return nil,loot,quests end
    local bosses={} for _,boss in ipairs(selected.bosses) do bosses[boss.id]=true for _,r in ipairs(GetForeverBossLoot(boss.id)) do if not seen[r.id] then seen[r.id]=true loot[#loot+1]=r end end end
    for id,q in pairs(ForeverSourceData and ForeverSourceData.quests or {}) do
        if type(q)=="table" then local linked=q.dungeonName==name or q.zoneName==name or (type(q.dungeonAssociations)=="table" and q.dungeonAssociations[name])
            for _,field in ipairs({"npcStarters","npcFinishers"}) do for _,npc in pairs(type(q[field])=="table" and q[field] or {}) do if type(npc)=="table" and bosses[tonumber(npc.id)] then linked=true end end end
            if linked then quests[#quests+1]={id=tonumber(id) or q.id,name=q.name or ("Quest "..tostring(id))} end
        end
    end
    table.sort(quests,function(a,b) return a.name<b.name end)
    return selected,loot,quests
end
function ForeverBrowser_C198Dungeon(name)
    if not name or name=="" then
        local y=ForeverBrowser_C198Head("Dungeon Journals","Recorded bosses, loot, explicitly related quests and account collection progress.")
        for _,d in ipairs(GetForeverDungeonIndex()) do y=ForeverBrowser_C198Row(y,d.name,#d.bosses.." boss records • "..(d.isForever and "Forever" or "Recorded dungeon"),"forever://codex/dungeon/"..d.name) end return
    end
    local dungeon,loot,quests=ForeverBrowser_C198DungeonData(name)
    local y=ForeverBrowser_C198Head(name,"Dungeon Journal • collection progress describes obtained items, never boss kills.")
    if not dungeon then ForeverBrowser_C198Row(y,"Dungeon unavailable","This dungeon is no longer in the loaded database.") return end
    local collected=0 for _,r in ipairs(loot) do if IsForeverItemCollected(r.id) then collected=collected+1 end end
    y=ForeverBrowser_C198Row(y,"Loot Collection",collected.." / "..#loot.." recorded items collected","forever://dungeon/"..name,function()
        local ids={} for _,r in ipairs(loot) do ids[r.id]=true end ForeverBrowser_C198SaveGoal("Dungeon: "..name,ids,"Recorded dungeon loot") Navigate("forever://codex/goals") end,"Track collection")
    for _,boss in ipairs(dungeon.bosses) do y=ForeverBrowser_C198Row(y,boss.name,tostring(boss.role or "Dungeon Boss").." • recorded boss","forever://npc/"..boss.id,function() Navigate("forever://dungeonboss/"..boss.id) end,"View Loot") end
    y=ForeverBrowser_C198Row(y,"Related Quests",#quests.." explicitly linked quests in the loaded database")
    for _,q in ipairs(quests) do y=ForeverBrowser_C198Row(y,q.name,ForeverBrowser_QuestStatusText225(q.id),"forever://codex/chain/"..q.id) end
end
function ForeverBrowser_C198SaveGoal(name,ids,source)
    local state=ForeverBrowser_C198State()
    for _,goal in pairs(state.goals) do if goal.name==name and goal.source==source and source~="Custom wishlist" then goal.items=ids return end end
    local id=state.nextGoal or 1 state.nextGoal=id+1 state.goals[tostring(id)]={name=name,items=ids or {},source=source or "Custom wishlist"}
end
function ForeverBrowser_C198Goals(addItem)
    local y=ForeverBrowser_C198Head("Collection Goals","Account collection progress for dungeon loot, recorded item sets and custom wishlists.")
    local input=CreateFrame("EditBox",nil,PageContent,"InputBoxTemplate") input:SetSize(460,28) input:SetPoint("TOPLEFT",PageContent,"TOPLEFT",35,y) input:SetAutoFocus(false) input:SetFontObject("ChatFontNormal")
    local create=CreateButton(PageContent,"Create Wishlist",150,28) create:SetPoint("LEFT",input,"RIGHT",12,0)
    local function new() local name=(input:GetText() or ""):match("^%s*(.-)%s*$") if name~="" then ForeverBrowser_C198SaveGoal(name,addItem and {[tonumber(addItem)]=true} or {},"Custom wishlist") ForeverBrowser_C198Goals() end end
    create:SetScript("OnClick",new) input:SetScript("OnEnterPressed",new) y=y-48
    y=ForeverBrowser_C198Row(y,"Dungeon Collections","Choose a journal, then Track collection.","forever://codex/dungeons")
    y=ForeverBrowser_C198Row(y,"Recorded Item Sets","Create goals only where explicit item-set fields exist.","forever://codex/sets")
    local state=ForeverBrowser_C198State() local goals={} for id,g in pairs(state.goals) do goals[#goals+1]={id=id,g=g} end table.sort(goals,function(a,b) return a.g.name<b.g.name end)
    for _,r in ipairs(goals) do local total,done=0,0 for id in pairs(r.g.items) do total=total+1 if IsForeverItemCollected(id) then done=done+1 end end
        y=ForeverBrowser_C198Row(y,r.g.name,done.." / "..total.." collected • "..r.g.source,"forever://codex/goal/"..r.id,function()
            if addItem then r.g.items[tonumber(addItem)]=true ForeverBrowser_C198Goals() else state.goals[r.id]=nil ForeverBrowser_C198Goals() end
        end,addItem and "Add this item" or "Remove goal")
    end
end
function ForeverBrowser_C198Goal(id)
    local goal=ForeverBrowser_C198State().goals[tostring(id)] local y=ForeverBrowser_C198Head(goal and goal.name or "Collection unavailable","Account-wide collection • remove items to edit your goal.")
    if not goal then return end
    local ids={} for itemID in pairs(goal.items) do ids[#ids+1]=tonumber(itemID) end table.sort(ids)
    for _,itemID in ipairs(ids) do y=ForeverBrowser_C198Row(y,GetItemName(itemID),IsForeverItemCollected(itemID) and "Collected" or "Missing","forever://item/"..itemID,function() goal.items[itemID]=nil ForeverBrowser_C198Goal(id) end,"Remove item") end
end
function ForeverBrowser_C198Sets()
    local y=ForeverBrowser_C198Head("Recorded Item Sets","Sets are grouped by explicit set IDs or set names; unlabelled items are excluded.")
    local sets={}
    for id,r in pairs(ForeverSourceData and ForeverSourceData.items or {}) do if type(r)=="table" then
        local key=r.itemSetID or r.setID or r.itemSetName or r.setName
        if key and tostring(key)~="" and tostring(key)~="0" then local k=tostring(key) sets[k]=sets[k] or {name=r.itemSetName or r.setName or ("Item Set "..k),items={}} local itemID=tonumber(id) or tonumber(r.id) if itemID then sets[k].items[itemID]=true end end
    end end
    local entries={} for _,r in pairs(sets) do entries[#entries+1]=r end table.sort(entries,function(a,b) return a.name<b.name end)
    if #entries==0 then ForeverBrowser_C198Row(y,"No explicit item sets loaded","Custom wishlists and dungeon collection goals are still available.","forever://codex/goals") end
    for _,r in ipairs(entries) do y=ForeverBrowser_C198Row(y,r.name,ForeverBrowser_CountRecords(r.items).." recorded pieces",nil,function() ForeverBrowser_C198SaveGoal(r.name,r.items,"Recorded item set") Navigate("forever://codex/goals") end,"Track set") end
end
function ForeverBrowser_C198Actions(kind,id)
    ForeverBrowser_C218Button(kind,id)
    ForeverBrowser_C200NotesButton(kind,id)
    local related=CreateButton(PageContent,"Related Records",135,28)
    if kind=="item" and ItemActionsAnchor then
        related:SetPoint("TOPLEFT",ItemActionsAnchor,"BOTTOMLEFT",320,-20)
    else
        related:SetPoint("BOTTOMRIGHT",PageContent,"BOTTOMRIGHT",-155,12)
    end
    related:SetScript("OnClick",function() Navigate("forever://codex/related/"..kind.."/"..tostring(id).."/1") end)
    local state=ForeverBrowser_C198State() local key=kind..":"..tostring(id)
    local r=({item=GetAnyItem,quest=FindQuestSourceData,npc=FindNPCSourceData,recipe=GetRecipeData})[kind]
    local record=r and r(id) or {name=id,isForever=kind=="dungeon"}
    local name=type(record)=="table" and (record.name or record.title) or tostring(id)
    local url="forever://"..kind.."/"..tostring(id)
    local button=CreateButton(PageContent,state.bookmarks[key] and "Unbookmark" or "Bookmark",115,28) button:SetPoint("TOPLEFT",PageContent,"TOPLEFT",190,-20)
    button:SetScript("OnClick",function() if state.bookmarks[key] then state.bookmarks[key]=nil else state.bookmarks[key]={kind=kind,id=id,name=name or tostring(id),url=url} end button.text:SetText(state.bookmarks[key] and "Unbookmark" or "Bookmark") end)
    local source=ForeverBrowser_AchievementLabel(PageContent,ForeverBrowser_C198Source(record,kind=="item" and GetPlayerItem(id)),10,{.87,.81,.67,1}) source:SetPoint("TOPLEFT",PageContent,"TOPLEFT",460,-28) source:SetWidth(300) source:SetJustifyH("LEFT")
    if kind=="quest" or kind=="recipe" then
        button:ClearAllPoints() button:SetPoint("BOTTOMLEFT",PageContent,"BOTTOMLEFT",25,12)
        source:ClearAllPoints() source:SetPoint("BOTTOMLEFT",PageContent,"BOTTOMLEFT",300,20)
    end
    local label=kind=="recipe" and "Add Craft" or kind=="item" and "Add to Goal" or kind=="quest" and "Quest Journal" or kind=="dungeon" and "Dungeon Journal"
    if label then local b=CreateButton(PageContent,label,135,28) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",315,-20)
        if kind=="quest" or kind=="recipe" then b:ClearAllPoints() b:SetPoint("BOTTOMLEFT",PageContent,"BOTTOMLEFT",150,12) end
        b:SetScript("OnClick",function()
        if kind=="recipe" then state.shopping[id]=(state.shopping[id] or 0)+1 Navigate("forever://codex/shopping")
        elseif kind=="item" then Navigate("forever://codex/goal-add/"..id)
        elseif kind=="quest" then Navigate("forever://codex/chain/"..id)
        else Navigate("forever://codex/dungeon/"..id) end
    end) end
end
-- Grouped toolkit navigation; all existing tool routes remain available.
function ForeverBrowser_C202Groups()
    return {
        {key="explore",name="Explore & Search",description="Search records and discover your current zone.",icon="Interface\\Icons\\INV_Misc_Map_01",tools={
            {"Unified Search","All five database record types","search/all/1/"},
            {"Advanced Search","Levels, rarity, slots, zones & sources","advanced"},
            {"Zone Codex","Explore records by zone or map","zones"},
            {"What Can I Do Here?","Current-zone opportunities","here"},
            {"Acquisition Finder","Compare recorded item sources","acquire"},
            {"Source Guide","Understand the origin of records","sources"},
            {"Forever Directory","Browse explicitly marked Forever content","forever"},
            {"Object Database","Quest objects, recorded loot & locations","objects"},
        }},
        {key="adventure",name="Quests & Dungeons",description="Follow storylines and prepare your next dungeon run.",icon="Interface\\Icons\\INV_Misc_Book_11",tools={
            {"Quest Journals","Prerequisites, progress & continuation","chains"},
            {"Quest Progress Maps","Ordered quests and recorded branches","chain-map"},
            {"Dungeon Journals","Boss records, loot & related quests","dungeons"},
            {"Dungeon Guides","Entrances, quests, boss notes & loot","guides"},
            {"Dungeon Preparation","Quests, missing loot & entrances","prep"},
        }},
        {key="collections",name="Collections & Goals",description="Organize collections and track what you still need.",icon="Interface\\Icons\\INV_Misc_Bag_10",tools={
            {"Collection Goals","Dungeon loot, item sets & wishlists","goals"},
            {"Collection Shelves","Mounts, pets, sets & Forever items","shelves"},
            {"Tracked Goals","Movable goals & materials panel","tracker"},
        }},
        {key="crafting",name="Professions & Materials",description="Plan recipes, combine materials and prepare shopping lists.",icon="Interface\\Icons\\Trade_BlackSmithing",tools={
            {"Profession Planner","Compare skill and reagent requirements","planner"},
            {"Profession Shopping","Combine selected recipe materials","shopping"},
            {"Raw Materials","Expand crafted ingredients safely","raw"},
        }},
        {key="journal",name="Personal Journal",description="Review characters, discoveries and saved records.",icon="Interface\\Icons\\INV_Misc_Book_09",tools={
            {"Character Journal","Quests, recipes and item observations","progress"},
            {"Character Comparison","Recorded character skills & progress","compare"},
            {"Discovery Timeline","Dated item, recipe and quest observations","timeline"},
            {"Bookmarks","Save records from any database","bookmarks"},
            {"Navigation History","Recently viewed records","history"},
        }},
        {key="manage",name="Settings & Utilities",description="Adjust readability and export personal collections.",icon="Interface\\Icons\\INV_Gizmo_02",tools={
            {"Codex Settings","Readability, scale & tracker controls","options"},
            {"List Exports","Copy shopping lists & collections","exports"},
        }},
        {key="review",name="Database Review",description="Inspect missing data, record evidence and review corrections.",icon="Interface\\Icons\\INV_Misc_Book_09",tools={
            {"Data Corrections","Saved reports, evidence & owner review","corrections"},
            {"Missing Data","Search records with incomplete fields","missing"},
        }},
    }
end
-- Shared navigation strip for Codex homes with a page-level back button.
function ForeverBrowser_C209ReserveNavigation(hero)
    hero:ClearAllPoints() hero:SetPoint("TOP",PageContent,"TOP",0,-56)
end
function ForeverBrowser_C198Hub(category)
    local groups=ForeverBrowser_C202Groups() local selected
    for _,group in ipairs(groups) do if group.key==category then selected=group break end end
    local hero=ForeverBrowser_CodexHome191(selected and selected.name or "Codex Tools",selected and selected.description or "Choose a chapter to find the tools you need.",selected and selected.icon or "Interface\\Icons\\INV_Misc_Book_09","","Search Codex",function(q) Navigate("forever://codex/search/all/1/"..q) end,
        {},selected and "Tools in this chapter" or "Your Codex Chapters")
    ForeverBrowser_C209ReserveNavigation(hero)
    local missing=CreateButton(PageContent,"Missing Data",140,28) missing:SetPoint("TOPLEFT",PageContent,"TOPLEFT",160,-12)
    missing:SetScript("OnClick",function() Navigate("forever://codex/missing") end)
    if selected then
        local back=CreateButton(PageContent,"All Chapters",120,28) back:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,-12) back:SetScript("OnClick",function() Navigate("forever://codex") end)
        for i,tool in ipairs(selected.tools) do ForeverBrowser_CodexCard191(hero,i,tool[1],tool[2],"Open",selected.icon,"forever://codex/"..tool[3],70) end
        PageContent:SetHeight(math.max(700,360+math.ceil(#selected.tools/2)*112))
    else
        for i,group in ipairs(groups) do ForeverBrowser_CodexCard191(hero,i,group.name,group.description,#group.tools.." tools",group.icon,"forever://codex/chapter/"..group.key,70) end
        PageContent:SetHeight(700)
    end
end
-- Zone associations use explicit map/zone fields and source relationships.
function ForeverBrowser_Z199Index()
    local zones,npcZones,questZones,mapNames={},{},{},{}
    local source=ForeverSourceData or {}
    local cache=ForeverBrowserZoneCache226
    if cache and cache.source==source and cache.items==source.items and cache.npcs==source.npcs and cache.quests==source.quests and cache.locations==source.npcLocations and cache.dungeons==source.dungeons then return cache.zones end
    local function checkpoint()
        local job=ForeverBrowserZoneJob226
        if job and job.thread==coroutine.running() then
            job.steps=job.steps+1
            if job.steps%100==0 then
                local expired=type(debugprofilestop)=="function" and debugprofilestop()-job.started>4
                if expired or job.steps-job.sliceStart>=2000 then coroutine.yield() end
            end
        end
    end

    local function locationZones(record)
        local result={}
        local function add(r)
            if type(r)~="table" then return end
            local mapID=tonumber(r.uiMapID)
            if mapID and mapNames[mapID]==nil then mapNames[mapID]=GetAutomaticMapName(mapID) or false end
            local name=mapID and mapNames[mapID] or nil
            name=name or r.zoneName or r.zone or r.areaName
            if type(name)~="string" or name:match("^%s*$") or tonumber(name) then
                if not mapID then return end
                name="Map "..mapID
            end
            name=name:match("^%s*(.-)%s*$")
            local key=string.lower(name)
            zones[key]=zones[key] or {key=key,name=name,mapIDs={},quests={},npcs={},vendors={},loot={},dungeons={},entrances={}}
            if mapID then zones[key].mapIDs[mapID]=true end
            result[key]=true
        end
        add(record)
        if type(record)=="table" then
            for _,field in ipairs({"locations","giverLocations"}) do
                for _,r in pairs(type(record[field])=="table" and record[field] or {}) do add(r) end
            end
        end
        return result
    end
    local npcIndex=ForeverBrowser_N187Index()
    for rawID,r in pairs(npcIndex) do
        checkpoint()
        local id=tonumber(rawID)
        if id then
            local associations={}
            for _,field in ipairs({"npcs","foreverNPCs"}) do
                local record=type(source[field])=="table" and (source[field][id] or source[field][tostring(id)])
                for key in pairs(locationZones(record)) do associations[key]=true end
            end
            for _,location in pairs(type(source.npcLocations)=="table" and (source.npcLocations[id] or source.npcLocations[tostring(id)]) or {}) do
                for key in pairs(locationZones(location)) do associations[key]=true end
            end
            npcZones[id]=associations
            local custom=type(source.foreverNPCs)=="table" and (source.foreverNPCs[id] or source.foreverNPCs[tostring(id)])
            for key in pairs(associations) do
                zones[key].npcs[id]={id=id,name=r.name,detail="Recorded NPC location"}
                if r.vendors or (type(source.vendors)=="table" and (source.vendors[id] or source.vendors[tostring(id)])) then
                    zones[key].vendors[id]={id=id,name=r.name,detail="Recorded vendor inventory"}
                end
                if type(custom)=="table" and custom.dungeonName and custom.dungeonName~="" then
                    zones[key].dungeons[custom.dungeonName]={name=custom.dungeonName,detail="Associated through a located Forever NPC"}
                end
            end
        end
    end
    for rawID,q in pairs(source.quests or {}) do
        checkpoint()
        local id=tonumber(rawID) or (type(q)=="table" and tonumber(q.id))
        if id and type(q)=="table" then
            local associations=locationZones(q)
            local explicit={} for key in pairs(associations) do explicit[key]=true end
            local npcs={}
            if tonumber(q.giverID) then npcs[tonumber(q.giverID)]=true end
            for _,field in ipairs({"npcStarters","npcFinishers"}) do for _,r in pairs(type(q[field])=="table" and q[field] or {}) do
                local npcID=type(r)=="table" and tonumber(r.id or r.npcID) or tonumber(r)
                if npcID then npcs[npcID]=true end
                if type(r)=="table" then for key in pairs(locationZones(r)) do associations[key]=true end end
            end end
            for npcID in pairs(npcs) do for key in pairs(npcZones[npcID] or {}) do associations[key]=true end end
            questZones[id]=associations
            for key in pairs(associations) do zones[key].quests[id]={id=id,name=q.name or q.title or ("Quest "..id),detail=explicit[key] and "Recorded quest zone/location" or "Quest starter or finisher associated with this zone"} end
        end
    end
    for rawID,item in pairs(source.items or {}) do
        checkpoint()
        local id=tonumber(rawID) or (type(item)=="table" and tonumber(item.id))
        if id and type(item)=="table" then
            for _,r in pairs(type(item.sources)=="table" and item.sources or {}) do
        checkpoint()
                if type(r)=="table" then
                    local sourceType=tostring(r.type or "")
                    if sourceType=="drop" or sourceType=="pickpocket" or sourceType=="skinning" or sourceType=="vendor" or sourceType=="quest" then
                        local associations=locationZones(r)
                        local relation=sourceType=="quest" and questZones[tonumber(r.id or r.questID)] or npcZones[tonumber(r.id or r.npcID)]
                        for key in pairs(relation or {}) do associations[key]=true end
                        for key in pairs(associations) do
                            local old=zones[key].loot[id]
                            if old then old.types[sourceType]=true else zones[key].loot[id]={id=id,name=item.name or GetItemName(id),types={[sourceType]=true}} end
                        end
                    end
                end
            end
        end
    end
    -- Entrance markers require explicit entrance fields, never boss coordinates.
    for _,d in pairs(type(source.dungeons)=="table" and source.dungeons or {}) do
        checkpoint()
        if type(d)=="table" and (d.name or d.dungeonName) then
            local name=d.name or d.dungeonName
            for key in pairs(locationZones(d)) do zones[key].dungeons[name]={name=name,detail="Recorded dungeon zone"} end
            for _,r in pairs(type(d.entranceLocations or d.entrances)=="table" and (d.entranceLocations or d.entrances) or {}) do
                if type(r)=="table" then for key in pairs(locationZones(r)) do
                    zones[key].dungeons[name]={name=name,detail="Recorded dungeon entrance"}
                    if tonumber(r.uiMapID) and tonumber(r.x) and tonumber(r.y) then
                        local markerKey=name..":"..r.uiMapID..":"..r.x..":"..r.y
                        zones[key].entrances[markerKey]={name=name,mapID=tonumber(r.uiMapID),x=tonumber(r.x),y=tonumber(r.y),detail="Explicit entrance location"}
                    end
                end end
            end
        end
    end
    ForeverBrowserZoneCache226={source=source,items=source.items,npcs=source.npcs,quests=source.quests,locations=source.npcLocations,dungeons=source.dungeons,zones=zones}
    return zones
end
function ForeverBrowser_Z199Home(query,page)
    query=tostring(query or "") page=tonumber(page) or 1
    local zones=ForeverBrowser_Z199Index() local entries={}
    for _,z in pairs(zones) do if query=="" or string.find(string.lower(z.name),string.lower(query),1,true) then entries[#entries+1]=z end end
    table.sort(entries,function(a,b) return a.name<b.name end)
    local total=ForeverBrowser_CountRecords(zones)
    local hero=ForeverBrowser_CodexHome191("The Zone Codex","Explore quests, people, vendors and recorded item sources by zone.","Interface\\Icons\\INV_Misc_Map_01",query,"Search Zones",function(text) Navigate("forever://codex/zones/1/"..text) end,
        {{total,"Recorded Zones"},{#entries,"Matching Zones"},{"NPCs","Locations"},{"Quests","Zone Associations"}},"Explore the Zones")
    ForeverBrowser_C209ReserveNavigation(hero)
    local pages=math.max(1,math.ceil(#entries/10)) page=math.max(1,math.min(page,pages))
    for i=(page-1)*10+1,math.min(page*10,#entries) do
        local z=entries[i]
        ForeverBrowser_CodexCard191(hero,i-(page-1)*10,z.name,ForeverBrowser_CountRecords(z.quests).." quests • "..ForeverBrowser_CountRecords(z.npcs).." NPCs",ForeverBrowser_CountRecords(z.loot).." item sources","Interface\\Icons\\INV_Misc_Map_01","forever://codex/zone/all/1/"..z.key)
    end
    if #entries==0 then ForeverBrowser_C198Row(-370,"No matching recorded zones","Zone names and map associations must exist in the loaded source data.") end
    local current=type(GetRealZoneText)=="function" and GetRealZoneText() or type(GetZoneText)=="function" and GetZoneText()
    if type(current)=="string" and zones[string.lower(current)] then
        local button=CreateButton(PageContent,"Current Zone",130,28) button:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,-12)
        button:SetScript("OnClick",function() Navigate("forever://codex/zone/all/1/"..string.lower(current)) end)
    end
    for i,text in ipairs({"Previous","Next"}) do local button=CreateButton(PageContent,text,110,28) button:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",(i-1)*130,-702)
        if (i==1 and page==1) or (i==2 and page==pages) then button:Disable() else button:SetScript("OnClick",function() Navigate("forever://codex/zones/"..(page+(i==1 and -1 or 1)).."/"..query) end) end
    end
    local label=ForeverBrowser_AchievementLabel(PageContent,"Page "..page.." / "..pages,11,{.87,.81,.67,1}) label:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",290,-710)
    PageContent:SetHeight(1000)
end
function ForeverBrowser_Z199Page(key,kind,page)
    local zones=ForeverBrowser_Z199Index() local zone=zones[key]
    local y=ForeverBrowser_C198Head(zone and zone.name or "Zone unavailable","Only recorded associations are listed. Quest-giver associations are labeled separately from quest zones.")
    local back=CreateButton(PageContent,"All Zones",110,28) back:SetPoint("TOPLEFT",PageContent,"TOPLEFT",160,-20) back:SetScript("OnClick",function() Navigate("forever://codex/zones") end)
    if zone then ForeverBrowser_C200NotesButton("zone",key) end
    if not zone then ForeverBrowser_C198Row(y,"No zone data","This zone is absent from the loaded database.") return end
    kind=kind or "all" page=tonumber(page) or 1
    local completed=0 for id in pairs(zone.quests) do if ForeverBrowser_GetQuestPlayerStatus(id)==true then completed=completed+1 end end
    y=ForeverBrowser_C198Row(y,"Zone Overview",ForeverBrowser_CountRecords(zone.quests).." associated quests • "..completed.." completed • "..ForeverBrowser_CountRecords(zone.npcs).." NPCs • "..ForeverBrowser_CountRecords(zone.loot).." obtainable item records")
    for i,k in ipairs({"all","quests","npcs","vendors","loot","dungeons","entrances"}) do
        local b=CreateButton(PageContent,k==kind and "["..k.."]" or k,100,26) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25+(i-1)*112,y)
        b:SetScript("OnClick",function() Navigate("forever://codex/zone/"..k.."/1/"..key) end)
    end y=y-40
    local entries={}
    local knownDungeons={} for _,d in ipairs(GetForeverDungeonIndex()) do knownDungeons[d.name]=true end
    for _,bucket in ipairs({"quests","npcs","vendors","loot","dungeons","entrances"}) do if kind=="all" or kind==bucket then
        for _,r in pairs(zone[bucket]) do
            local row={name=r.name,detail=bucket.." • "..(r.detail or "Recorded source association")}
            if bucket=="quests" then row.url="forever://codex/chain/"..r.id row.detail=row.detail.." • "..(ForeverBrowser_QuestStatusText225(r.id))
            elseif bucket=="npcs" or bucket=="vendors" then row.url="forever://npc/"..r.id
            elseif bucket=="loot" then local types={} for t in pairs(r.types) do types[#types+1]=t end table.sort(types) row.url="forever://item/"..r.id row.detail="Obtainable item • "..table.concat(types,", ")
            elseif bucket=="dungeons" then if knownDungeons[r.name] then row.url="forever://codex/dungeon/"..r.name end
            else row.marker=r end
            entries[#entries+1]=row
        end
    end end
    table.sort(entries,function(a,b) if a.name==b.name then return a.detail<b.detail end return a.name<b.name end)
    local pages=math.max(1,math.ceil(#entries/12)) page=math.max(1,math.min(page,pages))
    y=ForeverBrowser_C198Row(y,#entries.." matching records","Page "..page.." / "..pages.." • no full-zone completion or boss-kill completion is inferred")
    if #entries==0 then y=ForeverBrowser_C198Row(y,"No recorded "..kind,"This category has no explicit associations for this zone.") end
    for i=(page-1)*12+1,math.min(page*12,#entries) do local r=entries[i]
        y=ForeverBrowser_C198Row(y,r.name,r.detail,r.url,r.marker and function() ShowForeverBrowserMapMarker(r.marker.mapID,r.marker.x,r.marker.y,r.marker.name) end or nil,r.marker and "Show Entrance" or nil)
    end
    for i,text in ipairs({"Previous","Next"}) do local b=CreateButton(PageContent,text,110,28) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25+(i-1)*130,y)
        if (i==1 and page==1) or (i==2 and page==pages) then b:Disable() else b:SetScript("OnClick",function() Navigate("forever://codex/zone/"..kind.."/"..(page+(i==1 and -1 or 1)).."/"..key) end) end
    end
    PageContent:SetHeight(math.max(900,math.abs(y)+80))
end

-- Safe planning/organization tools; no combat event subscriptions.
function ForeverBrowser_C200State()
    local state=ForeverBrowser_C198State()
    state.notes=state.notes or {} state.filters=state.filters or {}
    state.tracker=state.tracker or {goals={},shopping=true,visible=false}
    state.tracker.goals=state.tracker.goals or {}
    state.timeline=state.timeline or {} state.timelineSeen=state.timelineSeen or {} state.timelineBaseline=state.timelineBaseline or {}
    return state
end
function ForeverBrowser_C200Input(parent,x,y,width,value,multiline,height)
    local box=CreateFrame("EditBox",nil,parent,multiline and nil or "InputBoxTemplate")
    box:SetSize(width,height or 28) box:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y) box:SetAutoFocus(false) box:SetFontObject("ChatFontNormal") box:SetText(tostring(value or ""))
    if multiline then box:SetMultiLine(true) box:SetTextInsets(10,10,8,8) CreateSolidBackground(box,.025,.022,.017,1) end
    box:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    return box
end
function ForeverBrowser_C200Notes(kind,id,embeddedY)
    local state=ForeverBrowser_C200State() local key=kind..":"..tostring(id) local note=state.notes[key] or {}
    local y=embeddedY or ForeverBrowser_C198Head(kind=="item" and ("Notes: "..GetItemName(tonumber(id))) or "Personal Notes","Notes and tags for "..kind.." "..tostring(id).." • click Save Notes to keep changes.")
    if kind=="item" then
        local notebook=CreateButton(PageContent,"Tags & Notes",120,28) notebook:SetPoint("TOPLEFT",PageContent,"TOPLEFT",160,-20) notebook:SetScript("OnClick",function() Navigate("forever://tags") end)
        local item=CreateButton(PageContent,"Item Details",120,28) item:SetPoint("TOPLEFT",PageContent,"TOPLEFT",290,-20) item:SetScript("OnClick",function() Navigate("forever://item/"..id) end)
    end
    local tags=ForeverBrowser_C200Input(PageContent,35,y,740,kind=="item" and GetSavedItemTags(tonumber(id)) or note.tags)
    local label=ForeverBrowser_AchievementLabel(PageContent,"Tags • separate with commas; duplicate tags are removed when saved",11,{.87,.81,.67,1}) label:SetPoint("TOPLEFT",tags,"BOTTOMLEFT",0,-6)
    local scroll=CreateFrame("ScrollFrame",nil,PageContent,"UIPanelScrollFrameTemplate")
    scroll:SetSize(760,300) scroll:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,y-60)
    local editor=ForeverBrowser_C200Input(scroll,0,0,720,kind=="item" and GetSavedItemNote(tonumber(id)) or note.text,true,300)
    scroll:SetScrollChild(editor)
    local function resize(self)
        local text=self:GetText() or "" local _,lines=string.gsub(text,"\n","")
        self:SetHeight(math.max(300,(lines+math.ceil(#text/90)+2)*16))
    end
    editor:SetScript("OnTextChanged",resize) resize(editor)
    local save=CreateButton(PageContent,"Save Notes",140,28) save:SetPoint("TOPLEFT",scroll,"BOTTOMLEFT",0,-12)
    local status=ForeverBrowser_AchievementLabel(PageContent,"",12,{.4,.9,.5,1}) status:SetPoint("LEFT",save,"RIGHT",12,0)
    editor:SetScript("OnTextChanged",function(self) resize(self) status:SetText("Unsaved changes") end)
    tags:SetScript("OnTextChanged",function() status:SetText("Unsaved changes") end)
    local clear=CreateButton(PageContent,"Clear Draft",110,28) clear:SetPoint("TOPRIGHT",scroll,"BOTTOMRIGHT",0,-12)
    clear:SetScript("OnClick",function() editor:SetText("") tags:SetText("") status:SetText("Draft cleared • save to apply") end)
    save:SetScript("OnClick",function()
        tags:SetText(ForeverBrowser_L206Tags(tags:GetText()))
        state.notes[key]={text=editor:GetText() or "",tags=tags:GetText() or ""}
        if kind=="item" then SaveItemNote(tonumber(id),editor:GetText() or "") SaveItemTags(tonumber(id),tags:GetText() or "") end
        tags:ClearFocus() editor:ClearFocus() status:SetText("Saved")
    end)
end
function ForeverBrowser_C200NotesButton(kind,id)
    local button=CreateButton(PageContent,"Notes & Tags",125,28)
    if kind=="item" and ItemActionsAnchor then
        button:SetPoint("TOPLEFT",ItemActionsAnchor,"BOTTOMLEFT",470,-20)
    else
        button:SetPoint("BOTTOMRIGHT",PageContent,"BOTTOMRIGHT",-25,12)
    end
    button:SetScript("OnClick",function() Navigate("forever://codex/notes/"..kind.."/"..tostring(id)) end)
end
function ForeverBrowser_C200Acquisition(id,query)
    local y=ForeverBrowser_C198Head("Where Do I Get This?","Recorded drops, vendors, quest rewards and crafting sources. Imported records are not independently verified; missing rates stay unknown.")
    if not id then
        query=tostring(query or "")
        local box=ForeverBrowser_C200Input(PageContent,35,y,500,query)
        local search=CreateButton(PageContent,"Search Items",130,28) search:SetPoint("LEFT",box,"RIGHT",12,0)
        local function run() Navigate("forever://codex/acquire-search/"..(box:GetText() or "")) end search:SetScript("OnClick",run) box:SetScript("OnEnterPressed",run)
        if query=="" then return end y=y-44
        local records=ForeverBrowser_C198Index() local shown=0
        for _,r in ipairs(records) do if r.kind=="item" and (tonumber(query)==tonumber(r.id) or string.find(string.lower(r.name),string.lower(query),1,true)) then
            shown=shown+1 if shown<=30 then y=ForeverBrowser_C198Row(y,r.name,r.source,"forever://codex/acquire/"..r.id) end
        end end
        if shown==0 then ForeverBrowser_C198Row(y,"No matching items","Try an item name or exact ID.") elseif shown>30 then ForeverBrowser_C198Row(y,"Refine your search",shown.." matches; first 30 shown.") end return
    end
    id=tonumber(id)
    y=ForeverBrowser_C198Row(y,GetItemName(id),"Open item details for full source/location records.","forever://item/"..id)
    local sources,seen={},{}
    for _,record in ipairs({GetAutomaticItemSources(id) or {},GetPlayerItem(id) or {}}) do
        for _,r in pairs(type(record.sources)=="table" and record.sources or {}) do if type(r)=="table" then
            local key=tostring(r.type)..":"..tostring(r.id or r.spellID or r.questID)..":"..tostring(r.name)
            if not seen[key] then seen[key]=true sources[#sources+1]=r end
        end end
    end
    -- Reverse crafting references are reliable even if item sources omit them.
    for rawID,r in pairs(ForeverSourceData and ForeverSourceData.recipes or {}) do if type(r)=="table" and tonumber(r.createsItemID or r.createdItemID or r.itemID or r.creates)==id then
        local recipeID=tonumber(rawID) or tonumber(r.id)
        if recipeID then local key="recipe:"..recipeID if not seen[key] then sources[#sources+1]={type="crafted",spellID=recipeID,name=r.name} seen[key]=true end end
    end end
    table.sort(sources,function(a,b) return tostring(a.type)..tostring(a.name or a.id)<tostring(b.type)..tostring(b.name or b.id) end)
    for _,r in ipairs(sources) do
        local kind=tostring(r.type or "unknown") local target=tonumber(r.id or r.questID or r.spellID) local url
        if kind=="quest" and target then url="forever://quest/"..target
        elseif kind=="crafted" and tonumber(r.spellID or r.recipeID or r.id) then url="forever://recipe/"..tonumber(r.spellID or r.recipeID or r.id)
        elseif (kind=="drop" or kind=="vendor" or kind=="pickpocket" or kind=="skinning") and target then url="forever://npc/"..target end
        local rate=tonumber(r.chance or r.dropChance)
        local detail=GetSourceTypeLabel(kind).." • "..(rate and string.format("Recorded chance: %.2f%%",rate) or "Chance not recorded (not a zero drop rate)")
        -- FOREVER_REPORTED_VENDOR_UI_232
        if r.currencyAmount and r.currencyName then detail=GetSourceTypeLabel(kind).." - "..tostring(r.currencyAmount).." "..r.currencyName
        elseif r.buyPrice or r.price then detail=detail.." • price (copper): "..tostring(r.buyPrice or r.price) end
        if r.evidenceStatus then detail=detail.." - "..r.evidenceStatus end
        y=ForeverBrowser_C198Row(y,r.name or (kind.." "..tostring(target or "source")),detail,url)
        -- FOREVER_RECIPE_REQUIREMENTS_UI_237
        if r.requiredProfessionSkill or r.reportedReputationRank then
            local requirement="Published learning requirements"
            if r.requiredProfessionSkill then requirement=tostring(r.reportedProfession or "Profession").." "..tostring(r.requiredProfessionSkill) end
            if r.guideSkill and r.guideSkill~=r.requiredProfessionSkill then requirement=requirement.." (guide lists "..tostring(r.guideSkill)..")" end
            if r.reportedReputationRank then requirement=requirement.." - Reputation: "..r.reportedReputationRank.." (reported)" end
            y=ForeverBrowser_C198Row(y,"Reported requirements",requirement)
        end
    end
    if #sources==0 then ForeverBrowser_C198Row(y,"No recorded acquisition sources","This item has no usable source or reverse crafting references in the loaded data.") end
end
function ForeverBrowser_C200Filter(records,filters,preparedZones)
    local result={} local query=string.lower(filters.query or "") local kind=filters.kind or "all"
    local qualityNames={poor=0,common=1,uncommon=2,rare=3,epic=4,legendary=5,artifact=6}
    local quality=tonumber(filters.quality) or qualityNames[string.lower(filters.quality or "")]
    local zoneMatches=preparedZones
    if zoneMatches==nil and (filters.zone or "")~="" then
        zoneMatches={}
        for _,z in pairs(ForeverBrowser_Z199Index()) do if string.find(string.lower(z.name),string.lower(filters.zone),1,true) then
            for id in pairs(z.npcs) do zoneMatches["npc:"..id]=true end
            for id in pairs(z.quests) do zoneMatches["quest:"..id]=true end
            for id in pairs(z.loot) do zoneMatches["item:"..id]=true end
            for name in pairs(z.dungeons) do zoneMatches["dungeon:"..name]=true end
        end end
    end
    for _,r in ipairs(records) do
        local matches=(kind=="all" or kind==r.kind) and (query=="" or tostring(r.id)==query or string.find(string.lower(r.name),query,1,true))
        if matches then
            local data=type(r.data)=="table" and r.data or {}
            -- Never query native item-info APIs across the database: missing values remain unknown.
            local level
            if tonumber(filters.min) or tonumber(filters.max) then
                if r.kind=="item" then level=tonumber(data.itemLevel or data.ItemLevel or data.ilevel or data.level)
                else level=tonumber(data.level or data.levelMin or data.requiredSkill or data.minSkill or data.skillRequired) end
                if r.kind=="npc" and not level then local npc=FindNPCSourceData(r.id) level=npc and tonumber(npc.levelMin) end
            end
            if tonumber(filters.min) then matches=matches and level~=nil and level>=tonumber(filters.min) end
            if tonumber(filters.max) then matches=matches and level~=nil and level<=tonumber(filters.max) end
            if (filters.quality or "")~="" then matches=matches and quality~=nil and r.kind=="item" and tonumber(data.quality or data.Quality or data.overallQualityID or data.OverallQualityID)==quality end
            local slot=string.lower(filters.slot or "")
            if slot~="" then matches=matches and r.kind=="item" and string.find(string.lower(tostring(data.equipLoc or data.EquipLoc or data.equipSlot or data.inventoryType or "")),slot,1,true) end
            local source=string.lower(filters.source or "")
            if source~="" then
                local found=string.find(string.lower(r.source),source,1,true)
                if string.find(string.lower(ForeverBrowser_C198Source(data)),source,1,true) then found=true end
                for _,v in pairs(type(data.sources)=="table" and data.sources or {}) do if type(v)=="table" and string.find(string.lower(tostring(v.type or "")),source,1,true) then found=true end end
                if source=="crafted" and r.kind=="recipe" then found=true end
                matches=matches and found
            end
            if zoneMatches then matches=matches and zoneMatches[r.kind..":"..tostring(r.id)] end
            if matches then result[#result+1]=r end
        end
    end return result
end
-- Incremental metadata filtering keeps the client responsive and cancels on navigation.
function ForeverBrowser_C203StartSearch(filters,page,signature,y)
    ForeverBrowserAdvancedToken203=(ForeverBrowserAdvancedToken203 or 0)+1
    local token=ForeverBrowserAdvancedToken203 local snapshot={}
    for k,v in pairs(filters) do snapshot[k]=v end
    local progress=ForeverBrowser_AchievementLabel(PageContent,"Preparing saved database records...",12,{.87,.81,.67,1}) progress:SetPoint("TOPLEFT",PageContent,"TOPLEFT",35,y)
    local worker=CreateFrame("Frame",nil,PageContent) local records,results,cursor,zones=nil,{},1,nil
    local cancel=CreateButton(PageContent,"Cancel Search",130,28) cancel:SetPoint("TOPLEFT",progress,"BOTTOMLEFT",0,-12)
    cancel:SetScript("OnClick",function() ForeverBrowserAdvancedToken203=token+1 worker:SetScript("OnUpdate",nil) worker:Hide() progress:SetText("Search canceled. Adjust filters and apply again.") cancel:Disable() end)
    worker:SetScript("OnUpdate",function(self)
        if token~=ForeverBrowserAdvancedToken203 or (CurrentURL and not CurrentURL:match("^forever://codex/advanced")) then self:SetScript("OnUpdate",nil) self:Hide() return end
        if not records then records=ForeverBrowser_C198Index() progress:SetText("Filtering "..#records.." saved records...") return end
        if zones==nil then
            zones=false
            if (snapshot.zone or "")~="" then
                zones={}
                for _,z in pairs(ForeverBrowser_Z199Index()) do if string.find(string.lower(z.name),string.lower(snapshot.zone),1,true) then
                    for id in pairs(z.npcs) do zones["npc:"..id]=true end
                    for id in pairs(z.quests) do zones["quest:"..id]=true end
                    for id in pairs(z.loot) do zones["item:"..id]=true end
                    for name in pairs(z.dungeons) do zones["dungeon:"..name]=true end
                end end
            end
            return
        end
        local batch={} local last=math.min(cursor+99,#records)
        for i=cursor,last do batch[#batch+1]=records[i] end
        for _,r in ipairs(ForeverBrowser_C200Filter(batch,snapshot,zones)) do results[#results+1]=r end
        cursor=last+1 progress:SetText("Checked "..last.." / "..#records.." records • "..#results.." matches")
        if cursor>#records then self:SetScript("OnUpdate",nil) self:Hide() ForeverBrowserAdvancedCache203={signature=signature,results=results} ForeverBrowser_C200Advanced(page,results) end
    end)
end
function ForeverBrowser_C200Advanced(page,cached)
    local state=ForeverBrowser_C200State() local filters=state.filters
    local y=ForeverBrowser_C198Head("Advanced Codex Search","Search saved database metadata. Click Apply Filters to begin; unknown item levels and rarity cannot match those filters.")
    local boxes={} local fields={{"query","Name or ID"},{"min","Minimum level / skill"},{"max","Maximum level / skill"},{"quality","Rarity (epic or 4)"},{"slot","Slot (e.g. HEAD)"},{"zone","Zone name"},{"source","Source (drop, vendor, Forever...)"}}
    for i,f in ipairs(fields) do local col=(i-1)%3 local row=math.floor((i-1)/3)
        local label=ForeverBrowser_AchievementLabel(PageContent,f[2],10,{.87,.81,.67,1}) label:SetPoint("TOPLEFT",PageContent,"TOPLEFT",35+col*260,y-row*62)
        boxes[f[1]]=ForeverBrowser_C200Input(PageContent,35+col*260,y-row*62-18,235,filters[f[1]])
    end
    local typeButton=CreateButton(PageContent,"Type: "..(filters.kind or "all"),160,28) typeButton:SetPoint("TOPLEFT",PageContent,"TOPLEFT",295,y-142)
    typeButton:SetScript("OnClick",function() local types={"all","item","npc","quest","recipe","dungeon"} local index=1 for i,v in ipairs(types) do if v==(filters.kind or "all") then index=i end end filters.kind=types[index%#types+1] typeButton.text:SetText("Type: "..filters.kind) end)
    local apply=CreateButton(PageContent,"Apply Filters",130,28) apply:SetPoint("TOPLEFT",PageContent,"TOPLEFT",470,y-142)
    apply:SetScript("OnClick",function() for key,box in pairs(boxes) do filters[key]=(box:GetText() or ""):match("^%s*(.-)%s*$") end ForeverBrowserAdvancedRequested203=true ForeverBrowserAdvancedCache203=nil ForeverBrowserIndexCache211=nil Navigate("forever://codex/advanced/1") end)
    local reset=CreateButton(PageContent,"Reset",100,28) reset:SetPoint("LEFT",apply,"RIGHT",8,0) reset:SetScript("OnClick",function() state.filters={} ForeverBrowserAdvancedRequested203=nil ForeverBrowserAdvancedCache203=nil Navigate("forever://codex/advanced/1") end)
    y=y-195
    if ((filters.min or "")~="" and not tonumber(filters.min)) or ((filters.max or "")~="" and not tonumber(filters.max)) then
        ForeverBrowser_C198Row(y,"Invalid level range","Enter numbers or leave the level fields blank.") return
    end
    if not ForeverBrowserAdvancedRequested203 and not cached then
        ForeverBrowser_C198Row(y,"Ready to search","Choose filters, then click Apply Filters. Opening this page does not scan items.") return
    end
    local signature={} for _,key in ipairs({"kind","query","min","max","quality","slot","zone","source"}) do signature[#signature+1]=tostring(filters[key] or "") end signature=table.concat(signature,"\031")
    local cache=ForeverBrowserAdvancedCache203
    local results=cached or (cache and cache.signature==signature and cache.results)
    if not results then
        ForeverBrowser_C203StartSearch(filters,page,signature,y) return
    end
    local pages=math.max(1,math.ceil(#results/12)) page=math.max(1,math.min(tonumber(page) or 1,pages))
    y=ForeverBrowser_C198Row(y,#results.." matching records","Page "..page.." / "..pages)
    for i=(page-1)*12+1,math.min(page*12,#results) do local r=results[i] y=ForeverBrowser_C198Row(y,r.name,r.kind.." • "..r.source,r.url) end
    for i,text in ipairs({"Previous","Next"}) do local button=CreateButton(PageContent,text,110,28) button:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25+(i-1)*130,y)
        if (i==1 and page==1) or (i==2 and page==pages) then button:Disable() else button:SetScript("OnClick",function() Navigate("forever://codex/advanced/"..(page+(i==1 and -1 or 1))) end) end
    end PageContent:SetHeight(math.max(900,math.abs(y)+80))
end
function ForeverBrowser_C200Copy(text,title)
    text=tostring(text or "")
    local frame=ForeverBrowserCopyDialog225
    if not frame then
        frame=CreateFrame("Frame","ForeverBrowserCopyDialog225",UIParent)
        ForeverBrowserCopyDialog225=frame
        frame:SetSize(700,500) frame:SetPoint("CENTER") frame:SetClampedToScreen(true)
        frame:SetFrameStrata("TOOLTIP") frame:SetFrameLevel(1000)
        frame:SetMovable(true)
        local drag=CreateFrame("Frame",nil,frame) drag:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0) drag:SetPoint("TOPRIGHT",frame,"TOPRIGHT",0,0) drag:SetHeight(44) drag:SetFrameStrata("TOOLTIP") drag:SetFrameLevel(1004)
        drag:EnableMouse(true) drag:RegisterForDrag("LeftButton")
        drag:SetScript("OnDragStart",function() frame:StartMoving() end)
        drag:SetScript("OnDragStop",function() frame:StopMovingOrSizing() end)
        CreateSolidBackground(frame,.045,.038,.029,1) frame:EnableMouse(true)
        frame.label=ForeverBrowser_AchievementLabel(frame,"Copy Export",18,{1,.82,.28,1}) frame.label:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-16)
        local scroll=CreateFrame("ScrollFrame",nil,frame,"UIPanelScrollFrameTemplate") scroll:SetFrameStrata("TOOLTIP") scroll:SetFrameLevel(1001)
        scroll:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-52) scroll:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-38,56)
        local editor=CreateFrame("EditBox",nil,scroll) editor:SetFrameStrata("TOOLTIP") editor:SetFrameLevel(1002)
        editor:SetWidth(630) editor:SetMultiLine(true) editor:SetAutoFocus(false) editor:SetFontObject("ChatFontNormal")
        frame.editor=editor scroll:SetScrollChild(editor)
        editor:SetScript("OnEscapePressed",function() frame:Hide() end)
        frame:SetScript("OnHide",function()
            frame:StopMovingOrSizing() editor:ClearFocus()
            local browser=frame.restoreBrowser frame.restoreBrowser=nil
            if browser then browser:Show() end
        end)
        local select=CreateButton(frame,"Select All",120,28) select:SetFrameStrata("TOOLTIP") select:SetFrameLevel(1003) select:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",18,14)
        select:SetScript("OnClick",function() editor:SetFocus() editor:HighlightText() end)
        local hint=ForeverBrowser_AchievementLabel(frame,"Select All, then Ctrl+C to copy.",11,{.87,.81,.67,1}) hint:SetPoint("LEFT",select,"RIGHT",12,0)
        local close=CreateButton(frame,"Close",85,28) close:SetFrameStrata("TOOLTIP") close:SetFrameLevel(1003) close:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-18,14)
        close:SetScript("OnClick",function() frame:Hide() end)
        UISpecialFrames=UISpecialFrames or {} table.insert(UISpecialFrames,"ForeverBrowserCopyDialog225")
    end
    frame.label:SetText(title or "Copy Export") frame.editor:SetText(text)
    local _,lineCount=string.gsub(text,"\n","")
    frame.editor:SetHeight(math.max(360,(lineCount+math.ceil(#text/75)+2)*16))
    frame:SetFrameStrata("TOOLTIP") frame:SetFrameLevel(1000)
    if BrowserFrame and BrowserFrame:IsShown() then frame.restoreBrowser=BrowserFrame BrowserFrame:Hide() end
    frame:Show() if frame.Raise then frame:Raise() end frame.editor:SetFocus() frame.editor:HighlightText()
end
function ForeverBrowser_C200Export(kind,id)
    local lines={"Forever Codex • "..kind.." export"}
    if kind=="shopping" then
        local materials,unknown=ForeverBrowser_C198Materials() local ids={} for item in pairs(materials) do ids[#ids+1]=item end table.sort(ids)
        for _,item in ipairs(ids) do local have=ForeverBrowser_C198Bags(item) lines[#lines+1]=GetItemName(item).." (#"..item.."): required "..materials[item]..", bags "..(have==nil and "unknown" or have)..", remaining "..(have==nil and "unknown" or math.max(0,materials[item]-have)) end
        if #unknown>0 then lines[#lines+1]=#unknown.." recipe entries have incomplete reagent data." end
    else
        local state=ForeverBrowser_C200State() local goals={}
        for key,g in pairs(state.goals) do if not id or tostring(key)==tostring(id) then goals[#goals+1]=g end end table.sort(goals,function(a,b) return a.name<b.name end)
        for _,g in ipairs(goals) do lines[#lines+1]="" lines[#lines+1]=g.name local ids={} for item in pairs(g.items) do ids[#ids+1]=tonumber(item) end table.sort(ids)
            for _,item in ipairs(ids) do lines[#lines+1]=(IsForeverItemCollected(item) and "[Collected] " or "[Missing] ")..GetItemName(item).." (#"..item..")" end
        end
    end return table.concat(lines,"\n")
end
function ForeverBrowser_C200Exports()
    local y=ForeverBrowser_C198Head("Collection & Shopping Exports","Generate plain text, then copy it manually. Nothing is sent to chat or other players.")
    y=ForeverBrowser_C198Row(y,"Shopping Materials","Required quantities, available bag counts and remaining materials",nil,function() ForeverBrowser_C200Copy(ForeverBrowser_C200Export("shopping"),"Shopping List Export") end,"Copy Shopping")
    y=ForeverBrowser_C198Row(y,"All Collection Goals","Custom wishlists, recorded sets and dungeon goals",nil,function() ForeverBrowser_C200Copy(ForeverBrowser_C200Export("goals"),"Collection Export") end,"Copy Goals")
    local goals={} for id,g in pairs(ForeverBrowser_C200State().goals) do goals[#goals+1]={id=id,name=g.name} end table.sort(goals,function(a,b) return a.name<b.name end)
    for _,g in ipairs(goals) do y=ForeverBrowser_C198Row(y,g.name,"Export this collection only",nil,function() ForeverBrowser_C200Copy(ForeverBrowser_C200Export("goals",g.id),g.name) end,"Copy Goal") end
end
function ForeverBrowser_C200PlannerData(key,skill)
    local data=GetProfessionData()[key] or GetProfessionData()[tonumber(key)]
    local rows={} if not data then return rows end skill=tonumber(skill) or 0
    for _,id in ipairs(GetProfessionRecipeIDs(data)) do local r=GetRecipeData(id) or {}
        local required=tonumber(r.requiredSkill or r.minSkill or r.skillRequired)
        local gray=tonumber(r.graySkill or r.greySkill or r.skillGrey or r.skillGray)
        local quantity,unknown=0,false local reagents=r.reagents or r.materials
        if type(reagents)~="table" or next(reagents)==nil then unknown=true else for _,v in pairs(reagents) do local count=tonumber(type(v)=="table" and (v.count or v.quantity or v.amount or 1) or v) if count and count>0 then quantity=quantity+count else unknown=true end end end
        if not required or (required<=skill and (not gray or skill<gray)) then
            local known=nil if type(IsSpellKnown)=="function" then local ok,value=pcall(IsSpellKnown,id) if ok then known=value==true end end
            rows[#rows+1]={id=id,name=r.name or ("Recipe "..id),required=required,gray=gray,quantity=quantity,unknown=unknown,known=known}
        end
    end
    table.sort(rows,function(a,b)
        if a.unknown~=b.unknown then return not a.unknown end
        if a.quantity~=b.quantity then return a.quantity<b.quantity end
        if (a.required or -1)~=(b.required or -1) then return (a.required or -1)>(b.required or -1) end
        return a.name<b.name
    end) return rows
end
function ForeverBrowser_C200Planner(key,skill,page)
    local y=ForeverBrowser_C198Head("Profession Leveling Planner","Compare recorded requirements and reagent quantities. Fewer reagents does not imply lower price; skill-up chances are not assumed.")
    if not key then
        local entries={} for k,data in pairs(GetProfessionData()) do entries[#entries+1]={key=k,name=GetProfessionName(data,k)} end table.sort(entries,function(a,b) return a.name<b.name end)
        for _,r in ipairs(entries) do y=ForeverBrowser_C198Row(y,r.name,"Choose your skill level to compare recipe candidates.","forever://codex/planner/"..tostring(r.key).."/1/1") end return
    end
    skill=tonumber(skill) or 1
    local box=ForeverBrowser_C200Input(PageContent,35,y,160,skill) local apply=CreateButton(PageContent,"Set Skill",110,28) apply:SetPoint("LEFT",box,"RIGHT",12,0)
    apply:SetScript("OnClick",function() local value=tonumber(box:GetText()) if value and value>=0 then Navigate("forever://codex/planner/"..key.."/"..math.floor(value).."/1") end end) y=y-42
    local rows=ForeverBrowser_C200PlannerData(key,skill) local pages=math.max(1,math.ceil(#rows/12)) page=math.max(1,math.min(tonumber(page) or 1,pages))
    y=ForeverBrowser_C198Row(y,#rows.." candidate recipes","Sorted by reagent units per craft • page "..page.." / "..pages.." • recorded gray recipes are excluded")
    for i=(page-1)*12+1,math.min(page*12,#rows) do local r=rows[i]
        local detail="Required: "..tostring(r.required or "unknown").." • reagents: "..(r.unknown and "incomplete" or r.quantity).." • gray at: "..tostring(r.gray or "unknown").." • "..(r.known==nil and "knowledge unavailable" or r.known and "known" or "not known")
        y=ForeverBrowser_C198Row(y,r.name,detail,"forever://recipe/"..r.id,function() local state=ForeverBrowser_C200State() state.shopping[r.id]=(state.shopping[r.id] or 0)+1 ForeverBrowser_C200Planner(key,skill,page) end,"Add One Craft")
    end
    for i,text in ipairs({"Previous","Next"}) do local b=CreateButton(PageContent,text,110,28) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25+(i-1)*130,y)
        if (i==1 and page==1) or (i==2 and page==pages) then b:Disable() else b:SetScript("OnClick",function() Navigate("forever://codex/planner/"..key.."/"..skill.."/"..(page+(i==1 and -1 or 1))) end) end
    end PageContent:SetHeight(math.max(900,math.abs(y)+80))
end
function ForeverBrowser_C200TimelineScan()
    local state=ForeverBrowser_C200State() local c=ForeverBrowser_JournalCharacter() local identity=c.name
    for i=#state.timeline,1,-1 do if state.timeline[i].kind=="Achievement" then table.remove(state.timeline,i) end end
    local now=type(time)=="function" and time() or 0 local baseline=state.timelineBaseline[identity]
    local function add(kind,id,name,stamp,route,import)
        stamp=tonumber(stamp)
        if kind=="Quest completion" and (not stamp or stamp<=0) then return end
        local owner=kind=="Recipe learned" and identity or "Account records"
        local key=owner..":"..kind..":"..tostring(id)
        if state.timelineSeen[key] then return end state.timelineSeen[key]=true
        if stamp and stamp>0 and (baseline or import) then state.timeline[#state.timeline+1]={kind=kind,id=id,name=name,timestamp=stamp,url=route,character=owner} end
    end
    for id,r in pairs(GetPlayerItems() or {}) do
        local stamp=type(r)=="table" and tonumber(r.discoveredAt or r.firstSeenAt or r.firstSeen) or nil
        add("Item discovery",id,type(r)=="table" and r.name or GetItemName(id),stamp or now,"forever://item/"..id,stamp~=nil)
    end
    for id,stamp in pairs(ForeverBrowser_GetQuestCompletionHistory() or {}) do add("Quest completion",id,"Quest "..id,stamp,"forever://quest/"..id,true) end
    for id,r in pairs(ForeverSourceData and ForeverSourceData.recipes or {}) do if type(IsSpellKnown)=="function" and tonumber(id) then local ok,known=pcall(IsSpellKnown,tonumber(id)) if ok and known then add("Recipe learned",id,type(r)=="table" and r.name or ("Recipe "..id),now,"forever://recipe/"..id,false) end end end
    state.timelineBaseline[identity]=true
    table.sort(state.timeline,function(a,b) return a.timestamp>b.timestamp end)
    while #state.timeline>500 do table.remove(state.timeline) end
end
function ForeverBrowser_C200Timeline(page)
    ForeverBrowser_C200TimelineScan()
    local state=ForeverBrowser_C200State() local y=ForeverBrowser_C198Head("Discovery Timeline","Recorded timestamps and newly observed discoveries • pre-existing undated items/recipes are not backdated • latest 500 records.")
    local pages=math.max(1,math.ceil(#state.timeline/12)) page=math.max(1,math.min(tonumber(page) or 1,pages))
    y=ForeverBrowser_C198Row(y,#state.timeline.." dated records","Page "..page.." / "..pages.." • item/recipe timestamps after installation are observation times")
    for i=(page-1)*12+1,math.min(page*12,#state.timeline) do local r=state.timeline[i] local stamp=type(date)=="function" and date("%Y-%m-%d %H:%M",r.timestamp) or tostring(r.timestamp)
        y=ForeverBrowser_C198Row(y,r.name or (r.kind.." "..r.id),stamp.." • "..r.kind.." • "..r.character,r.url)
    end
    for i,text in ipairs({"Previous","Next"}) do local b=CreateButton(PageContent,text,110,28) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25+(i-1)*130,y)
        if (i==1 and page==1) or (i==2 and page==pages) then b:Disable() else b:SetScript("OnClick",function() Navigate("forever://codex/timeline/"..(page+(i==1 and -1 or 1))) end) end
    end PageContent:SetHeight(math.max(900,math.abs(y)+80))
end
function ForeverBrowser_C200TrackedRows()
    local state=ForeverBrowser_C200State() local rows={} local seen={}
    for id,flag in pairs(state.tracker.goals) do local goal=state.goals[id]
        if flag and goal then for itemID in pairs(goal.items) do itemID=tonumber(itemID) if itemID and not IsForeverItemCollected(itemID) and not seen[itemID] then seen[itemID]=true rows[#rows+1]={id=itemID,name=GetItemName(itemID),detail="Missing • "..goal.name} end end end
    end
    if state.tracker.shopping then local materials=ForeverBrowser_C198Materials() for itemID,required in pairs(materials) do local have=ForeverBrowser_C198Bags(itemID)
        if have==nil or required>have then rows[#rows+1]={id=itemID,name=GetItemName(itemID),detail="Materials: "..(have==nil and "bags unknown" or math.max(0,required-have).." remaining")} end
    end end
    table.sort(rows,function(a,b) if a.name==b.name then return a.detail<b.detail end return a.name<b.name end) return rows
end
function ForeverBrowser_C200TrackerRefresh()
    local frame=ForeverBrowserCodexTracker200 if not frame or not frame:IsShown() then return end
    frame.rows=frame.rows or {} for _,row in ipairs(frame.rows) do row:Hide() end
    local rows=ForeverBrowser_C200TrackedRows() frame.count:SetText(#rows.." remaining entries • first 8 shown")
    for i=1,math.min(8,#rows) do local r=rows[i] local row=frame.rows[i]
        if not row then row=CreateFrame("Button",nil,frame) row:SetSize(310,40) row:SetPoint("TOPLEFT",frame,"TOPLEFT",12,-64-(i-1)*44)
            row.name=ForeverBrowser_AchievementLabel(row,"",12,WOW_THEME.gold) row.name:SetPoint("TOPLEFT",row,"TOPLEFT",0,0) row.name:SetWidth(304) row.name:SetHeight(16) row.name:SetJustifyH("LEFT")
            row.detail=ForeverBrowser_AchievementLabel(row,"",10,WOW_THEME.text) row.detail:SetPoint("TOPLEFT",row,"TOPLEFT",0,-20) row.detail:SetWidth(304) row.detail:SetHeight(16) row.detail:SetJustifyH("LEFT")
            row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight") frame.rows[i]=row
        end
        row.name:SetText(r.name) row.name:SetTextColor(unpack(WOW_THEME.gold)) row.detail:SetText(r.detail) row.detail:SetTextColor(unpack(WOW_THEME.text))
        row:SetScript("OnClick",function() Navigate("forever://codex/acquire/"..r.id) if BrowserFrame then BrowserFrame:Show() end end) row:Show()
    end frame:SetHeight(100+math.min(8,#rows)*44)
end
function ForeverBrowser_C200TrackerCreate()
    if ForeverBrowserCodexTracker200 then return end
    local frame=CreateFrame("Frame",nil,UIParent) ForeverBrowserCodexTracker200=frame frame:SetSize(334,150) frame:SetClampedToScreen(true) frame:SetFrameStrata("MEDIUM") frame:EnableMouse(true) frame:SetMovable(true) frame:RegisterForDrag("LeftButton")
    local config=ForeverBrowser_C200State().tracker local p=config.position
    frame:SetPoint(p and p.point or "CENTER",UIParent,p and p.relativePoint or "CENTER",p and p.x or 300,p and p.y or 0)
    CreateSolidBackground(frame,.035,.025,.014,1)
    local title=ForeverBrowser_AchievementLabel(frame,"Codex Goals",17,{1,.82,.28,1}) title:SetPoint("TOPLEFT",frame,"TOPLEFT",12,-12)
    frame.count=ForeverBrowser_AchievementLabel(frame,"",10,{.87,.81,.67,1}) frame.count:SetPoint("TOPLEFT",frame,"TOPLEFT",12,-40)
    local close=CreateButton(frame,"X",24,22) close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-8,-8) close:SetScript("OnClick",function() config.visible=false frame:Hide() end)
    frame:SetScript("OnDragStart",function(self) if not ForeverBrowser_C201State().settings.locked then self:StartMoving() end end)
    frame:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() local point,_,relativePoint,x,y=self:GetPoint(1) config.position={point=point,relativePoint=relativePoint,x=x,y=y} end)
    frame.elapsed=0 frame:SetScript("OnUpdate",function(self,elapsed) self.elapsed=self.elapsed+elapsed if self.elapsed>=5 then self.elapsed=0 ForeverBrowser_C200TrackerRefresh() end end)
    if config.visible then frame:Show() ForeverBrowser_C200TrackerRefresh() else frame:Hide() end
end
function ForeverBrowser_C200Tracker()
    ForeverBrowser_C200TrackerCreate() local state=ForeverBrowser_C200State() local config=state.tracker
    local y=ForeverBrowser_C198Head("Tracked Goals Panel","Movable panel, independent of the browser • item links open the acquisition finder • refreshes every five seconds while visible.")
    y=ForeverBrowser_C198Row(y,"Tracker Visibility",config.visible and "Shown" or "Hidden",nil,function() config.visible=not config.visible if config.visible then ForeverBrowserCodexTracker200:Show() ForeverBrowser_C200TrackerRefresh() else ForeverBrowserCodexTracker200:Hide() end ForeverBrowser_C200Tracker() end,config.visible and "Hide Tracker" or "Show Tracker")
    y=ForeverBrowser_C198Row(y,"Shopping Materials",config.shopping and "Tracked" or "Not tracked",nil,function() config.shopping=not config.shopping ForeverBrowser_C200TrackerRefresh() ForeverBrowser_C200Tracker() end,"Toggle Shopping")
    local goals={} for id,g in pairs(state.goals) do goals[#goals+1]={id=id,name=g.name} end table.sort(goals,function(a,b) return a.name<b.name end)
    for _,g in ipairs(goals) do y=ForeverBrowser_C198Row(y,g.name,config.goals[g.id] and "Pinned to tracker" or "Not pinned","forever://codex/goal/"..g.id,function() config.goals[g.id]=not config.goals[g.id] ForeverBrowser_C200TrackerRefresh() ForeverBrowser_C200Tracker() end,config.goals[g.id] and "Unpin" or "Pin Goal") end
end
function ForeverBrowser_C200Init()
    if ForeverBrowserCodexObserver200 then return end
    ForeverBrowser_C200TrackerCreate() ForeverBrowser_C200TimelineScan() ForeverBrowser_C201Snapshot()
    local observer=CreateFrame("Frame",nil,UIParent) ForeverBrowserCodexObserver200=observer observer.elapsed=0
    observer:SetScript("OnUpdate",function(self,elapsed) self.elapsed=self.elapsed+elapsed if self.elapsed>=120 then self.elapsed=0 if ForeverBrowser_S222().backgroundRefresh then ForeverBrowser_C200TimelineScan() ForeverBrowser_C201Snapshot() end end end)
end
function ForeverBrowser_C200Route(route)
    if route=="tracker" then ForeverBrowser_C200Tracker()
    elseif route=="advanced" or route:match("^advanced/%d+$") then ForeverBrowser_C200Advanced(route:match("(%d+)$"))
    elseif route=="acquire" then ForeverBrowser_C200Acquisition()
    elseif route:match("^acquire/%d+$") then ForeverBrowser_C200Acquisition(tonumber(route:match("(%d+)$")))
    elseif route:match("^acquire%-search/") then ForeverBrowser_C200Acquisition(nil,route:sub(16))
    elseif route:match("^notes/") then local kind,id=route:match("^notes/(%a+)/(.*)$") if kind then ForeverBrowser_C200Notes(kind,id) end
    elseif route=="exports" then ForeverBrowser_C200Exports()
    elseif route=="timeline" or route:match("^timeline/%d+$") then ForeverBrowser_C200Timeline(route:match("(%d+)$"))
    elseif route=="planner" then ForeverBrowser_C200Planner()
    elseif route:match("^planner/") then local key,skill,page=route:match("^planner/([^/]+)/(%d+)/(%d+)$") if key then ForeverBrowser_C200Planner(key,skill,page) end
    else return false end return true
end

-- Codex companion tools: explicit records and safe character snapshots.
function ForeverBrowser_C201State()
    local s=ForeverBrowser_C200State()
    s.companion=s.companion or {history={},corrections={},settings={font=14,compact=false,scale=1,locked=false}}
    return s.companion
end
function ForeverBrowser_C201List(title,description,rows,page,prefix,controls,countLabel)
    local y=ForeverBrowser_C198Head(title,description)
    if controls then y=controls(y) end
    table.sort(rows,function(a,b) return tostring(a.name)<tostring(b.name) end)
    local size=ForeverBrowser_S222().pageSize
    local pages=math.max(1,math.ceil(#rows/size)) page=math.max(1,math.min(tonumber(page) or 1,pages))
    y=ForeverBrowser_C198Row(y,#rows.." "..(countLabel or "records"),"Page "..page.." / "..pages)
    if #rows==0 then y=ForeverBrowser_C198Row(y,"No matching records","The loaded data has no explicit matches for this view.") end
    for i=(page-1)*size+1,math.min(page*size,#rows) do local r=rows[i] y=ForeverBrowser_C198Row(y,r.name,r.detail or "Recorded relationship",r.url,r.action,r.actionText) end
    for i,label in ipairs({"Previous","Next"}) do local b=CreateButton(PageContent,label,110,28) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25+(i-1)*130,y)
        if (i==1 and page==1) or (i==2 and page==pages) then b:Disable() else b:SetScript("OnClick",function() Navigate(prefix..(page+(i==1 and -1 or 1))) end) end
    end
end
function ForeverBrowser_C201Here(page)
    local name=type(GetRealZoneText)=="function" and GetRealZoneText() or ""
    local zones=ForeverBrowser_Z199Index() local z=zones[string.lower(name)] local rows={}
    if z then
        rows[#rows+1]={name="Browse "..z.name,detail="All recorded zone associations",url="forever://codex/zone/all/1/"..z.key}
        for id,q in pairs(z.quests) do local completed=ForeverBrowser_GetQuestPlayerStatus(id)
            local status=ForeverBrowser_QuestStatusText225(id)
            if not completed then rows[#rows+1]={name=q.name,detail="Quest • "..tostring(status or "status unknown").." • eligibility not inferred",url="forever://quest/"..id} end
        end
        for id,r in pairs(z.loot) do if not IsForeverItemCollected(id) then rows[#rows+1]={name=r.name,detail="Missing from account collection • recorded zone source",url="forever://codex/acquire/"..id} end end
        for id,n in pairs(z.vendors) do rows[#rows+1]={name=n.name,detail="Recorded vendor",url="forever://npc/"..id} end
        for id,n in pairs(z.npcs) do
            local source=ForeverSourceData or {}
            local d=(source.npcs or {})[id] or (source.npcs or {})[tostring(id)] or {}
            local custom=(source.foreverNPCs or {})[id] or (source.foreverNPCs or {})[tostring(id)] or {}
            local trainer=(source.trainers or {})[id] or (source.trainers or {})[tostring(id)]
            if trainer or d.isTrainer or d.trainer or d.trainerType or custom.isTrainer or custom.trainer or custom.trainerType then
                rows[#rows+1]={name=n.name,detail="Recorded trainer",url="forever://npc/"..id}
            end
        end
        for _,r in pairs(z.entrances) do rows[#rows+1]={name=r.name.." entrance",detail=r.detail,action=function() ShowForeverBrowserMapMarker(r.mapID,r.x,r.y,r.name) end,actionText="Show Entrance"} end
    end
    ForeverBrowser_C201List("What Can I Do Here?",name~="" and (name.." • recorded opportunities; requirements and live NPC availability may vary.") or "Current zone unavailable from the client.",rows,page,"forever://codex/here/")
end
function ForeverBrowser_C201Snapshot()
    local c=ForeverBrowser_JournalCharacter() local now=type(time)=="function" and time() or 0
    c.codex201=c.codex201 or {} local snap=c.codex201 snap.observedAt=now
    if type(UnitLevel)=="function" then local ok,v=pcall(UnitLevel,"player") if ok then snap.level=v end end
    if type(GetNumSkillLines)=="function" and type(GetSkillLineInfo)=="function" then
        local ok,n=pcall(GetNumSkillLines) if ok and type(n)=="number" then snap.skills={} for i=1,n do
            local good,name,header,_,rank,_,_,max=pcall(GetSkillLineInfo,i)
            if good and name and not header and type(rank)=="number" then snap.skills[name]={rank=rank,max=max} end
        end end
    end
    if type(GetNumFactions)=="function" and type(GetFactionInfo)=="function" then
        local ok,n=pcall(GetNumFactions) if ok and type(n)=="number" then snap.reputations={} for i=1,n do
            local good,name,_,standing,_,_,value,_,_,header=pcall(GetFactionInfo,i)
            if good and name and not header and standing then snap.reputations[name]={standing=standing,value=value} end
        end end
    end
end
function ForeverBrowser_C201Compare(page)
    ForeverBrowser_C201Snapshot() local stats=ForeverBrowser_JournalState() local rows={}
    local standing={[1]="Hated",[2]="Hostile",[3]="Unfriendly",[4]="Neutral",[5]="Friendly",[6]="Honored",[7]="Revered",[8]="Exalted"}
    for name,c in pairs(stats.characters185 or {}) do
        local snap=c.codex201 or {}
        rows[#rows+1]={name=name,detail="Level "..tostring(snap.level or "unknown").." • observed items "..ForeverBrowser_CountRecords(c.items or {}).." • quests "..ForeverBrowser_CountRecords(c.quests or {}).." • snapshot "..tostring(snap.observedAt or "unavailable")}
        for skill,r in pairs(snap.skills or {}) do rows[#rows+1]={name=name.." • "..skill,detail="Recorded skill "..r.rank.." / "..tostring(r.max or "unknown")} end
        for faction,r in pairs(snap.reputations or {}) do rows[#rows+1]={name=name.." • "..faction,detail="Recorded reputation "..tostring(standing[r.standing] or r.standing)} end
        if not snap.observedAt then rows[#rows+1]={name=name.." • snapshot unavailable",detail="Log into this character with this version to record skills and reputation."} end
    end
    ForeverBrowser_C201List("Character Comparison","Snapshots update while this character uses the addon. Collapsed skill/faction rows may be absent; item and quest counts are observations since tracking began.",rows,page,"forever://codex/compare/")
end
function ForeverBrowser_C201Raw(recipeID,crafts,choices)
    local raw,issues,steps={},{},{} choices=choices or ForeverBrowser_C201State().craftChoices or {}
    local outputs={} for id,r in pairs(ForeverSourceData and ForeverSourceData.recipes or {}) do if type(r)=="table" then local output=tonumber(r.createsItemID or r.createItemID or r.createdItemID or r.resultItemID or r.itemID or r.creates)
        if output then outputs[output]=outputs[output] or {} outputs[output][#outputs[output]+1]=tonumber(id) or id end
    end end
    local function expand(id,count,path)
        if path[id] then issues[#issues+1]="Crafting cycle at recipe "..id return false end
        local r=GetRecipeData(id) local reagents=r and (r.reagents or r.materials)
        if type(reagents)~="table" or next(reagents)==nil then issues[#issues+1]="Missing materials for recipe "..id return false end
        path[id]=true steps[id]=(steps[id] or 0)+count
        for k,v in pairs(reagents) do
            local item=tonumber(type(v)=="table" and (v.itemID or v.id or k) or k)
            local amount=tonumber(type(v)=="table" and (v.count or v.quantity or v.amount) or v)
            if item and amount and amount>0 then
                local need=amount*count local candidates=outputs[item] or {} local selected=choices[tostring(item)] or choices[item]
                if not selected and #candidates==1 then selected=candidates[1] end
                local sub=selected and GetRecipeData(tonumber(selected) or selected)
                local yield=sub and tonumber(sub.createsItemCount or sub.createItemCount or sub.createdItemCount or sub.resultCount or sub.outputCount)
                if sub and tonumber(sub.createsItemID or sub.createItemID or sub.createdItemID or sub.resultItemID or sub.itemID or sub.creates)==item and yield and yield>0 and yield==math.floor(yield) and not path[tonumber(selected) or selected] then
                    if not expand(tonumber(selected) or selected,math.ceil(need/yield),path) then raw[item]=(raw[item] or 0)+need end
                else
                    raw[item]=(raw[item] or 0)+need
                    if #candidates>0 then issues[#issues+1]=GetItemName(item)..": kept as ingredient (ambiguous recipe, missing output quantity, or cycle)." end
                end
            else issues[#issues+1]="Invalid reagent quantity in recipe "..id end
        end
        path[id]=nil return true
    end
    expand(recipeID,math.max(1,math.floor(tonumber(crafts) or 1)),{}) return raw,issues,steps
end
function ForeverBrowser_C201Materials(id,crafts)
    local y=ForeverBrowser_C198Head("Raw Material Breakdown","Expands a unique recorded crafting recipe only when its output quantity is known. Quantities round up per craft; inventory is not deducted.")
    if not id then
        for rid,q in pairs(ForeverBrowser_C198State().shopping) do y=ForeverBrowser_C198Row(y,(GetRecipeData(rid) or {}).name or tostring(rid),q.." crafts","forever://codex/raw/"..rid.."/"..q) end
        if not next(ForeverBrowser_C198State().shopping) then ForeverBrowser_C198Row(y,"Choose a recipe","Add crafts to your shopping list first.","forever://codex/shopping") end return
    end
    local raw,issues=ForeverBrowser_C201Raw(id,crafts) local ids={} for item in pairs(raw) do ids[#ids+1]=item end table.sort(ids)
    y=ForeverBrowser_C198Row(y,(GetRecipeData(id) or {}).name or ("Recipe "..id),tostring(crafts or 1).." crafts","forever://recipe/"..id)
    for _,item in ipairs(ids) do y=ForeverBrowser_C198Row(y,GetItemName(item),raw[item].." units required","forever://codex/acquire/"..item) end
    for _,issue in ipairs(issues) do y=ForeverBrowser_C198Row(y,"Incomplete expansion",issue) end
end
function ForeverBrowser_C201IDs(value,out)
    out=out or {} if type(value)=="number" or type(value)=="string" then local n=tonumber(value) if n then out[n]=true end
    elseif type(value)=="table" then if value.id or value.questID or value.questId then ForeverBrowser_C201IDs(value.id or value.questID or value.questId,out)
        else for k,v in pairs(value) do if v==true then ForeverBrowser_C201IDs(k,out) else ForeverBrowser_C201IDs(v,out) end end end
    end return out
end
function ForeverBrowser_C201Graph(id)
    local nodes,edges,adj={},{},{}
    for key,q in pairs(ForeverSourceData and ForeverSourceData.quests or {}) do if type(q)=="table" then local qid=tonumber(key) or tonumber(q.id)
        if qid then nodes[qid]=q local before,after={},{}
            for _,f in ipairs({"previousQuest","previousQuestID","prevQuest","prevQuestID","prerequisiteQuest","prerequisiteQuestID","requiredQuest","requiredQuestID","previousQuests","prerequisites","requires"}) do ForeverBrowser_C201IDs(q[f],before) end
            for _,f in ipairs({"nextQuest","nextQuestID","followupQuest","followupQuestID","nextQuests","followups"}) do ForeverBrowser_C201IDs(q[f],after) end
            local function edge(a,b) edges[a]=edges[a] or {} edges[a][b]=true adj[a]=adj[a] or {} adj[b]=adj[b] or {} adj[a][b]=true adj[b][a]=true end
            for a in pairs(before) do edge(a,qid) end for b in pairs(after) do edge(qid,b) end
        end
    end end
    local component,queue={}, {id} component[id]=true local cursor=1
    while queue[cursor] do local a=queue[cursor] cursor=cursor+1 for b in pairs(adj[a] or {}) do if not component[b] then component[b]=true queue[#queue+1]=b end end end
    local indegree={} for a in pairs(component) do indegree[a]=0 end for a in pairs(component) do for b in pairs(edges[a] or {}) do if component[b] then indegree[b]=indegree[b]+1 end end end
    local order,ready={},{} for a,n in pairs(indegree) do if n==0 then ready[#ready+1]=a end end table.sort(ready)
    while #ready>0 do local a=table.remove(ready,1) order[#order+1]=a for b in pairs(edges[a] or {}) do if indegree[b] then indegree[b]=indegree[b]-1 if indegree[b]==0 then ready[#ready+1]=b table.sort(ready) end end end end
    local cycle=false for a,n in pairs(indegree) do if n>0 then cycle=true end end
    if cycle then local remaining={} for a,n in pairs(indegree) do if n>0 then remaining[#remaining+1]=a end end table.sort(remaining) for _,a in ipairs(remaining) do order[#order+1]=a end end
    return order,nodes,edges,cycle
end
function ForeverBrowser_C201Chain(id)
    if not id then local y=ForeverBrowser_C198Head("Quest Progress Maps","Choose a quest to inspect its explicit linked storyline.")
        local box=ForeverBrowser_C200Input(PageContent,25,y,220,"") local b=CreateButton(PageContent,"Open Quest ID",150,28) b:SetPoint("LEFT",box,"RIGHT",8,0)
        b:SetScript("OnClick",function() local q=tonumber(box:GetText()) if q then Navigate("forever://codex/chain-map/"..q) end end)
        ForeverBrowser_C198Row(y-45,"Browse Quest Journals","Choose a quest from existing relationships.","forever://codex/chains") return
    end
    local order,nodes,edges,cycle=ForeverBrowser_C201Graph(id)
    local y=ForeverBrowser_C198Head("Quest Progress Map","Ordered prerequisite rows; arrows name explicit next quests. Branches do not imply every route is required. Completion uses the existing quest-status API.")
    if cycle then y=ForeverBrowser_C198Row(y,"Cyclic relationship data","Some recorded links form a cycle; those quests appear after the ordered portion.") end
    for i,qid in ipairs(order) do local q=nodes[qid] or {} local nexts={} for b in pairs(edges[qid] or {}) do nexts[#nexts+1]=b end table.sort(nexts)
        local text={} for _,b in ipairs(nexts) do text[#text+1]=tostring(b) end
        y=ForeverBrowser_C198Row(y,i..". "..(q.name or q.title or ("Quest "..qid)),tostring(ForeverBrowser_QuestStatusText225(qid)).." • next: "..(#text>0 and table.concat(text,", ") or "no recorded continuation"),"forever://quest/"..qid)
    end
end
function ForeverBrowser_C201Prep(name,page)
    if not name then local y=ForeverBrowser_C198Head("Dungeon Preparation","Bring related quests, missing loot and entrance records together before a run.") for _,d in ipairs(GetForeverDungeonIndex()) do y=ForeverBrowser_C198Row(y,d.name,"Prepare your run","forever://codex/prep/"..d.name.."/1") end return end
    local d,loot,quests=ForeverBrowser_C198DungeonData(name) local rows={}
    if d then
        rows[#rows+1]={name="Personal notes",detail="Dungeon notes and tags",url="forever://codex/notes/dungeon/"..name}
        rows[#rows+1]={name="Dungeon journal",detail="Recorded bosses and all loot",url="forever://codex/dungeon/"..name}
        for _,q in ipairs(quests) do rows[#rows+1]={name=q.name,detail="Quest • "..tostring(ForeverBrowser_QuestStatusText225(q.id)),url="forever://quest/"..q.id} end
        for _,r in ipairs(loot) do if not IsForeverItemCollected(r.id) then rows[#rows+1]={name=r.name or GetItemName(r.id),detail="Missing account loot",url="forever://codex/acquire/"..r.id} end end
        for _,z in pairs(ForeverBrowser_Z199Index()) do for _,r in pairs(z.entrances) do if r.name==name then rows[#rows+1]={name="Entrance • "..z.name,detail="Explicit database entrance",action=function() ShowForeverBrowserMapMarker(r.mapID,r.x,r.y,r.name) end,actionText="Show Entrance"} end end end
    end
    ForeverBrowser_C201List(name.." Preparation","Recorded information for planning; boss completion and live quest eligibility are not inferred.",rows,page,"forever://codex/prep/"..name.."/")
end
function ForeverBrowser_C201Shelf(kind,page)
    kind=kind or "forever" local rows={}
    for _,r in ipairs(ForeverBrowser_C198Index()) do if r.kind=="item" then local d=r.data local category=string.lower(tostring(d.collectionType or d.itemType or d.subType or d.subclass or ""))
        local match=kind=="forever" and (d.isForever or d.foreverExclusive or string.lower(tostring(d.dataSource or d.sourceDatabase))=="forever")
            or kind=="mounts" and (d.isMount or category=="mount" or category=="mounts")
            or kind=="pets" and (d.isCompanion or d.isPet or category=="companion pet" or category=="pet" or category=="pets")
        if match then rows[#rows+1]={name=r.name,detail=(IsForeverItemCollected(r.id) and "Collected" or "Missing").." • explicit collection classification",url=r.url} end
    end end
    if kind=="sets" then ForeverBrowser_C198Sets()
        local back=CreateButton(PageContent,"Collection Shelves",150,28) back:SetPoint("TOPLEFT",PageContent,"TOPLEFT",160,-20) back:SetScript("OnClick",function() Navigate("forever://codex/shelves") end) return end
    ForeverBrowser_C201List("Collection Shelf: "..kind,"Only explicitly classified records appear. Missing classification does not mean an item is absent from the realm.",rows,page,"forever://codex/shelf/"..kind.."/")
    for i,k in ipairs({"forever","mounts","pets","sets"}) do local b=CreateButton(PageContent,k,90,26) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",160+(i-1)*100,-20) b:SetScript("OnClick",function() Navigate("forever://codex/shelf/"..k.."/1") end) end
end
function ForeverBrowser_C216Relations(force)
    local source=ForeverSourceData or {}
    local now=type(GetTime)=="function" and GetTime() or 0
    local cache=ForeverBrowserCrossLinks216
    if not force and cache and cache.source==source and now-cache.stamp<60 then return cache.links end
    local links={}
    local function name(kind,id)
        local bucket=source[({item="items",npc="npcs",quest="quests",recipe="recipes"})[kind]] or {}
        local r=bucket[id] or bucket[tostring(id)]
        if kind=="npc" and not r then r=(source.foreverNPCs or {})[id] or (source.foreverNPCs or {})[tostring(id)] end
        return type(r)=="table" and (r.name or r.title) or (kind=="item" and GetItemName(id)) or (kind.." "..id)
    end
    local function link(a,aid,b,bid,detail)
        aid=tonumber(aid) bid=tonumber(bid)
        if not aid or not bid or aid<=0 or bid<=0 then return end
        local key=a..":"..aid links[key]=links[key] or {}
        local tag=b..":"..bid..":"..detail
        links[key][tag]={name=name(b,bid),detail=detail,url="forever://"..b.."/"..bid,kind=b,id=bid}
    end
    local function entries(value,fn)
        if type(value)~="table" then return end
        for key,v in pairs(value) do
            local id=type(v)=="table" and tonumber(v.itemID or v.npcID or v.id) or tonumber(v)
            if v==true then id=tonumber(key) end
            if id then fn(id) end
        end
    end
    for qid,q in pairs(source.quests or {}) do if type(q)=="table" then
        for _,field in ipairs({"rewardItems","choiceRewardItems","requiredItems"}) do
            local label=field=="requiredItems" and "Required for quest" or field=="choiceRewardItems" and "Choice quest reward" or "Quest reward"
            entries(q[field],function(item) link("quest",qid,"item",item,label) link("item",item,"quest",qid,label) end)
        end
        for _,field in ipairs({"npcStarters","npcFinishers"}) do
            local label=field=="npcStarters" and "Quest giver" or "Quest turn-in"
            entries(q[field],function(npc) link("quest",qid,"npc",npc,label) link("npc",npc,"quest",qid,label) end)
        end
        for _,field in ipairs({"giverID","starterNPCID","finisherNPCID"}) do local npc=tonumber(q[field]) if npc then
            local label=field=="finisherNPCID" and "Quest turn-in" or "Quest giver"
            link("quest",qid,"npc",npc,label) link("npc",npc,"quest",qid,label)
        end end
        local item=tonumber(q.startItemID or q.requiredStartItemID)
        if item then link("quest",qid,"item",item,"Quest-starting item") link("item",item,"quest",qid,"Starts quest") end
    end end
    for item,r in pairs(source.items or {}) do if type(r)=="table" then
        for _,s in pairs(type(r.sources)=="table" and r.sources or {}) do if type(s)=="table" then
            local kind=({vendor="npc",drop="npc",pickpocket="npc",skinning="npc",quest="quest"})[s.type]
            local target=tonumber(s.npcID or s.questID or s.id)
            if kind and target then
                local label=({vendor="Vendor inventory",drop="Recorded drop",pickpocket="Pickpocket loot",skinning="Skinning loot",quest="Quest reward"})[s.type]
                link("item",item,kind,target,label) link(kind,target,"item",item,label)
            end
        end end
    end end
    for rid,r in pairs(source.recipes or {}) do if type(r)=="table" then
        local output=tonumber(r.createsItemID or r.createItemID or r.createdItemID or r.resultItemID or r.itemID or r.creates)
        if output then link("recipe",rid,"item",output,"Crafted output") link("item",output,"recipe",rid,"Crafted by recipe") end
        for key,v in pairs(r.reagents or r.materials or {}) do
            local item=tonumber(type(v)=="table" and (v.itemID or v.id or key) or key)
            if item then link("recipe",rid,"item",item,"Ingredient") link("item",item,"recipe",rid,"Used by recipe") end
        end
    end end
    ForeverBrowserCrossLinks216={source=source,stamp=now,links=links}
    return links
end
function ForeverBrowser_C216RelatedData(kind,id)
    local rows,seen={},{} local number=tonumber(id)
    local function add(row)
        local key=row.url..":"..row.detail
        if not seen[key] then seen[key]=true rows[#rows+1]=row end
    end
    for _,row in pairs(ForeverBrowser_C216Relations()[kind..":"..tostring(number or id)] or {}) do add(row) end
    if kind=="item" then add({name="Acquisition sources",detail="Drop, vendor and quest source details",url="forever://codex/acquire/"..id}) end
    if kind=="quest" then
        local _,nodes,edges=ForeverBrowser_C201Graph(number)
        for a,nexts in pairs(edges) do if a==number then for b in pairs(nexts) do add({name=(nodes[b] or {}).name or ("Quest "..b),detail="Next quest",url="forever://quest/"..b}) end
            elseif nexts[number] then add({name=(nodes[a] or {}).name or ("Quest "..a),detail="Previous quest",url="forever://quest/"..a}) end end
    end
    local getter=({item=GetAnyItem,npc=FindNPCSourceData,quest=FindQuestSourceData,recipe=GetRecipeData})[kind]
    local record=getter and getter(number) or {}
    if type(record)=="table" and type(record.dungeonName)=="string" and record.dungeonName~="" then
        add({name=record.dungeonName,detail="Recorded dungeon association",url="forever://codex/dungeon/"..record.dungeonName})
    end
    for _,z in pairs(ForeverBrowser_Z199Index()) do
        local bucket=kind=="item" and z.loot or kind=="npc" and z.npcs or kind=="quest" and z.quests
        if bucket and (bucket[number] or bucket[id]) then add({name=z.name,detail="Recorded zone association",url="forever://codex/zone/all/1/"..z.key}) end
    end
    if kind=="item" or kind=="quest" then
        for oid,o in pairs(ForeverBrowser_C217Objects()) do
            local bucket=kind=="item" and o.items or o.quests
            if bucket[number] or bucket[id] then add({name=o.name,detail=kind=="item" and "Object loot source" or "Quest object association",url="forever://codex/object/"..oid.."/1"}) end
        end
    end
    table.sort(rows,function(a,b) if a.detail~=b.detail then return a.detail<b.detail end return tostring(a.name)<tostring(b.name) end)
    return rows
end
function ForeverBrowser_C201Related(kind,id,page)
    local rows=ForeverBrowser_C216RelatedData(kind,id)
    ForeverBrowser_C201List("Related Records","Recorded connections • grouped by relationship • missing links mean the database has no recorded connection.",rows,page,"forever://codex/related/"..kind.."/"..id.."/")
    local back=CreateButton(PageContent,"Return to Record",135,28) back:SetPoint("TOPLEFT",PageContent,"TOPLEFT",160,-20)
    back:SetScript("OnClick",function() Navigate("forever://"..kind.."/"..id) end)
end
function ForeverBrowser_CanReview225()
    if type(UnitName)~="function" then return false end
    local ok,name,second=pcall(UnitName,"player")
    if not ok or type(name)~="string" then return false end
    local function normalize(v) return v:lower():gsub("^%s+",""):gsub("%s+$",""):gsub("%s+"," ") end
    if normalize(name)=="zyntrix farheart" then return true end
    -- Forever may return the displayed name in two parts; require the exact pair.
    return type(second)=="string" and normalize(name.." "..second)=="zyntrix farheart"
end
function ForeverBrowser_ReviewFields225(kind)
    return ({item={"sources","rates","provenance"},npc={"locations","provenance"},quest={"locations","requirements","provenance"},recipe={"requirements","provenance"},object={"locations","provenance"},dungeon={"locations","requirements","provenance"}})[kind] or {"provenance"}
end
function ForeverBrowser_ReviewFieldLabel225(field)
    return ({record="General record",locations="Coordinates",sources="Acquisition sources",rates="Drop rates",requirements="Requirements",provenance="Data provenance"})[field] or "General record"
end
function ForeverBrowser_OfficialReview225(kind,id,field)
    local source=ForeverSourceData or {} local key=kind..":"..tostring(id)
    if field and field~="record" then return (type(source.reviewFieldStatuses)=="table" and type(source.reviewFieldStatuses[key])=="table" and source.reviewFieldStatuses[key][field]) or {} end
    return (source.reviewStatuses or {})[key] or {}
end
function ForeverBrowser_ReviewStatus225(kind,id,field)
    local official=ForeverBrowser_OfficialReview225(kind,id,field)
    local status=type(official)=="table" and official.status or official
    if ForeverBrowser_CanReview225() then
        local r=ForeverBrowser_C201State().corrections[kind..":"..tostring(id)]
        if field and field~="record" then r=type(r)=="table" and type(r.fieldReviews)=="table" and r.fieldReviews[field] or nil end
        if type(r)=="table" and r.status then status=r.status end
    end
    local labels={investigate="Needs Investigation",confirmed="Confirmed",fixed="Fixed",notApplicable="Not Applicable"}
    return labels[status] or "Needs Investigation",labels[status] and status or "investigate"
end
function ForeverBrowser_SaveObservation225(kind,id,text)
    local state=ForeverBrowser_C201State() local key=kind..":"..tostring(id)
    local r=state.corrections[key] or {kind=kind,id=id,recordedAt=type(time)=="function" and time() or 0}
    r.text=tostring(text or "") state.corrections[key]=r return r
end
function ForeverBrowser_SaveEvidence225(kind,id,field,draft)
    field=field or "record" draft=draft or {}
    local state=ForeverBrowser_C201State() local key=kind..":"..tostring(id)
    local r=state.corrections[key] or {kind=kind,id=id,text="",recordedAt=type(time)=="function" and time() or 0}
    state.corrections[key]=r local target=r
    if field~="record" then r.fieldReviews=r.fieldReviews or {} r.fieldReviews[field]=r.fieldReviews[field] or {} target=r.fieldReviews[field] end
    for _,k in ipairs({"observed","proposed","evidence"}) do if draft[k]~=nil then target[k]=tostring(draft[k]) end end
    if field=="record" and draft.observed~=nil then r.text=tostring(draft.observed) end
    if ForeverBrowser_CanReview225() and draft.reviewNotes~=nil then target.reviewNotes=tostring(draft.reviewNotes) end
    return target
end
function ForeverBrowser_SetReview225(kind,id,status,text,field)
    if not ForeverBrowser_CanReview225() or not ({investigate=true,confirmed=true,fixed=true,notApplicable=true})[status] then return false end
    local target
    if field and field~="record" then target=ForeverBrowser_SaveEvidence225(kind,id,field,text~=nil and {observed=text} or {})
    else local old=ForeverBrowser_C201State().corrections[kind..":"..tostring(id)] target=ForeverBrowser_SaveObservation225(kind,id,text~=nil and text or old and old.text or "") end
    target.status=status target.reviewedAt=type(time)=="function" and time() or 0 return true
end
function ForeverBrowser_ExportReviews225()
    if not ForeverBrowser_CanReview225() then return nil end
    local records,fields={},{} local valid={investigate=true,confirmed=true,fixed=true,notApplicable=true}
    local function value(r)
        local status=type(r)=="table" and r.status or r
        if not valid[status] then return nil end
        return {status=status,reviewNotes=type(r)=="table" and r.reviewNotes or nil}
    end
    for key,r in pairs((ForeverSourceData or {}).reviewStatuses or {}) do records[key]=value(r) end
    for key,f in pairs((ForeverSourceData or {}).reviewFieldStatuses or {}) do if type(f)=="table" then fields[key]={} for field,r in pairs(f) do fields[key][field]=value(r) end end end
    for key,r in pairs(ForeverBrowser_C201State().corrections) do
        if valid[r.status] then records[key]=value(r) end
        for field,f in pairs(r.fieldReviews or {}) do if valid[f.status] then fields[key]=fields[key] or {} fields[key][field]=value(f) end end
    end
    local function encode(v)
        if type(v)=="string" then return string.format("%q",v) end
        local keys={} for key in pairs(v) do keys[#keys+1]=key end table.sort(keys)
        local lines={"{"} for _,key in ipairs(keys) do lines[#lines+1]="["..string.format("%q",key).."]="..encode(v[key]).."," end lines[#lines+1]="}" return table.concat(lines,"\n")
    end
    return "-- Official statuses and owner review notes; no player observations/evidence.\nForeverSourceData = ForeverSourceData or {}\nForeverSourceData.reviewStatuses = "..encode(records).."\nForeverSourceData.reviewFieldStatuses = "..encode(fields)
end
function ForeverBrowser_ExportCorrections225()
    if not ForeverBrowser_CanReview225() then return nil end
    local function quote(value)
        return '"'..tostring(value or ""):gsub('[%z\1-\31\\"]',function(c)
            if c=='"' then return '\\"' end
            if c=='\\' then return '\\\\' end
            return string.format('\\u%04x',string.byte(c))
        end)..'"'
    end
    local rows={}
    for _,record in pairs(ForeverBrowser_C201State().corrections or {}) do
        if type(record)=="table" and record.kind and record.id then
            for field,review in pairs(record.fieldReviews or {}) do
                if type(review)=="table" and review.status=="confirmed" then
                    local parts={}
                    local values={kind=record.kind,id=record.id,field=field,status="confirmed",observed=review.observed or "",proposed=review.proposed or "",evidence=review.evidence or "",reviewNotes=review.reviewNotes or "",reviewedAt=review.reviewedAt or ""}
                    for _,key in ipairs({"kind","id","field","status","observed","proposed","evidence","reviewNotes","reviewedAt"}) do
                        local value=values[key]
                        parts[#parts+1]=quote(key)..":"..(key=="id" and record.kind~="dungeon" and tonumber(value) and tostring(tonumber(value)) or quote(value))
                    end
                    rows[#rows+1]={key=tostring(record.kind)..":"..tostring(record.id)..":"..field,text="{"..table.concat(parts,",").."}"}
                end
            end
        end
    end
    table.sort(rows,function(a,b) return a.key<b.key end)
    local result={}
    for _,row in ipairs(rows) do result[#result+1]=row.text end
    return '{"schema":"ForeverBrowserCorrectionReview/v1","addonVersion":'..quote(ForeverBrowserVersion)..',"corrections":['..table.concat(result,",\n")..']} '
end

function ForeverBrowser_IssueReport225(kind,id,observation,field,draft)
    local source=ForeverSourceData or {}
    local bucket=source[({item="items",quest="quests",npc="npcs",recipe="recipes",object="objects",dungeon="dungeons"})[kind]] or {}
    local r=bucket[tonumber(id) or id] or bucket[tostring(id)]
    if kind=="dungeon" then for _,d in pairs(bucket) do if type(d)=="table" and d.name==id then r=d break end end end
    r=type(r)=="table" and r or {}
    local name=r.name or r.itemName or r.questName or r.npcName
    if not name and kind=="item" then name=GetItemName(tonumber(id) or id) end
    local route=kind=="object" and "forever://codex/object/"..id.."/1" or kind=="dungeon" and "forever://codex/guide/"..id.."/1" or "forever://"..kind.."/"..id
    draft=draft or {}
    return table.concat({"ForeverBrowser — Database Issue Report",
        "Addon version: "..tostring(ForeverBrowserVersion or "v1.0.1"),
        "Build: "..tostring(ForeverBrowserBuild225 or "Not recorded"),
        "Record type: "..tostring(kind),"Record name: "..tostring(name or "Not recorded"),
        "Record ID / key: "..tostring(id),"Record link: "..route,
        "Data source: "..tostring(r.dataSource or r.sourceDatabase or "Not recorded"),
        "Enrichment source: "..tostring(r.enrichmentSource or "Not recorded"),
        "Import date: "..tostring(r.importedAt or r.enrichmentImportedAt or "Not recorded"),
        "Verification date: "..tostring(r.verifiedAt or r.verifiedDate or "Not recorded"),
        "Content classification: "..tostring(r.contentStatus or "Not recorded"),
        "Reviewed field: "..ForeverBrowser_ReviewFieldLabel225(field),
        "Review status: "..ForeverBrowser_ReviewStatus225(kind,id,field),
        "Note: Review status does not establish source verification. Import dates do not establish verification.","","Player observation:",
        tostring(draft.observed or observation or ""),"","Proposed correction:",tostring(draft.proposed or ""),"","Evidence / source:",tostring(draft.evidence or ""),"","Owner review notes:",tostring(draft.reviewNotes or "")},"\n")
end
function ForeverBrowser_C201Corrections(kind,id,field,page)
    local s=ForeverBrowser_C201State()
    if not kind then
        local rows={}
        for _,r in pairs(s.corrections) do
            if (r.observed or r.text or "")~="" or r.status or (r.proposed or "")~="" or (r.evidence or "")~="" then
                rows[#rows+1]={name=r.kind.." "..r.id.." — General report",detail=ForeverBrowser_ReviewStatus225(r.kind,r.id).." • "..(r.observed or r.text or ""),url="forever://codex/correct/"..r.kind.."/"..r.id}
            end
            for _,f in ipairs(ForeverBrowser_ReviewFields225(r.kind)) do local entry=(r.fieldReviews or {})[f] if entry then
                rows[#rows+1]={name=r.kind.." "..r.id.." — "..ForeverBrowser_ReviewFieldLabel225(f),detail=ForeverBrowser_ReviewStatus225(r.kind,r.id,f).." • "..(entry.observed or ""),url="forever://codex/correct/"..r.kind.."/"..r.id.."/field/"..f}
            end end
        end
        ForeverBrowser_C201List("Saved Reports","Open a saved draft to continue reviewing. Your observations stay local.",rows,page,"forever://codex/corrections/",nil,"saved reports")
        local queue=CreateButton(PageContent,"Review Queue",140,28) queue:SetPoint("TOPLEFT",PageContent,"TOPLEFT",160,-20) queue:SetScript("OnClick",function() Navigate("forever://codex/missing") end)
        if ForeverBrowser_CanReview225() then local export=CreateButton(PageContent,"Export Official Reviews",190,28) export:SetPoint("LEFT",queue,"RIGHT",10,0) export:SetScript("OnClick",function() ForeverBrowser_C200Copy(ForeverBrowser_ExportReviews225(),"Official Review Data") end) local corrections=CreateButton(PageContent,"Export Corrections",170,28) corrections:SetPoint("LEFT",export,"RIGHT",10,0) corrections:SetScript("OnClick",function() ForeverBrowser_C200Copy(ForeverBrowser_ExportCorrections225(),"Confirmed Corrections — Copy JSON") end) end
        return
    end
    local y=ForeverBrowser_C198Head("Review: "..kind.." "..id,"Review one field. Save your draft or copy a report.")
    field=field or "record"
    local key=kind..":"..id local recordSaved=s.corrections[key] or {}
    local saved=field=="record" and recordSaved or (recordSaved.fieldReviews or {})[field] or {}
    local official=ForeverBrowser_OfficialReview225(kind,id,field) local owner=ForeverBrowser_CanReview225()
    local record=CreateButton(PageContent,"View Record",130,28) record:SetPoint("TOPLEFT",PageContent,"TOPLEFT",160,-20)
    record:SetScript("OnClick",function() Navigate(kind=="dungeon" and "forever://codex/guide/"..id.."/1" or kind=="object" and "forever://codex/object/"..id.."/1" or "forever://"..kind.."/"..id) end)
    local buffers={observed=saved.observed or (field=="record" and saved.text) or "",proposed=saved.proposed or "",evidence=saved.evidence or "",reviewNotes=owner and (saved.reviewNotes or (type(official)=="table" and official.reviewNotes) or "") or (type(official)=="table" and official.reviewNotes or "")}
    local selected="observed" local tabs={} local statusButtons={} local editor
    local function capture() if editor and (selected~="reviewNotes" or owner) then buffers[selected]=editor:GetText() or "" end end
    local function save() capture() ForeverBrowser_SaveEvidence225(kind,id,field,buffers) end
    local fieldButton=CreateButton(PageContent,"Field: "..ForeverBrowser_ReviewFieldLabel225(field),240,28) fieldButton:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,y)
    local statusLabel=ForeverBrowser_AchievementLabel(PageContent,(owner and "Status: " or "Status (read-only): ")..ForeverBrowser_ReviewStatus225(kind,id,field),12,{1,.82,.28,1}) statusLabel:SetPoint("LEFT",fieldButton,"RIGHT",16,0)
    fieldButton:SetScript("OnClick",function()
        save() local fields={"record"} for _,f in ipairs(ForeverBrowser_ReviewFields225(kind)) do fields[#fields+1]=f end
        local nextField=fields[1] for i,f in ipairs(fields) do if f==field then nextField=fields[i%#fields+1] break end end
        Navigate("forever://codex/correct/"..kind.."/"..id.."/field/"..nextField)
    end)
    y=y-38
    if owner then
        local function refreshStatus()
            local _,current=ForeverBrowser_ReviewStatus225(kind,id,field)
            for _,entry in ipairs(statusButtons) do entry.button:SetText((entry.key==current and "["..entry.label.."]" or entry.label)) end
            statusLabel:SetText("Status: "..ForeverBrowser_ReviewStatus225(kind,id,field))
        end
        for i,spec in ipairs({{"investigate","Needs Investigation"},{"confirmed","Confirmed"},{"fixed","Fixed"},{"notApplicable","Not Applicable"}}) do
            local status,title=spec[1],spec[2]
            local button=CreateButton(PageContent,title,180,28) button:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25+(i-1)*190,y)
            statusButtons[#statusButtons+1]={button=button,key=status,label=title}
            button:SetScript("OnClick",function() if not ForeverBrowser_CanReview225() then return end save() ForeverBrowser_SetReview225(kind,id,status,nil,field) refreshStatus() end)
        end
        refreshStatus() y=y-38
    end
    local tabY=y
    local scroll=CreateFrame("ScrollFrame",nil,PageContent,"UIPanelScrollFrameTemplate") scroll:SetSize(760,170) scroll:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,tabY-38)
    CreateSolidBackground(scroll,.025,.022,.017,1)
    editor=CreateFrame("EditBox",nil,scroll) editor:SetSize(720,170) editor:SetMultiLine(true) editor:SetAutoFocus(false) editor:SetFontObject("ChatFontNormal") editor:SetTextInsets(12,12,10,10) scroll:SetScrollChild(editor)
    editor:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    editor:SetScript("OnTextChanged",function(self) local text=self:GetText() or "" local _,lines=text:gsub("\n","") self:SetHeight(math.max(170,(lines+math.ceil(#text/75)+2)*18)) end)
    local function showTab(tab)
        capture() selected=tab
        for _,entry in ipairs(tabs) do entry.button:SetText(entry.key==tab and "["..entry.label.."]" or entry.label) end
        editor:ClearFocus() editor:EnableMouse(tab~="reviewNotes" or owner) editor:EnableKeyboard(tab~="reviewNotes" or owner)
        editor:SetText(buffers[tab] or "") if scroll.SetVerticalScroll then scroll:SetVerticalScroll(0) end
    end
    for i,spec in ipairs({{"observed","Observation"},{"proposed","Correction"},{"evidence","Evidence"},{"reviewNotes","Review Notes"}}) do
        local tab,title=spec[1],spec[2]
        local button=CreateButton(PageContent,title,180,28) button:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25+(i-1)*190,tabY)
        tabs[#tabs+1]={button=button,key=tab,label=title}
        button:SetScript("OnClick",function() showTab(tab) end)
    end
    -- Populate without capturing the initially empty editor over the saved observation.
    selected=nil
    local initial=buffers.observed editor:SetText(initial) selected="observed"
    for _,entry in ipairs(tabs) do entry.button:SetText(entry.key==selected and "["..entry.label.."]" or entry.label) end
    y=tabY-226
    local b=CreateButton(PageContent,"Save Draft",150,28) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,y)
    b:SetScript("OnClick",function() save() Navigate("forever://codex/corrections") end)
    local copy=CreateButton(PageContent,"Copy Report",150,28) copy:SetPoint("LEFT",b,"RIGHT",10,0)
    copy:SetScript("OnClick",function() capture() ForeverBrowser_C200Copy(ForeverBrowser_IssueReport225(kind,id,nil,field,buffers),"Copy Database Issue Report") end)
    local remove=CreateButton(PageContent,"Clear Local Draft",160,28) remove:SetPoint("TOPLEFT",PageContent,"TOPLEFT",605,y)
    remove:SetScript("OnClick",function() local r=s.corrections[key] if r then
        if field=="record" then r.text="" r.observed=nil r.proposed=nil r.evidence=nil r.reviewNotes=nil r.status=nil
        elseif r.fieldReviews then r.fieldReviews[field]=nil end
    end Navigate("forever://codex/corrections") end)
    local hint=ForeverBrowser_AchievementLabel(PageContent,owner and "Status choices save the draft. Review Notes are public when exported." or "You can save and copy reports. Statuses and Review Notes are read-only.",11,{.87,.81,.67,1}) hint:SetPoint("TOPLEFT",b,"BOTTOMLEFT",0,-12) hint:SetWidth(730) hint:SetJustifyH("LEFT")
    PageContent:SetHeight(math.max(700,math.abs(y)+90))
end
function ForeverBrowser_C201History()
    local y=ForeverBrowser_C198Head("Navigation History","Recently viewed database records; stored locally, newest first. Back and Forward follow the current session history.")
    for i,label in ipairs({"Back","Forward"}) do local b=CreateButton(PageContent,label,100,28) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",300+(i-1)*110,-20)
        local target=HistoryPosition+(i==1 and -1 or 1)
        if target<1 or target>#History then b:Disable() else b:SetScript("OnClick",function() HistoryPosition=target Navigate(History[target],true) end) end
    end
    for _,r in ipairs(ForeverBrowser_C201State().history) do y=ForeverBrowser_C198Row(y,r.name,r.url,r.url) end
    local clear=CreateButton(PageContent,"Clear Recent",120,28) clear:SetPoint("TOPLEFT",PageContent,"TOPLEFT",160,-20) clear:SetScript("OnClick",function() ForeverBrowser_C201State().history={} ForeverBrowser_C201History() end)
end
function ForeverBrowser_S222()
    local s=ForeverBrowser_C201State().settings
    local defaults={startup="welcome",rememberFilters=true,models=true,rotateModels=false,modelZoom=0,showCollected=true,lootSort="NAME",wishlistFirst=false,openMap=true,backgroundRefresh=true,pageSize=12,simpleTooltips=false,richTooltips=true}
    for k,v in pairs(defaults) do if s[k]==nil then s[k]=v end end
    return s
end
function ForeverBrowser_S222Tooltip(itemID,item)
    if not ForeverBrowser_S222().richTooltips or not GameTooltip or type(GameTooltip.AddLine)~="function" then return end
    local source=type(item)=="table" and (item.dataSource or item.sourceDatabase)
    if source then GameTooltip:AddLine("Database source: "..tostring(source),.8,.75,.6,true) end
    GameTooltip:AddLine((IsForeverItemCollected(itemID) and "Collected" or "Not recorded as collected")..(IsForeverItemTracked(itemID) and " • On farming wishlist" or ""),.8,.75,.6,true)
end
function ForeverBrowser_S222Start()
    local s=ForeverBrowser_S222() local route=({welcome="forever://welcome",home="forever://home",items="forever://items",npcs="forever://npcdatabase",dungeons="forever://dungeons",last=s.lastPage})[s.startup]
    return type(route)=="string" and route:match("^forever://") and route or "forever://home"
end
function ForeverBrowser_S222Export(kind)
    local db=GetDatabase() local data=kind=="favorites" and db.favorites or kind=="lists" and db.customLists or kind=="wishlist" and db.farmingWishlist or {items=db.itemNotes,tags=db.itemTags,records=ForeverBrowser_C200State().notes}
    local seen={}
    local function encode(v,depth)
        if type(v)=="string" then return string.format("%q",v) elseif type(v)=="number" or type(v)=="boolean" then return tostring(v)
        elseif type(v)~="table" or depth>12 or seen[v] then return "nil" end
        seen[v]=true local fields={} for k,value in pairs(v) do if type(k)=="number" or type(k)=="string" then fields[#fields+1]="["..encode(k,depth+1).."]="..encode(value,depth+1) end end
        seen[v]=nil table.sort(fields) return "{"..table.concat(fields,",\n").."}"
    end
    return "-- ForeverBrowser personal "..kind.." export\nreturn "..encode(data or {},0)
end
function ForeverBrowser_S222Reset(kind,confirmed)
    if not confirmed then ForeverBrowserSettingsReset222=kind return false end
    if ForeverBrowserSettingsReset222~=kind then return false end
    local db=GetDatabase()
    if kind=="favorites" then db.favorites={}
    elseif kind=="lists" then db.customLists={}
    elseif kind=="wishlist" then db.farmingWishlist={}
    elseif kind=="notes" then db.itemNotes={} db.itemTags={} ForeverBrowser_C200State().notes={}
    elseif kind=="settings" then ForeverBrowser_C201State().settings={font=14,compact=false,scale=1,locked=false} db.browserSettings={}
    else return false end
    ForeverBrowserSettingsReset222=nil return true
end
function ForeverBrowser_U223Page()
    local y=ForeverBrowser_C198Head("Addon Updates","Check installed version information and find the latest ForeverBrowser release.")
    y=ForeverBrowser_C198Row(y,"Installed version",ForeverBrowserVersion)
    y=ForeverBrowser_C198Row(y,"Installed build",ForeverBrowserBuild225)
    y=ForeverBrowser_C198Row(y,"Latest release","Copy the CurseForge link, open it in your web browser, and compare the newest release with your installed version.",nil,function() ForeverBrowser_C200Copy(ForeverBrowserReleaseURL,"ForeverBrowser Releases") end,"Copy Link")
    y=ForeverBrowser_C198Row(y,"Update status","Not checked online. This in-game page cannot contact CurseForge; it does not automatically detect or download updates.")
    y=ForeverBrowser_C198Row(y,"Installing an update","Exit the game, replace the addon files with the downloaded release, then launch the game again. Keep your SavedVariables to retain your preferences and personal data.")
end

function ForeverBrowser_C201Settings(tab)
    tab=tab or "general" local tabs={"general","appearance","browsing","models","maps","performance","personal"}
    local valid=false for _,k in ipairs(tabs) do if k==tab then valid=true end end if not valid then tab="general" end
    local s=ForeverBrowser_S222() local y=ForeverBrowser_C198Head("Browser Settings","Choose a section. Preferences are saved for this account; personal data resets require a second confirmation click.")
    for i,k in ipairs(tabs) do local b=CreateButton(PageContent,k=="personal" and "Personal Data" or (k:sub(1,1):upper()..k:sub(2)),101,28) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25+(i-1)*112,y)
        if k==tab then b:Disable() else b:SetScript("OnClick",function() ForeverBrowserSettingsReset222=nil Navigate("forever://codex/options/"..k) end) end
    end y=y-48
    local function refresh() ForeverBrowser_C201Apply() ForeverBrowser_C201Settings(tab) end
    local function toggle(label,key,detail,native)
        local value=native and BrowserSettingEnabled(key) or (not native and s[key])
        y=ForeverBrowser_C198Row(y,label,(value and "Enabled" or "Disabled").." • "..detail,nil,function() if native then SetBrowserSetting(key,not value) else s[key]=not value end refresh() end,"Toggle")
    end
    local function cycle(label,key,values,detail)
        y=ForeverBrowser_C198Row(y,label,tostring(s[key]).." • "..detail,nil,function() local n=0 for i,v in ipairs(values) do if v==s[key] then n=i end end s[key]=values[n%#values+1] refresh() end,"Change")
    end
    local function reset(label,key)
        local pending=ForeverBrowserSettingsReset222==key
        y=ForeverBrowser_C198Row(y,label,pending and "Confirm permanently clearing this category. Export first if you want a backup." or "Only this category is cleared; other saved data is retained.",nil,function() ForeverBrowser_S222Reset(key,pending) refresh() end,pending and "Confirm Reset" or "Reset")
    end
    if tab=="general" then
        y=ForeverBrowser_C198Row(y,"Check for Updates",ForeverBrowserVersion.." • View release information and copy the CurseForge link","forever://codex/updates",nil,"Updates")
        cycle("Opening page","startup",{"welcome","home","items","npcs","dungeons","last"},"Used by /fb and the minimap button")
        toggle("Remember browsing filters","rememberFilters","Dungeon loot, boss loot, favorites and farming wishlist")
        toggle("Save recent searches","saveRecentSearches","Keep recent NPC and quest search history",true)
        y=ForeverBrowser_C198Row(y,"Reset window position","Return the browser to the center of the screen",nil,function() if BrowserFrame then BrowserFrame:ClearAllPoints() BrowserFrame:SetPoint("CENTER",UIParent,"CENTER",0,0) end end,"Center Window")
        reset("Reset browser preferences","settings")
    elseif tab=="appearance" then
        local font=ForeverBrowser_C200Input(PageContent,25,y,100,tostring(s.font or 14)) local scale=ForeverBrowser_C200Input(PageContent,150,y,100,tostring(s.scale or 1))
        local apply=CreateButton(PageContent,"Apply Values",135,28) apply:SetPoint("TOPLEFT",PageContent,"TOPLEFT",265,y)
        apply:SetScript("OnClick",function() local f,n=tonumber(font:GetText()),tonumber(scale:GetText()) if f and n then s.font=math.max(11,math.min(20,math.floor(f))) s.scale=math.max(.65,math.min(1.35,n)) refresh() end end)
        y=ForeverBrowser_C198Row(y-40,"Font size / window scale","Codex list font: 11–20 • browser scale: 0.65–1.35")
        toggle("Compact Codex rows","compact","Use shorter list rows") toggle("Lock tracker position","locked","Prevent dragging the Codex Goals tracker")
        y=ForeverBrowser_C198Row(y,"Theme",ForeverBrowserTheme.GetName(),nil,function() local names={} for k in pairs(FOREVER_THEMES) do names[#names+1]=k end table.sort(names) local n=0 for i,k in ipairs(names) do if k==ForeverBrowserTheme.GetName() then n=i end end ForeverBrowserTheme.Apply(names[n%#names+1],ForeverBrowserRefreshThemeButton222,refresh) end,"Change Theme")
    elseif tab=="browsing" then
        toggle("Item tooltips","showItemTooltips","Display item hover information",true)
        toggle("Simple item tooltips","simpleTooltips","Use database metadata instead of native item tooltips")
        toggle("Database tooltip details","richTooltips","Append recorded source and personal collection status")
        toggle("Show collected dungeon loot","showCollected","Default collection filter when opening a dungeon")
        cycle("Default dungeon loot sort","lootSort",{"NAME","CHANCE"},"Name or recorded drop chance")
        toggle("Wishlist items first","wishlistFirst","Prioritize tracked items in dungeon and boss loot")
    elseif tab=="models" then
        toggle("Inline item 3D previews","models","Supported items use 3D; unsupported items keep their icons")
        toggle("Automatic item rotation","rotateModels","Rotate verified item previews while visible")
        cycle("Default item zoom","modelZoom",{0,.3,.6,-.3,-.6},"Applied when opening or resetting a preview")
    elseif tab=="maps" then
        toggle("Map markers","enableMapMarkers","Allow database map buttons to place markers",true)
        toggle("Open map on location click","openMap","Disable to place the marker without opening the map")
    elseif tab=="performance" then
        cycle("Codex list page size","pageSize",{8,12,20},"Applies to standard Codex list pages")
        toggle("Background journal refresh","backgroundRefresh","Refresh discovery timeline and character snapshots every two minutes")
        y=ForeverBrowser_C198Row(y,"Refresh journal now","Scan currently available records once",nil,function() ForeverBrowser_C200TimelineScan() ForeverBrowser_C201Snapshot() refresh() end,"Refresh Now")
    elseif tab=="personal" then
        for _,k in ipairs({"favorites","lists","notes","wishlist"}) do
            y=ForeverBrowser_C198Row(y,"Export "..k,"Copy a Lua text backup of this personal category",nil,function() ForeverBrowser_C200Copy(ForeverBrowser_S222Export(k),"Personal "..k.." Export") end,"Export")
            reset("Reset "..k,k)
        end
    end
    if ForeverBrowserSettingsReset222 then y=ForeverBrowser_C198Row(y,"Cancel pending reset","Keep all saved data",nil,function() ForeverBrowserSettingsReset222=nil refresh() end,"Cancel Reset") end
    PageContent:SetHeight(math.max(750,math.abs(y)+80))
end
function ForeverBrowser_C201Apply()
    local s=ForeverBrowser_C201State().settings if BrowserFrame then BrowserFrame:SetScale(s.scale or 1) end
    if ForeverBrowserCodexTracker200 then ForeverBrowserCodexTracker200:SetMovable(not s.locked) end
end
function ForeverBrowser_C201Record(url)
    local kind,id=url:match("^forever://(%a+)/(.*)$")
    if not ({item=true,npc=true,quest=true,recipe=true,dungeon=true})[kind] then return end
    local history=ForeverBrowser_C201State().history for i=#history,1,-1 do if history[i].url==url then table.remove(history,i) end end
    local fn=({item=GetAnyItem,npc=FindNPCSourceData,quest=FindQuestSourceData,recipe=GetRecipeData})[kind]
    local r=fn and fn(tonumber(id) or id)
    table.insert(history,1,{url=url,name=type(r)=="table" and (r.name or r.title) or kind.." "..id}) while #history>50 do table.remove(history) end
end
function ForeverBrowser_MissingData225(category,gap)
    local source=ForeverSourceData or {}
    local cache=ForeverBrowserMissingCache225
    if not cache or cache.source~=source then
        cache={source=source,rows={}} ForeverBrowserMissingCache225=cache
        local function present(v) return v~=nil and v~="" end
        local function coords(r)
            if type(r)~="table" then return false end
            local m,x,y=tonumber(r.uiMapID or r.mapID),tonumber(r.x),tonumber(r.y)
            return m and m>0 and x and y and x==x and y==y and x>=0 and x<=100 and y>=0 and y<=100
        end
        local function located(r,kind,id)
            if coords(r) then return true end
            for _,field in ipairs({"locations","giverLocations","entranceLocations"}) do
                for _,v in pairs(type(r[field])=="table" and r[field] or {}) do if coords(v) then return true end end
            end
            if kind=="npc" then
                local t=(source.npcLocations or {})[tonumber(id) or id] or (source.npcLocations or {})[tostring(id)]
                if coords(t) then return true end
                for _,v in pairs(type(t)=="table" and t or {}) do if coords(v) then return true end end
            end
            return false
        end
        for kind,bucket in pairs({item="items",npc="npcs",quest="quests",recipe="recipes",object="objects",dungeon="dungeons"}) do
            for key,r in pairs(source[bucket] or {}) do if type(r)=="table" then
                local id=tostring(kind=="dungeon" and (r.name or key) or (r.id or r.spellID or key))
                local flags={} local labels={}
                local function add(flag,label) flags[flag]=true labels[#labels+1]=label end
                if not present(r.dataSource) and not present(r.sourceDatabase) and not present(r.enrichmentSource) then add("provenance","Per-record provenance") end
                if kind=="item" then
                    if type(r.sources)~="table" or next(r.sources)==nil then add("sources","Acquisition sources") end
                    for _,v in pairs(type(r.sources)=="table" and r.sources or {}) do
                        if type(v)=="table" and v.type=="drop" and v.chance==nil and v.dropChance==nil then add("rates","Recorded drop chance") break end
                    end
                end
                if (kind=="npc" or kind=="object" or kind=="quest" or kind=="dungeon") and not located(r,kind,id) then add("locations","Primary/indexed coordinates") end
                if kind=="recipe" and r.requiredSkill==nil and r.minSkill==nil and r.skillRequired==nil then add("requirements","Required profession skill") end
                if kind=="quest" and r.minLevel==nil and r.requiredLevel==nil then add("requirements","Minimum quest level") end
                if kind=="dungeon" and not present(r.requirements) and not present(r.attunement) then add("requirements","Entry requirements / attunement") end
                if #labels>0 then
                    local url=kind=="dungeon" and "forever://codex/guide/"..id.."/1" or kind=="object" and "forever://codex/object/"..id.."/1" or "forever://"..kind.."/"..id
                    cache.rows[#cache.rows+1]={kind=kind,id=id,flags=flags,name=r.name or (kind.." "..id),detail=kind.." #"..id.." • Not recorded: "..table.concat(labels,", "),url=url}
                end
            end end
        end
        table.sort(cache.rows,function(a,b) if tostring(a.name)==tostring(b.name) then return a.kind..a.id<b.kind..b.id end return tostring(a.name)<tostring(b.name) end)
    end
    local rows={}
    for _,r in ipairs(cache.rows) do if (category=="all" or r.kind==category) and (gap=="any" or r.flags[gap]) then rows[#rows+1]=r end end
    return rows
end
function ForeverBrowser_FilterReviews225(entries,status,query,gap)
    local result={} local needle=tostring(query or ""):lower():match("^%s*(.-)%s*$")
    for _,r in ipairs(entries) do
        if needle=="" or tostring(r.id)==needle or string.find(tostring(r.name):lower(),needle,1,true) then
            for _,field in ipairs(ForeverBrowser_ReviewFields225(r.kind)) do if (r.flags or {})[field] and (not gap or gap=="any" or field==gap) then
                local label,key=ForeverBrowser_ReviewStatus225(r.kind,r.id,field)
                if status=="all" or status==key or (status=="unresolved" and key~="fixed" and key~="notApplicable") then result[#result+1]={record=r,statusLabel=label,field=field} end
            end end
        end
    end return result
end
function ForeverBrowser_MissingPage225(category,gap,page)
    category=category or "all" gap=gap or "any"
    local categories={"all","item","npc","quest","recipe","object","dungeon"}
    local gaps={"any","locations","sources","rates","requirements","provenance"}
    local labels={any="Any gap",locations="Coordinates",sources="Acquisition sources",rates="Drop rates",requirements="Requirements",provenance="Data provenance"}
    ForeverBrowserReviewFilters225=ForeverBrowserReviewFilters225 or {status="unresolved",query=""}
    local prefs=ForeverBrowserReviewFilters225
    local rows={}
    for _,match in ipairs(ForeverBrowser_FilterReviews225(ForeverBrowser_MissingData225(category,gap),prefs.status,prefs.query,gap)) do
        local r=match.record local kind,id,field=r.kind,r.id,match.field
        rows[#rows+1]={name="[Review] "..r.name.." — "..ForeverBrowser_ReviewFieldLabel225(field),detail=kind.." #"..id.." • Field status: "..match.statusLabel,url="forever://codex/correct/"..kind.."/"..id.."/field/"..field,actionText="Review",action=function() Navigate("forever://codex/correct/"..kind.."/"..id.."/field/"..field) end}
    end
    ForeverBrowser_C201List("Missing Data — Review Queue","Search and filter, then open a field to review. Missing information does not mean the content is absent.",rows,page,"forever://codex/missing/"..category.."/"..gap.."/",function(y)
        local search=ForeverBrowser_C200Input(PageContent,25,y,330,prefs.query)
        local apply=CreateButton(PageContent,"Search Name / ID",140,28) apply:SetPoint("LEFT",search,"RIGHT",10,0)
        local function submit() prefs.query=(search:GetText() or ""):sub(1,128) search:ClearFocus() Navigate("forever://codex/missing/"..category.."/"..gap.."/1") end
        apply:SetScript("OnClick",submit) search:SetScript("OnEnterPressed",submit)
        local statusLabels={all="All Statuses",unresolved="Unresolved Only",investigate="Needs Investigation",confirmed="Confirmed",fixed="Fixed",notApplicable="Not Applicable"}
        local status=CreateButton(PageContent,statusLabels[prefs.status] or "All Statuses",210,28) status:SetPoint("LEFT",apply,"RIGHT",10,0)
        status:SetScript("OnClick",function()
            prefs.query=(search:GetText() or ""):sub(1,128)
            prefs.status=({unresolved="investigate",investigate="confirmed",confirmed="fixed",fixed="notApplicable",notApplicable="all",all="unresolved"})[prefs.status] or "unresolved"
            Navigate("forever://codex/missing/"..category.."/"..gap.."/1")
        end)
        local clear=CreateButton(PageContent,"Clear Search",120,26) clear:SetPoint("TOPLEFT",search,"BOTTOMLEFT",0,-8)
        clear:SetScript("OnClick",function() prefs.query="" Navigate("forever://codex/missing/"..category.."/"..gap.."/1") end)
        return y-82
    end,"field gaps")
    local function cycle(values,value) for i,v in ipairs(values) do if v==value then return values[i%#values+1] end end return values[1] end
    local cat=CreateButton(PageContent,"Category: "..category,165,28) cat:SetPoint("TOPLEFT",PageContent,"TOPLEFT",160,-20)
    cat:SetScript("OnClick",function() Navigate("forever://codex/missing/"..cycle(categories,category).."/"..gap.."/1") end)
    local filter=CreateButton(PageContent,labels[gap] or "Any gap",170,28) filter:SetPoint("LEFT",cat,"RIGHT",8,0)
    filter:SetScript("OnClick",function() Navigate("forever://codex/missing/"..category.."/"..cycle(gaps,gap).."/1") end)
    local refresh=CreateButton(PageContent,"Refresh Data",110,28) refresh:SetPoint("LEFT",filter,"RIGHT",8,0)
    refresh:SetScript("OnClick",function() ForeverBrowserMissingCache225=nil Navigate("forever://codex/missing/"..category.."/"..gap.."/1") end)
end
function ForeverBrowser_C201Route(route)
    if route=="missing" then ForeverBrowser_MissingPage225()
    elseif route:match("^missing/") then local c,g,p=route:match("^missing/(%a+)/(%a+)/(%d+)$") if c then ForeverBrowser_MissingPage225(c,g,p) end
    elseif route=="here" or route:match("^here/%d+$") then ForeverBrowser_C201Here(route:match("(%d+)$"))
    elseif route=="compare" or route:match("^compare/%d+$") then ForeverBrowser_C201Compare(route:match("(%d+)$"))
    elseif route=="raw" then ForeverBrowser_C201Materials()
    elseif route:match("^raw/%d+/%d+$") then local id,q=route:match("^raw/(%d+)/(%d+)$") ForeverBrowser_C201Materials(tonumber(id),tonumber(q))
    elseif route=="chain-map" then ForeverBrowser_C201Chain()
    elseif route:match("^chain%-map/%d+$") then ForeverBrowser_C201Chain(tonumber(route:match("(%d+)$")))
    elseif route=="prep" then ForeverBrowser_C201Prep()
    elseif route:match("^prep/") then local name,p=route:match("^prep/(.*)/(%d+)$") if name then ForeverBrowser_C201Prep(name,p) end
    elseif route=="shelves" then ForeverBrowser_C201Shelf()
    elseif route:match("^shelf/") then local kind,p=route:match("^shelf/(%a+)/(%d+)$") if kind then ForeverBrowser_C201Shelf(kind,p) end
    elseif route:match("^related/") then local kind,id,p=route:match("^related/(%a+)/(.*)/(%d+)$") if kind then ForeverBrowser_C201Related(kind,id,p)
        local b=CreateButton(PageContent,"Flag Data",100,28) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",310,-20) b:SetScript("OnClick",function() Navigate("forever://codex/correct/"..kind.."/"..id) end) end
    elseif route=="corrections" or route:match("^corrections/%d+$") then ForeverBrowser_C201Corrections(nil,nil,nil,route:match("(%d+)$"))
    elseif route:match("^correct/") then local kind,id,field=route:match("^correct/(%a+)/(.*)/field/(%a+)$") if not kind then kind,id=route:match("^correct/(%a+)/(.*)$") end if kind then ForeverBrowser_C201Corrections(kind,id,field) end
    elseif route=="history" then ForeverBrowser_C201History()
    elseif route=="updates" then ForeverBrowser_U223Page()
    elseif route=="options" then ForeverBrowser_C201Settings()
    elseif route:match("^options/%a+$") then ForeverBrowser_C201Settings(route:match("^options/(%a+)$"))
    else return false end return true
end

-- Personal collections and notebook retain existing saved-variable tables.
function ForeverBrowser_L206Tags(text)
    local seen,tags={},{}
    for tag in tostring(text or ""):gmatch("[^,;\n]+") do tag=tag:match("^%s*(.-)%s*$") local key=string.lower(tag)
        if tag~="" and not seen[key] then seen[key]=true tags[#tags+1]=tag end
    end
    return table.concat(tags,", ")
end
function ForeverBrowser_L206Header(title,description)
    local y=ForeverBrowser_C198Head(title,description)
    local back=CreateButton(PageContent,"Item Database",120,28) back:SetPoint("TOPLEFT",PageContent,"TOPLEFT",160,-20) back:SetScript("OnClick",function() Navigate("forever://items") end)
    return y
end
function ForeverBrowser_L206Items(list)
    local ids,seen={},{} for key,value in pairs(list.items or {}) do local id=tonumber(key) if id and value and not seen[id] then seen[id]=true ids[#ids+1]=id end end
    table.sort(ids,function(a,b) local an,bn=string.lower(GetItemName(a)),string.lower(GetItemName(b)) if an==bn then return a<b end return an<bn end) return ids
end
function ForeverBrowser_L206Home(query)
    local y=ForeverBrowser_L206Header("My Lists","Personal item collections • open a list to manage its items, export it or track collection progress.")
    query=query or "" local search=ForeverBrowser_C200Input(PageContent,25,y,365,query)
    local find=CreateButton(PageContent,"Find Lists",110,28) find:SetPoint("LEFT",search,"RIGHT",8,0)
    local function run() ForeverBrowser_L206Home(search:GetText()) end find:SetScript("OnClick",run) search:SetScript("OnEnterPressed",run)
    y=y-48
    local name=ForeverBrowser_C200Input(PageContent,25,y,365,"") local create=CreateButton(PageContent,"Create List",110,28) create:SetPoint("LEFT",name,"RIGHT",8,0)
    local status=ForeverBrowser_AchievementLabel(PageContent,"Enter a new list name",11,{.87,.81,.67,1}) status:SetPoint("LEFT",create,"RIGHT",12,0)
    local function add() local value=(name:GetText() or ""):match("^%s*(.-)%s*$")
        if value=="" then status:SetText("Enter a name first.") elseif GetCustomLists()[value] then status:SetText("That list already exists.") else CreateCustomList(value) Navigate("forever://list/"..value) end
    end create:SetScript("OnClick",add) name:SetScript("OnEnterPressed",add)
    y=y-48 local state=ForeverBrowser_C200State()
    if state.deletedList206 then local deleted=state.deletedList206
        y=ForeverBrowser_C198Row(y,"Recently deleted: "..deleted.name,"Restore is available until another list is deleted.",nil,function()
            if GetCustomLists()[deleted.name] then status:SetText("Rename the existing list before restoring.") else GetCustomLists()[deleted.name]=deleted.list state.deletedList206=nil ForeverBrowser_L206Home(query) end
        end,"Restore List")
    end
    local names={} for value in pairs(GetCustomLists()) do if string.find(string.lower(value),string.lower(query),1,true) then names[#names+1]=value end end table.sort(names)
    if #names==0 then y=ForeverBrowser_C198Row(y,"No matching lists","Create a list above, or clear your search.") end
    for _,value in ipairs(names) do local ids=ForeverBrowser_L206Items(GetCustomLists()[value]) local collected=0 for _,id in ipairs(ids) do if IsForeverItemCollected(id) then collected=collected+1 end end
        y=ForeverBrowser_C198Row(y,value,#ids.." items • "..collected.." collected • "..(#ids-collected).." missing","forever://list/"..value)
    end
end
function ForeverBrowser_L206List(name,query,mode,page,addItem)
    local list=GetCustomLists()[name] local y=ForeverBrowser_L206Header(name,"Personal collection • obtained status uses the account collection, not current bag ownership.")
    if not list then ForeverBrowser_C198Row(y,"List unavailable","It may have been renamed or removed.","forever://lists") return end
    query=query or "" mode=mode or "all" page=tonumber(page) or 1
    local back=CreateButton(PageContent,"My Lists",100,28) back:SetPoint("TOPLEFT",PageContent,"TOPLEFT",290,-20) back:SetScript("OnClick",function() Navigate("forever://lists") end)
    local search=ForeverBrowser_C200Input(PageContent,25,y,320,query) local rename=ForeverBrowser_C200Input(PageContent,470,y,225,name)
    local find=CreateButton(PageContent,"Filter Items",110,28) find:SetPoint("LEFT",search,"RIGHT",8,0)
    local function run() ForeverBrowser_L206List(name,search:GetText(),mode,1) end find:SetScript("OnClick",run) search:SetScript("OnEnterPressed",run)
    local ren=CreateButton(PageContent,"Rename",90,28) ren:SetPoint("LEFT",rename,"RIGHT",8,0)
    y=y-44 local feedback=ForeverBrowser_AchievementLabel(PageContent,"Search by item name, ID or saved tags.",11,{.87,.81,.67,1}) feedback:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,y)
    ren:SetScript("OnClick",function() local value=rename:GetText() if RenameCustomList(name,value) then Navigate("forever://list/"..value:match("^%s*(.-)%s*$")) else feedback:SetText("Choose a different, unused list name.") end end)
    y=y-32
    local input=ForeverBrowser_C200Input(PageContent,25,y,190,addItem and tostring(addItem) or "") local add=CreateButton(PageContent,"Add Item ID",120,28) add:SetPoint("LEFT",input,"RIGHT",8,0)
    local function insert() local id=tonumber(input:GetText()) if not id or id<=0 or id~=math.floor(id) or not GetAnyItem(id) then feedback:SetText("Enter an item ID present in the database.") return end list.items=list.items or {} list.items[id]=true list.items[tostring(id)]=nil ForeverBrowser_L206List(name,query,mode,page) end add:SetScript("OnClick",insert) input:SetScript("OnEnterPressed",insert)
    for i,k in ipairs({"all","missing","collected"}) do local b=CreateButton(PageContent,k==mode and "["..k.."]" or k,100,28) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",370+(i-1)*112,y) b:SetScript("OnClick",function() ForeverBrowser_L206List(name,query,k,1) end) end
    y=y-44 local ids=ForeverBrowser_L206Items(list) local matches={} local collected=0
    for _,id in ipairs(ids) do local got=IsForeverItemCollected(id) if got then collected=collected+1 end
        if (mode=="all" or mode=="collected" and got or mode=="missing" and not got) and (query=="" or tostring(id)==query or string.find(string.lower(GetItemName(id).." "..GetSavedItemTags(id)),string.lower(query),1,true)) then matches[#matches+1]=id end
    end
    y=ForeverBrowser_C198Row(y,"Collection Progress",collected.." / "..#ids.." collected • "..#matches.." shown",nil,function()
        local goal={} for _,id in ipairs(ids) do goal[id]=true end ForeverBrowser_C198SaveGoal(name,goal,"My Lists snapshot") Navigate("forever://codex/goals")
    end,"Track Collection")
    local pages=math.max(1,math.ceil(#matches/12)) page=math.max(1,math.min(page,pages))
    for i=(page-1)*12+1,math.min(page*12,#matches) do local id=matches[i]
        y=ForeverBrowser_C198Row(y,GetItemName(id),(IsForeverItemCollected(id) and "Collected" or "Missing").." • ID "..id.." • "..GetSavedItemTags(id),"forever://item/"..id,function() list.items[id]=nil list.items[tostring(id)]=nil ForeverBrowser_L206List(name,query,mode,page) end,"Remove Item")
    end
    if #matches==0 then y=ForeverBrowser_C198Row(y,"No matching items","Add an item ID above, or change your filters.") end
    for i,label in ipairs({"Previous","Next"}) do local b=CreateButton(PageContent,label,100,28) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25+(i-1)*112,y)
        if (i==1 and page==1) or (i==2 and page==pages) then b:Disable() else b:SetScript("OnClick",function() ForeverBrowser_L206List(name,query,mode,page+(i==1 and -1 or 1)) end) end
    end
    local export=CreateButton(PageContent,"Export List",110,28) export:SetPoint("TOPLEFT",PageContent,"TOPLEFT",260,y) export:SetScript("OnClick",function() local lines={name} for _,id in ipairs(ids) do lines[#lines+1]=GetItemName(id).." ["..id.."] • "..(IsForeverItemCollected(id) and "collected" or "missing") end ForeverBrowser_C200Copy(table.concat(lines,"\n"),"Export My List") end)
    local delete=CreateButton(PageContent,"Delete List",110,28) delete:SetPoint("TOPLEFT",PageContent,"TOPLEFT",390,y) local armed=false
    delete:SetScript("OnClick",function() if not armed then armed=true delete.text:SetText("Confirm Delete") feedback:SetText("Click Confirm Delete to remove this list. Restore is available on My Lists.") else ForeverBrowser_C200State().deletedList206={name=name,list=list} DeleteCustomList(name) Navigate("forever://lists") end end)
    PageContent:SetHeight(math.max(900,math.abs(y)+100))
end
function ForeverBrowser_L206Add(id)
    local y=ForeverBrowser_L206Header("Add to My Lists",GetItemName(id).." • choose the lists that should contain this item.")
    local input=ForeverBrowser_C200Input(PageContent,25,y,350,"") local b=CreateButton(PageContent,"Create & Add",130,28) b:SetPoint("LEFT",input,"RIGHT",8,0)
    b:SetScript("OnClick",function() local name=(input:GetText() or ""):match("^%s*(.-)%s*$") if name~="" then CreateCustomList(name) local list=GetCustomLists()[name] list.items[id]=true list.items[tostring(id)]=nil ForeverBrowser_L206Add(id) end end)
    y=y-45 local names={} for name in pairs(GetCustomLists()) do names[#names+1]=name end table.sort(names)
    for _,name in ipairs(names) do local included=IsItemInCustomList(name,id)
        y=ForeverBrowser_C198Row(y,name,included and "Included" or "Not included","forever://list/"..name,function() local list=GetCustomLists()[name] list.items=list.items or {} if included then list.items[id]=nil list.items[tostring(id)]=nil else list.items[id]=true list.items[tostring(id)]=nil end ForeverBrowser_L206Add(id) end,included and "Remove" or "Add")
    end
end
function ForeverBrowser_L206Notebook(query,mode,page)
    query=query or "" mode=mode or "all" page=tonumber(page) or 1
    local y=ForeverBrowser_L206Header("Tags & Notes","Your item notebook • search item names, IDs, tags and note text. Open Edit Notes to change a record.")
    local box=ForeverBrowser_C200Input(PageContent,25,y,360,query) local find=CreateButton(PageContent,"Search Notebook",145,28) find:SetPoint("LEFT",box,"RIGHT",8,0)
    local function run() ForeverBrowser_L206Notebook(box:GetText(),mode,1) end find:SetScript("OnClick",run) box:SetScript("OnEnterPressed",run)
    for i,k in ipairs({"all","tags","notes"}) do local b=CreateButton(PageContent,k==mode and "["..k.."]" or k,80,28) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",555+(i-1)*88,y) b:SetScript("OnClick",function() ForeverBrowser_L206Notebook(query,k,1) end) end
    y=y-44 local seen,entries={},{}
    for _,bucket in ipairs({GetItemTags(),GetItemNotes()}) do for key in pairs(bucket) do local id=tonumber(key) if id then seen[id]=true end end end
    for id in pairs(seen) do local tags,note=GetSavedItemTags(id),GetSavedItemNote(id)
        if (tags~="" or note~="") and (mode=="all" or mode=="tags" and tags~="" or mode=="notes" and note~="") and (query=="" or tostring(id)==query or string.find(string.lower(GetItemName(id).." "..tags.." "..note),string.lower(query),1,true)) then entries[#entries+1]={id=id,name=GetItemName(id),tags=tags,note=note} end
    end
    table.sort(entries,function(a,b) if a.name==b.name then return a.id<b.id end return a.name<b.name end)
    local pages=math.max(1,math.ceil(#entries/12)) page=math.max(1,math.min(page,pages))
    y=ForeverBrowser_C198Row(y,#entries.." notebook entries","Page "..page.." / "..pages.." • tags are comma-separated")
    for i=(page-1)*12+1,math.min(page*12,#entries) do local r=entries[i] local detail=(r.tags~="" and "Tags: "..r.tags or "No tags").." • "..r.note:gsub("[\r\n]+"," ")
        y=ForeverBrowser_C198Row(y,r.name,detail,"forever://item/"..r.id,function() Navigate("forever://codex/notes/item/"..r.id) end,"Edit Notes")
    end
    if #entries==0 then y=ForeverBrowser_C198Row(y,"No matching notes or tags","Add notes from an item detail page, or clear the search.") end
    for i,label in ipairs({"Previous","Next"}) do local b=CreateButton(PageContent,label,110,28) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25+(i-1)*130,y) if (i==1 and page==1) or (i==2 and page==pages) then b:Disable() else b:SetScript("OnClick",function() ForeverBrowser_L206Notebook(query,mode,page+(i==1 and -1 or 1)) end) end end
end
function ForeverBrowser_L206Route(url)
    if url=="forever://lists" then ForeverBrowser_L206Home()
    elseif url=="forever://tags" then ForeverBrowser_L206Notebook()
    elseif url:match("^forever://lists/add/%d+$") then ForeverBrowser_L206Add(tonumber(url:match("(%d+)$")))
    elseif url:match("^forever://list/") then ForeverBrowser_L206List(url:sub(16))
    else return false end return true
end

function ForeverBrowser_F207Data(query,mode,sort)
    local rows,seen={},{} local total,collected=0,0 query=string.lower(query or "")
    for key,value in pairs(GetFavorites()) do local id=tonumber(key)
        if value and id and not seen[id] then
            seen[id]=true total=total+1 local got=IsForeverItemCollected(id) if got then collected=collected+1 end
            local item=GetAnyItem(id) or {} local name=GetItemName(id) local tags=GetSavedItemTags(id)
            if (mode=="all" or mode==nil or mode=="collected" and got or mode=="missing" and not got) and (query=="" or tostring(id)==query or string.find(string.lower(name.." "..tags),query,1,true)) then
                rows[#rows+1]={id=id,name=name,tags=tags,collected=got,quality=tonumber(item.quality or item.Quality or item.overallQualityID),level=tonumber(item.itemLevel or item.ItemLevel or item.ilevel)}
            end
        end
    end
    table.sort(rows,function(a,b)
        if sort=="rarity" and (a.quality or -1)~=(b.quality or -1) then return (a.quality or -1)>(b.quality or -1) end
        if sort=="level" and (a.level or -1)~=(b.level or -1) then return (a.level or -1)>(b.level or -1) end
        if sort=="id" then return a.id<b.id end
        if string.lower(a.name)==string.lower(b.name) then return a.id<b.id end return string.lower(a.name)<string.lower(b.name)
    end)
    return rows,total,collected
end
function ForeverBrowser_F207Page(query,mode,sort,page)
    local settings=ForeverBrowser_S222() local saved=settings.rememberFilters and settings.favoriteFilters
    if query==nil and saved then query=saved.query mode=saved.mode sort=saved.sort end
    if settings.rememberFilters then settings.favoriteFilters={query=query or "",mode=mode or "all",sort=sort or "name"} end
    query=query or "" mode=mode or "all" sort=sort or "name" page=tonumber(page) or 1
    local rows,total,collected=ForeverBrowser_F207Data(query,mode,sort)
    local hero=ForeverBrowser_CodexHome191("Favorite Items","Your saved items • search names, IDs or tags and organize your next collection goals.","Interface\\COMMON\\ReputationStar",query,"Find Favorites",function(q) ForeverBrowser_F207Page(q,mode,sort,1) end,
        {{total,"Favorites"},{collected,"Collected"},{total-collected,"Missing"},{#rows,"Shown"}},"Your Favorite Collection")
    ForeverBrowser_C209ReserveNavigation(hero)
    local back=CreateButton(PageContent,"Item Database",120,26) back:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,-12) back:SetScript("OnClick",function() Navigate("forever://items") end)
    for i,k in ipairs({"all","missing","collected"}) do local b=CreateButton(PageContent,k==mode and "["..k.."]" or k,105,26) b:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",(i-1)*115,-125) b:SetScript("OnClick",function() ForeverBrowser_F207Page(query,k,sort,1) end) end
    local sorts={"name","rarity","level","id"} local order=CreateButton(PageContent,"Sort: "..sort,130,26) order:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",360,-125)
    order:SetScript("OnClick",function() local index=1 for i,k in ipairs(sorts) do if k==sort then index=i end end ForeverBrowser_F207Page(query,mode,sorts[index%#sorts+1],1) end)
    local reset=CreateButton(PageContent,"Reset Filters",115,26) reset:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",505,-125) reset:SetScript("OnClick",function() ForeverBrowser_F207Page("","all","name",1) end)
    local y=-445 local state=ForeverBrowser_C200State()
    if state.removedFavorite207 then local id=state.removedFavorite207
        y=ForeverBrowser_C198Row(y,"Removed: "..GetItemName(id),"Restore the most recently removed favorite.",nil,function() SetFavorite(id,true) state.removedFavorite207=nil ForeverBrowser_F207Page(query,mode,sort,page) end,"Undo Removal")
    end
    local pages=math.max(1,math.ceil(#rows/10)) page=math.max(1,math.min(page,pages))
    if #rows==0 then y=ForeverBrowser_C198Row(y,total==0 and "No favorites yet" or "No matching favorites",total==0 and "Open any item and click Favorite to save it here." or "Change your search or collection filter.","forever://items") end
    local qualities={[0]="Poor",[1]="Common",[2]="Uncommon",[3]="Rare",[4]="Epic",[5]="Legendary",[6]="Artifact"}
    for i=(page-1)*10+1,math.min(page*10,#rows) do local r=rows[i]
        local row=CreateFrame("Button",nil,PageContent) row:SetSize(790,72) row:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,y) CreateSolidBackground(row,.045,.038,.029,1)
        local icon=row:CreateTexture(nil,"ARTWORK") icon:SetSize(46,46) icon:SetPoint("LEFT",row,"LEFT",12,0) icon:SetTexture(GetItemIcon(r.id,GetAnyItem(r.id)))
        local title=ForeverBrowser_AchievementLabel(row,r.name,14,{1,.82,.28,1}) title:SetPoint("TOPLEFT",row,"TOPLEFT",72,-12) title:SetWidth(485) title:SetHeight(20) title:SetJustifyH("LEFT")
        local detail=(r.collected and "Collected" or "Missing").." • "..(qualities[r.quality] or "rarity unknown").." • level "..tostring(r.level or "unknown").." • ID "..r.id
        local info=ForeverBrowser_AchievementLabel(row,detail,10,{.87,.81,.67,1}) info:SetPoint("TOPLEFT",row,"TOPLEFT",72,-36) info:SetWidth(485) info:SetHeight(16) info:SetJustifyH("LEFT")
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight") row:SetScript("OnClick",function() if IsShiftLinkClick() then LinkItemToChat(r.id) else Navigate("forever://item/"..r.id) end end)
        row:SetScript("OnEnter",function(self) ShowItemTooltip(r.id,self) end) row:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
        local lists=CreateButton(row,"My Lists",90,25) lists:SetPoint("TOPRIGHT",row,"TOPRIGHT",-12,-9) lists:SetScript("OnClick",function() Navigate("forever://lists/add/"..r.id) end)
        local remove=CreateButton(row,"Unfavorite",90,25) remove:SetPoint("BOTTOMRIGHT",row,"BOTTOMRIGHT",-12,9) remove:SetScript("OnClick",function() SetFavorite(r.id,false) state.removedFavorite207=r.id ForeverBrowser_F207Page(query,mode,sort,page) end)
        y=y-80
    end
    for i,label in ipairs({"Previous","Next"}) do local b=CreateButton(PageContent,label,100,28) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25+(i-1)*112,y) if (i==1 and page==1) or (i==2 and page==pages) then b:Disable() else b:SetScript("OnClick",function() ForeverBrowser_F207Page(query,mode,sort,page+(i==1 and -1 or 1)) end) end end
    local count=ForeverBrowser_AchievementLabel(PageContent,"Page "..page.." / "..pages,11,{.87,.81,.67,1}) count:SetPoint("TOPLEFT",PageContent,"TOPLEFT",265,y-8)
    local export=CreateButton(PageContent,"Export Shown",125,28) export:SetPoint("TOPLEFT",PageContent,"TOPLEFT",420,y) export:SetScript("OnClick",function() local text={"Favorite Items • current filters"} for _,r in ipairs(rows) do text[#text+1]=r.name.." ["..r.id.."] • "..(r.collected and "collected" or "missing") end ForeverBrowser_C200Copy(table.concat(text,"\n"),"Export Favorites") end)
    PageContent:SetHeight(math.max(700,math.abs(y)+90))
end

function ForeverBrowser_D208Data()
    local rows,seen={},{} local source=ForeverSourceData or {} local bosses={}
    for _,d in ipairs(GetForeverDungeonIndex()) do for _,b in ipairs(d.bosses or {}) do bosses[tonumber(b.id)]={name=b.name,dungeon=d.name} end end
    local state=ForeverBrowser_C200State() state.farm208=state.farm208 or {priorities={}}
    for key,flag in pairs(GetForeverWishlist()) do local id=tonumber(key)
        if flag and id and not seen[id] then seen[id]=true
            local item=GetAnyItem(id) or {} local recorded=source.items and (source.items[id] or source.items[tostring(id)]) or item
            local associations,labels={},{} local unique={}
            for _,r in pairs(type(recorded.sources)=="table" and recorded.sources or {}) do if type(r)=="table" then
                local npcID=tonumber(r.id or r.npcID) local npc=npcID and source.foreverNPCs and (source.foreverNPCs[npcID] or source.foreverNPCs[tostring(npcID)])
                local b=(r.type=="drop" or r.type=="pickpocket" or r.type=="skinning") and (bosses[npcID] or (npc and npc.dungeonName and {name=npc.name,dungeon=npc.dungeonName}))
                if b then local tag=b.dungeon..":"..tostring(npcID) if not unique[tag] then unique[tag]=true associations[#associations+1]={dungeon=b.dungeon,boss=b.name or ("NPC "..npcID),id=npcID} labels[#labels+1]=b.dungeon.." / "..(b.name or tostring(npcID)) end end
            end end
            table.sort(labels)
            rows[#rows+1]={id=id,name=GetItemName(id),collected=IsForeverItemCollected(id),quality=tonumber(recorded.quality or recorded.Quality or item.quality),associations=associations,detail=#labels>0 and table.concat(labels,"; ") or "Dungeon source not recorded",priority=state.farm208.priorities[tostring(id)] or 0}
        end
    end
    table.sort(rows,function(a,b) if a.priority~=b.priority then return a.priority>b.priority end if a.name==b.name then return a.id<b.id end return a.name<b.name end)
    return rows,state.farm208
end
function ForeverBrowser_D208Filter(rows,f)
    local results={} for _,r in ipairs(rows) do
        local location=f.dungeon=="all" or not f.dungeon or f.dungeon=="unassigned" and #r.associations==0
        local boss=(f.boss or "")==""
        for _,a in ipairs(r.associations) do if f.dungeon=="all" or not f.dungeon or a.dungeon==f.dungeon then location=true if string.find(string.lower(a.boss),string.lower(f.boss or ""),1,true) then boss=true end end end
        if location and boss and (f.mode=="all" or not f.mode or f.mode=="collected" and r.collected or f.mode=="missing" and not r.collected) and (not f.quality or r.quality==f.quality) and ((f.query or "")=="" or tostring(r.id)==f.query or string.find(string.lower(r.name.." "..GetSavedItemTags(r.id).." "..GetSavedItemNote(r.id)),string.lower(f.query),1,true)) then results[#results+1]=r end
    end return results
end
function ForeverBrowser_D208Page(filters,page)
    local all,state=ForeverBrowser_D208Data() filters=filters or (ForeverBrowser_S222().rememberFilters and state.filters) or {dungeon="all",mode="missing",query="",boss=""} state.filters=filters
    page=tonumber(page) or 1 local rows=ForeverBrowser_D208Filter(all,filters)
    local collected,groups=0,{} for _,r in ipairs(all) do if r.collected then collected=collected+1 end
        local added={} for _,a in ipairs(r.associations) do if not added[a.dungeon] then added[a.dungeon]=true groups[a.dungeon]=groups[a.dungeon] or {total=0,missing=0} local g=groups[a.dungeon] g.total=g.total+1 if not r.collected then g.missing=g.missing+1 end end end
    end
    local hero=ForeverBrowser_CodexHome191("Dungeon Farming & Wishlist","Choose a dungeon, prioritize desired loot and keep your farming notes together.","Interface\\Icons\\INV_Misc_Bag_10",filters.query,"Find Targets",function(q) filters.query=q ForeverBrowser_D208Page(filters,1) end,
        {{#all,"Tracked Items"},{#all-collected,"Missing"},{collected,"Collected"},{ForeverBrowser_CountRecords(groups),"Dungeons"}},"Your Farming Plan")
    ForeverBrowser_C209ReserveNavigation(hero)
    local y=-440 local left=-440
    local back=CreateButton(PageContent,"Dungeon Database",150,26) back:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,-12) back:SetScript("OnClick",function() Navigate("forever://dungeons") end)
    local function choice(name,label)
        local b=CreateButton(PageContent,(filters.dungeon==name and "> " or "")..label,205,34) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,left)
        b:SetScript("OnClick",function() filters.dungeon=name filters.boss="" ForeverBrowser_D208Page(filters,1) end) left=left-42
    end
    choice("all","All Wishlist Items") choice("unassigned","Unassigned Sources")
    local names={} for name in pairs(groups) do names[#names+1]=name end table.sort(names)
    for _,name in ipairs(names) do local g=groups[name] choice(name,name.." ("..g.missing.." missing)") end
    local x=250 local label=ForeverBrowser_AchievementLabel(PageContent,filters.dungeon=="all" and "All Wishlist Items" or filters.dungeon=="unassigned" and "Unassigned Sources" or filters.dungeon,17,{1,.82,.28,1}) label:SetPoint("TOPLEFT",PageContent,"TOPLEFT",x,y) label:SetWidth(550) label:SetHeight(26) y=y-36
    for i,mode in ipairs({"all","missing","collected"}) do local b=CreateButton(PageContent,filters.mode==mode and "["..mode.."]" or mode,100,26) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",x+(i-1)*110,y) b:SetScript("OnClick",function() filters.mode=mode ForeverBrowser_D208Page(filters,1) end) end
    local rarity=CreateButton(PageContent,"Rarity: "..tostring(filters.quality or "all"),130,26) rarity:SetPoint("TOPLEFT",PageContent,"TOPLEFT",x+340,y)
    rarity:SetScript("OnClick",function() filters.quality=filters.quality==nil and 0 or filters.quality<6 and filters.quality+1 or nil ForeverBrowser_D208Page(filters,1) end)
    y=y-38 local boss=ForeverBrowser_C200Input(PageContent,x,y,290,filters.boss)
    local apply=CreateButton(PageContent,"Filter Boss",110,26) apply:SetPoint("LEFT",boss,"RIGHT",8,0) local function run() filters.boss=boss:GetText() ForeverBrowser_D208Page(filters,1) end apply:SetScript("OnClick",run) boss:SetScript("OnEnterPressed",run)
    local reset=CreateButton(PageContent,"Reset",85,26) reset:SetPoint("LEFT",apply,"RIGHT",8,0) reset:SetScript("OnClick",function() state.filters=nil ForeverBrowser_D208Page({dungeon="all",mode="all",query="",boss=""},1) end)
    y=y-38
    for i,text in ipairs({"Pin Missing","Export Shown","Dungeon Prep"}) do local b=CreateButton(PageContent,text,140,26) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",x+(i-1)*150,y)
        b:SetScript("OnClick",function()
            if i==1 then local ids={} for _,r in ipairs(rows) do if not r.collected then ids[r.id]=true end end
                if next(ids) then local name="Farming: "..tostring(filters.dungeon) local s=ForeverBrowser_C200State() ForeverBrowser_C198SaveGoal(name,ids,"Farming wishlist snapshot") for id,g in pairs(s.goals) do if g.name==name and g.source=="Farming wishlist snapshot" then s.tracker.goals[id]=true end end s.tracker.visible=true ForeverBrowser_C200TrackerCreate() ForeverBrowser_C200TrackerRefresh() ForeverBrowserCodexTracker200:Show() end
            elseif i==2 then local lines={"Dungeon Farming / Wishlist"} for _,r in ipairs(rows) do lines[#lines+1]=r.name.." ["..r.id.."] • "..(r.collected and "collected" or "missing").." • "..r.detail.." • priority "..r.priority end ForeverBrowser_C200Copy(table.concat(lines,"\n"),"Farming Export")
            else Navigate(filters.dungeon~="all" and filters.dungeon~="unassigned" and "forever://codex/prep/"..filters.dungeon.."/1" or "forever://codex/prep") end
        end)
    end
    y=y-42
    if state.removed then local undo=CreateButton(PageContent,"Undo Last Removal",170,26) undo:SetPoint("TOPLEFT",PageContent,"TOPLEFT",x,y) undo:SetScript("OnClick",function() SetForeverItemTracked(state.removed,true) state.removed=nil ForeverBrowser_D208Page(filters,page) end) y=y-36 end
    local pages=math.max(1,math.ceil(#rows/6)) page=math.max(1,math.min(page,pages))
    local count=ForeverBrowser_AchievementLabel(PageContent,#rows.." targets • page "..page.." / "..pages.." • priorities sort highest first",11,{.87,.81,.67,1}) count:SetPoint("TOPLEFT",PageContent,"TOPLEFT",x,y) y=y-28
    if #rows==0 then local empty=ForeverBrowser_AchievementLabel(PageContent,#all==0 and "Track loot from a dungeon page to start your wishlist." or "No targets match these filters. Try Reset.",12,{.87,.81,.67,1}) empty:SetPoint("TOPLEFT",PageContent,"TOPLEFT",x,y) empty:SetWidth(540) y=y-55 end
    for n=(page-1)*6+1,math.min(page*6,#rows) do local r=rows[n]
        local row=CreateFrame("Frame",nil,PageContent) row:SetSize(565,165) row:SetPoint("TOPLEFT",PageContent,"TOPLEFT",x,y) CreateSolidBackground(row,.045,.038,.029,1)
        local icon=CreateFrame("Button",nil,row) icon:SetSize(42,42) icon:SetPoint("TOPLEFT",row,"TOPLEFT",12,-12) local tex=icon:CreateTexture(nil,"ARTWORK") tex:SetAllPoints(icon) tex:SetTexture(GetItemIcon(r.id,GetAnyItem(r.id))) icon:SetScript("OnClick",function() Navigate("forever://item/"..r.id) end) icon:SetScript("OnEnter",function(self) ShowItemTooltip(r.id,self) end) icon:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
        local title=ForeverBrowser_AchievementLabel(row,r.name,14,{1,.82,.28,1}) title:SetPoint("TOPLEFT",row,"TOPLEFT",65,-12) title:SetWidth(480) title:SetHeight(20) title:SetJustifyH("LEFT")
        local status=ForeverBrowser_AchievementLabel(row,(r.collected and "Collected" or "Missing").." • rarity "..tostring(r.quality or "unknown").." • ID "..r.id,10,{.87,.81,.67,1}) status:SetPoint("TOPLEFT",row,"TOPLEFT",65,-37)
        local sources=ForeverBrowser_AchievementLabel(row,r.detail,10,{.87,.81,.67,1}) sources:SetPoint("TOPLEFT",row,"TOPLEFT",12,-64) sources:SetWidth(540) sources:SetHeight(28) sources:SetJustifyH("LEFT")
        local note=GetSavedItemNote(r.id):gsub("[\r\n]+"," ") local notes=ForeverBrowser_AchievementLabel(row,note~="" and note or "No farming notes yet",10,{.87,.81,.67,1}) notes:SetPoint("TOPLEFT",row,"TOPLEFT",12,-96) notes:SetWidth(540) notes:SetHeight(16) notes:SetJustifyH("LEFT")
        for i,text in ipairs({"Sources","My Lists","Notes","Priority "..r.priority,"Remove"}) do local b=CreateButton(row,text,100,25) b:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",12+(i-1)*109,12)
            b:SetScript("OnClick",function() if i==1 then Navigate("forever://codex/acquire/"..r.id) elseif i==2 then Navigate("forever://lists/add/"..r.id) elseif i==3 then Navigate("forever://codex/notes/item/"..r.id) elseif i==4 then state.priorities[tostring(r.id)]=(r.priority+1)%4 ForeverBrowser_D208Page(filters,page) else SetForeverItemTracked(r.id,false) state.removed=r.id ForeverBrowser_D208Page(filters,page) end end)
        end
        y=y-175
    end
    for i,text in ipairs({"Previous","Next"}) do local b=CreateButton(PageContent,text,110,28) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",x+(i-1)*125,y) if (i==1 and page==1) or (i==2 and page==pages) then b:Disable() else b:SetScript("OnClick",function() ForeverBrowser_D208Page(filters,page+(i==1 and -1 or 1)) end) end end
    local hint=ForeverBrowser_AchievementLabel(PageContent,"Collection records confirm obtained items. Boss kills and drop attempts are not tracked.",10,{.87,.81,.67,1}) hint:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,math.min(y,left)-48) hint:SetWidth(780)
    PageContent:SetHeight(math.max(850,math.abs(math.min(y,left))+100))
end

-- Bounded boss-loot browser with reusable rows and saved-metadata filters.
function ForeverBrowser_B211Loot(npcID,query,mode,quality,page)
    local prefs=ForeverBrowser_S222() prefs.bossFilters=prefs.bossFilters or {} local saved=prefs.rememberFilters and prefs.bossFilters[tostring(npcID)]
    if query==nil and saved then query=saved.query mode=saved.mode quality=saved.quality end
    mode=mode or (prefs.showCollected and "all" or "missing")
    if prefs.rememberFilters then prefs.bossFilters[tostring(npcID)]={query=query or "",mode=mode,quality=quality} end
    npcID=tonumber(npcID) query=query or "" mode=mode or "all" page=tonumber(page) or 1
    local boss=FindNPCSourceData(npcID) or {} local name=boss.name or ("Boss "..tostring(npcID))
    local y=ForeverBrowser_C198Head(name.." Loot","Recorded acquisition sources • collection status does not imply a boss kill. Unknown rarity cannot match a rarity filter.")
    local back=CreateButton(PageContent,"Dungeon Database",150,28) back:SetPoint("TOPLEFT",PageContent,"TOPLEFT",160,-20) back:SetScript("OnClick",function() Navigate("forever://dungeons") end)
    local farming=CreateButton(PageContent,"Farming Wishlist",145,28) farming:SetPoint("TOPLEFT",PageContent,"TOPLEFT",320,-20) farming:SetScript("OnClick",function() Navigate("forever://farming") end)
    local box=ForeverBrowser_C200Input(PageContent,25,y,330,query) local search=CreateButton(PageContent,"Find Loot",100,28) search:SetPoint("LEFT",box,"RIGHT",8,0)
    local function run() ForeverBrowser_B211Loot(npcID,box:GetText(),mode,quality,1) end search:SetScript("OnClick",run) box:SetScript("OnEnterPressed",run)
    local refresh=CreateButton(PageContent,"Refresh Data",120,28) refresh:SetPoint("LEFT",search,"RIGHT",8,0) refresh:SetScript("OnClick",function() ForeverBrowser_LootIndex211(true) ForeverBrowser_B211Loot(npcID,query,mode,quality,1) end)
    y=y-42 for i,k in ipairs({"all","missing","collected","tracked"}) do local b=CreateButton(PageContent,k==mode and "["..k.."]" or k,100,26) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25+(i-1)*112,y) b:SetScript("OnClick",function() ForeverBrowser_B211Loot(npcID,query,k,quality,1) end) end
    local rarity=CreateButton(PageContent,"Rarity: "..tostring(quality or "all"),130,26) rarity:SetPoint("TOPLEFT",PageContent,"TOPLEFT",490,y) rarity:SetScript("OnClick",function() local q=quality==nil and 0 or quality<6 and quality+1 or nil ForeverBrowser_B211Loot(npcID,query,mode,q,1) end)
    y=y-40 local rows={} for _,r in ipairs(GetForeverBossLoot(npcID)) do local item=GetAnyItem(r.id) or {} local q=tonumber(item.quality or item.Quality) local got=IsForeverItemCollected(r.id)
        if (query=="" or tostring(r.id)==query or string.find(string.lower(r.name),string.lower(query),1,true)) and (mode=="all" or mode=="missing" and not got or mode=="collected" and got or mode=="tracked" and IsForeverItemTracked(r.id)) and (quality==nil or q==quality) then r.quality=q r.collected=got rows[#rows+1]=r end
    end
    if prefs.wishlistFirst then table.sort(rows,function(a,b) local at,bt=IsForeverItemTracked(a.id),IsForeverItemTracked(b.id) if at~=bt then return at end return tostring(a.name)<tostring(b.name) end) end
    local pages=math.max(1,math.ceil(#rows/10)) page=math.max(1,math.min(page,pages)) y=ForeverBrowser_C198Row(y,#rows.." matching items","Page "..page.." / "..pages.." • chance values are database records")
    ForeverBrowserLootRows211=ForeverBrowserLootRows211 or {}
    if #rows==0 then y=ForeverBrowser_C198Row(y,"No matching loot","Clear the filters or refresh the loaded source data.") end
    for n=(page-1)*10+1,math.min(page*10,#rows) do local r=rows[n] local slot=n-(page-1)*10 local row=ForeverBrowserLootRows211[slot]
        if not row then
            row=CreateFrame("Button",nil,PageContent) row:SetSize(790,80) row.background=CreateSolidBackground(row,.045,.038,.029,1)
            row.icon=row:CreateTexture(nil,"ARTWORK") row.icon:SetSize(42,42) row.icon:SetPoint("LEFT",row,"LEFT",12,0)
            row.title=ForeverBrowser_AchievementLabel(row,"",14,WOW_THEME.gold) row.title:SetPoint("TOPLEFT",row,"TOPLEFT",68,-13) row.title:SetWidth(490) row.title:SetHeight(20) row.title:SetJustifyH("LEFT")
            row.detail=ForeverBrowser_AchievementLabel(row,"",10,WOW_THEME.muted) row.detail:SetPoint("TOPLEFT",row,"TOPLEFT",68,-40) row.detail:SetWidth(490) row.detail:SetHeight(28) row.detail:SetJustifyH("LEFT")
            row.track=CreateButton(row,"",100,26) row.track:SetPoint("TOPRIGHT",row,"TOPRIGHT",-12,-10)
            row.sources=CreateButton(row,"Sources",100,26) row.sources:SetPoint("BOTTOMRIGHT",row,"BOTTOMRIGHT",-12,10)
            row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight") ForeverBrowserLootRows211[slot]=row
        end
        row:SetParent(PageContent) row:ClearAllPoints() row:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,y) row:Show()
        if type(ForeverBrowserTheme.RestyleBorder)=="function" then ForeverBrowserTheme.RestyleBorder(row) end
        row.background:SetVertexColor(unpack(WOW_THEME.row)) RegisterThemeVisual("row",row.background)
        row.title:SetText(r.name) row.title:SetTextColor(unpack(GetQualityColor(r.quality or 0)))
        row.icon:SetTexture(GetItemIcon(r.id,GetAnyItem(r.id)))
        row.detail:SetText((r.collected and "Collected" or "Missing").." • "..(r.chance and string.format("Recorded chance %.2f%%",r.chance) or "Chance unknown").." • "..tostring(r.sourceType or "drop")) row.detail:SetTextColor(unpack(WOW_THEME.muted)) RegisterThemeVisual("muted",row.detail)
        row.track.text:SetText(IsForeverItemTracked(r.id) and "Untrack" or "Track") if type(ForeverBrowserTheme.StyleButton)=="function" then ForeverBrowserTheme.StyleButton(row.track) ForeverBrowserTheme.StyleButton(row.sources) end
        row.track:SetScript("OnClick",function() SetForeverItemTracked(r.id,not IsForeverItemTracked(r.id)) ForeverBrowser_B211Loot(npcID,query,mode,quality,page) end)
        row.sources:SetScript("OnClick",function() Navigate("forever://codex/acquire/"..r.id) end)
        row:SetScript("OnClick",function() if IsShiftLinkClick() then LinkItemToChat(r.id) else Navigate("forever://item/"..r.id) end end)
        row:SetScript("OnEnter",function(self) ShowItemTooltip(r.id,self) end) row:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
        y=y-88
    end
    for i,label in ipairs({"Previous","Next"}) do local b=CreateButton(PageContent,label,110,28) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25+(i-1)*125,y) if (i==1 and page==1) or (i==2 and page==pages) then b:Disable() else b:SetScript("OnClick",function() ForeverBrowser_B211Loot(npcID,query,mode,quality,page+(i==1 and -1 or 1)) end) end end
    PageContent:SetHeight(math.max(700,math.abs(y)+90))
end

-- Codex directories use recorded relationships and never infer encounter completion.
function ForeverBrowser_C217Objects(force)
    local source=ForeverSourceData or {} local now=type(GetTime)=="function" and GetTime() or 0
    local cache=ForeverBrowserObjects217
    if not force and cache and cache.source==source and now-cache.stamp<60 then return cache.records end
    local records={}
    local function object(id,r)
        id=tonumber(id) if not id or id<=0 then return end
        records[id]=records[id] or {id=id,name="Object "..id,items={},quests={},locations={}}
        local o=records[id]
        if type(r)=="table" then
            o.name=r.name or r.title or o.name o.category=r.objectType or r.category or o.category
            if r.uiMapID and r.x and r.y then o.locations[#o.locations+1]=r end
            for _,p in pairs(type(r.locations)=="table" and r.locations or {}) do if type(p)=="table" then o.locations[#o.locations+1]=p end end
        end return o
    end
    for _,field in ipairs({"objects","gameObjects"}) do for id,r in pairs(type(source[field])=="table" and source[field] or {}) do object(type(r)=="table" and (r.id or r.objectID or id) or id,r) end end
    for item,r in pairs(source.items or {}) do if type(r)=="table" then
        for _,s in pairs(type(r.sources)=="table" and r.sources or {}) do if type(s)=="table" and s.type=="object" then local o=object(s.objectID or s.id,s) if o then o.items[tonumber(item) or item]=true end end end
    end end
    for qid,q in pairs(source.quests or {}) do if type(q)=="table" then for _,field in ipairs({"objectStarters","objectFinishers","requiredObjects"}) do
        for key,r in pairs(type(q[field])=="table" and q[field] or {}) do
            local id=type(r)=="table" and (r.objectID or r.id) or (r==true and key or r)
            local o=object(id,r) if o then o.quests[tonumber(qid) or qid]=true end
        end
    end end end
    ForeverBrowserObjects217={source=source,stamp=now,records=records} return records
end
function ForeverBrowser_C217ObjectHome(query,page)
    query=tostring(query or "") local rows={}
    for id,o in pairs(ForeverBrowser_C217Objects()) do if string.find(string.lower(o.name.." "..id),string.lower(query),1,true) then
        rows[#rows+1]={name=o.name,detail=(o.category or "Recorded object").." • "..ForeverBrowser_CountRecords(o.items).." item links • "..ForeverBrowser_CountRecords(o.quests).." quest links",url="forever://codex/object/"..id.."/1"}
    end end
    table.sort(rows,function(a,b) return a.name<b.name end)
    ForeverBrowser_C201List("Object Database","Search recorded objects, quest interactables and item sources. Categories and locations appear only when recorded.",rows,page,"forever://codex/objects/"..query.."/")
    local input=ForeverBrowser_C200Input(PageContent,160,-20,230,query)
    local search=CreateButton(PageContent,"Search Objects",130,28) search:SetPoint("LEFT",input,"RIGHT",10,0)
    search:SetScript("OnClick",function() Navigate("forever://codex/objects/"..input:GetText().."/1") end)
end
function ForeverBrowser_C217Object(id,page)
    local o=ForeverBrowser_C217Objects()[tonumber(id)] local rows={}
    if o then
        for item in pairs(o.items) do rows[#rows+1]={name=GetItemName(item),detail="Recorded object loot source",url="forever://item/"..item} end
        for qid in pairs(o.quests) do local q=FindQuestSourceData(qid) or {} rows[#rows+1]={name=q.name or ("Quest "..qid),detail="Recorded quest association",url="forever://quest/"..qid} end
        local seen={}
        for _,p in ipairs(o.locations) do local map,x,y=tonumber(p.uiMapID),tonumber(p.x),tonumber(p.y)
            local key=tostring(map)..":"..tostring(x)..":"..tostring(y)
            if map and x and y and not seen[key] then seen[key]=true rows[#rows+1]={name=p.zoneName or p.zone or ("Map "..map),detail="Recorded object location",action=function() ShowForeverBrowserMapMarker(map,x,y,o.name) end,actionText="Show Map"} end
        end
        if not next(seen) then rows[#rows+1]={name="Location unavailable",detail="No usable map coordinates are recorded for this object."} end
    end
    table.sort(rows,function(a,b) return a.detail==b.detail and tostring(a.name)<tostring(b.name) or a.detail<b.detail end)
    ForeverBrowser_C201List(o and o.name or "Object unavailable","Object ID "..id.." • source records describe associations, not guaranteed loot.",rows,page,"forever://codex/object/"..id.."/")
    local back=CreateButton(PageContent,"Object Database",140,28) back:SetPoint("TOPLEFT",PageContent,"TOPLEFT",160,-20) back:SetScript("OnClick",function() Navigate("forever://codex/objects") end)
    if o then ForeverBrowser_C200NotesButton("object",id) ForeverBrowser_C218Button("object",id) end
end
function ForeverBrowser_C217Forever(kind,page)
    kind=kind or "all" local rows,seen={},{}
    local function add(k,id,r,url)
        local key=k..":"..tostring(id) if seen[key] or (kind~="all" and kind~=k) then return end seen[key]=true
        rows[#rows+1]={name=r.name or r.title or (k.." "..id),detail=k.." • explicitly identified Forever content",url=url}
    end
    for _,r in ipairs(ForeverBrowser_C198Index()) do local d=r.data
        if ForeverBrowser_IsForeverRecord(d) or (type(d)=="table" and (d.isForeverNPC or d.isForeverItem or d.isForeverQuest)) then add(r.kind,r.id,d,r.url) end
    end
    for id,r in pairs(ForeverSourceData and ForeverSourceData.foreverNPCs or {}) do if type(r)=="table" and tonumber(id) then add("npc",id,r,"forever://npc/"..id) end end
    for id,r in pairs(ForeverSourceData and ForeverSourceData.zones or {}) do if ForeverBrowser_IsForeverRecord(r) and r.name then add("zone",id,r,"forever://codex/zone/all/1/"..string.lower(r.name)) end end
    table.sort(rows,function(a,b) return a.detail==b.detail and tostring(a.name)<tostring(b.name) or a.detail<b.detail end)
    ForeverBrowser_C201List("Forever Content Directory","Only records explicitly marked Forever appear. A Forever source label does not necessarily mean exclusive content.",rows,page,"forever://codex/forever/"..kind.."/")
    for i,k in ipairs({"all","item","npc","quest","recipe","zone"}) do local b=CreateButton(PageContent,k,85,26) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",160+(i-1)*90,-20) b:SetScript("OnClick",function() Navigate("forever://codex/forever/"..k.."/1") end) end
end
function ForeverBrowser_G221Home(query,page)
    query=tostring(query or "") local entries={}
    for _,d in ipairs(GetForeverDungeonIndex()) do if string.find(string.lower(d.name),string.lower(query),1,true) then entries[#entries+1]=d end end
    local pages=math.max(1,math.ceil(#entries/10)) page=math.max(1,math.min(tonumber(page) or 1,pages))
    local hero=ForeverBrowser_CodexHome191("Dungeon Guides","Choose a dungeon, then explore its overview, quests, bosses and personal notes.","Interface\\Icons\\INV_Misc_Map_01",query,"Search Guides",function(q) Navigate("forever://codex/guides/search/"..q.."/1") end,
        {{#GetForeverDungeonIndex(),"Dungeon Guides"},{#entries,"Matching Guides"},{page,"Current Page"},{pages,"Total Pages"}},"Choose Your Dungeon")
    ForeverBrowser_C209ReserveNavigation(hero)
    local back=CreateButton(PageContent,"Dungeon Codex",140,28) back:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,-12) back:SetScript("OnClick",function() Navigate("forever://dungeons") end)
    for i=(page-1)*10+1,math.min(page*10,#entries) do local d=entries[i]
        ForeverBrowser_CodexCard191(hero,i-(page-1)*10,d.name,"Levels "..tostring(d.minLevel or "?").."–"..tostring(d.maxLevel or "?").." • "..#d.bosses.." boss records","Overview • Quests • Loot • Notes","Interface\\Icons\\INV_Misc_Map_01","forever://codex/guide/"..d.name.."/overview/1",125)
    end
    local y=-365-math.ceil(math.min(10,#entries)/2)*112
    if #entries==0 then ForeverBrowser_C198Row(-360,"No matching dungeon guides","Try another name, or check that source and enrichment data are loaded.") y=-455 end
    for i,label in ipairs({"Previous","Next"}) do local b=CreateButton(PageContent,label,110,28) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",65+(i-1)*125,y)
        if (i==1 and page==1) or (i==2 and page==pages) then b:Disable() else b:SetScript("OnClick",function() Navigate("forever://codex/guides/search/"..query.."/"..(page+(i==1 and -1 or 1))) end) end
    end
    PageContent:SetHeight(math.max(700,math.abs(y)+90))
end
function ForeverBrowser_C217Guide(name,page,tab)
    if not name then ForeverBrowser_G221Home("",page) return end
    tab=tab or "overview" local allowed={overview=true,quests=true,bosses=true,notes=true}
    if not allowed[tab] then tab="overview" end
    local d,loot=ForeverBrowser_C198DungeonData(name)
    local record,quests,entrances=ForeverBrowser_D220OverviewData(name)
    local collected=0 for _,r in ipairs(loot or {}) do if IsForeverItemCollected(r.id) then collected=collected+1 end end
    local hero=ForeverBrowser_CodexHome191("Dungeon Guide",name,"Interface\\Icons\\INV_Misc_Map_01","","Find Guide",function(q) Navigate("forever://codex/guides/search/"..q.."/1") end,
        {{d and #d.bosses or 0,"Boss Records"},{#quests,"Related Quests"},{#(loot or {}),"Loot Records"},{collected,"Items Collected"}},({overview="Overview & Entrances",quests="Related Quests",bosses="Bosses & Loot",notes="Your Dungeon Notes"})[tab])
    ForeverBrowser_C209ReserveNavigation(hero)
    local back=CreateButton(PageContent,"All Guides",120,28) back:SetPoint("TOPLEFT",PageContent,"TOPLEFT",25,-12) back:SetScript("OnClick",function() Navigate("forever://codex/guides") end)
    local details=CreateButton(PageContent,"Dungeon Details",145,28) details:SetPoint("LEFT",back,"RIGHT",12,0) details:SetScript("OnClick",function() Navigate("forever://dungeon/"..name) end)
    for i,k in ipairs({"overview","quests","bosses","notes"}) do local text=({overview="Overview",quests="Quests",bosses="Bosses & Loot",notes="Notes & Tags"})[k]
        local b=CreateButton(PageContent,text,155,28) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",65+(i-1)*170,-355)
        if k==tab then b:Disable() else b:SetScript("OnClick",function() Navigate("forever://codex/guide/"..name.."/"..k.."/1") end) end
    end
    if not d then ForeverBrowser_C198Row(-405,"Dungeon unavailable","No dungeon record matches this guide.") PageContent:SetHeight(700) return end
    if tab=="notes" then ForeverBrowser_C200Notes("dungeon",name,-405) PageContent:SetHeight(930) return end
    local rows={}
    if tab=="overview" then
        rows[#rows+1]={name="Recommended Levels",detail=tostring(record.minLevel or d.minLevel or "unknown").."–"..tostring(record.maxLevel or d.maxLevel or "unknown").." • recommendation, not an entry requirement"}
        rows[#rows+1]={name="Location",detail=record.locationDescription or "Location description not recorded"}
        for i,p in ipairs(entrances) do rows[#rows+1]={name="Entrance "..i,detail="Recorded map coordinates",action=function() ShowForeverBrowserMapMarker(p.mapID,p.x,p.y,name.." Entrance") end,actionText="Show Map"} end
        if #entrances==0 then rows[#rows+1]={name="Entrance unavailable",detail="No explicit entrance coordinates recorded."} end
        for _,f in ipairs({{"Entry requirements","requirements"},{"Attunement","attunement"},{"Guide notes","description"},{"Strategy","strategy"}}) do if type(record[f[2]])=="string" and record[f[2]]~="" then rows[#rows+1]={name=f[1],detail=record[f[2]]} end end
        rows[#rows+1]={name="Prepare Your Run",detail="Related quests, missing loot and recorded entrances",url="forever://codex/prep/"..name.."/1"}
        rows[#rows+1]={name="Recorded Details",detail="Source, import date and known requirements",url="forever://codex/data/dungeon/"..name.."/1"}
    elseif tab=="quests" then rows=quests
    elseif tab=="bosses" then
        rows[#rows+1]={name="Browse All Dungeon Loot",detail=#loot.." unique loot records • "..collected.." collected",url="forever://dungeon/"..name}
        for _,b in ipairs(d.bosses) do local r=FindNPCSourceData(b.id) or {}
            rows[#rows+1]={name=b.name,detail=tostring(b.role or "Dungeon Boss").." • "..tostring(r.strategy or r.description or "No encounter notes recorded"),url="forever://npc/"..b.id,action=function() Navigate("forever://dungeonboss/"..b.id) end,actionText="View Loot"}
        end
    end
    local pages=math.max(1,math.ceil(#rows/8)) page=math.max(1,math.min(tonumber(page) or 1,pages)) local y=-405
    if #rows==0 then y=ForeverBrowser_C198Row(y,"No records in this section","The loaded database has no recorded information for this view.") end
    for i=(page-1)*8+1,math.min(page*8,#rows) do local r=rows[i] y=ForeverBrowser_C198Row(y,r.name,r.detail,r.url,r.action,r.actionText) end
    for i,label in ipairs({"Previous","Next"}) do local b=CreateButton(PageContent,label,110,28) b:SetPoint("TOPLEFT",PageContent,"TOPLEFT",65+(i-1)*125,y-12)
        if (i==1 and page==1) or (i==2 and page==pages) then b:Disable() else b:SetScript("OnClick",function() Navigate("forever://codex/guide/"..name.."/"..tab.."/"..(page+(i==1 and -1 or 1))) end) end
    end
    local count=ForeverBrowser_AchievementLabel(PageContent,"Page "..page.." / "..pages.." • recorded information; boss completion is not tracked",10,WOW_THEME.muted) count:SetPoint("TOPLEFT",PageContent,"TOPLEFT",65,y-52)
    PageContent:SetHeight(math.max(700,math.abs(y)+110))
end
function ForeverBrowser_C218Data(kind,id)
    local source=ForeverSourceData or {} local bucket=source[({item="items",quest="quests",npc="npcs",recipe="recipes",object="objects",dungeon="dungeons"})[kind]] or {}
    local r=bucket[tonumber(id) or id] or bucket[tostring(id)]
    if kind=="dungeon" then for _,d in pairs(bucket) do if type(d)=="table" and d.name==id then r=d break end end end
    r=type(r)=="table" and r or {} local meta=source.enrichment or {} local rows={}
    local function add(name,value,url) rows[#rows+1]={name=name,detail=value==nil and "Not recorded" or tostring(value),url=url} end
    add("Record source",r.dataSource or r.sourceDatabase or "Loaded database; per-record source not specified")
    add("Import date",r.importedAt or r.enrichmentImportedAt)
    if r.enrichmentSource then add("Enrichment source",r.enrichmentSource) end
    add("Verification date",r.verifiedAt or r.verifiedDate)
    add("Content classification",r.contentStatus or (r.isForever and "Marked Forever content") or "Not classified")
    add("Forever exclusivity",r.foreverExclusive==true and "Explicitly marked exclusive" or r.foreverExclusive==false and "Explicitly marked non-exclusive" or "Not established by recorded data")
    if kind=="recipe" then
        for _,f in ipairs({{"Required skill","requiredSkill"},{"Yellow at","yellowSkill"},{"Green at","greenSkill"},{"Gray at","graySkill"},{"Items per craft","createsCount"},{"Recipe notes","description"}}) do add(f[1],r[f[2]]) end
        add("Recipe data provenance",meta.recipeSource)
        for _,v in pairs(r.recipeItems or {}) do if type(v)=="table" and tonumber(v.itemID) then add(v.itemName or GetItemName(v.itemID),"Recipe teaching item","forever://item/"..v.itemID) end end
    elseif kind=="quest" then
        add("Minimum level",r.minLevel or r.requiredLevel) add("Objective text",r.objectiveText)
        for _,p in pairs(r.previousQuests or {}) do local qid=type(p)=="table" and p.id or p if tonumber(qid) then add("Prerequisite quest "..qid,"Recorded prerequisite","forever://quest/"..qid) end end
    elseif kind=="dungeon" then
        add("Recommended levels",tostring(r.minLevel or "unknown").."–"..tostring(r.maxLevel or "unknown"))
        add("Location description",r.locationDescription) add("Entry requirements",r.requirements) add("Attunement",r.attunement)
    end
    if kind=="npc" or kind=="item" then
        for npc,inventory in pairs(source.vendors or {}) do if kind=="item" or tonumber(npc)==tonumber(id) then
            for _,v in pairs(type(inventory)=="table" and inventory or {}) do if type(v)=="table" and (kind=="npc" or tonumber(v.itemID)==tonumber(id)) then
                local price=v.buyPrice==nil and "unknown" or tostring(v.buyPrice)
                local stock=v.maxCount==nil and "unknown" or tonumber(v.maxCount)==0 and "unlimited" or tostring(v.maxCount)
                local detail="Recorded base price: "..price.." copper • quantity: "..tostring(v.buyCount or "unknown").." • stock: "..stock.." • restock: "..tostring(v.restockSeconds or "unknown").." seconds"
                if v.extendedCost and tonumber(v.extendedCost)~=0 then detail=detail.." • extended-cost ID: "..tostring(v.extendedCost).." (currency details not decoded)" end
                if v.requiredReputation then detail=detail.." • reputation requirement: "..tostring(v.requiredReputation) end
                add(kind=="npc" and (v.name or GetItemName(v.itemID)) or ("Vendor "..npc),detail,kind=="npc" and "forever://item/"..v.itemID or "forever://npc/"..npc)
            end end
        end end
    end
    return rows,r
end
function ForeverBrowser_C218Page(kind,id,page)
    local rows,r=ForeverBrowser_C218Data(kind,id)
    ForeverBrowser_C201List("Recorded Details: "..(r.name or (kind.." "..id)),"Imported source details • import dates are not verification dates • prices and requirements are not live merchant checks.",rows,page,"forever://codex/data/"..kind.."/"..id.."/")
    local back=CreateButton(PageContent,"Return to Record",140,28) back:SetPoint("TOPLEFT",PageContent,"TOPLEFT",160,-20)
    back:SetScript("OnClick",function() Navigate(kind=="object" and "forever://codex/object/"..id.."/1" or kind=="dungeon" and "forever://codex/guide/"..id.."/1" or "forever://"..kind.."/"..id) end)
end
function ForeverBrowser_C218Button(kind,id)
    local b=CreateButton(PageContent,"Recorded Details",140,28)
    if kind=="item" and ItemActionsAnchor then
        b:SetPoint("TOPLEFT",ItemActionsAnchor,"BOTTOMLEFT",170,-20)
    else
        b:SetPoint("BOTTOMRIGHT",PageContent,"BOTTOMRIGHT",-25,48)
    end
    b:SetScript("OnClick",function() Navigate("forever://codex/data/"..kind.."/"..id.."/1") end)
    local report=CreateButton(PageContent,"Report Issue",130,28)
    if kind=="item" and ItemActionsAnchor then
        report:SetPoint("TOPLEFT",ItemActionsAnchor,"BOTTOMLEFT",20,-20)
    else
        report:SetPoint("BOTTOMRIGHT",PageContent,"BOTTOMRIGHT",-175,48)
    end
    report:SetScript("OnClick",function() Navigate("forever://codex/correct/"..kind.."/"..id) end)
end

function ForeverBrowser_C217Route(route)
    local dn,dpage=route:match("^dungeon%-quests/(.*)/(%d+)$") if dn then ForeverBrowser_D220Quests(dn,dpage) return true end
    local dk,di,dp=route:match("^data/(%a+)/(.*)/(%d+)$") if dk then ForeverBrowser_C218Page(dk,di,dp) return true end
    if route=="objects" then ForeverBrowser_C217ObjectHome() return true end
    local q,p=route:match("^objects/(.*)/(%d+)$") if q then ForeverBrowser_C217ObjectHome(q,p) return true end
    local id,op=route:match("^object/(%d+)/(%d+)$") if id then ForeverBrowser_C217Object(id,op) return true end
    if route=="forever" then ForeverBrowser_C217Forever() return true end
    local k,fp=route:match("^forever/(%a+)/(%d+)$") if k then ForeverBrowser_C217Forever(k,fp) return true end
    local gq,gpage=route:match("^guides/search/(.*)/(%d+)$") if gq then ForeverBrowser_G221Home(gq,gpage) return true end
    local gn,gt,gp2=route:match("^guide/(.*)/(%a+)/(%d+)$") if gn then ForeverBrowser_C217Guide(gn,gp2,gt) return true end
    if route=="guides" then ForeverBrowser_C217Guide() return true end
    local gp=route:match("^guides/(%d+)$") if gp then ForeverBrowser_C217Guide(nil,gp) return true end
    local name,np=route:match("^guide/(.*)/(%d+)$") if name then ForeverBrowser_C217Guide(name,np) return true end
    return false
end

function ForeverBrowser_C198Route(url)
    ForeverBrowser_C200Init()
    ForeverBrowser_C201Apply()
    ForeverBrowser_C201Record(url)
    local bossLootID=url:match("^forever://dungeonboss/(%d+)$")
    if bossLootID then ForeverBrowser_B211Loot(tonumber(bossLootID)) return true end
    if url=="forever://farming" then ForeverBrowser_D208Page() return true end
    if url=="forever://favorites" then ForeverBrowser_F207Page() return true end
    if ForeverBrowser_L206Route(url) then return true end
    if url=="forever://codex" then ForeverBrowser_C198Hub() return true end
    local route=url:match("^forever://codex/(.*)$") if not route then return false end
    local chapter=route:match("^chapter/([%a]+)$")
    if chapter then ForeverBrowser_C198Hub(chapter) return true end
    if ForeverBrowser_C217Route(route) then return true end
    if ForeverBrowser_C201Route(route) then return true end
    if ForeverBrowser_C200Route(route) then return true end
    local kind,page,query=route:match("^search/(%a+)/(%d+)/(.*)$")
    local zoneKind,zonePage,zoneKey=route:match("^zone/(%a+)/(%d+)/(.*)$")
    local zoneHomePage,zoneQuery=route:match("^zones/(%d+)/(.*)$")
    if route=="zones" then ForeverBrowser_Z199Home()
    elseif zoneHomePage then ForeverBrowser_Z199Home(zoneQuery,zoneHomePage)
    elseif zoneKind then ForeverBrowser_Z199Page(zoneKey,zoneKind,zonePage)
    elseif kind then ForeverBrowser_C198Search(query,kind,page)
    elseif route=="bookmarks" then ForeverBrowser_C198Bookmarks()
    elseif route=="progress" then ForeverBrowser_C198Progress()
    elseif route=="shopping" then ForeverBrowser_C198Shopping()
    elseif route=="dungeons" then ForeverBrowser_C198Dungeon()
    elseif route:match("^dungeon/") then ForeverBrowser_C198Dungeon(route:sub(9))
    elseif route=="goals" then ForeverBrowser_C198Goals()
    elseif route=="sets" then ForeverBrowser_C198Sets()
    elseif route:match("^goal%-add/%d+$") then ForeverBrowser_C198Goals(tonumber(route:match("(%d+)$")))
    elseif route:match("^goal/%d+$") then ForeverBrowser_C198Goal(route:match("(%d+)$"))
    elseif route=="chains" then ForeverBrowser_BuildQuestRelationshipsPage() ForeverBrowserRelationshipBrowse198(1)
    elseif route:match("^chain/%d+$") then
        ForeverBrowser_BuildQuestRelationshipsPage()
        local id=tonumber(route:match("(%d+)$")) local q=FindQuestSourceData(id)
        if q then
            ForeverBrowserRelationshipOpen198(id,q)
            ForeverBrowser_C198Row(-((PageContent:GetHeight() or 900)-60),"Quest Rewards & Locations",
                "XP: "..tostring(q.rewardXP or "unknown").." • money (copper): "..tostring(q.rewardMoney or "unknown").." • open details for reward items and giver locations.",
                "forever://quest/"..id)
        end
    else local y=ForeverBrowser_C198Head("Source Guide","Source labels describe recorded provenance; unspecified records retain an explicit unknown label.")
        for _,r in ipairs({{"Forever","Explicit Forever flags or source identifiers; dungeon records come from Forever NPC data."},{"Classic","Records explicitly identified as Classic data; realm behavior may differ."},{"Character discovery","Items present in the account's discovered item database."},{"Database • provenance unspecified","Loaded records without an explicit source flag; no origin is inferred."}}) do y=ForeverBrowser_C198Row(y,r[1],r[2]) end
    end return true
end

Navigate =
    function(
        selfOrURL,
        url,
        skipHistory
    )

        HideSearchSuggestions()

        --------------------------------------------------
        -- SUPPORT BOTH:
        -- Navigate(url)
        -- Navigate(self, url)
        --------------------------------------------------

        if type(selfOrURL)
            == "string" then

            local directSkipHistory =
                url

            url =
                selfOrURL

            skipHistory =
                directSkipHistory == true

        end


        if type(url)
            ~= "string" then

            return

        end


        -- Global item shortcut: Alt + Left Click. Every existing item row that
        -- calls Navigate("forever://item/...") automatically gets Wardrobe.
        if string.sub(url,1,15) == "forever://item/"
            and IsAltKeyDown and IsAltKeyDown() then

            local wardrobeID = tonumber(string.sub(url,16))
            if wardrobeID then
                OpenWardrobePreview(wardrobeID)
                return
            end
        end


        CurrentURL =
            url
        ForeverBrowser_S222().lastPage=url

        UpdateNavigationState(
            url
        )


        --------------------------------------------------
        -- HISTORY
        --------------------------------------------------

        if not skipHistory then

            AddHistory(
                url
            )

        end


        if AddressBox then

            AddressBox:SetText(
                url
            )

        end


        --------------------------------------------------
        -- HOME
        --------------------------------------------------

        if ForeverBrowserNavigation226 and ForeverBrowserNavigation226.replay then
            ForeverBrowserNavigation226.replay()
            return
        end

        if ForeverBrowser_C198Route(url) then return end

        if url ==
            "forever://home" then

            BuildHomePage()
            return

        end


        --------------------------------------------------
        -- ITEMS / SEARCH
        --------------------------------------------------

        if url == "forever://items" then
            BuildItemDatabasePage()
            return
        end

        if url == "forever://itembrowse" then
            BuildItemBrowsePage()
            return
        end

        if string.sub(url,1,17) == "forever://search/" then
            local searchText=string.sub(url,18)
            BuildSearchPage(searchText)
            return
        end


        --------------------------------------------------
        -- WELCOME
        --------------------------------------------------

        if url == "forever://welcome" then
            BuildWelcomePage()
            return
        end


        --------------------------------------------------
        -- QUEST DATABASE / SEARCH
        --------------------------------------------------

        if url == "forever://quests"
            or url == "forever://quests/" then
            ForeverBrowserQuestBrowseFilter = nil
            BuildQuestDatabasePage()
            return
        end

if url == "forever://npcdatabase" then
    ForeverBrowser_BuildNPCDatabasePage()
    return
end

if string.sub(url,1,20) == "forever://npcsearch/" then
    ForeverBrowser_N187Search(string.sub(url,21))
    return
end

if string.sub(url,1,20) == "forever://npcbrowse/" then
    ForeverBrowser_N187Browse(string.sub(url,21),"",1)
    return
end

if url == "forever://questrewards" then
    ForeverBrowser_BuildQuestRewardsPage()
    return
end

if url == "forever://questrelationships" then
            ForeverBrowser_BuildQuestRelationshipsPage()
            return
        end

        if url == "forever://questbrowse" then
            ForeverBrowserQuestBrowseFilter = nil
            BuildQuestBrowsePage("")
            return
        end

        if url == "forever://questbrowse/all" then
            ForeverBrowserQuestBrowseFilter = nil
            BuildQuestBrowsePage("")
            return
        end

        if url == "forever://questbrowse/inprogress" then
            ForeverBrowserQuestBrowseFilter = "inprogress"
            BuildQuestBrowsePage("")
            return
        end

        if url == "forever://questbrowse/completed" then
            ForeverBrowserQuestBrowseFilter = "completed"
            ForeverBrowserCompletedQuestPage = 1
            BuildQuestBrowsePage("")
            return
        end

        if string.sub(url,1,29) == "forever://questbrowse/search/" then
            ForeverBrowserQuestBrowseFilter = nil
            BuildQuestBrowsePage(string.sub(url,30))
            return
        end


        --------------------------------------------------
        -- NPC DATABASE / SEARCH
        --------------------------------------------------

        if url == "forever://npcs" then
            BuildNPCDatabasePage("")
            return
        end

        if url == "forever://npcs/recent" then

            BuildNPCDatabasePage("")

            return
        end

        if string.sub(
            url,
            1,
            15
        )
        == "forever://npcs/" then

            local searchText =
                string.sub(
                    url,
                    16
                )

            BuildNPCDatabasePage(
                searchText
            )

            return
        end


        --------------------------------------------------
        -- FARMING LIST / WISHLIST
        --------------------------------------------------

        if url == "forever://farming" then
            ForeverBrowserBuildFarmingListPage()
            return
        end

        --------------------------------------------------
        -- DUNGEON DATABASE
        --------------------------------------------------

        if url == "forever://dungeons" then
            ForeverBrowserBuildDungeonDatabasePage("")
            return
        end

        if string.sub(url, 1, 19) == "forever://dungeons/" then
            ForeverBrowserBuildDungeonDatabasePage(string.sub(url, 20))
            return
        end

        if string.sub(url, 1, 18) == "forever://dungeon/" then
            ForeverBrowserBuildDungeonPage(string.sub(url, 19))
            ForeverBrowser_C198Actions("dungeon",string.sub(url,19))
            return
        end

        if string.sub(url, 1, 22) == "forever://dungeonboss/" then
            local bossID = tonumber(string.sub(url, 23))
            if bossID then
                ForeverBrowserBuildDungeonBossLootPage(bossID)
            end
            return
        end


        --------------------------------------------------
        -- PROFESSION DATABASE
        --------------------------------------------------

        if url == "forever://professions" then
            BuildProfessionsPage()
            return
        end

        if string.sub(url, 1, 21) == "forever://profession/" then
            BuildProfessionPage(string.sub(url, 22))
            return
        end

        if string.sub(url, 1, 17) == "forever://recipe/" then
            local spellID = tonumber(string.sub(url, 18))
            if spellID then BuildRecipePage(spellID) ForeverBrowser_C198Actions("recipe",spellID) end
            return
        end

        --------------------------------------------------
        -- TALENT BUILDER
        --------------------------------------------------

        if url == "forever://talents" then
            if ForeverTalents and ForeverTalents.BuildHome then
                ForeverTalents.BuildHome({
                    PageContent=PageContent,
                    ClearPage=ClearPage,
                    Navigate=Navigate,
                })
            end
            return
        end

        if string.sub(url,1,18) == "forever://talents/" then
            if ForeverTalents and ForeverTalents.BuildClass then
                ForeverTalents.BuildClass({
                    PageContent=PageContent,
                    ClearPage=ClearPage,
                    Navigate=Navigate,
                },string.sub(url,19))
            end
            return
        end

        --------------------------------------------------
        -- BIS LISTS
        --------------------------------------------------

        if url == "forever://bis" then
            if ForeverBiS and ForeverBiS.BuildHome then
                ForeverBiS.BuildHome({
                    PageContent=PageContent,
                    ClearPage=ClearPage,
                    Navigate=Navigate,
                })
            end
            return
        end


        --------------------------------------------------
        -- SETTINGS
        --------------------------------------------------

        if url == "forever://settings" then
            ForeverBrowser_C201Settings()
            return
        end


        --------------------------------------------------
        -- SIDEBAR PAGES
        --------------------------------------------------

        if url == "forever://favorites" then
            BuildFavoritesPage()
            return
        end

        if url == "forever://recent" then
            BuildRecentPage()
            return
        end

        if url == "forever://tags" then
            BuildTagsPage()
            return
        end

        if url == "forever://debug" then
            BuildDebugPage()
            return
        end


        --------------------------------------------------
        -- CUSTOM LISTS
        --------------------------------------------------

        if url == "forever://lists" then

            BuildListsPage()
            return
        end

        if string.sub(
            url,
            1,
            20
        )
        == "forever://lists/add/" then

            local itemID =
                tonumber(
                    string.sub(
                        url,
                        21
                    )
                )

            if itemID then

                BuildAddToListPage(
                    itemID
                )
            end

            return
        end

        if string.sub(
            url,
            1,
            15
        )
        == "forever://list/" then

            local listName =
                string.sub(
                    url,
                    16
                )

            BuildListPage(
                listName
            )

            return
        end


        --------------------------------------------------
        -- COMPARE SELECT
        --------------------------------------------------

        if string.sub(
            url,
            1,
            25
        )
        == "forever://compare-select/" then

            local firstItemID =
                tonumber(
                    string.sub(
                        url,
                        26
                    )
                )

            if firstItemID then

                BuildCompareSelectPage(
                    firstItemID
                )

            end

            return
        end


        --------------------------------------------------
        -- COMPARE
        --------------------------------------------------

        if string.sub(
            url,
            1,
            18
        )
        == "forever://compare/" then

            local values =
                string.sub(
                    url,
                    19
                )

            local slash =
                string.find(
                    values,
                    "/",
                    1,
                    true
                )

            if slash then

                local firstItemID =
                    tonumber(
                        string.sub(
                            values,
                            1,
                            slash - 1
                        )
                    )

                local secondItemID =
                    tonumber(
                        string.sub(
                            values,
                            slash + 1
                        )
                    )

                if firstItemID
                    and secondItemID then

                    BuildComparePage(
                        firstItemID,
                        secondItemID
                    )

                end
            end

            return
        end


        --------------------------------------------------
        -- QUEST
        --------------------------------------------------

        if string.sub(
            url,
            1,
            16
        )
        == "forever://quest/" then

            local questID =
                tonumber(
                    string.sub(
                        url,
                        17
                    )
                )

            if questID then
                BuildQuestPage(
                    questID
                )
                ForeverBrowser_C198Actions("quest",questID)
            end

            return
        end


        --------------------------------------------------
        -- NPC
        --------------------------------------------------

        if string.sub(
            url,
            1,
            14
        )
        == "forever://npc/" then

            local npcID =
                tonumber(
                    string.sub(
                        url,
                        15
                    )
                )

            if npcID then
                BuildNPCPage(
                    npcID
                )
                ForeverBrowser_C198Actions("npc",npcID)
            end

            return
        end


        --------------------------------------------------
        -- ITEM
        --------------------------------------------------

        if string.sub(
            url,
            1,
            15
        )
        == "forever://item/" then

            local idText =
                string.sub(
                    url,
                    16
                )


            local itemID =
                tonumber(
                    idText
                )


            if itemID then

                BuildItemPage(
                    itemID
                )
                ForeverBrowser_C198Actions("item",itemID)

            end


            return

        end


        --------------------------------------------------
        -- CATEGORY
        --------------------------------------------------

        if string.sub(
            url,
            1,
            19
        )
        == "forever://category/" then

            local idText =
                string.sub(
                    url,
                    20
                )


            local categoryID =
                tonumber(
                    idText
                )


            if categoryID ~= nil then

                BuildCategoryPage(
                    categoryID
                )

            end


            return

        end


        --------------------------------------------------
        -- NORMAL TEXT
        --------------------------------------------------

        BuildSearchPage(
            url
        )

    end


--------------------------------------------------
-- SEARCH AUTOCOMPLETE
--------------------------------------------------

HideSearchSuggestions = function()

    if SuggestionFrame then
        SuggestionFrame:Hide()
    end
end


local function ShowSearchSuggestions(text)

    if not SuggestionFrame then
        return
    end

    text = tostring(text or "")

    if text == ""
        or string.sub(text, 1, 10) == "forever://" then
        HideSearchSuggestions()
        return
    end

    local search = string.lower(text)
    local numericSearch = tonumber(text)
    local matches = {}

    for id, item in pairs(GetWorldItems()) do

        local itemID = tonumber(id)

        if itemID and item then

            local name = GetItemField(
                item,
                "name",
                "Name",
                "itemName",
                "item_name"
            )

            name = CleanItemDisplayName(itemID, item, name)
            local lowerName = string.lower(name)
            local isMatch

            if numericSearch then
                isMatch = string.find(
                    tostring(itemID),
                    text,
                    1,
                    true
                ) ~= nil
            else
                isMatch = string.find(
                    lowerName,
                    search,
                    1,
                    true
                ) ~= nil
            end

            if isMatch then

                table.insert(matches, {
                    id = itemID,
                    name = name ~= "" and name or "Unknown Item",
                    item = item,
                    startsWith = not numericSearch
                        and string.sub(
                            lowerName,
                            1,
                            string.len(search)
                        ) == search,
                })

            end

        end

    end

    for id, item in pairs(GetPlayerItems()) do

        local itemID = tonumber(id)

        if itemID and item then

            local name = GetItemField(
                item,
                "name",
                "Name",
                "itemName",
                "item_name"
            )

            name = CleanItemDisplayName(itemID, item, name)
            local lowerName = string.lower(name)
            local isMatch

            if numericSearch then
                isMatch = string.find(
                    tostring(itemID),
                    text,
                    1,
                    true
                ) ~= nil
            else
                isMatch = string.find(
                    lowerName,
                    search,
                    1,
                    true
                ) ~= nil
            end

            if isMatch then

                local duplicate = false

                for _, existing in ipairs(matches) do
                    if existing.id == itemID then
                        duplicate = true
                        break
                    end
                end

                if not duplicate then

                    table.insert(matches, {
                        id = itemID,
                        name = name ~= "" and name or "Unknown Item",
                        item = item,
                        startsWith = not numericSearch
                            and string.sub(
                                lowerName,
                                1,
                                string.len(search)
                            ) == search,
                    })

                end

            end

        end

    end

    table.sort(matches, function(a, b)

        if a.startsWith ~= b.startsWith then
            return a.startsWith
        end

        local an = string.lower(a.name)
        local bn = string.lower(b.name)

        if an == bn then
            return a.id < b.id
        end

        return an < bn

    end)

    local count = math.min(#matches, 6)

    if count == 0 then
        HideSearchSuggestions()
        return
    end

    for i = 1, 6 do

        local button = SuggestionFrame.buttons[i]

        if i <= count then

            local match = matches[i]

            button.itemID = match.id
            button.itemData = match.item
            button:Show()

            button.icon:SetTexture(
                GetItemIcon(
                    match.id,
                    match.item
                )
            )

            button.name:SetText(match.name)

            button.id:SetText(
                "Item ID: " .. tostring(match.id)
            )

        else
            button:Hide()
        end

    end

    SuggestionFrame:SetHeight(
        count * 46 + 8
    )

    SuggestionFrame:Show()
end


local function CreateSearchSuggestions(parent)

    SuggestionFrame = CreateFrame(
        "Frame",
        nil,
        parent
    )

    SuggestionFrame:SetWidth(520)
    SuggestionFrame:SetHeight(8)

    SuggestionFrame:SetPoint(
        "TOPLEFT",
        AddressBox,
        "BOTTOMLEFT",
        0,
        -3
    )

    SuggestionFrame:SetFrameStrata("DIALOG")
    SuggestionFrame:SetFrameLevel(200)

    CreateSolidBackground(
        SuggestionFrame,
        0.015,
        0.02,
        0.035,
        0.98
    )

    SuggestionFrame.buttons = {}

    for i = 1, 6 do

        local button = CreateFrame(
            "Button",
            nil,
            SuggestionFrame
        )

        button:SetHeight(46)

        button:SetPoint(
            "TOPLEFT",
            SuggestionFrame,
            "TOPLEFT",
            4,
            -4 - ((i - 1) * 46)
        )

        button:SetPoint(
            "RIGHT",
            SuggestionFrame,
            "RIGHT",
            -4,
            0
        )

        CreateSolidBackground(
            button,
            0.032,
            0.024,
            0.016,
            0.92
        )

        button.icon = button:CreateTexture(
            nil,
            "ARTWORK"
        )

        button.icon:SetSize(34, 34)

        button.icon:SetPoint(
            "LEFT",
            button,
            "LEFT",
            6,
            0
        )

        button.name = CreateLabel(
            button,
            "",
            13,
            {
                1,
                0.82,
                0.25,
                1
            }
        )

        button.name:SetPoint(
            "TOPLEFT",
            button.icon,
            "TOPRIGHT",
            9,
            -1
        )

        button.id = CreateLabel(
            button,
            "",
            11,
            {
                0.55,
                0.58,
                0.65,
                1
            }
        )

        button.id:SetPoint(
            "BOTTOMLEFT",
            button.icon,
            "BOTTOMRIGHT",
            9,
            1
        )

        button:SetScript(
            "OnEnter",
            function(self)

                self.highlight = CreateSolidBackground(
                    self,
                    0.08,
                    0.11,
                    0.18,
                    1
                )

            end
        )

        button:SetScript(
            "OnLeave",
            function(self)

                if self.highlight then
                    self.highlight:Hide()
                    self.highlight = nil
                end

            end
        )

        button:SetScript(
            "OnClick",
            function(self)

                if self.itemID then

                    HideSearchSuggestions()

                    if IsShiftLinkClick() then

                        LinkItemToChat(
                            self.itemID
                        )

                        return
                    end

                    Navigate(
                        "forever://item/"
                        .. tostring(self.itemID)
                    )

                end

            end
        )

        SuggestionFrame.buttons[i] = button

    end

    SuggestionFrame:Hide()
end


--------------------------------------------------
-- BROWSER FRAME
--------------------------------------------------


--------------------------------------------------
-- PAGE VISUAL IDENTITY
--------------------------------------------------

local function AddPageIdentity(parent, pageType, titleText, subtitleText, y)
    local iconPath = WOW_PAGE_ICONS[pageType] or WOW_PAGE_ICONS.home
    return CreateWoWBanner(
        parent,
        titleText or "Forever Database",
        subtitleText or "",
        iconPath,
        y or -12
    )
end


local function CreateBrowser()
    CopyThemeIntoActive(LoadForeverTheme())


    if BrowserFrame then
        return
    end


    --------------------------------------------------
    -- MAIN FRAME
    --------------------------------------------------

    BrowserFrame =
        CreateFrame(
            "Frame",
            "ForeverBrowser",
            UIParent
        )


    BrowserFrame:SetSize(
        1080,
        650
    )


    BrowserFrame:SetPoint(
        "CENTER"
    )


    BrowserFrame:SetFrameStrata(
        "DIALOG"
    )


    BrowserFrame:SetFrameLevel(
        100
    )


    BrowserFrame:SetMovable(
        true
    )


    BrowserFrame:EnableMouse(
        true
    )


    BrowserFrame:SetClampedToScreen(
        true
    )


    --------------------------------------------------
    -- ACHIEVEMENTS TAB - ATTACHED TO BROWSER
    --------------------------------------------------

    --------------------------------------------------
    -- MAIN BACKGROUND
    --------------------------------------------------

    AddWoWPanelTexture(BrowserFrame, 0.98)
    AddWoWBorder(BrowserFrame, 2, 1)
    AddWoWCornerOrnaments(BrowserFrame)

    local innerFrame = CreateFrame("Frame", nil, BrowserFrame)
    innerFrame:SetPoint("TOPLEFT", BrowserFrame, "TOPLEFT", 5, -5)
    innerFrame:SetPoint("BOTTOMRIGHT", BrowserFrame, "BOTTOMRIGHT", -5, 5)
    innerFrame:EnableMouse(false)
    AddWoWBorder(innerFrame, 1, 0.45)


    --------------------------------------------------
    -- TITLE BAR
    --------------------------------------------------

    local titleBar =
        CreateFrame(
            "Frame",
            nil,
            BrowserFrame
        )


    titleBar:SetHeight(
        36
    )


    titleBar:SetPoint(
        "TOPLEFT",
        BrowserFrame,
        "TOPLEFT",
        0,
        0
    )


    titleBar:SetPoint(
        "TOPRIGHT",
        BrowserFrame,
        "TOPRIGHT",
        0,
        0
    )


    local tc=WOW_THEME.title or {0.040,0.026,0.016,1}
    local titleBG=CreateSolidBackground(
        titleBar,tc[1],tc[2],tc[3],tc[4] or 1
    )
    ThemeColor(titleBG,"title")
    AddWoWBorder(titleBar, 1)


    AddWoWSoftGlow(titleBar, "CENTER", titleBar, "CENTER", 0, 0, 430, 28)

    local title =
        CreateLabel(
            titleBar,
            "ForeverBrowser  |cffc79a3b•|r  Azeroth Database",
            15,
            {
                1,
                0.82,
                0.25,
                1
            }
        )


    title:SetPoint(
        "CENTER",
        titleBar,
        "CENTER",
        0,
        0
    )

    AddWoWHeaderAccent(titleBar, title, 115)

    local titleEmblem = titleBar:CreateTexture(nil, "OVERLAY")
    titleEmblem:SetTexture(WOW_THEME.icon or "Interface\\Icons\\INV_Misc_Book_09")
    RegisterThemeVisual("icon", titleEmblem)
    titleEmblem:SetSize(22, 22)
    titleEmblem:SetPoint("LEFT", titleBar, "LEFT", 12, 0)
    AddWoWIconFrame(titleBar, titleEmblem, 22)

    local titleEmblemRight = titleBar:CreateTexture(nil, "OVERLAY")
    titleEmblemRight:SetTexture(WOW_THEME.icon or "Interface\\Icons\\INV_Misc_Book_09")
    RegisterThemeVisual("icon", titleEmblemRight)
    titleEmblemRight:SetSize(22, 22)
    titleEmblemRight:SetPoint("RIGHT", titleBar, "RIGHT", -202, 0)
    AddWoWIconFrame(titleBar, titleEmblemRight, 22)


    --------------------------------------------------
    -- THEME SELECTOR
    --------------------------------------------------
    local ThemeButton = CreateFrame("Button", nil, titleBar)
    ThemeButton:SetSize(150, 24)
    ThemeButton:SetPoint("RIGHT", titleBar, "RIGHT", -42, 0)
    ThemeButton:SetFrameStrata("DIALOG")
    ThemeButton:SetFrameLevel(titleBar:GetFrameLevel() + 10)
    local thbc=WOW_THEME.button or {0.025,0.020,0.016,0.98}
    ThemeButton.bg = CreateSolidBackground(ThemeButton,thbc[1],thbc[2],thbc[3],thbc[4] or 0.98)
    ThemeColor(ThemeButton.bg,"button")
    AddWoWBorder(ThemeButton,1,0.85)

    local ThemeButtonText = CreateLabel(ThemeButton, "THEME", 11, WOW_THEME.gold)
    ThemeButtonText:SetPoint("LEFT",ThemeButton,"LEFT",8,0)

    local ThemeArrow = CreateLabel(ThemeButton, "v", 11, WOW_THEME.goldSoft)
    ThemeArrow:SetPoint("RIGHT",ThemeButton,"RIGHT",-8,0)

    local ThemeMenu = CreateFrame("Frame", nil, BrowserFrame)
    ThemeMenu:SetSize(184, #FOREVER_THEME_ORDER*27 + 12)
    ThemeMenu:SetPoint("TOPRIGHT", ThemeButton, "BOTTOMRIGHT", 0, -3)
    ThemeMenu:SetFrameStrata("TOOLTIP")
    ThemeMenu:SetFrameLevel(BrowserFrame:GetFrameLevel() + 50)
    ThemeMenu:Hide()
    local tmic=WOW_THEME.inset or {0.012,0.010,0.009,0.99}
    local themeMenuBG=CreateSolidBackground(ThemeMenu,tmic[1],tmic[2],tmic[3],tmic[4] or 0.99)
    ThemeColor(themeMenuBG,"inset")
    AddWoWBorder(ThemeMenu,1,0.95)

    local function RefreshThemeButton()
        local t=FOREVER_THEMES[ForeverBrowserTheme.GetName()] or FOREVER_THEMES.Classic
        ThemeButtonText:SetText("THEME: "..(t.displayName or ForeverBrowserTheme.GetName()))
        ThemeButtonText:SetTextColor(t.gold[1],t.gold[2],t.gold[3],1)
        ThemeArrow:SetTextColor(t.goldSoft[1],t.goldSoft[2],t.goldSoft[3],1)
    end

    ForeverBrowserRefreshThemeButton222=RefreshThemeButton
    ApplyForeverTheme = function(themeName)
        ForeverBrowserTheme.Apply(themeName,RefreshThemeButton,function()
            if CurrentURL and Navigate then Navigate(CurrentURL,true) end
            if ForeverBrowserCodexTracker200 and ForeverBrowserCodexTracker200:IsShown() then ForeverBrowser_C200TrackerRefresh() end
        end)
    end

    for i,themeName in ipairs(FOREVER_THEME_ORDER) do
        local theme=FOREVER_THEMES[themeName]
        local row=CreateFrame("Button",nil,ThemeMenu)
        row:SetSize(172,24)
        row:SetPoint("TOPLEFT",ThemeMenu,"TOPLEFT",6,-6-((i-1)*27))
        local trc=WOW_THEME.row or {0.025,0.020,0.016,0.96}
        row.bg=CreateSolidBackground(row,trc[1],trc[2],trc[3],trc[4] or 0.96)
        ThemeColor(row.bg,"row")

        local swatch=row:CreateTexture(nil,"ARTWORK")
        swatch:SetTexture("Interface\\\\Buttons\\\\WHITE8X8")
        swatch:SetSize(12,12)
        swatch:SetPoint("LEFT",row,"LEFT",7,0)
        swatch:SetVertexColor(theme.accent[1],theme.accent[2],theme.accent[3],1)

        local label=CreateLabel(row,theme.displayName,11,theme.ivory)
        label:SetPoint("LEFT",row,"LEFT",25,0)

        row:SetScript("OnEnter",function(self)
            self.bg:SetVertexColor(theme.hover[1],theme.hover[2],theme.hover[3],1)
        end)
        row:SetScript("OnLeave",function(self)
            local c=WOW_THEME.row or {0.025,0.020,0.016,0.96}
            self.bg:SetVertexColor(c[1],c[2],c[3],c[4] or 0.96)
        end)
        row:SetScript("OnClick",function()
            ApplyForeverTheme(themeName)
            ThemeMenu:Hide()
        end)
    end

    ThemeButton:SetScript("OnClick",function()
        if ThemeMenu:IsShown() then ThemeMenu:Hide() else ThemeMenu:Show() end
    end)
    ThemeButton:SetScript("OnEnter",function(self)
        self.bg:SetVertexColor(WOW_THEME.hover[1],WOW_THEME.hover[2],WOW_THEME.hover[3],1)
    end)
    ThemeButton:SetScript("OnLeave",function(self)
        local c=WOW_THEME.button or {0.025,0.020,0.016,0.98}
        self.bg:SetVertexColor(c[1],c[2],c[3],c[4] or 0.98)
    end)

    RefreshThemeButton()

    local ThemeIdentityIcon=titleBar:CreateTexture(nil,"OVERLAY")
    ThemeIdentityIcon:SetTexture((FOREVER_THEMES[ForeverBrowserTheme.GetName()] or FOREVER_THEMES.Classic).icon)
    ThemeIdentityIcon:SetSize(20,20)
    ThemeIdentityIcon:SetPoint("RIGHT",ThemeButton,"LEFT",-7,0)
    RegisterThemeVisual("icon",ThemeIdentityIcon)

    local titleRule = titleBar:CreateTexture(nil, "ARTWORK")
    titleRule:SetTexture("Interface\\Buttons\\WHITE8X8")
    titleRule:SetVertexColor(0.62, 0.43, 0.12, 0.75)
    titleRule:SetHeight(1)
    titleRule:SetPoint("BOTTOMLEFT", titleBar, "BOTTOMLEFT", 8, 0)
    titleRule:SetPoint("BOTTOMRIGHT", titleBar, "BOTTOMRIGHT", -8, 0)


    titleBar:EnableMouse(
        true
    )


    titleBar:SetScript(
        "OnMouseDown",
        function()

            BrowserFrame:StartMoving()

        end
    )


    titleBar:SetScript(
        "OnMouseUp",
        function()

            BrowserFrame:StopMovingOrSizing()

        end
    )


    --------------------------------------------------
    -- CLOSE
    --------------------------------------------------

    local close =
        CreateButton(
            titleBar,
            "X",
            32,
            28
        )


    close:SetPoint(
        "RIGHT",
        titleBar,
        "RIGHT",
        -4,
        0
    )


    close:SetScript(
        "OnClick",
        function()

            BrowserFrame:Hide()

-- Do not inspect native GameTooltip text here.
-- Some clients protect tooltip text as secret values.

        end
    )


    --------------------------------------------------
    -- TOOLBAR
    --------------------------------------------------

    local toolbar =
        CreateFrame(
            "Frame",
            nil,
            BrowserFrame
        )


    toolbar:SetHeight(
        42
    )


    toolbar:SetPoint(
        "TOPLEFT",
        titleBar,
        "BOTTOMLEFT",
        0,
        0
    )


    toolbar:SetPoint(
        "TOPRIGHT",
        titleBar,
        "BOTTOMRIGHT",
        0,
        0
    )


    local tbc=WOW_THEME.toolbar or {0.020,0.016,0.012,0.98}
    local toolbarBG=CreateSolidBackground(
        toolbar,tbc[1],tbc[2],tbc[3],tbc[4] or 0.98
    )
    ThemeColor(toolbarBG,"toolbar")
    AddWoWBorder(toolbar, 1)


    --------------------------------------------------
    -- BACK
    --------------------------------------------------

    local back =
        CreateButton(
            toolbar,
            "<",
            32,
            30
        )


    back:SetPoint(
        "LEFT",
        toolbar,
        "LEFT",
        6,
        0
    )


    back:SetScript(
        "OnClick",
        function()

            if HistoryPosition > 1 then

                HistoryPosition =
                    HistoryPosition - 1


                local previous =
                    History[
                        HistoryPosition
                    ]


                Navigate(
                    previous,
                    true
                )

            end

        end
    )


    --------------------------------------------------
    -- FORWARD
    --------------------------------------------------

    local forward =
        CreateButton(
            toolbar,
            ">",
            32,
            30
        )


    ForeverBrowserNavigationBack226=back
    ForeverBrowserNavigationForward226=forward

    forward:SetPoint(
        "LEFT",
        back,
        "RIGHT",
        4,
        0
    )


    forward:SetScript(
        "OnClick",
        function()

            if HistoryPosition
                < #History then

                HistoryPosition =
                    HistoryPosition + 1


                local nextURL =
                    History[
                        HistoryPosition
                    ]


                Navigate(
                    nextURL,
                    true
                )

            end

        end
    )


    --------------------------------------------------
    -- HOME
    --------------------------------------------------

    local home =
        CreateButton(
            toolbar,
            "HOME",
            52,
            30
        )


    home:SetPoint(
        "LEFT",
        forward,
        "RIGHT",
        4,
        0
    )


    home:SetScript(
        "OnClick",
        function()

            Navigate(
                "forever://home"
            )

        end
    )


    --------------------------------------------------
    -- REFRESH
    --------------------------------------------------

    local refresh =
        CreateButton(
            toolbar,
            "R",
            32,
            30
        )


    refresh:SetPoint(
        "LEFT",
        home,
        "RIGHT",
        4,
        0
    )


    refresh:SetScript(
        "OnClick",
        function()

            Navigate(
                CurrentURL,
                true
            )

        end
    )


    --------------------------------------------------
    -- ADDRESS BOX
    --------------------------------------------------

    AddressBox =
        CreateFrame(
            "EditBox",
            nil,
            toolbar
        )


    AddressBox:SetHeight(
        30
    )


    AddressBox:SetPoint(
        "LEFT",
        refresh,
        "RIGHT",
        8,
        0
    )


    AddressBox:SetPoint(
        "RIGHT",
        toolbar,
        "RIGHT",
        -8,
        0
    )



    AddressBox:SetAutoFocus(
        false
    )


    AddressBox:SetFontObject(
        "GameFontHighlight"
    )


    AddressBox:SetText(
        "forever://home"
    )


    AddressBox:SetTextInsets(
        10,
        10,
        0,
        0
    )


    local ac=WOW_THEME.inset or {0.012,0.010,0.008,1}
    local addressBG=CreateSolidBackground(
        AddressBox,ac[1],ac[2],ac[3],ac[4] or 1
    )
    ThemeColor(addressBG,"inset")
    AddWoWBorder(AddressBox, 1, 0.70)

    local addressInner = AddressBox:CreateTexture(nil, "ARTWORK")
    addressInner:SetTexture("Interface\\Buttons\\WHITE8X8")
    addressInner:SetVertexColor(0.20, 0.14, 0.06, 0.20)
    addressInner:SetPoint("TOPLEFT", AddressBox, "TOPLEFT", 2, -2)
    addressInner:SetPoint("BOTTOMRIGHT", AddressBox, "BOTTOMRIGHT", -2, 2)
    if AddressBox.SetTextColor then
        AddressBox:SetTextColor(0.92, 0.82, 0.62, 1)
    end


    AddressBox:SetScript(
        "OnEnterPressed",
        function(self)

            local text =
                self:GetText()


            if text == "" then

                return

            end


            if string.sub(
                text,
                1,
                10
            )
            ~= "forever://" then

                text =
                    "forever://search/"
                    .. text

            end


            HideSearchSuggestions()

            Navigate(
                text
            )


            self:ClearFocus()

        end
    )


    AddressBox:SetScript(
        "OnTextChanged",
        function(self)
            ShowSearchSuggestions(
                self:GetText()
            )
        end
    )


    AddressBox:SetScript(
        "OnEscapePressed",
        function(self)
            HideSearchSuggestions()
            self:ClearFocus()
        end
    )


    CreateSearchSuggestions(
        BrowserFrame
    )


    --------------------------------------------------
    -- NAVIGATION SIDEBAR
    --------------------------------------------------

    NavigationFrame = CreateFrame("Frame", nil, BrowserFrame)
    NavigationFrame:SetWidth(180)
    NavigationFrame:SetPoint("TOPLEFT", toolbar, "BOTTOMLEFT", 10, -10)
    NavigationFrame:SetPoint("BOTTOMLEFT", BrowserFrame, "BOTTOMLEFT", 10, 10)

    AddWoWInset(NavigationFrame)

    local navSeal = NavigationFrame:CreateTexture(nil, "ARTWORK")
    navSeal:SetTexture(WOW_THEME.icon or "Interface\\Icons\\INV_Misc_Book_09")
    RegisterThemeVisual("icon", navSeal)
    navSeal:SetSize(28, 28)
    navSeal:SetPoint("BOTTOM", NavigationFrame, "BOTTOM", 0, 13)
    navSeal:SetAlpha(0.30)

    local navSealRing = NavigationFrame:CreateTexture(nil, "OVERLAY")
    navSealRing:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    navSealRing:SetSize(42, 42)
    navSealRing:SetPoint("CENTER", navSeal, "CENTER", 0, 0)
    navSealRing:SetVertexColor(0.72, 0.52, 0.18, 0.34)

    local navHeader =
        CreateLabel(
            NavigationFrame,
            "FOREVER DATABASE",
            13,
            {1, 0.82, 0.25, 1}
        )

    navHeader:SetPoint("TOP", NavigationFrame, "TOP", 8, -15)

    local navEmblem = NavigationFrame:CreateTexture(nil, "OVERLAY")
    navEmblem:SetTexture(WOW_THEME.icon or "Interface\\Icons\\INV_Misc_Book_09")
    RegisterThemeVisual("icon", navEmblem)
    navEmblem:SetSize(20, 20)
    navEmblem:SetPoint("RIGHT", navHeader, "LEFT", -7, 0)
    AddWoWIconFrame(NavigationFrame, navEmblem, 20)

    AddWoWDivider(NavigationFrame, 12, 12, -38)

    --------------------------------------------------
    -- COLLAPSIBLE NAVIGATION
    --------------------------------------------------

    local itemMenuOpen = false
    local questMenuOpen = false
    local npcMenuOpen = false
    local dungeonMenuOpen = false

    local function MakeNav(key, textValue, iconPath, url, child)
        local b = CreateFrame("Button", nil, NavigationFrame)
        b:SetSize(child and 146 or 156, child and 34 or 42)
        local bg = CreateSolidBackground(
            b,
            child and 0.040 or 0.065,
            child and 0.028 or 0.038,
            child and 0.018 or 0.020,
            1
        )
        local icon = b:CreateTexture(nil, "ARTWORK")
        icon:SetSize(child and 20 or 25, child and 20 or 25)
        icon:SetPoint("LEFT", b, "LEFT", child and 14 or 8, 0)
        icon:SetTexture(iconPath)

        local label = CreateLabel(
            b,
            textValue,
            child and 11 or 12,
            child and {0.68,0.64,0.56,1} or {0.90,0.78,0.50,1}
        )
        label:SetPoint("LEFT", icon, "RIGHT", 9, 0)

        b.navBackground = bg
        b.navLabel = label
        b.navKey = key
        b.navChild = child

        b:SetScript("OnEnter", function(self)
            if self.navKey ~= NavigationFrame.activeKey then
                self.navBackground:SetVertexColor(unpack(WOW_THEME.hover))
            end
        end)

        b:SetScript("OnLeave", function(self)
            if self.navKey ~= NavigationFrame.activeKey then
                if self.navChild then
                    self.navBackground:SetVertexColor(unpack(WOW_THEME.inset))
                else
                    self.navBackground:SetVertexColor(unpack(WOW_THEME.row))
                end
            end
        end)

        if url then
            b:SetScript("OnClick", function() Navigate(url) end)
        end

        ForeverBrowser_AchievementBorder(b,true)
        if key then NavigationButtons[key] = b end
        return b
    end

    local toolsButton=CreateButton(BrowserFrame,"CODEX TOOLS",135,24)
    toolsButton:SetPoint("TOPRIGHT",BrowserFrame,"BOTTOMRIGHT",-426,-6)
    toolsButton:SetScript("OnClick",function() Navigate("forever://codex") end)

    local homeButton = MakeNav("home","HOME","Interface\\Icons\\INV_Misc_Book_09","forever://home",false)
    local itemHeader = MakeNav(nil,"ITEM DATABASE","Interface\\Icons\\INV_Misc_Spyglass_03",nil,false)
    local itemArrow = CreateLabel(itemHeader, ">", 14, {1,0.82,0.25,1})
    itemArrow:SetPoint("RIGHT", itemHeader, "RIGHT", -10, 0)

    local itemChildren = {
        MakeNav("browse","BROWSE ITEMS","Interface\\Icons\\INV_Misc_Spyglass_03","forever://search/",true),
        MakeNav("favorites","FAVORITES","Interface\\COMMON\\ReputationStar","forever://favorites",true),
        MakeNav("recent","RECENT ITEMS","Interface\\Icons\\INV_Misc_PocketWatch_01","forever://recent",true),
        MakeNav("lists","MY LISTS","Interface\\Icons\\INV_Misc_Note_05","forever://lists",true),
        MakeNav("tags","TAGS & NOTES","Interface\\Icons\\INV_Inscription_Scroll","forever://tags",true)
    }

    local questHeader = MakeNav(nil,"QUEST DATABASE","Interface\\Icons\\INV_Misc_Note_01",nil,false)
    local questArrow = CreateLabel(questHeader, ">", 14, {1,0.82,0.25,1})
    questArrow:SetPoint("RIGHT", questHeader, "RIGHT", -10, 0)

    local questChildren = {
        MakeNav("quests","SEARCH QUESTS","Interface\\Icons\\INV_Misc_Note_01","forever://questbrowse",true)
    }

    local npcHeader = MakeNav("npc_home","NPC DATABASE","Interface\\Icons\\Ability_Hunter_BeastCall",nil,false)
    local npcArrow = CreateLabel(npcHeader, ">", 14, {1,0.82,0.25,1})
    npcArrow:SetPoint("RIGHT", npcHeader, "RIGHT", -10, 0)

    local npcChildren = {
        MakeNav("npcs","SEARCH NPCS","Interface\\Icons\\Ability_Hunter_BeastCall","forever://npcs/",true),
        MakeNav("npcs_recent","RECENT SEARCHES","Interface\\Icons\\INV_Misc_Note_05","forever://npcs/recent",true)
    }

    local professionButton = MakeNav("professions","PROFESSIONS","Interface\\Icons\\Trade_Engineering","forever://professions",false)

    local dungeonHeader = MakeNav("dungeons_header","DUNGEONS","Interface\\Icons\\INV_Misc_Map_01",nil,false)
    local dungeonArrow = CreateLabel(dungeonHeader, ">", 14, {1,0.82,0.25,1})
    dungeonArrow:SetPoint("RIGHT", dungeonHeader, "RIGHT", -10, 0)

    local dungeonChildren = {
        MakeNav("dungeons","DUNGEON DATABASE","Interface\\Icons\\INV_Misc_Map_01","forever://dungeons",true),
        MakeNav("farming","FARMING LIST","Interface\\Icons\\INV_Misc_Bag_10","forever://farming",true)
    }

    local settingsButton = MakeNav("settings","SETTINGS","Interface\\Icons\\INV_Gizmo_02","forever://settings",false)
    MakeNav("updates","CHECK FOR UPDATES","Interface\\Icons\\INV_Misc_PocketWatch_01","forever://codex/updates",false)
    local debugButton = MakeNav("debug","DEBUG","Interface\\Icons\\INV_Gizmo_02","forever://debug",false)

    -- Utility tabs: hang directly UNDER the bottom-right edge of the addon.
    -- DEBUG, SETTINGS, CHECK FOR UPDATES and CODEX TOOLS share one anchored row.
    debugButton:ClearAllPoints()
    debugButton:SetWidth(92)
    debugButton:SetPoint("TOPRIGHT", BrowserFrame, "BOTTOMRIGHT", -10, -6)

    settingsButton:ClearAllPoints()
    settingsButton:SetWidth(108)
    settingsButton:SetPoint("RIGHT", debugButton, "LEFT", -6, 0)

    NavigationButtons.updates:ClearAllPoints()
    NavigationButtons.updates:SetWidth(190)
    NavigationButtons.updates:SetPoint("RIGHT",settingsButton,"LEFT",-6,0)
    toolsButton:ClearAllPoints()
    toolsButton:SetPoint("RIGHT",NavigationButtons.updates,"LEFT",-6,0)

    local divider = NavigationFrame:CreateTexture(nil, "ARTWORK")
    divider:SetTexture("Interface\\Buttons\\WHITE8X8")
    divider:SetVertexColor(0.35,0.28,0.10,0.75)
    divider:SetHeight(1)

    local tip = CreateLabel(NavigationFrame, "TIP", 12, {1,0.82,0.25,1})
    local tipText = CreateLabel(NavigationFrame, "Shift-click an item to link it in chat.", 11, {0.55,0.58,0.65,1})
    tipText:SetWidth(140)
    tipText:SetJustifyH("LEFT")

    local function ShowChildren(list, shown)
        for _, b in ipairs(list) do
            if shown then b:Show() else b:Hide() end
        end
    end

    local function LayoutNav()
        local y = -42
        local function Place(b, child)
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", NavigationFrame, "TOPLEFT", child and 22 or 12, y)
            y = y - (child and 38 or 47)
        end

        Place(homeButton,false)
        Place(itemHeader,false)
        if itemMenuOpen then
            for _,b in ipairs(itemChildren) do Place(b,true) end
        end
        Place(questHeader,false)
        if questMenuOpen then
            for _,b in ipairs(questChildren) do Place(b,true) end
        end
        Place(npcHeader,false)
        if npcMenuOpen then
            for _,b in ipairs(npcChildren) do Place(b,true) end
        end
        y = y - 5
        Place(professionButton,false)
        Place(dungeonHeader,false)
        if dungeonMenuOpen then
            for _,b in ipairs(dungeonChildren) do Place(b,true) end
        end

        divider:ClearAllPoints()
        divider:SetPoint("TOPLEFT",NavigationFrame,"TOPLEFT",12,y-3)
        divider:SetPoint("TOPRIGHT",NavigationFrame,"TOPRIGHT",-12,y-3)

        tip:ClearAllPoints()
        tip:SetPoint("TOPLEFT",divider,"BOTTOMLEFT",2,-16)
        tipText:ClearAllPoints()
        tipText:SetPoint("TOPLEFT",tip,"BOTTOMLEFT",0,-7)
    end

    itemHeader:SetScript("OnClick", function()
        Navigate("forever://items")
        itemMenuOpen = not itemMenuOpen
        if itemMenuOpen then
            questMenuOpen = false
            npcMenuOpen = false
        end
        itemArrow:SetText(itemMenuOpen and "v" or ">")
        questArrow:SetText(questMenuOpen and "v" or ">")
        npcArrow:SetText(npcMenuOpen and "v" or ">")
        ShowChildren(itemChildren,itemMenuOpen)
        ShowChildren(questChildren,questMenuOpen)
        ShowChildren(npcChildren,npcMenuOpen)
        LayoutNav()
    end)

    questHeader:SetScript("OnClick", function()
            Navigate("forever://quests")
        questMenuOpen = not questMenuOpen
        if questMenuOpen then
            itemMenuOpen = false
            npcMenuOpen = false
        end
        itemArrow:SetText(itemMenuOpen and "v" or ">")
        questArrow:SetText(questMenuOpen and "v" or ">")
        npcArrow:SetText(npcMenuOpen and "v" or ">")
        ShowChildren(itemChildren,itemMenuOpen)
        ShowChildren(questChildren,questMenuOpen)
        ShowChildren(npcChildren,npcMenuOpen)
        LayoutNav()
    end)

    npcHeader:SetScript("OnClick", function()
        Navigate("forever://npcdatabase")
        npcMenuOpen = not npcMenuOpen
        if npcMenuOpen then
            itemMenuOpen = false
            questMenuOpen = false
        end
        itemArrow:SetText(itemMenuOpen and "v" or ">")
        questArrow:SetText(questMenuOpen and "v" or ">")
        npcArrow:SetText(npcMenuOpen and "v" or ">")
        ShowChildren(itemChildren,itemMenuOpen)
        ShowChildren(questChildren,questMenuOpen)
        ShowChildren(npcChildren,npcMenuOpen)
        LayoutNav()
    end)

    dungeonHeader:SetScript("OnClick", function()
        dungeonMenuOpen = not dungeonMenuOpen
        if dungeonMenuOpen then
            itemMenuOpen = false
            questMenuOpen = false
            npcMenuOpen = false
        end
        itemArrow:SetText(itemMenuOpen and "v" or ">")
        questArrow:SetText(questMenuOpen and "v" or ">")
        npcArrow:SetText(npcMenuOpen and "v" or ">")
        dungeonArrow:SetText(dungeonMenuOpen and "v" or ">")
        ShowChildren(itemChildren,itemMenuOpen)
        ShowChildren(questChildren,questMenuOpen)
        ShowChildren(npcChildren,npcMenuOpen)
        ShowChildren(dungeonChildren,dungeonMenuOpen)
        LayoutNav()
    end)

    ShowChildren(itemChildren,false)
    ShowChildren(questChildren,false)
    ShowChildren(npcChildren,false)
    ShowChildren(dungeonChildren,false)
    LayoutNav()

    --------------------------------------------------
    -- TOOLS: RIGHT-SIDE FEATURE LIST
    --------------------------------------------------
    local toolsHeader=CreateFrame("Frame",nil,BrowserFrame)
    toolsHeader:SetSize(156,28)
    toolsHeader:SetPoint("TOPLEFT",BrowserFrame,"TOPRIGHT",12,-111)
    local toolsBG=toolsHeader:CreateTexture(nil,"BACKGROUND")
    toolsBG:SetAllPoints(toolsHeader)
    toolsBG:SetTexture("Interface\\Buttons\\WHITE8X8")
    toolsBG:SetVertexColor(0.07,0.052,0.024,0.97)
    if AddWoWBorder then AddWoWBorder(toolsHeader,1,0.82) end
    local toolsLabel=toolsHeader:CreateFontString(nil,"OVERLAY","GameFontNormal")
    toolsLabel:SetPoint("CENTER",toolsHeader,"CENTER",0,0)
    toolsLabel:SetText("TOOLS")

    local function CreateRightFeatureTab(text,iconPath,url,yOffset,coming)
        local button=CreateFrame("Button",nil,BrowserFrame)
        button:SetSize(156,44)
        button:SetPoint("TOPLEFT",BrowserFrame,"TOPRIGHT",12,yOffset)
        local bg=button:CreateTexture(nil,"BACKGROUND")
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetAllPoints(button)
        bg:SetVertexColor(0.025,0.02,0.015,0.98)
        if AddWoWBorder then AddWoWBorder(button,1,0.82) end
        local icon=button:CreateTexture(nil,"ARTWORK")
        icon:SetSize(28,28)
        icon:SetPoint("LEFT",button,"LEFT",9,0)
        icon:SetTexture(iconPath)
        local label=button:CreateFontString(nil,"OVERLAY","GameFontNormal")
        label:SetPoint("LEFT",icon,"RIGHT",8,7)
        label:SetPoint("RIGHT",button,"RIGHT",-6,7)
        label:SetJustifyH("LEFT")
        label:SetText(text)
        label:SetTextColor(coming and 0.78 or 1,coming and 0.70 or 0.82,0.48,1)
        local status=button:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        status:SetPoint("LEFT",icon,"RIGHT",8,-10)
        status:SetPoint("RIGHT",button,"RIGHT",-6,-10)
        status:SetJustifyH("LEFT")
        status:SetText(coming and "COMING SOON" or "OPEN TOOL")
        status:SetTextColor(coming and 0.55 or 0.35,coming and 0.55 or 0.83,coming and 0.55 or 0.55,1)
        icon:SetAlpha(coming and 0.62 or 1)
        button:SetScript("OnClick",function()
            if not coming then Navigate(url) end
        end)
        button:SetScript("OnEnter",function()
            bg:SetVertexColor(0.055,0.045,0.030,1)
        end)
        button:SetScript("OnLeave",function()
            bg:SetVertexColor(0.025,0.02,0.015,0.98)
        end)
        return button
    end

    local talentFeatureTab=CreateRightFeatureTab(
        "TALENT BUILDER","Interface\\Icons\\Spell_Holy_MagicalSentry",
        "forever://talents",-146,false)
    local bisFeatureTab=CreateRightFeatureTab(
        "BIS LISTS","Interface\\Icons\\INV_Chest_Plate04",
        "forever://bis",-196,true)

    --------------------------------------------------
    -- SCROLL FRAME
    --------------------------------------------------

    ScrollFrame =
        CreateFrame(
            "ScrollFrame",
            nil,
            BrowserFrame
        )


    ScrollFrame:SetPoint(
        "TOPLEFT",
        NavigationFrame,
        "TOPRIGHT",
        10,
        0
    )


    ScrollFrame:SetPoint(
        "BOTTOMRIGHT",
        BrowserFrame,
        "BOTTOMRIGHT",
        -10,
        10
    )

    AddWoWInset(ScrollFrame)

    -- The old content-pane ornament was removed so the welcome artwork
    -- can meet the interface cleanly without a floating bar/icon over it.

    ScrollFrame:EnableMouseWheel(
        true
    )


    ScrollFrame:SetScript(
        "OnMouseWheel",
        function(
            self,
            delta
        )

            local current =
                self:GetVerticalScroll()


            local maximum =
                self:GetVerticalScrollRange()


            local newValue =
                current
                - delta * 60


            if newValue < 0 then
                newValue = 0
            end


            if newValue > maximum then
                newValue = maximum
            end


            self:SetVerticalScroll(
                newValue
            )

        end
    )


    --------------------------------------------------
    -- PAGE CONTENT
    --------------------------------------------------

    PageContent =
        CreateFrame(
            "Frame",
            nil,
            ScrollFrame
        )


    PageContent:SetWidth(
        840
    )


    PageContent:SetHeight(
        600
    )

    local pageBackdrop = PageContent:CreateTexture(nil, "BACKGROUND")
    pageBackdrop:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    pageBackdrop:SetVertexColor(0.13, 0.09, 0.045, 0.20)


    -- Persistent, low-key watermark gives the content pane a Warcraft codex feel.
    local pageWatermark = PageContent:CreateTexture(nil, "BACKGROUND")
    pageWatermark:SetTexture(WOW_THEME.icon or "Interface\\Icons\\INV_Misc_Book_09")
    RegisterThemeVisual("icon", pageWatermark)
    pageWatermark:SetSize(150, 150)
    pageWatermark:SetPoint("TOPRIGHT", PageContent, "TOPRIGHT", -28, -30)
    local wc=WOW_THEME.watermark or {0.72,0.52,0.18,0.025}
    pageWatermark:SetVertexColor(wc[1],wc[2],wc[3],1)
    pageWatermark:SetAlpha(wc[4] or 0.025)
    ThemeColor(pageWatermark,"watermark")


    --------------------------------------------------
    -- ACTIVE THEME ARTWORK
    --------------------------------------------------
    local activeTheme=FOREVER_THEMES[ForeverBrowserTheme.GetName()] or FOREVER_THEMES.Classic

    local themeArtLeft=PageContent:CreateTexture(nil,"BACKGROUND")
    themeArtLeft:SetTexture(activeTheme.visualLeft or activeTheme.icon)
    themeArtLeft:SetSize(112,112)
    themeArtLeft:SetPoint("BOTTOMLEFT",PageContent,"BOTTOMLEFT",22,24)
    themeArtLeft:SetAlpha(activeTheme.visualAlpha or 0.25)
    RegisterThemeVisual("visualLeft",themeArtLeft)

    local themeArtRight=PageContent:CreateTexture(nil,"BACKGROUND")
    themeArtRight:SetTexture(activeTheme.visualRight or activeTheme.icon)
    themeArtRight:SetSize(112,112)
    themeArtRight:SetPoint("BOTTOMRIGHT",PageContent,"BOTTOMRIGHT",-22,24)
    themeArtRight:SetAlpha(activeTheme.visualAlpha or 0.25)
    RegisterThemeVisual("visualRight",themeArtRight)

    local themeCornerTL=BrowserFrame:CreateTexture(nil,"ARTWORK")
    themeCornerTL:SetTexture(activeTheme.visualCorner or activeTheme.icon)
    themeCornerTL:SetSize(46,46)
    themeCornerTL:SetPoint("TOPLEFT",BrowserFrame,"TOPLEFT",10,-10)
    themeCornerTL:SetAlpha((activeTheme.visualAlpha or 0.25)*0.75)
    RegisterThemeVisual("visualCorner",themeCornerTL)

    local themeCornerBR=BrowserFrame:CreateTexture(nil,"ARTWORK")
    themeCornerBR:SetTexture(activeTheme.visualCorner or activeTheme.icon)
    themeCornerBR:SetSize(46,46)
    themeCornerBR:SetPoint("BOTTOMRIGHT",BrowserFrame,"BOTTOMRIGHT",-10,10)
    themeCornerBR:SetAlpha((activeTheme.visualAlpha or 0.25)*0.75)
    RegisterThemeVisual("visualCorner",themeCornerBR)

    -- Large translucent theme crest behind the content pane.
    local themeCrest=PageContent:CreateTexture(nil,"BACKGROUND")
    themeCrest:SetTexture(activeTheme.heroSymbol or activeTheme.icon)
    themeCrest:SetSize(420,420)
    themeCrest:SetPoint("CENTER",PageContent,"CENTER",80,-20)
    themeCrest:SetAlpha((activeTheme.visualAlpha or 0.25)*0.22)
    RegisterThemeVisual("visualCrest",themeCrest)


    --------------------------------------------------
    -- GUARANTEED-VISIBLE THEME IDENTITY
    --------------------------------------------------
    local themeIdentity = CreateFrame("Frame", nil, PageContent)
    themeIdentity:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 18, -16)
    themeIdentity:SetPoint("TOPRIGHT", PageContent, "TOPRIGHT", -18, -16)
    themeIdentity:SetHeight(62)
    themeIdentity:SetFrameLevel(PageContent:GetFrameLevel() + 6)

    local themeIdentityBG = themeIdentity:CreateTexture(nil, "BACKGROUND")
    themeIdentityBG:SetTexture("Interface\\Buttons\\WHITE8X8")
    themeIdentityBG:SetAllPoints(themeIdentity)
    local tic=WOW_THEME.title or WOW_THEME.panel
    themeIdentityBG:SetVertexColor(tic[1],tic[2],tic[3],0.94)
    ThemeColor(themeIdentityBG,"title")

    local themeIdentityTop = themeIdentity:CreateTexture(nil,"ARTWORK")
    themeIdentityTop:SetTexture("Interface\\Buttons\\WHITE8X8")
    themeIdentityTop:SetHeight(3)
    themeIdentityTop:SetPoint("TOPLEFT",themeIdentity,"TOPLEFT",0,0)
    themeIdentityTop:SetPoint("TOPRIGHT",themeIdentity,"TOPRIGHT",0,0)
    local tg=WOW_THEME.gold
    themeIdentityTop:SetVertexColor(tg[1],tg[2],tg[3],1)
    ThemeColor(themeIdentityTop,"gold")

    local themeIdentityBottom = themeIdentity:CreateTexture(nil,"ARTWORK")
    themeIdentityBottom:SetTexture("Interface\\Buttons\\WHITE8X8")
    themeIdentityBottom:SetHeight(2)
    themeIdentityBottom:SetPoint("BOTTOMLEFT",themeIdentity,"BOTTOMLEFT",0,0)
    themeIdentityBottom:SetPoint("BOTTOMRIGHT",themeIdentity,"BOTTOMRIGHT",0,0)
    themeIdentityBottom:SetVertexColor(tg[1],tg[2],tg[3],0.75)
    ThemeColor(themeIdentityBottom,"gold")

    local ta=WOW_THEME.accent
    local leftBanner = themeIdentity:CreateTexture(nil,"ARTWORK")
    leftBanner:SetTexture("Interface\\Buttons\\WHITE8X8")
    leftBanner:SetWidth(12)
    leftBanner:SetPoint("TOPLEFT",themeIdentity,"TOPLEFT",0,-3)
    leftBanner:SetPoint("BOTTOMLEFT",themeIdentity,"BOTTOMLEFT",0,2)
    leftBanner:SetVertexColor(ta[1],ta[2],ta[3],1)
    ThemeColor(leftBanner,"accent")

    local rightBanner = themeIdentity:CreateTexture(nil,"ARTWORK")
    rightBanner:SetTexture("Interface\\Buttons\\WHITE8X8")
    rightBanner:SetWidth(12)
    rightBanner:SetPoint("TOPRIGHT",themeIdentity,"TOPRIGHT",0,-3)
    rightBanner:SetPoint("BOTTOMRIGHT",themeIdentity,"BOTTOMRIGHT",0,2)
    rightBanner:SetVertexColor(ta[1],ta[2],ta[3],1)
    ThemeColor(rightBanner,"accent")

    local identityTitle=themeIdentity:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    identityTitle:SetPoint("TOP",themeIdentity,"TOP",0,-10)
    identityTitle:SetText(activeTheme.themeTitle or activeTheme.displayName)
    identityTitle:SetTextColor(tg[1],tg[2],tg[3],1)
    RegisterThemeVisual("themeTitle",identityTitle)

    local identitySub=themeIdentity:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    identitySub:SetPoint("TOP",identityTitle,"BOTTOM",0,-5)
    identitySub:SetText(activeTheme.themeSub or "")
    local ts=WOW_THEME.goldSoft
    identitySub:SetTextColor(ts[1],ts[2],ts[3],1)
    RegisterThemeVisual("themeSub",identitySub)


    --------------------------------------------------
    -- PROMINENT THEME SYMBOL
    --------------------------------------------------
    local heroPlate=CreateFrame("Frame",nil,PageContent)
    heroPlate:SetSize(206,206)
    heroPlate:SetPoint("TOPRIGHT",BrowserFrame,"TOPRIGHT",72,-70)
    heroPlate:SetFrameLevel(PageContent:GetFrameLevel()+5)

    local heroPlateBG=heroPlate:CreateTexture(nil,"BACKGROUND")
    heroPlateBG:SetTexture("Interface\\Buttons\\WHITE8X8")
    heroPlateBG:SetAllPoints(heroPlate)
    local hp=WOW_THEME.inset or WOW_THEME.panel
    heroPlateBG:SetVertexColor(hp[1],hp[2],hp[3],0.92)
    ThemeColor(heroPlateBG,"inset")

    local heroOuter=heroPlate:CreateTexture(nil,"BORDER")
    heroOuter:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    heroOuter:SetBlendMode("ADD")
    heroOuter:SetSize(246,246)
    heroOuter:SetPoint("CENTER",heroPlate,"CENTER",0,0)
    local hg=WOW_THEME.gold
    heroOuter:SetVertexColor(hg[1],hg[2],hg[3],0.95)
    ThemeColor(heroOuter,"gold")

    local heroSymbol=heroPlate:CreateTexture(nil,"ARTWORK")
    heroSymbol:SetTexture(activeTheme.heroSymbol or activeTheme.icon)
    heroSymbol:SetSize(184,184)
    heroSymbol:SetPoint("CENTER",heroPlate,"CENTER",0,0)
    heroSymbol:SetAlpha(1)
    RegisterThemeVisual("heroSymbol",heroSymbol)

    -- Matching smaller seal in the title bar.
    local titleThemeSeal=titleBar:CreateTexture(nil,"OVERLAY")
    titleThemeSeal:SetTexture(activeTheme.heroSymbol or activeTheme.icon)
    titleThemeSeal:SetSize(30,30)
    titleThemeSeal:SetPoint("RIGHT",ThemeButton,"LEFT",-32,0)
    titleThemeSeal:SetAlpha(1)
    RegisterThemeVisual("heroSymbol",titleThemeSeal)


    --------------------------------------------------
    -- THEME CHARACTER / CREATURE MODEL
    --------------------------------------------------
    local themeModelFrame=CreateFrame("PlayerModel",nil,BrowserFrame)
    themeModelFrame:SetSize(360,620)
    themeModelFrame:SetPoint("BOTTOMRIGHT",BrowserFrame,"BOTTOMLEFT",-70,8)
    themeModelFrame:SetFrameLevel(BrowserFrame:GetFrameLevel()+8)

    -- Keep the 3D model viewport visually transparent.
    if themeModelFrame.SetBackdrop then
        themeModelFrame:SetBackdrop(nil)
    end
    if themeModelFrame.SetBackdropColor then
        themeModelFrame:SetBackdropColor(0,0,0,0)
    end
    if themeModelFrame.SetBackdropBorderColor then
        themeModelFrame:SetBackdropBorderColor(0,0,0,0)
    end
    if themeModelFrame.SetClampedToScreen then
        themeModelFrame:SetClampedToScreen(true)
    end

    local initialDisplayID=ResolveThemeModelDisplay(activeTheme,1)

    if initialDisplayID and themeModelFrame.SetDisplayInfo then
        themeModelFrame:SetDisplayInfo(initialDisplayID)
        if themeModelFrame.SetModelScale then
            themeModelFrame:SetModelScale(activeTheme.modelScale1 or 0.38)
        end
        if themeModelFrame.SetPosition then
            themeModelFrame:SetPosition(0,0,activeTheme.modelZ1 or 0.00)
        end
        themeModelFrame:Show()
    else
        themeModelFrame:Hide()
    end

    if themeModelFrame.SetFacing then
        themeModelFrame:SetFacing(0.35)
    end
    RegisterThemeVisual("themeModel",themeModelFrame)



    --------------------------------------------------
    -- RIGHT-SIDE THEME MODEL REMOVED - Beta v1.020
    -- The left-side theme model remains intact.
    -- Right-side space is reserved for feature panels
    -- such as the Talent Builder stats panel.
    --------------------------------------------------


    local leftRail=PageContent:CreateTexture(nil,"BACKGROUND")
    leftRail:SetTexture("Interface\\Buttons\\WHITE8X8")
    leftRail:SetWidth(5)
    leftRail:SetPoint("TOPLEFT",PageContent,"TOPLEFT",6,-92)
    leftRail:SetPoint("BOTTOMLEFT",PageContent,"BOTTOMLEFT",6,16)
    leftRail:SetVertexColor(ta[1],ta[2],ta[3],0.55)
    ThemeColor(leftRail,"accent")

    local rightRail=PageContent:CreateTexture(nil,"BACKGROUND")
    rightRail:SetTexture("Interface\\Buttons\\WHITE8X8")
    rightRail:SetWidth(5)
    rightRail:SetPoint("TOPRIGHT",PageContent,"TOPRIGHT",-6,-92)
    rightRail:SetPoint("BOTTOMRIGHT",PageContent,"BOTTOMRIGHT",-6,16)
    rightRail:SetVertexColor(ta[1],ta[2],ta[3],0.55)
    ThemeColor(rightRail,"accent")

    local function MakeThemePlate(point, relativePoint, x, y)
        local plate=PageContent:CreateTexture(nil,"BACKGROUND")
        plate:SetTexture("Interface\\Buttons\\WHITE8X8")
        plate:SetSize(52,18)
        plate:SetPoint(point,PageContent,relativePoint,x,y)
        plate:SetVertexColor(ta[1],ta[2],ta[3],0.42)
        ThemeColor(plate,"accent")
        return plate
    end

    MakeThemePlate("TOPLEFT","TOPLEFT",18,-84)
    MakeThemePlate("TOPRIGHT","TOPRIGHT",-18,-84)
    MakeThemePlate("BOTTOMLEFT","BOTTOMLEFT",18,12)
    MakeThemePlate("BOTTOMRIGHT","BOTTOMRIGHT",-18,12)
    pageBackdrop:SetPoint("TOPLEFT", PageContent, "TOPLEFT", 0, 0)
    pageBackdrop:SetPoint("BOTTOMRIGHT", PageContent, "BOTTOMRIGHT", 0, 0)


    ScrollFrame:SetScrollChild(
        PageContent
    )


    --------------------------------------------------
    -- START HIDDEN
    --------------------------------------------------

    BrowserFrame:Hide()

end


--------------------------------------------------
-- MINIMAP BUTTON
--------------------------------------------------

local ForeverBrowserMinimapButton = nil

local function GetForeverBrowserMinimapSettings()
    if not ForeverDBDatabase then
        ForeverDBDatabase = {}
    end

    ForeverDBDatabase.foreverBrowserMinimap =
        ForeverDBDatabase.foreverBrowserMinimap or {}

    local settings = ForeverDBDatabase.foreverBrowserMinimap

    if settings.angle == nil then
        settings.angle = 225
    end

    return settings
end

local function PositionForeverBrowserMinimapButton()
    if not ForeverBrowserMinimapButton or not Minimap then
        return
    end

    local settings = GetForeverBrowserMinimapSettings()
    local angle = tonumber(settings.angle) or 225
    local radians = math.rad(angle)
    -- Keep the button just OUTSIDE the edge of the circular minimap.
    -- The minimap is roughly 140px wide on this client, so 94px keeps
    -- the 32px button clear of the map instead of overlapping it.
    -- Keep the entire 32px button clearly OUTSIDE the minimap circle.
    -- Increased from 94 so the inner edge of the button no longer overlaps
    -- the minimap border.
    local radius = 112

    ForeverBrowserMinimapButton:ClearAllPoints()
    ForeverBrowserMinimapButton:SetPoint(
        "CENTER",
        Minimap,
        "CENTER",
        math.cos(radians) * radius,
        math.sin(radians) * radius
    )
end

local function UpdateForeverBrowserMinimapDrag()
    if not ForeverBrowserMinimapButton or not Minimap then
        return
    end

    local mx, my = Minimap:GetCenter()
    local scale = UIParent:GetEffectiveScale()
    local cx, cy = GetCursorPosition()

    cx = cx / scale
    cy = cy / scale

    local dx = cx - mx
    local dy = cy - my
    local angle

    if math.atan2 then
        angle = math.deg(math.atan2(dy, dx))
    else
        if dx == 0 then
            angle = dy >= 0 and 90 or -90
        else
            angle = math.deg(math.atan(dy / dx))
            if dx < 0 then
                angle = angle + 180
            end
        end
    end

    GetForeverBrowserMinimapSettings().angle = angle
    PositionForeverBrowserMinimapButton()
end

local function ToggleForeverBrowserFromMinimap()
    CreateBrowser()

    if BrowserFrame:IsShown() then
        BrowserFrame:Hide()
    else
        BrowserFrame:Show()

        -- Match the behavior of typing /fb with no arguments.
        -- Always open the Welcome page when opening from the minimap.
        Navigate(ForeverBrowser_S222Start())
    end
end

local function CreateForeverBrowserMinimapButton()
    if ForeverBrowserMinimapButton or not Minimap then
        return
    end

    ForeverBrowserMinimapButton = CreateFrame(
        "Button",
        "ForeverBrowserMinimapButton",
        Minimap
    )

    ForeverBrowserMinimapButton:SetSize(32, 32)
    ForeverBrowserMinimapButton:SetFrameStrata("MEDIUM")
    ForeverBrowserMinimapButton:SetFrameLevel(
        (Minimap:GetFrameLevel() or 0) + 8
    )
    ForeverBrowserMinimapButton:EnableMouse(true)
    ForeverBrowserMinimapButton:RegisterForClicks("LeftButtonUp")
    ForeverBrowserMinimapButton:RegisterForDrag("LeftButton")

    local icon = ForeverBrowserMinimapButton:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    icon:SetPoint("TOPLEFT", ForeverBrowserMinimapButton, "TOPLEFT", 7, -7)
    icon:SetPoint("BOTTOMRIGHT", ForeverBrowserMinimapButton, "BOTTOMRIGHT", -7, 7)
    ForeverBrowserMinimapButton.icon = icon

    local border = ForeverBrowserMinimapButton:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", ForeverBrowserMinimapButton, "TOPLEFT", 0, 0)
    ForeverBrowserMinimapButton.border = border

    local highlight = ForeverBrowserMinimapButton:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints(ForeverBrowserMinimapButton)

    ForeverBrowserMinimapButton:SetScript(
        "OnClick",
        function(self, button)
            if button == "LeftButton" then
                ToggleForeverBrowserFromMinimap()
            end
        end
    )

    ForeverBrowserMinimapButton:SetScript(
        "OnDragStart",
        function(self)
            self.dragging = true
            self:SetScript(
                "OnUpdate",
                function()
                    UpdateForeverBrowserMinimapDrag()
                end
            )
        end
    )

    ForeverBrowserMinimapButton:SetScript(
        "OnDragStop",
        function(self)
            self.dragging = nil
            self:SetScript("OnUpdate", nil)
            PositionForeverBrowserMinimapButton()
        end
    )

    ForeverBrowserMinimapButton:SetScript(
        "OnEnter",
        function(self)
            if not GameTooltip then
                return
            end

            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:AddLine("ForeverBrowser", 1, 0.82, 0.25)
            GameTooltip:AddLine("Left-click: Open / Close", 1, 1, 1)
            GameTooltip:AddLine("Drag: Move around minimap", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end
    )

    ForeverBrowserMinimapButton:SetScript(
        "OnLeave",
        function()
            if GameTooltip then
                GameTooltip:Hide()
            end
        end
    )

    PositionForeverBrowserMinimapButton()
    ForeverBrowserMinimapButton:Show()
end


--------------------------------------------------
-- SLASH COMMAND
--------------------------------------------------

SLASH_FOREVERBROWSER1 =
    "/fb"


SlashCmdList["FOREVERBROWSER"] =
    function(msg)

        CreateBrowser()


        msg =
            msg or ""


        local command = msg:match("^%s*(.-)%s*$"):lower()
        if command == "updates" then
            BrowserFrame:Show()
            Navigate("forever://codex/updates")
            return
        end

        if msg == "" then

            BrowserFrame:Show()


            Navigate(
                ForeverBrowser_S222Start()
            )


            return

        end


        BrowserFrame:Show()


        local itemID =
            tonumber(msg)


        if itemID then

            Navigate(
                "forever://item/"
                .. tostring(
                    itemID
                )
            )

        else

            Navigate(
                "forever://search/"
                .. msg
            )

        end

    end


SLASH_FOREVERBROWSERVERSION1 = "/fbversion"
SlashCmdList["FOREVERBROWSERVERSION"] = function()
    CreateBrowser()
    BrowserFrame:Show()
    Navigate("forever://codex/updates")
end

--------------------------------------------------
-- INITIALIZE
--------------------------------------------------

local ForeverBrowserInitFrame =
    CreateFrame(
        "Frame",
        "ForeverBrowserInitFrame",
        UIParent
    )

ForeverBrowserInitFrame:RegisterEvent(
    "ADDON_LOADED"
)

ForeverBrowserInitFrame:SetScript(
    "OnEvent",
    function(self, event, addonName)

        if event ~= "ADDON_LOADED" then
            return
        end

        if addonName ~= "ForeverBrowser" then
            return
        end

        -- SavedVariables are available here.
        -- Apply the saved theme before constructing the browser.
        CopyThemeIntoActive(
            LoadForeverTheme()
        )

        CreateBrowser()
        CreateForeverBrowserMinimapButton()

        self:UnregisterEvent(
            "ADDON_LOADED"
        )

        print(
            "|cff00ff00ForeverBrowser loaded.|r"
        )
    end
)




--------------------------------------------------

SLASH_FOREVERBROWSERMISSING2251 = "/fbmissing"
SlashCmdList["FOREVERBROWSERMISSING225"] = function()
    CreateBrowser() BrowserFrame:Show() Navigate("forever://codex/missing")
end

SLASH_FOREVERBROWSERSHOPPING2251="/fbshopping"
SlashCmdList["FOREVERBROWSERSHOPPING225"]=function()
    CreateBrowser()
    BrowserFrame:Show()
    Navigate("forever://codex/shopping")
end

-- Navigation consistency226: session history stores views, not database records.
do
    local nav={views={},active=HistoryPosition,render=nil,restoring=false,token=0}
    ForeverBrowserNavigation226=nav
    local keys={"ForeverBrowserQuestBrowseFilter","ForeverBrowserCurrentQuestBrowseFilter","ForeverBrowserCompletedQuestPage","ForeverBrowserCompletedQuestSort","ForeverBrowserQuestRewardFilter","ForeverBrowserQuestRewardSort","ForeverBrowserQuestRewardPage","ForeverBrowserRelationshipBrowsePage","ForeverBrowserReviewFilters225","ForeverBrowserProfessionViews226"}
    local function copy(value)
        if type(value)~="table" then return value end
        local result={} for k,v in pairs(value) do result[k]=copy(v) end return result
    end
    local function capture()
        if not nav.active or nav.active<1 then return end
        local globals={}
        for _,key in ipairs(keys) do globals[key]={value=copy(_G[key])} end
        local offset=0
        if ScrollFrame and ScrollFrame.GetVerticalScroll then offset=ScrollFrame:GetVerticalScroll() or 0 end
        nav.views[nav.active]={url=CurrentURL,scroll=offset,globals=globals,search=copy(SearchState),render=nav.render}
    end
    local function wrap(fn)
        if type(fn)~="function" then return fn end
        return function(...)
            local args={n=select("#",...),...}
            fn(...)
            if not nav.restoring then nav.render=function() fn(unpack(args,1,args.n)) end end
        end
    end
    BuildSearchPage=wrap(BuildSearchPage)
    BuildItemDatabasePage=wrap(BuildItemDatabasePage)
    BuildItemBrowsePage=wrap(BuildItemBrowsePage)
    BuildCategoryPage=wrap(BuildCategoryPage)
    BuildQuestDatabasePage=wrap(BuildQuestDatabasePage)
    BuildQuestBrowsePage=wrap(BuildQuestBrowsePage)
    ForeverBrowser_RefreshQuestBrowsePage=BuildQuestBrowsePage
    BuildNPCDatabasePage=wrap(BuildNPCDatabasePage)
    BuildProfessionsPage=wrap(BuildProfessionsPage)
    BuildProfessionPage=wrap(BuildProfessionPage)
    ForeverBrowser_ProfessionHome191=wrap(ForeverBrowser_ProfessionHome191)
    ForeverBrowser_DungeonHome191=wrap(ForeverBrowser_DungeonHome191)
    ForeverBrowser_N187Search=wrap(ForeverBrowser_N187Search)
    ForeverBrowser_N187Browse=wrap(ForeverBrowser_N187Browse)
    ForeverBrowser_BuildQuestRewardsPage=wrap(ForeverBrowser_BuildQuestRewardsPage)
    ForeverBrowser_BuildQuestRelationshipsPage=wrap(ForeverBrowser_BuildQuestRelationshipsPage)
    ForeverBrowserBuildDungeonPage=wrap(ForeverBrowserBuildDungeonPage)
    ForeverBrowser_C198Search=wrap(ForeverBrowser_C198Search)
    ForeverBrowser_F207Page=wrap(ForeverBrowser_F207Page)
    ForeverBrowser_MissingPage225=wrap(ForeverBrowser_MissingPage225)
    local restoreFrame=CreateFrame("Frame")
    local function restoreScroll(offset)
        nav.token=nav.token+1
        local token=nav.token local ticks=0
        restoreFrame:SetScript("OnUpdate",function(self)
            if token~=nav.token then self:SetScript("OnUpdate",nil) return end
            ticks=ticks+1
            if ticks<(ForeverBrowserLayout226 and 4 or 2) then return end
            if ScrollFrame and ScrollFrame.SetVerticalScroll then
                local maximum=ScrollFrame.GetVerticalScrollRange and ScrollFrame:GetVerticalScrollRange() or offset
                ScrollFrame:SetVerticalScroll(math.max(0,math.min(tonumber(offset) or 0,math.max(0,tonumber(maximum) or 0))))
            end
            self:SetScript("OnUpdate",nil)
        end)
    end
    local original=Navigate
    Navigate=function(selfOrURL,url,skipHistory)
        local target=type(selfOrURL)=="string" and selfOrURL or url
        local skip=type(selfOrURL)=="string" and url==true or skipHistory==true
        if type(target)~="string" then return original(selfOrURL,url,skipHistory) end
        if target:sub(1,15)=="forever://item/" and type(IsAltKeyDown)=="function" and IsAltKeyDown() then return original(selfOrURL,url,skipHistory) end
        capture()
        nav.token=nav.token+1;restoreFrame:SetScript("OnUpdate",nil)
        local snapshot=(skip or target==CurrentURL) and nav.views[HistoryPosition] or nil
        if snapshot and snapshot.url~=target then snapshot=nil end
        if snapshot then
            for _,key in ipairs(keys) do _G[key]=copy(snapshot.globals[key] and snapshot.globals[key].value) end
            for key in pairs(SearchState) do SearchState[key]=nil end
            for key,value in pairs(snapshot.search or {}) do SearchState[key]=copy(value) end
        end
        nav.restoring=snapshot~=nil;nav.replay=snapshot and snapshot.render or nil;nav.render=nil
        local ok,message=pcall(original,selfOrURL,url,skipHistory)
        nav.restoring=false;nav.replay=nil
        if not ok then error(message,0) end
        nav.active=HistoryPosition
        if snapshot then nav.render=snapshot.render end
        if not skip then for index in pairs(nav.views) do if index>#History then nav.views[index]=nil end end end
        restoreScroll(snapshot and snapshot.scroll or 0)
        if ForeverBrowserNavigationBack226 then
            if HistoryPosition>1 then ForeverBrowserNavigationBack226:Enable() else ForeverBrowserNavigationBack226:Disable() end
        end
        if ForeverBrowserNavigationForward226 then
            if HistoryPosition<#History then ForeverBrowserNavigationForward226:Enable() else ForeverBrowserNavigationForward226:Disable() end
        end
    end
end

-- Shared layout226 connection; the layout module loads after this script.
do
    local original=ClearPage
    ClearPage=function()
        if ForeverBrowserLayout226 then ForeverBrowserLayout226:Begin() end
        original()
        if ForeverBrowserLayout226 and PageContent and ScrollFrame and NavigationFrame then
            ForeverBrowserLayout226:Schedule({page=PageContent,scroll=ScrollFrame,navigation=NavigationFrame,url=CurrentURL,
                navigate=function(url,skip) Navigate(url,skip) end,database=GetDatabase,
                button=CreateButton,label=ForeverBrowser_AchievementLabel,background=CreateSolidBackground,theme=WOW_THEME})
        end
    end
end

-- Here performance226: build shared zone associations outside the navigation call.
do
    local original=ForeverBrowser_C201Here
    local worker=CreateFrame("Frame")
    local requestedPage=1
    local function ready()
        local source=ForeverSourceData or {} local c=ForeverBrowserZoneCache226
        return c and c.source==source and c.items==source.items and c.npcs==source.npcs and c.quests==source.quests and c.locations==source.npcLocations and c.dungeons==source.dungeons
    end
    ForeverBrowser_C201Here=function(page)
        requestedPage=tonumber(page) or 1
        if ready() then original(requestedPage) return end
        local y=ForeverBrowser_C198Head("What Can I Do Here?","Preparing recorded zone opportunities in small batches. You can continue browsing.")
        ForeverBrowser_C198Row(y,"Building zone index","This runs once for the loaded database. No NPC-by-NPC item source scans are performed.")
        if ForeverBrowserZoneJob226 then return end
        local job={steps=0,started=0,sliceStart=0}
        job.thread=coroutine.create(function() return ForeverBrowser_Z199Index() end)
        ForeverBrowserZoneJob226=job
        worker:SetScript("OnUpdate",function(frame)
            job.started=type(debugprofilestop)=="function" and debugprofilestop() or 0
            job.sliceStart=job.steps
            local ok,message=coroutine.resume(job.thread)
            if not ok or coroutine.status(job.thread)=="dead" then
                frame:SetScript("OnUpdate",nil);ForeverBrowserZoneJob226=nil
                if CurrentURL and CurrentURL:match("^forever://codex/here") then
                    if ok then original(requestedPage)
                    else local at=ForeverBrowser_C198Head("What Can I Do Here?","Zone data could not be prepared.") ForeverBrowser_C198Row(at,"Index error",tostring(message)) end
                end
            end
        end)
    end
end

-- Dungeon banners226: only dungeon homepage cards use this renderer.
do
    local original=ForeverBrowser_CodexCard191
    local art={
        ["Blackfathom Deeps"]="BlackfathomDeeps",["Blackrock Depths"]="BlackrockDepths",
        ["Blackrock Spire"]="BlackrockSpire",["Lower Blackrock Spire"]="BlackrockSpire",
        ["Upper Blackrock Spire"]="BlackrockSpire",["Deadmines"]="Deadmines",["The Deadmines"]="Deadmines",
        ["Dire Maul"]="DireMaul",["Dire Maul East"]="DireMaul",["Dire Maul North"]="DireMaul",["Dire Maul West"]="DireMaul",
        ["Gnomeregan"]="Gnomeregan",["Maraudon"]="Maraudon",["Ragefire Chasm"]="RagefireChasm",
        ["Razorfen Downs"]="RazorfenDowns",["Razorfen Kraul"]="RazorfenKraul",
        ["Scarlet Monastery"]="ScarletMonastery",["Scarlet Monastery Graveyard"]="ScarletMonastery",
        ["Scarlet Monastery Library"]="ScarletMonastery",["Scarlet Monastery Armory"]="ScarletMonastery",
        ["Scarlet Monastery Cathedral"]="ScarletMonastery",["Scholomance"]="Scholomance",
        ["Shadowfang Keep"]="ShadowfangKeep",["Stockades"]="Stockades",["The Stockade"]="Stockades",
        ["The Stockades"]="Stockades",["Stratholme"]="Stratholme",["Sunken Temple"]="SunkenTemple",
        ["The Temple of Atal'Hakkar"]="SunkenTemple",["Uldaman"]="Uldaman",
        ["Wailing Caverns"]="WailingCaverns",["Zul'Farrak"]="ZulFarrak",
        ["Molten Core"]="MoltenCore",["Blackwing Lair"]="BlackwingLair",
        ["Onyxia's Lair"]="OnyxiasLair",["Zul'Gurub"]="ZulGurub",
        ["Ruins of Ahn'Qiraj"]="RuinsofAhnQiraj",["Temple of Ahn'Qiraj"]="TempleofAhnQiraj",
        ["Naxxramas"]="Naxxramas"
    }
    ForeverBrowserDungeonBanners226=ForeverBrowserDungeonBanners226 or {}
    local function loadArt(texture,path)
        local ok,result=pcall(texture.SetTexture,texture,path)
        if not ok or result==false then return false end
        if texture.GetTexture then return texture:GetTexture()~=nil end
        return result==true
    end
    ForeverBrowser_CodexCard191=function(hero,index,name,description,count,iconPath,route,offset)
        if type(route)~="string" or route:sub(1,18)~="forever://dungeon/" then
            return original(hero,index,name,description,count,iconPath,route,offset)
        end
        local card=CreateFrame("Button",nil,PageContent) card:SetSize(338,100)
        card:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",index%2==1 and 0 or 362,-(offset or 125)-math.floor((index-1)/2)*112)
        CreateSolidBackground(card,.045,.038,.029,1)
        local picture=card:CreateTexture(nil,"BACKGROUND") picture:SetAllPoints(card)
        local path=ForeverBrowserDungeonBanners226[name] or (art[name] and ("Interface\\LFGFrame\\LFGIcon-"..art[name]))
        local loaded=path and loadArt(picture,path)
        if loaded then
            picture:SetTexCoord(0,1,.20,.80)
        else
            loadArt(picture,"Interface\\AchievementFrame\\UI-Achievement-Background")
            if picture.SetVertexColor then picture:SetVertexColor(.25,.22,.18,1) end
        end
        local band=CreateFrame("Frame",nil,card) band:SetSize(338,62) band:SetPoint("BOTTOM",card,"BOTTOM",0,0)
        CreateSolidBackground(band,.012,.010,.008,.88)
        if band.EnableMouse then band:EnableMouse(false) end
        local title=ForeverBrowser_AchievementLabel(band,name,16,{1,.82,.28,1})
        title:SetPoint("TOPLEFT",band,"TOPLEFT",12,-6) title:SetSize(314,34) title:SetJustifyH("LEFT") title:SetJustifyV("TOP")
        local footer=ForeverBrowser_AchievementLabel(band,count.."  |  Open dungeon >",10,{.94,.88,.73,1})
        footer:SetPoint("BOTTOMLEFT",band,"BOTTOMLEFT",12,7)
        local border=CreateFrame("Frame",nil,card) border:SetAllPoints(card)
        if border.EnableMouse then border:EnableMouse(false) end
        local gold=WOW_THEME and WOW_THEME.gold or {1,.82,.28,1}
        for _,edge in ipairs({"TOP","BOTTOM","LEFT","RIGHT"}) do
            local line=border:CreateTexture(nil,"OVERLAY")
            if line.SetColorTexture then line:SetColorTexture(gold[1],gold[2],gold[3],1) else line:SetTexture(gold[1],gold[2],gold[3],1) end
            line:SetPoint(edge,border,edge,0,0)
            if edge=="TOP" or edge=="BOTTOM" then line:SetSize(338,1) else line:SetSize(1,100) end
        end
        card:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        card:SetScript("OnClick",function() Navigate(route) end)
        return card
    end
end

-- Dungeon banners227: taller cards and normalized names with themed custom fallback.
do
    local original=ForeverBrowser_CodexCard191
    local art={
        ["Blackfathom Deeps"]="BlackfathomDeeps",["Blackrock Depths"]="BlackrockDepths",
        ["Blackrock Spire"]="BlackrockSpire",["Lower Blackrock Spire"]="BlackrockSpire",
        ["Upper Blackrock Spire"]="BlackrockSpire",["Deadmines"]="Deadmines",["The Deadmines"]="Deadmines",
        ["Dire Maul"]="DireMaul",["Dire Maul East"]="DireMaul",["Dire Maul North"]="DireMaul",["Dire Maul West"]="DireMaul",
        ["Gnomeregan"]="Gnomeregan",["Maraudon"]="Maraudon",["Ragefire Chasm"]="RagefireChasm",
        ["Razorfen Downs"]="RazorfenDowns",["Razorfen Kraul"]="RazorfenKraul",
        ["Scarlet Monastery"]="ScarletMonastery",["Scarlet Monastery Graveyard"]="ScarletMonastery",
        ["Scarlet Monastery Library"]="ScarletMonastery",["Scarlet Monastery Armory"]="ScarletMonastery",
        ["Scarlet Monastery Cathedral"]="ScarletMonastery",["Scholomance"]="Scholomance",
        ["Shadowfang Keep"]="ShadowfangKeep",["Stockades"]="Stockades",["The Stockade"]="Stockades",
        ["The Stockades"]="Stockades",["Stratholme"]="Stratholme",["Sunken Temple"]="SunkenTemple",
        ["The Temple of Atal'Hakkar"]="SunkenTemple",["Uldaman"]="Uldaman",
        ["Wailing Caverns"]="WailingCaverns",["Zul'Farrak"]="ZulFarrak",
        ["Molten Core"]="MoltenCore",["Blackwing Lair"]="BlackwingLair",
        ["Onyxia's Lair"]="OnyxiasLair",["Zul'Gurub"]="ZulGurub",
        ["Ruins of Ahn'Qiraj"]="RuinsofAhnQiraj",["Temple of Ahn'Qiraj"]="TempleofAhnQiraj",
        ["Naxxramas"]="Naxxramas"
    }
    local normalized={}
    local function key(name) return tostring(name or ""):lower():gsub("[^%w]","") end
    for name,value in pairs(art) do normalized[key(name)]=value end
    local themed={ruinsoflordaeron="Stratholme",alcazprison="Stockades",blackmawhold="BlackrockDepths",cityofdalaran="TheVioletHold"}
    local rendered=0
    ForeverBrowserDungeonBanners226=ForeverBrowserDungeonBanners226 or {}
    local function loadArt(texture,path)
        local ok,result=pcall(texture.SetTexture,texture,path)
        if not ok or result==false then return false end
        if texture.GetTexture then return texture:GetTexture()~=nil end
        return result==true
    end
    ForeverBrowser_CodexCard191=function(hero,index,name,description,count,iconPath,route,offset)
        if type(route)~="string" or route:sub(1,18)~="forever://dungeon/" then
            return original(hero,index,name,description,count,iconPath,route,offset)
        end
        local card=CreateFrame("Button",nil,PageContent) card:SetSize(338,108)
        card:SetPoint("TOPLEFT",hero,"BOTTOMLEFT",index%2==1 and 0 or 362,-(offset or 125)-math.floor((index-1)/2)*120)
        CreateSolidBackground(card,.045,.038,.029,1)
        local picture=card:CreateTexture(nil,"BACKGROUND") picture:SetAllPoints(card)
        rendered=math.max(rendered,index)
        local slug=normalized[key(name)]
        if not slug and key(name):find("scarletmonastery",1,true)==1 then slug="ScarletMonastery" end
        local custom=not slug and themed[key(name)]
        local override=ForeverBrowserDungeonBanners226[name]
        local path=override or ((slug or custom) and ("Interface\\LFGFrame\\LFGIcon-"..(slug or custom)))
        local loaded=path and loadArt(picture,path)
        local isThemed=not not custom and not override
        if not loaded then
            isThemed=true
            loaded=loadArt(picture,"Interface\\LFGFrame\\LFGIcon-BlackrockDepths")
        end
        if loaded then
            picture:SetTexCoord(0,1,.05,.95)
        else
            loadArt(picture,"Interface\\AchievementFrame\\UI-Achievement-Background")
            if picture.SetVertexColor then picture:SetVertexColor(.25,.22,.18,1) end
        end
        local band=CreateFrame("Frame",nil,card) band:SetSize(338,42) band:SetPoint("BOTTOM",card,"BOTTOM",0,0)
        CreateSolidBackground(band,.012,.010,.008,.73)
        if band.EnableMouse then band:EnableMouse(false) end
        local title=ForeverBrowser_AchievementLabel(band,name,14,{1,.82,.28,1})
        title:SetPoint("TOPLEFT",band,"TOPLEFT",12,-6) title:SetSize(314,20) title:SetJustifyH("LEFT") title:SetJustifyV("TOP")
        local footer=ForeverBrowser_AchievementLabel(band,count,10,{.94,.88,.73,1})
        footer:SetPoint("BOTTOMLEFT",band,"BOTTOMLEFT",12,7)
        local border=CreateFrame("Frame",nil,card) border:SetAllPoints(card)
        if border.EnableMouse then border:EnableMouse(false) end
        local gold=WOW_THEME and WOW_THEME.gold or {1,.82,.28,1}
        for _,edge in ipairs({"TOP","BOTTOM","LEFT","RIGHT"}) do
            local line=border:CreateTexture(nil,"OVERLAY")
            if line.SetColorTexture then line:SetColorTexture(gold[1],gold[2],gold[3],1) else line:SetTexture(gold[1],gold[2],gold[3],1) end
            line:SetPoint(edge,border,edge,0,0)
            if edge=="TOP" or edge=="BOTTOM" then line:SetSize(338,1) else line:SetSize(1,108) end
        end
        card:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        card:SetScript("OnClick",function() Navigate(route) end)
        return card
    end
    local home=ForeverBrowser_DungeonHome191
    ForeverBrowser_DungeonHome191=function(...)
        rendered=0
        home(...)
        PageContent:SetHeight(math.max(650,186+164+math.ceil(rendered/2)*120+60))
    end
end

-- Compact dungeon banners228


-- ForeverBrowser map highlight geometry probe (diagnostic only).
-- No map rendering or item action button anchors are changed.
do
    ForeverBrowserMapGeometryProbe = ForeverBrowserMapGeometryProbe or {}
    local probe = ForeverBrowserMapGeometryProbe
    local function say(message)
        if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage('|cffffd25aFB Map Geometry:|r '..tostring(message)) end
    end
    local function capture()
        local results, visited, frameCount = {}, {}, 0
        local function walk(frame, path, depth)
            if not frame or visited[frame] or depth > 12 or frameCount > 1400 then return end
            visited[frame] = true
            frameCount = frameCount + 1
            if frame.GetRegions then
                local regions = {frame:GetRegions()}
                for index, region in ipairs(regions) do
                    if region and region.GetObjectType and region:GetObjectType() == 'Texture' then
                        local key = path..'/region'..index
                        local vertex = region.GetVertexColor and {region:GetVertexColor()} or {}
                        results[key] = {
                            region=region, parent=frame,
                            texture=tostring(region.GetTexture and region:GetTexture()),
                            atlas=tostring(region.GetAtlas and region:GetAtlas()),
                            visible=tostring(region.IsVisible and region:IsVisible()),
                            alpha=tostring(region.GetAlpha and region:GetAlpha()),
                            vertex=table.concat(vertex, ','),
                        }
                    end
                end
            end
            if frame.GetChildren then
                local children = {frame:GetChildren()}
                for i,child in ipairs(children) do walk(child,path..'/child'..i,depth+1) end
            end
        end
        if WorldMapFrame then walk(WorldMapFrame,'WorldMapFrame',0) end
        return results,frameCount
    end
    local function number(n) return type(n)=='number' and string.format('%.3f',n) or tostring(n) end
    local function rect(region)
        if not region then return 'missing' end
        local ok,left,right,top,bottom=pcall(function()
            return region:GetLeft(),region:GetRight(),region:GetTop(),region:GetBottom()
        end)
        if not ok then return 'geometry unavailable' end
        return 'L='..number(left)..' R='..number(right)..' T='..number(top)..' B='..number(bottom)
    end
    SLASH_FOREVERBROWSERMAPGEOSCAN1='/fbmapgeoscan'
    SlashCmdList.FOREVERBROWSERMAPGEOSCAN=function()
        local data,count=capture()
        probe.before=data
        local n=0 for _ in pairs(data) do n=n+1 end
        say('Snapshot saved: '..count..' frames, '..n..' textures. Hover another zone and use /fbmapgeodiff.')
    end
    SLASH_FOREVERBROWSERMAPGEODIFF1='/fbmapgeodiff'
    SlashCmdList.FOREVERBROWSERMAPGEODIFF=function()
        if not probe.before then say('Run /fbmapgeoscan first.') return end
        local after,count=capture()
        local changes={}
        for path,new in pairs(after) do
            local old=probe.before[path]
            if not old or new.texture~=old.texture or new.atlas~=old.atlas or new.visible~=old.visible or new.alpha~=old.alpha or new.vertex~=old.vertex then
                changes[#changes+1]={path=path,new=new}
            end
        end
        table.sort(changes,function(a,b) return a.path<b.path end)
        probe.changes=changes
        say('Changed textures: '..#changes..'. Showing first '..math.min(#changes,12)..' with geometry:')
        for i=1,math.min(#changes,12) do
            local entry=changes[i]
            local r=entry.new.region
            say(i..' '..entry.path..' ID='..entry.new.texture..' visible='..entry.new.visible..' alpha='..entry.new.alpha)
            say('  texture '..rect(r)..'  parent '..rect(entry.new.parent))
            if r and r.GetTexCoord then
                local ok,a,b,c,d,e,f,g,h=pcall(r.GetTexCoord,r)
                if ok then say('  UV '..table.concat({number(a),number(b),number(c),number(d),number(e),number(f),number(g),number(h)},',')) end
            end
            if r and r.GetDrawLayer then
                local ok,layer,sub=pcall(r.GetDrawLayer,r)
                if ok then say('  layer='..tostring(layer)..' sub='..tostring(sub)) end
            end
        end
        if #changes>12 then say('Additional changes omitted to avoid flooding chat.') end
    end
end


-- LIVE map highlight capture: records changes WHILE the mouse is over the world map.
-- /fbmaplive to start/stop; /fbmapreport to print the recorded texture transitions.
do
    local state={running=false,elapsed=0,previous=nil,events={},seen={},samples=0}
    local function say(msg)
        if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage('|cffffd25aFB Map Live:|r '..tostring(msg)) end
    end
    local function scan()
        local data,visited={},{}
        local count=0
        local function walk(frame,path,depth)
            if not frame or visited[frame] or depth>12 or count>1400 then return end
            visited[frame]=true count=count+1
            if frame.GetRegions then
                local regions={frame:GetRegions()}
                for i,region in ipairs(regions) do
                    if region and region.GetObjectType and region:GetObjectType()=='Texture' then
                        local texture=region.GetTexture and region:GetTexture()
                        local atlas=region.GetAtlas and region:GetAtlas()
                        local visible=region.IsVisible and region:IsVisible()
                        local alpha=region.GetAlpha and region:GetAlpha()
                        local vertex=region.GetVertexColor and {region:GetVertexColor()} or {}
                        local value=tostring(texture)..'/'..tostring(atlas)..'/'..tostring(visible)..'/'..tostring(alpha)..'/'..table.concat(vertex,',')
                        data[path..'/region'..i]={value=value,region=region,texture=texture,visible=visible,alpha=alpha}
                    end
                end
            end
            if frame.GetChildren then
                local children={frame:GetChildren()}
                for i,child in ipairs(children) do walk(child,path..'/child'..i,depth+1) end
            end
        end
        if WorldMapFrame and WorldMapFrame.IsShown and WorldMapFrame:IsShown() then walk(WorldMapFrame,'WorldMapFrame',0) end
        return data
    end
    local watcher=CreateFrame('Frame')
    watcher:SetScript('OnUpdate',function(_,elapsed)
        if not state.running then return end
        state.elapsed=state.elapsed+(elapsed or 0)
        if state.elapsed<0.22 then return end
        state.elapsed=0
        if not (WorldMapFrame and WorldMapFrame.IsShown and WorldMapFrame:IsShown()) then return end
        local now=scan()
        if state.previous then
            for path,item in pairs(now) do
                local old=state.previous[path]
                if old and old.value~=item.value then
                    local eventKey=path..'|'..item.value
                    if not state.seen[eventKey] and #state.events<150 then
                        state.seen[eventKey]=true
                        local r=item.region
                        local function coord(method)
                            if not r or not r[method] then return '?' end
                            local ok,n=pcall(r[method],r)
                            return ok and type(n)=='number' and string.format('%.1f',n) or '?'
                        end
                        local tc={}
                        if r and r.GetTexCoord then
                            local ok,a,b,c,d=pcall(r.GetTexCoord,r)
                            if ok then tc={a,b,c,d} end
                        end
                        state.events[#state.events+1]={path=path,texture=tostring(item.texture),visible=tostring(item.visible),alpha=tostring(item.alpha),rect='L'..coord('GetLeft')..' T'..coord('GetTop')..' W'..coord('GetWidth')..' H'..coord('GetHeight'),texcoord=table.concat(tc,',')}
                    end
                end
            end
        end
        state.previous=now
        state.samples=state.samples+1
    end)
    SLASH_FOREVERBROWSERMAPLIVE1='/fbmaplive'
    SlashCmdList.FOREVERBROWSERMAPLIVE=function()
        if state.running then
            state.running=false
            say('Capture stopped. '..state.samples..' samples; '..#state.events..' unique changes. Type /fbmapreport.')
        else
            state.running=true state.elapsed=0 state.previous=nil state.events={} state.seen={} state.samples=0
            say('LIVE capture started. Hover over 2-3 zones on the open World Map for 5 seconds, then /fbmaplive to stop.')
        end
    end
    SLASH_FOREVERBROWSERMAPREPORT1='/fbmapreport'
    SlashCmdList.FOREVERBROWSERMAPREPORT=function()
        say('Samples='..state.samples..' changes='..#state.events..'. Showing first '..math.min(16,#state.events)..':')
        for i=1,math.min(16,#state.events) do
            local e=state.events[i]
            say(i..' '..e.path..' ID='..e.texture..' visible='..e.visible..' alpha='..e.alpha)
            say('  '..e.rect..' uv='..e.texcoord)
        end
        if #state.events>16 then say('Additional changes recorded: '..(#state.events-16)) end
    end
end


-- Focused map-highlight texture capture (read-only).
-- /fbmapfocus starts/stops capture; /fbmapfocusreport displays top candidates.
do
    local state={active=false,clock=0,previous={},events={},seen={},samples=0}
    local function say(message)
        if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage('|cffffd25aFB Map Focus:|r '..tostring(message)) end
    end
    local function snapshot()
        local data,visited={},{}
        local function visit(frame,path,depth)
            if not frame or visited[frame] or depth>16 then return end
            visited[frame]=true
            if frame.GetRegions then
                local regions={frame:GetRegions()}
                for i,region in ipairs(regions) do
                    if region and region.GetObjectType and region:GetObjectType()=='Texture' then
                        local texture=region.GetTexture and region:GetTexture()
                        local atlas=region.GetAtlas and region:GetAtlas()
                        local shown=region.IsShown and region:IsShown()
                        local alpha=region.GetAlpha and region:GetAlpha()
                        local l=region.GetLeft and region:GetLeft()
                        local t=region.GetTop and region:GetTop()
                        local w=region.GetWidth and region:GetWidth()
                        local h=region.GetHeight and region:GetHeight()
                        local key=path..'/region'..i
                        local value=table.concat({tostring(texture),tostring(atlas),tostring(shown),tostring(alpha),tostring(l),tostring(t),tostring(w),tostring(h)},'|')
                        data[key]={value=value,region=region,texture=texture,shown=shown,alpha=alpha,l=l,t=t,w=w,h=h}
                    end
                end
            end
            if frame.GetChildren then
                local children={frame:GetChildren()}
                for i,child in ipairs(children) do visit(child,path..'/child'..i,depth+1) end
            end
        end
        if WorldMapFrame and WorldMapFrame.IsShown and WorldMapFrame:IsShown() then visit(WorldMapFrame,'WorldMapFrame',0) end
        return data
    end
    local function coords(region)
        if not region or not region.GetTexCoord then return '?' end
        local ok,a,b,c,d,e,f,g,h=pcall(region.GetTexCoord,region)
        if not ok then return '?' end
        local parts={a,b,c,d,e,f,g,h}
        local output={}
        for _,v in ipairs(parts) do output[#output+1]=string.format('%.3f',tonumber(v) or 0) end
        return table.concat(output,',')
    end
    local watcher=CreateFrame('Frame')
    watcher:SetScript('OnUpdate',function(_,elapsed)
        if not state.active then return end
        state.clock=state.clock+(elapsed or 0)
        if state.clock<0.12 then return end
        state.clock=0
        local current=snapshot()
        for path,item in pairs(current) do
            local old=state.previous[path]
            if old and old.value~=item.value and item.shown and (item.alpha or 0)>0 then
                local signature=path..'|'..tostring(item.texture)..'|'..tostring(item.w)..'|'..tostring(item.h)
                if not state.seen[signature] and #state.events<100 then
                    state.seen[signature]=true
                    state.events[#state.events+1]={path=path,texture=tostring(item.texture),atlas=item.region.GetAtlas and tostring(item.region:GetAtlas()) or 'nil',rect=string.format('L%.1f T%.1f W%.1f H%.1f',item.l or 0,item.t or 0,item.w or 0,item.h or 0),uv=coords(item.region),layer=item.region.GetDrawLayer and tostring(item.region:GetDrawLayer()) or '?',alpha=tostring(item.alpha)}
                end
            end
        end
        state.previous=current
        state.samples=state.samples+1
    end)
    SLASH_FOREVERBROWSERMAPFOCUS1='/fbmapfocus'
    SlashCmdList.FOREVERBROWSERMAPFOCUS=function()
        if state.active then
            state.active=false
            say('Stopped: '..state.samples..' samples, '..#state.events..' changed visible textures. Run /fbmapfocusreport.')
        else
            state={active=true,clock=0,previous={},events={},seen={},samples=0}
            say('Started. Keep World Map open and hover slowly over 2-3 zones for 5 seconds; run /fbmapfocus to stop.')
        end
    end
    SLASH_FOREVERBROWSERMAPFOCUSREPORT1='/fbmapfocusreport'
    SlashCmdList.FOREVERBROWSERMAPFOCUSREPORT=function()
        say('Samples='..state.samples..'; candidates='..#state.events..'. First '..math.min(8,#state.events)..':')
        for i=1,math.min(8,#state.events) do
            local e=state.events[i]
            say(i..' '..e.path..' texture='..e.texture..' atlas='..e.atlas)
            say('  '..e.rect..' alpha='..e.alpha..' layer='..e.layer..' uv='..e.uv)
        end
    end
end


-- Map focus and highlight-layer probe (diagnostic only; no UI modifications).
do
    local P={active=false,elapsed=0,samples=0,events={},seen={},previous={}}
    local function say(s) if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage('|cffffcc55FB Map Hover:|r '..s) end end
    local function pathFor(f)
        if not f then return 'nil' end
        local parts={}
        for i=1,12 do
            if not f then break end
            local name=f.GetName and f:GetName()
            local parent=f.GetParent and f:GetParent()
            local tag=name
            if not tag then
                local idx='?'
                if parent and parent.GetChildren then
                    local children={parent:GetChildren()}
                    for n,c in ipairs(children) do if c==f then idx=tostring(n) break end end
                end
                tag='child'..idx
            end
            table.insert(parts,1,tag)
            if f==WorldMapFrame then break end
            f=parent
        end
        return table.concat(parts,'/')
    end
    local function snapshot()
        local out={}
        local function visit(frame,path,depth)
            if depth>16 or not frame then return end
            if frame.GetRegions then
                local regions={frame:GetRegions()}
                for i,r in ipairs(regions) do
                    if r and r.GetObjectType and r:GetObjectType()=='Texture' then
                        local layer=r.GetDrawLayer and r:GetDrawLayer() or '?'
                        local texture=r.GetTexture and r:GetTexture() or 'nil'
                        local atlas=r.GetAtlas and r:GetAtlas() or 'nil'
                        local shown=r.IsShown and r:IsShown() or false
                        local alpha=r.GetAlpha and r:GetAlpha() or 0
                        local key=path..'/region'..i
                        out[key]={layer=layer,texture=texture,atlas=atlas,shown=shown,alpha=alpha,
                            x=r.GetLeft and r:GetLeft(),y=r.GetTop and r:GetTop(),
                            w=r.GetWidth and r:GetWidth(),h=r.GetHeight and r:GetHeight()}
                    end
                end
            end
            if frame.GetChildren then
                local children={frame:GetChildren()}
                for i,child in ipairs(children) do visit(child,path..'/child'..i,depth+1) end
            end
        end
        if WorldMapFrame and WorldMapFrame.IsShown and WorldMapFrame:IsShown() then
            visit(WorldMapFrame,'WorldMapFrame',0)
        end
        return out
    end
    local ticker=CreateFrame('Frame')
    ticker:SetScript('OnUpdate',function(_,elapsed)
        if not P.active then return end
        P.elapsed=P.elapsed+(elapsed or 0)
        if P.elapsed<0.12 then return end
        P.elapsed=0
        local focus=GetMouseFocus and GetMouseFocus() or nil
        local focusPath=pathFor(focus)
        local snap=snapshot()
        local changes=0
        for key,v in pairs(snap) do
            local old=P.previous[key]
            if old and (old.texture~=v.texture or old.alpha~=v.alpha or old.shown~=v.shown or old.atlas~=v.atlas) then
                local isHighlight=v.layer=='HIGHLIGHT' or old.layer=='HIGHLIGHT'
                local sig=key..'|'..tostring(v.texture)..'|'..tostring(v.shown)..'|'..tostring(v.alpha)
                if not P.seen[sig] and #P.events<100 then
                    P.seen[sig]=true
                    P.events[#P.events+1]={key=key,layer=v.layer,tex=tostring(v.texture),atlas=tostring(v.atlas),
                        alpha=tostring(v.alpha),shown=tostring(v.shown),focus=focusPath,
                        size=string.format('%.1fx%.1f',v.w or 0,v.h or 0),important=isHighlight}
                    changes=changes+1
                end
            end
        end
        if focusPath~=P.lastFocus and #P.events<100 then
            P.events[#P.events+1]={focusOnly=true,focus=focusPath}
            P.lastFocus=focusPath
        end
        P.previous=snap
        P.samples=P.samples+1
    end)
    SLASH_FOREVERBROWSERHOVERPROBE1='/fbhoverprobe'
    SlashCmdList.FOREVERBROWSERHOVERPROBE=function()
        if P.active then
            P.active=false
            say('Stopped: '..P.samples..' samples; '..#P.events..' changes/focus transitions. Use /fbhoverreport.')
        else
            P={active=true,elapsed=0,samples=0,events={},seen={},previous={}}
            say('Started. Keep World Map open and move over 3 zones for 5 seconds, then /fbhoverprobe.')
        end
    end
    SLASH_FOREVERBROWSERHOVERREPORT1='/fbhoverreport'
    SlashCmdList.FOREVERBROWSERHOVERREPORT=function()
        local ranked={}
        for _,v in ipairs(P.events) do
            if v.important then ranked[#ranked+1]=v end
        end
        say('Samples '..P.samples..'; highlight-layer changes '..#ranked..'; total events '..#P.events)
        if #ranked==0 then
            say('No HIGHLIGHT-layer changes detected; showing focus changes and first texture events.')
            for _,v in ipairs(P.events) do if #ranked<8 then ranked[#ranked+1]=v end end
        end
        for i=1,math.min(8,#ranked) do
            local v=ranked[i]
            if v.focusOnly then say(i..' Mouse focus: '..v.focus)
            else
                say(i..' '..v.key..' layer='..v.layer..' ID='..v.tex..' atlas='..v.atlas)
                say(' visible='..v.shown..' alpha='..v.alpha..' size='..v.size..' focus='..v.focus)
            end
        end
    end
end

-- FOREVERBROWSER: ZONE ART / CURSOR POSITION DIAGNOSTIC
-- Standalone diagnostic; does not modify the embedded map or button layout.
do
    local probe={running=false,elapsed=0,records={},last='',samples=0}
    local function say(msg)
        if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage('|cffffd36bFB Zone Art:|r '..tostring(msg)) end
    end
    local function api(name,...)
        if not C_Map or type(C_Map[name])~='function' then return nil,'unavailable' end
        local ok,a,b,c,d=pcall(C_Map[name],...)
        if ok then return a,b,c,d end
        return nil,tostring(a)
    end
    local function mouseMap()
        local map=WorldMapFrame
        if not map or not map.IsShown or not map:IsShown() then return nil end
        local container=map.ScrollContainer or map
        local left,right,top,bottom=container:GetLeft(),container:GetRight(),container:GetTop(),container:GetBottom()
        if not left or not right or not top or not bottom or right==left or top==bottom then return nil end
        local x,y=GetCursorPosition()
        local scale=container:GetEffectiveScale()
        if not scale or scale==0 then return nil end
        x=x/scale y=y/scale
        local px,py=(x-left)/(right-left),(top-y)/(top-bottom)
        if px<0 or px>1 or py<0 or py>1 then return nil end
        local id=(map.GetMapID and map:GetMapID()) or (map.mapID)
        if not id and C_Map and C_Map.GetBestMapForUnit then id=api('GetBestMapForUnit','player') end
        return id,px,py
    end
    local function sample()
        local id,x,y=mouseMap()
        if not id then return end
        local child,err=api('GetMapInfoAtPosition',id,x,y)
        local childID=type(child)=='table' and child.mapID or tonumber(child)
        local childName=type(child)=='table' and child.name or nil
        local key=tostring(id)..':'..tostring(childID)..':'..tostring(err)
        if key~=probe.last then
            probe.last=key
            if #probe.records<30 then
                probe.records[#probe.records+1]={parent=id,child=childID,name=childName,x=x,y=y,error=err}
            end
        end
        probe.samples=probe.samples+1
    end
    local driver=CreateFrame('Frame')
    driver:SetScript('OnUpdate',function(_,elapsed)
        if not probe.running then return end
        probe.elapsed=probe.elapsed+(elapsed or 0)
        if probe.elapsed>=0.15 then probe.elapsed=0 sample() end
    end)
    SLASH_FOREVERBROWSERZONEART1='/fbzoneart'
    SlashCmdList.FOREVERBROWSERZONEART=function()
        probe.running=not probe.running
        if probe.running then
            probe.records={} probe.last='' probe.samples=0 probe.elapsed=0
            say('Recording. Hover 3 zones on the OPEN normal World Map for 5 seconds; then /fbzoneart to stop.')
        else say('Stopped. '..probe.samples..' samples; '..#probe.records..' map transitions. Type /fbzoneartreport.') end
    end
    SLASH_FOREVERBROWSERZONEARTREPORT1='/fbzoneartreport'
    SlashCmdList.FOREVERBROWSERZONEARTREPORT=function()
        say('C_Map.GetMapInfoAtPosition='..tostring(C_Map and type(C_Map.GetMapInfoAtPosition)))
        say('C_Map.GetMapArtLayers='..tostring(C_Map and type(C_Map.GetMapArtLayers)))
        say('C_Map.GetMapArtLayerTextures='..tostring(C_Map and type(C_Map.GetMapArtLayerTextures)))
        say('Samples='..probe.samples..', transitions='..#probe.records)
        for i=1,math.min(10,#probe.records) do
            local r=probe.records[i]
            say(i..' map='..tostring(r.parent)..' at '..string.format('%.3f,%.3f',r.x,r.y)..' zone='..tostring(r.child)..' '..tostring(r.name or r.error or ''))
        end
        local id=probe.records[#probe.records] and probe.records[#probe.records].parent
        if id then
            local layers,err=api('GetMapArtLayers',id)
            say('Art layers for map '..id..': '..(type(layers)=='table' and #layers or tostring(err or 'none')))
            if type(layers)=='table' then
                for i=1,math.min(3,#layers) do
                    local layer=layers[i]
                    say('Layer '..i..': '..tostring(layer.layerIndex)..' '..tostring(layer.layerWidth)..'x'..tostring(layer.layerHeight)..' tiles '..tostring(layer.tileWidth)..'x'..tostring(layer.tileHeight))
                end
            end
        end
    end
end
