local _, namespace = ...
local FC = namespace.FC

local function itemIDFromLink(link)
    if FC:IsSecret(link) or type(link) ~= "string" then
        return nil
    end
    if GetItemInfoInstant then
        local itemID = GetItemInfoInstant(link)
        if not FC:IsSecret(itemID) and type(itemID) == "number" then
            return itemID
        end
    end
    return tonumber(link:match("item:(%d+)"))
end

local function npcIDFromUnit(unit)
    if FC:IsSecret(unit) or type(unit) ~= "string" then
        return nil
    end
    local exists = UnitExists(unit)
    if FC:IsSecret(exists) or not exists then
        return nil
    end
    local guid = UnitGUID(unit)
    if FC:IsSecret(guid) or type(guid) ~= "string" then
        return nil
    end
    local unitType, _, _, _, _, objectID = strsplit("-", guid)
    if unitType == "Creature" or unitType == "Vehicle" or unitType == "Pet" then
        return tonumber(objectID)
    end
    return nil
end

local function addHeader(tooltip)
    tooltip:AddLine(" ")
    tooltip:AddLine(FC.L.TOOLTIP_HEADER, 1.00, 0.82, 0.00)
end

local function ensureClearHook(tooltip)
    if not tooltip or tooltip.__foreverChronicleClearHook or not tooltip.HookScript then
        return
    end
    tooltip.__foreverChronicleClearHook = true
    tooltip:HookScript("OnTooltipCleared", function(owner)
        owner.__foreverChronicleItem = nil
        owner.__foreverChronicleNPC = nil
    end)
end

local function addItemMemory(tooltip)
    if not FC.initialized or not FC.db.settings.showTooltips or not tooltip or not tooltip.GetItem then
        return
    end
    ensureClearHook(tooltip)
    local _, link = tooltip:GetItem()
    local itemID = itemIDFromLink(link)
    if not itemID or tooltip.__foreverChronicleItem == itemID then
        return
    end
    tooltip.__foreverChronicleItem = itemID
    local memory = FC:GetItemMemory(itemID)
    if #memory.characters == 0 and not memory.latest and not next(memory.vendors) then
        return
    end

    addHeader(tooltip)
    for _, character in ipairs(memory.characters) do
        tooltip:AddDoubleLine(
            character.key,
            string.format(FC.L.TOOLTIP_COUNTS, character.bags, character.bank),
            0.88, 0.82, 0.66, 1.00, 1.00, 1.00
        )
    end
    if memory.latest and memory.latest.location then
        tooltip:AddDoubleLine(
            FC.L.TOOLTIP_LAST_SEEN,
            FC:FormatLocation(memory.latest.location),
            0.70, 0.70, 0.70, 0.45, 0.78, 1.00
        )
    end
    local vendors = {}
    for vendor in pairs(memory.vendors) do
        table.insert(vendors, vendor)
    end
    table.sort(vendors)
    if #vendors > 0 then
        tooltip:AddDoubleLine(FC.L.TOOLTIP_VENDOR, table.concat(vendors, ", "), 0.70, 0.70, 0.70, 1.00, 0.82, 0.25)
    end
    tooltip:Show()
end

local function addUnitMemory(tooltip)
    if not FC.initialized or not FC.db.settings.showTooltips or not tooltip or not tooltip.GetUnit then
        return
    end
    ensureClearHook(tooltip)
    local _, unit = tooltip:GetUnit()
    local npcID = npcIDFromUnit(unit)
    if not npcID or tooltip.__foreverChronicleNPC == npcID then
        return
    end
    tooltip.__foreverChronicleNPC = npcID
    local memory = FC:GetNPCMemory(npcID)
    if not memory then
        return
    end
    addHeader(tooltip)
        tooltip:AddDoubleLine(string.format(FC.L.NPC_ID, npcID), memory.kind == "rares" and FC.L.RARE or FC.L.NPC, 0.70, 0.70, 0.70, 1.00, 0.82, 0.25)
    if memory.location then
        tooltip:AddDoubleLine(FC.L.TOOLTIP_LAST_SEEN, FC:FormatLocation(memory.location), 0.70, 0.70, 0.70, 0.45, 0.78, 1.00)
    end
    tooltip:Show()
end

local function installTooltipHooks()
    if not GameTooltip or GameTooltip.__foreverChronicleHooks then
        return
    end
    GameTooltip.__foreverChronicleHooks = true
    ensureClearHook(GameTooltip)
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType
        and Enum.TooltipDataType.Item and Enum.TooltipDataType.Unit then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, addItemMemory)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, addUnitMemory)
    else
        GameTooltip:HookScript("OnTooltipSetItem", addItemMemory)
        GameTooltip:HookScript("OnTooltipSetUnit", addUnitMemory)
    end
end

FC:RegisterEvent("PLAYER_LOGIN", function()
    installTooltipHooks()
end)
