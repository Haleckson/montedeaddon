--------------------------------------------------
-- ForeverDB
-- Automatic Item Database + Source Learning
-- WoW Forever / Interface 30300
--------------------------------------------------

local ADDON_NAME = "ForeverDB"

--------------------------------------------------
-- DATABASE
--------------------------------------------------

ForeverDBDatabase = ForeverDBDatabase or {}

ForeverDBDatabase.items =
    ForeverDBDatabase.items or {}

local Items =
    ForeverDBDatabase.items


--------------------------------------------------
-- SAFE CALL
--------------------------------------------------

local function SafeCall(func, ...)
    if not func then
        return nil
    end

    local ok, a, b, c, d, e =
        pcall(func, ...)

    if ok then
        return a, b, c, d, e
    end

    return nil
end


--------------------------------------------------
-- ITEM INFO
--------------------------------------------------

local function GetItemInfoSafe(itemID)

    if not itemID then
        return nil
    end

    if C_Item
        and C_Item.GetItemInfo then

        local name,
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
            SafeCall(
                C_Item.GetItemInfo,
                itemID
            )

        if name then

            return {
                name = name,
                link = link,
                quality = quality,
                itemLevel = itemLevel,
                requiredLevel = requiredLevel,
                class = class,
                subclass = subclass,
                maxStack = maxStack,
                equipSlot = equipSlot,
                texture = texture,
                sellPrice = sellPrice,
            }

        end
    end


    if GetItemInfo then

        local name,
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
            SafeCall(
                GetItemInfo,
                itemID
            )

        if name then

            return {
                name = name,
                link = link,
                quality = quality,
                itemLevel = itemLevel,
                requiredLevel = requiredLevel,
                class = class,
                subclass = subclass,
                maxStack = maxStack,
                equipSlot = equipSlot,
                texture = texture,
                sellPrice = sellPrice,
            }

        end
    end

    return nil
end


--------------------------------------------------
-- ITEM INFO INSTANT
--------------------------------------------------

local function GetItemInfoInstantSafe(itemID)

    if not itemID then
        return nil
    end

    if C_Item
        and C_Item.GetItemInfoInstant then

        return SafeCall(
            C_Item.GetItemInfoInstant,
            itemID
        )
    end

    if GetItemInfoInstant then

        return SafeCall(
            GetItemInfoInstant,
            itemID
        )
    end

    return nil
end


--------------------------------------------------
-- ITEM ID FROM LINK
--------------------------------------------------

local function GetItemIDFromLink(link)

    if not link then
        return nil
    end

    local id =
        string.match(
            link,
            "item:(%d+)"
        )

    if id then
        return tonumber(id)
    end

    return nil
end


--------------------------------------------------
-- ITEM ID FROM TEXT
--------------------------------------------------

local function GetItemIDFromText(text)

    if not text then
        return nil
    end

    local id =
        string.match(
            text,
            "item:(%d+)"
        )

    if id then
        return tonumber(id)
    end

    return nil
end


--------------------------------------------------
-- SAVE ITEM
--------------------------------------------------

local function SaveItem(
    itemID,
    quantity,
    location
)

    if not itemID then
        return
    end

    itemID =
        tonumber(itemID)

    if not itemID then
        return
    end


    local item =
        Items[itemID]

    if not item then

        item = {}

        Items[itemID] =
            item

    end


    local info =
        GetItemInfoSafe(itemID)


    if info then

        item.name =
            info.name or item.name

        item.link =
            info.link or item.link

        item.quality =
            info.quality or item.quality

        item.itemLevel =
            info.itemLevel or item.itemLevel

        item.requiredLevel =
            info.requiredLevel
            or item.requiredLevel

        item.class =
            info.class or item.class

        item.subclass =
            info.subclass or item.subclass

        item.maxStack =
            info.maxStack or item.maxStack

        item.equipSlot =
            info.equipSlot
            or item.equipSlot

        item.texture =
            info.texture
            or item.texture

        item.sellPrice =
            info.sellPrice
            or item.sellPrice

    end


    item.itemID =
        itemID

    item.discovered =
        true

    item.lastSeen =
        time()


    if quantity then

        item.quantity =
            tonumber(quantity)
            or item.quantity
            or 1

    end


    --------------------------------------------------
    -- LOCATIONS
    --------------------------------------------------

    if location then

        item.locations =
            item.locations or {}

        local found = false

        for _, oldLocation
            in ipairs(item.locations) do

            if oldLocation == location then
                found = true
                break
            end

        end


        if not found then

            table.insert(
                item.locations,
                location
            )

        end

    end

