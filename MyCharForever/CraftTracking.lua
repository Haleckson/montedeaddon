local addonName, MCF = ...
-- Persistent crafting history; only structured successful result events count.
-- Independent of the optional debug recorder and its settings.
local frame = CreateFrame("Frame")
local function safe(v)
    if issecretvalue and issecretvalue(v) then return nil end
    return v
end
local function ensure()
    local db = MyCharForeverDB
    if type(db) ~= "table" then return nil end
    if type(db.crafting) ~= "table" then db.crafting = {} end
    local c = db.crafting
    if type(c.history) ~= "table" then c.history = {} end
    if type(c.items) ~= "table" then c.items = {} end
    if type(c.totals) ~= "table" then c.totals = {events=0,quantity=0} end
    return c
end
local function onCraft(result)
    if type(result) ~= "table" then return end
    local itemID = safe(result.itemID)
    local quantity = safe(result.quantity)
    local hyperlink = safe(result.hyperlink)
    if type(itemID) ~= "number" or itemID <= 0 then return end
    if type(quantity) ~= "number" or quantity <= 0 or quantity ~= math.floor(quantity) then return end
    local db = ensure()
    if not db then return end
    local stamp = time()
    local level = safe(UnitLevel("player"))
    local zone = safe(GetZoneText())
    local subZone = safe(GetSubZoneText())
    local mapID
    if C_Map and C_Map.GetBestMapForUnit then
        local ok, id = pcall(C_Map.GetBestMapForUnit, "player")
        if ok then mapID = safe(id) end
    end
    local entry = {
        time=stamp, itemID=itemID, quantity=quantity,
        hyperlink=type(hyperlink)=="string" and hyperlink or nil,
        level=type(level)=="number" and level or nil,
        zone=type(zone)=="string" and zone or nil,
        subZone=type(subZone)=="string" and subZone or nil,
        mapID=type(mapID)=="number" and mapID or nil,
        source="TRADE_SKILL_ITEM_CRAFTED_RESULT",
    }
    table.insert(db.history, entry)
    local key=tostring(itemID)
    local item=db.items[key]
    if type(item) ~= "table" then item={itemID=itemID,quantity=0,crafts=0}; db.items[key]=item end
    item.quantity=item.quantity+quantity
    item.crafts=item.crafts+1
    if entry.hyperlink then item.hyperlink=entry.hyperlink end
    db.totals.events=(db.totals.events or 0)+1
    db.totals.quantity=(db.totals.quantity or 0)+quantity
end
pcall(function() frame:RegisterEvent("TRADE_SKILL_ITEM_CRAFTED_RESULT") end) -- unknown event in some clients: must not abort loading
frame:SetScript("OnEvent", function(_, event, result)
    if event=="TRADE_SKILL_ITEM_CRAFTED_RESULT" then
        -- Never count CHAT_MSG_LOOT or spellcasts as a second craft.
        local ok, err=pcall(onCraft, result)
        if not ok and MCF and MCF.DebugLog then pcall(MCF.DebugLog, MCF, "professions", "CRAFT_TRACK_ERROR", tostring(err)) end
    end
end)
function MCF:GetCraftingHistory()
    local db=ensure()
    return db and db.history or {}
end
function MCF:GetCraftingTotals()
    local db=ensure()
    return db and db.items or {}
end