end


--------------------------------------------------
-- BAG SCANNING
--------------------------------------------------

local function ScanBag(bag)

    if not GetContainerNumSlots then
        return
    end

    local slots =
        GetContainerNumSlots(bag)

    if not slots then
        return
    end


    for slot = 1, slots do

        local link =
            GetContainerItemLink(
                bag,
                slot
            )

        local itemID =
            GetItemIDFromLink(link)


        if itemID then

            local _, count =
                GetContainerItemInfo(
                    bag,
                    slot
                )

            SaveItem(
                itemID,
                count,
                "Bag " .. tostring(bag)
            )

        end

    end

end


--------------------------------------------------
-- SCAN ALL BAGS
--------------------------------------------------

local function ScanAll()

    if not GetContainerNumSlots then
        return
    end


    for bag = 0, 4 do

        ScanBag(bag)

    end

end


--------------------------------------------------
-- BANK STATUS
--------------------------------------------------

local function IsBankOpen()

    if BankFrame
        and BankFrame:IsShown() then

        return true

    end

    return false
end


--------------------------------------------------
-- ZONE
--------------------------------------------------

local function GetCurrentZone()

    if GetRealZoneText then

        local zone =
            SafeCall(
                GetRealZoneText
            )

        if zone
            and zone ~= "" then

            return zone

        end

    end


    if GetZoneText then

        local zone =
            SafeCall(
                GetZoneText
            )

        if zone
            and zone ~= "" then

            return zone

        end

    end


    return "Unknown Zone"
end


--------------------------------------------------
-- GUID TYPE
--------------------------------------------------

local function GetGUIDType(guid)

    if not guid then
        return "Unknown"
    end


    local unitType =
        string.match(
            guid,
            "^([^%-]+)"
        )

    if unitType then

        return unitType

    end

    return "Unknown"
end


--------------------------------------------------
-- SOURCE NAME
--------------------------------------------------

local function GetSourceName(guid)

    if not guid then
        return nil
    end


    local unitID


    if UnitGUID then

        local playerGUID =
            SafeCall(
                UnitGUID,
                "player"
            )

        if guid == playerGUID then
            return UnitName("player")
        end

    end


    if UnitName then

        for i = 1, 40 do

            local unit =
                "nameplate" .. i

            local unitGUID =
                SafeCall(
                    UnitGUID,
                    unit
                )

            if unitGUID == guid then

                local name =
                    SafeCall(
                        UnitName,
                        unit
                    )

                if name then
                    return name
                end

            end

        end

    end


    return nil
end


--------------------------------------------------
-- SOURCE DEBUG
--------------------------------------------------

ForeverDBDebugLog = ForeverDBDebugLog or {}
ForeverDBDebugEnabled = true

local function AddForeverDBDebug(...)
    if not ForeverDBDebugEnabled then
        return
    end

    local parts = {}
    local count = select("#", ...)

    for i = 1, count do
        parts[i] = tostring(select(i, ...))
    end

    local stamp = date and date("%H:%M:%S") or ""
    local message = table.concat(parts, " ")

    if stamp ~= "" then
        message = "[" .. stamp .. "] " .. message
    end

    table.insert(ForeverDBDebugLog, message)

    while #ForeverDBDebugLog > 300 do
        table.remove(ForeverDBDebugLog, 1)
    end
end

_G.ForeverDB_AddDebug = AddForeverDBDebug

local function PrintSourceDebug(...)
    AddForeverDBDebug(...)
end


--------------------------------------------------
-- GET LOOT ITEM ID
--------------------------------------------------

local function GetLootItemID(slot)

    --------------------------------------------------
    -- METHOD 1: GetLootSlotLink
    --------------------------------------------------

    if GetLootSlotLink then

        local link =
            SafeCall(
                GetLootSlotLink,
                slot
            )

        if link then

            local itemID =
                GetItemIDFromLink(link)

            if itemID then

                PrintSourceDebug(
                    "Item found through GetLootSlotLink:",
                    itemID,
                    link
                )

                return itemID

            end

        end

    end


    --------------------------------------------------
    -- METHOD 2: GetLootSlotInfo
    --------------------------------------------------

    if GetLootSlotInfo then

        local icon,
            name,
            quantity,
            currencyID,
            quality,
            locked,
            isQuestItem,
            questItemID,
            isActive =
            SafeCall(
                GetLootSlotInfo,
                slot
            )


        PrintSourceDebug(
            "GetLootSlotInfo:",
            "icon=" .. tostring(icon),
            "name=" .. tostring(name),
            "quantity=" .. tostring(quantity),
            "currencyID=" .. tostring(currencyID),
            "quality=" .. tostring(quality)
        )


        if name then

            local itemID =
                GetItemIDFromText(name)

            if itemID then

                return itemID

            end


            --------------------------------------------------
            -- SEARCH OWNED DATABASE BY NAME
            --------------------------------------------------

            for id, item in pairs(Items) do

                if item
                    and item.name
                    and item.name == name then

                    return tonumber(id)

                end

            end

        end

    end


    return nil
end


--------------------------------------------------
-- SAVE LOOT SOURCE
--------------------------------------------------

local function SaveLootSource(
    itemID,
    sourceGUID,
    sourceType,
    sourceName,
    quantity
)

    if not itemID then
        return
    end


    itemID =
        tonumber(itemID)

    if not itemID then
        return
    end


    local item =
        Items[itemID]


    if not item then

        SaveItem(
            itemID,
            quantity,
            "Loot"
        )

        item =
            Items[itemID]

    end


    if not item then
        return
    end


    item.sources =
        item.sources or {}


    --------------------------------------------------
    -- SOURCE NAME
    --------------------------------------------------

    local finalName =
        sourceName


    if not finalName
        and sourceGUID then

        finalName =
            GetSourceName(
                sourceGUID
            )

    end


    if not finalName
        or finalName == "" then

        finalName =
            "Unknown Source"

    end


    --------------------------------------------------
    -- FIND EXISTING SOURCE
    --------------------------------------------------

    local existing = nil


    for _, source
        in ipairs(item.sources) do

        if source
            and source.guid
            and sourceGUID
            and source.guid == sourceGUID then

            existing = source
            break

        end


        if source
            and source.name == finalName then

            existing = source
            break

        end

    end


    --------------------------------------------------
    -- CREATE SOURCE
    --------------------------------------------------

    if not existing then

        existing = {

            name = finalName,

            type =
                sourceType
                or "Unknown",

            guid =
                sourceGUID,

            zone =
                GetCurrentZone(),

            observations = 0,

            quantity = 0,

            firstSeen = time(),

            lastSeen = time(),

        }


        table.insert(
            item.sources,
            existing
        )

    end


    --------------------------------------------------
    -- UPDATE SOURCE
    --------------------------------------------------

    existing.name =
        finalName

    existing.type =
        sourceType
        or existing.type
        or "Unknown"

    existing.guid =
        sourceGUID
        or existing.guid

    existing.zone =
        GetCurrentZone()

    existing.observations =
        (existing.observations or 0)
        + 1

    existing.quantity =
        (existing.quantity or 0)
        + (tonumber(quantity) or 1)

    existing.lastSeen =
        time()


    --------------------------------------------------
    -- LOCATION
    --------------------------------------------------

    item.locations =
        item.locations or {}


    local location =
        finalName
        .. " - "
        .. tostring(
            GetCurrentZone()
        )


    local found = false


    for _, oldLocation
        in ipairs(item.locations) do

        if oldLocation == location then

            found = true
            break

        end

    end


    if not found then

        table.insert(
            item.locations,
            location
        )

    end


    AddForeverDBDebug(
        "SOURCE LEARNED",
        itemID,
        finalName
    )

end


--------------------------------------------------
-- LEARN LOOT
--------------------------------------------------

local function LearnLoot()

    if not GetNumLootItems then

        PrintSourceDebug(
            "GetNumLootItems API is missing."
        )

        return

    end


    local numLoot =
        SafeCall(
            GetNumLootItems
        )


    PrintSourceDebug(
        "LOOT SLOTS:",
        tostring(numLoot)
    )


    if not numLoot
        or numLoot == 0 then

        PrintSourceDebug(
            "No loot slots found."
        )

        return

    end


    --------------------------------------------------
    -- SOURCE INFORMATION
    --------------------------------------------------

    local sourceGUID
    local sourceName
    local sourceType


    if GetLootSourceInfo then

        for slot = 1, numLoot do

            local a, b, c, d =
                SafeCall(
                    GetLootSourceInfo,
                    slot
                )


            PrintSourceDebug(
                "GetLootSourceInfo slot",
                slot,
                "A=" .. tostring(a),
                "B=" .. tostring(b),
                "C=" .. tostring(c),
                "D=" .. tostring(d)
            )


            if a then

                sourceGUID = a

                break

            end

        end

    else

        PrintSourceDebug(
            "GetLootSourceInfo API is missing."
        )

    end


    if sourceGUID then

        sourceType =
            GetGUIDType(
                sourceGUID
            )

        sourceName =
            GetSourceName(
                sourceGUID
            )

    end


    PrintSourceDebug(
        "FINAL SOURCE:",
        "GUID=" .. tostring(sourceGUID),
        "TYPE=" .. tostring(sourceType),
        "NAME=" .. tostring(sourceName)
    )


    --------------------------------------------------
    -- PROCESS LOOT
    --------------------------------------------------

    for slot = 1, numLoot do

        PrintSourceDebug(
            "Processing loot slot:",
            slot
        )


        local itemID =
            GetLootItemID(
                slot
            )


        if itemID then

            PrintSourceDebug(
                "Loot item ID:",
                itemID
            )


            local quantity = 1


            if GetLootSlotInfo then

                local icon,
                    name,
                    count =
                    SafeCall(
                        GetLootSlotInfo,
                        slot
                    )

                if count
                    and tonumber(count) then

                    quantity =
                        tonumber(count)

                end

            end


            SaveItem(
                itemID,
                quantity,
                "Loot"
            )


            SaveLootSource(
                itemID,
                sourceGUID,
                sourceType,
                sourceName,
                quantity
            )

        else

            PrintSourceDebug(
                "Could NOT determine item ID for slot",
                slot
            )

        end

    end

end


--------------------------------------------------
-- SEARCH
--------------------------------------------------

local function SearchItems(searchText)

    local results = {}

    if not searchText
        or searchText == "" then

        return results

    end


    searchText =
        string.lower(
            tostring(searchText)
        )


    for id, item in pairs(Items) do

        if item then

            local name =
                string.lower(
                    tostring(
                        item.name or ""
                    )
                )


            if string.find(
                name,
                searchText,
                1,
                true
            ) then

                table.insert(
                    results,
                    item
                )

            end

        end

    end


    table.sort(
        results,
        function(a, b)

            return tostring(
                a.name or ""
            )
            <
            tostring(
                b.name or ""
            )

        end
    )


    return results
end


--------------------------------------------------
-- SOURCE COUNT
--------------------------------------------------

local function GetSourceCount(itemID)

    itemID =
        tonumber(itemID)

    if not itemID then
        return 0
    end


    local item =
        Items[itemID]

    if not item
        or not item.sources then

        return 0

    end


    return #item.sources
end


--------------------------------------------------
-- PUBLIC API
--------------------------------------------------

local ForeverDB = {}


function ForeverDB:GetItem(itemID)

    return Items[
        tonumber(itemID)
    ]

end


function ForeverDB:GetItems()

    return Items

end


function ForeverDB:GetItemCount()

    local count = 0

    for _ in pairs(Items) do
        count = count + 1
    end

    return count
end


function ForeverDB:GetSourceCount(itemID)

    return GetSourceCount(itemID)

end


function ForeverDB:Search(text)

    return SearchItems(text)

end


function ForeverDB:Scan()

    ScanAll()

end


function ForeverDB:LearnLoot()

    LearnLoot()

end


function ForeverDB:GetItemSources(itemID)

    itemID =
        tonumber(itemID)

    local item =
        Items[itemID]

    if item
        and item.sources then

        return item.sources

    end

    return {}

end


--------------------------------------------------
-- WORLD DATABASE
--------------------------------------------------

local function GetWorldItems()

    if ForeverWorldData
        and ForeverWorldData.items then

        return ForeverWorldData.items

    end

    return {}
end


local function GetWorldItem(itemID)

    itemID =
        tonumber(itemID)

    if not itemID then
        return nil
    end


    local worldItems =
        GetWorldItems()


    return worldItems[itemID]
end


local function GetWorldItemCount()

    local count = 0


    for _ in pairs(
        GetWorldItems()
    ) do

        count =
            count + 1

    end


    return count
end


function ForeverDB:GetWorldItems()

    return GetWorldItems()

end


function ForeverDB:GetWorldItem(itemID)

    return GetWorldItem(itemID)

end


function ForeverDB:GetWorldItemCount()

    return GetWorldItemCount()

end


function ForeverDB:GetTotalItemCount()

    local playerCount =
        self:GetItemCount()

    local worldCount =
        self:GetWorldItemCount()


    return playerCount,
        worldCount,
        playerCount + worldCount
end


--------------------------------------------------
-- RESET
--------------------------------------------------

function ForeverDB:Reset()

    ForeverDBDatabase.items =
        {}

    Items =
        ForeverDBDatabase.items


    print(
        "|cffff8800ForeverDB: database reset.|r"
    )

end


--------------------------------------------------
-- DELAYED INITIAL SCAN
--------------------------------------------------

local ScanFrame =
    CreateFrame(
        "Frame"
    )


local scanTimer = 0
local scanPending = false


ScanFrame:SetScript(
    "OnUpdate",
    function(self, elapsed)

        if not scanPending then
            return
        end


        scanTimer =
            scanTimer + elapsed


        if scanTimer >= 3 then

            scanPending = false
            scanTimer = 0


            ScanAll()


            print(
                "|cff00ff00ForeverDB: initial bag scan complete.|r",
                "Items:",
                ForeverDB:GetItemCount()
            )

        end

    end
)


--------------------------------------------------
-- EVENT FRAME
--------------------------------------------------

local EventFrame =
    CreateFrame(
        "Frame"
    )


EventFrame:RegisterEvent(
    "PLAYER_LOGIN"
)

EventFrame:RegisterEvent(
    "PLAYER_ENTERING_WORLD"
)

EventFrame:RegisterEvent(
    "BAG_UPDATE"
)

EventFrame:RegisterEvent(
    "BANKFRAME_OPENED"
)

EventFrame:RegisterEvent(
    "PLAYERBANKSLOTS_CHANGED"
)

EventFrame:RegisterEvent(
    "LOOT_OPENED"
)

EventFrame:RegisterEvent(
    "LOOT_READY"
)


EventFrame:SetScript(
    "OnEvent",
    function(
        self,
        event,
        ...
    )

        --------------------------------------------------
        -- LOGIN
        --------------------------------------------------

        if event ==
            "PLAYER_LOGIN" then

            scanPending = true
            scanTimer = 0

            print(
                "|cff00ff00ForeverDB loaded.|r"
            )

            print(
                "Player items:",
                ForeverDB:GetItemCount()
            )

            print(
                "World items:",
                ForeverDB:GetWorldItemCount()
            )

            return
        end


        --------------------------------------------------
        -- ENTER WORLD
        --------------------------------------------------

        if event ==
            "PLAYER_ENTERING_WORLD" then

            scanPending = true
            scanTimer = 0

            return
        end


        --------------------------------------------------
        -- BAG UPDATE
        --------------------------------------------------

        if event ==
            "BAG_UPDATE" then

            local bag =
                ...

            if bag ~= nil then

                ScanBag(
                    tonumber(bag)
                    or 0
                )

            else

                ScanAll()

            end

            return
        end


        --------------------------------------------------
        -- BANK
        --------------------------------------------------

        if event ==
            "BANKFRAME_OPENED"
            or event ==
            "PLAYERBANKSLOTS_CHANGED" then

            if IsBankOpen() then

                ScanAll()

            end

            return
        end


        --------------------------------------------------
        -- LOOT OPENED
        --------------------------------------------------

        if event ==
            "LOOT_OPENED" then

            AddForeverDBDebug(
                "LOOT_OPENED detected."
            )

            LearnLoot()

            return
        end


        --------------------------------------------------
        -- LOOT READY
        --------------------------------------------------

        if event ==
            "LOOT_READY" then

            AddForeverDBDebug(
                "LOOT_READY detected."
            )

            LearnLoot()

            return
        end

    end
)


--------------------------------------------------
-- SLASH COMMAND
--------------------------------------------------

SLASH_FOREVERDB1 =
    "/fdb"


SlashCmdList["FOREVERDB"] =
    function(msg)

        msg =
            string.trim
            and string.trim(msg)
            or msg


        --------------------------------------------------
        -- SCAN
        --------------------------------------------------

        if msg == "scan" then

            ScanAll()

            print(
                "|cff00ff00ForeverDB scan complete.|r",
                ForeverDB:GetItemCount(),
                "items"
            )

            return

        end


        --------------------------------------------------
        -- COUNT
        --------------------------------------------------

        if msg == "count" then

            print(
                "|cff00ff00ForeverDB Player Items:|r",
                ForeverDB:GetItemCount()
            )

            print(
                "|cff00ff00ForeverDB World Items:|r",
                ForeverDB:GetWorldItemCount()
            )

            return

        end


        --------------------------------------------------
        -- SOURCES
        --------------------------------------------------

        if msg == "sources" then

            local total = 0

            for id, item
                in pairs(Items) do

                if item
                    and item.sources then

                    total =
                        total
                        + #item.sources

                end

            end


            print(
                "|cff00ff00ForeverDB learned source records:|r",
                total
            )

            return

        end


        --------------------------------------------------
        -- RESET
        --------------------------------------------------

        if msg == "reset" then

            ForeverDB:Reset()

            return

        end


        --------------------------------------------------
        -- ITEM ID
        --------------------------------------------------

        local itemID =
            tonumber(msg)


        if itemID then

            local item =
                Items[itemID]


            if not item then

                print(
                    "|cffff0000ForeverDB: item not discovered yet.|r"
                )

                return

            end


            print(
                "|cff00ff00ForeverDB Item:|r",
                item.name
                or "Unknown",
                "(" .. tostring(itemID) .. ")"
            )


            if item.sources
                and #item.sources > 0 then

                print(
                    "|cff00ff00Sources:|r"
                )


                for _, source
                    in ipairs(item.sources) do

                    print(
                        " - ",
                        source.name
                        or "Unknown Source",

                        "|",

                        source.type
                        or "Unknown",

                        "|",

                        source.zone
                        or "Unknown Zone",

                        "| Observed:",
                        source.observations
                        or 0
                    )

                end

            else

                print(
                    "|cffff8800No sources discovered yet.|r"
                )

            end


            return

        end


        --------------------------------------------------
        -- TEXT SEARCH
        --------------------------------------------------

        if msg
            and msg ~= "" then

            local results =
                SearchItems(msg)


            print(
                "|cff00ff00ForeverDB search:|r",
                msg
            )


            print(
                "Results:",
                #results
            )


            for i = 1,
                math.min(
                    #results,
                    20
                ) do

                local item =
                    results[i]

                print(
                    item.itemID,
                    item.name
                )

            end


            return

        end


        --------------------------------------------------
        -- HELP
        --------------------------------------------------

        print(
            "|cff00ff00ForeverDB commands:|r"
        )

        print(
            "/fdb scan"
        )

        print(
            "/fdb count"
        )

        print(
            "/fdb sources"
        )

        print(
            "/fdb <itemID>"
        )

        print(
            "/fdb <search text>"
        )

        print(
            "/fdb reset"
        )

    end


--------------------------------------------------
-- GLOBAL API
--------------------------------------------------

_G.ForeverDB =
    ForeverDB


--------------------------------------------------
-- STARTUP
--------------------------------------------------

print(
    "|cff00ff00ForeverDB database engine ready.|r"
)