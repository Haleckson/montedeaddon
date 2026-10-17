local addonName, MCF = ...
-- Gathering (mining, herbalism, skinning, fishing) and salvaging (disenchanting, prospecting, milling).
-- Counted per resource: when a loot window opens right after one of these actions, every item in it is
-- added to db.gathering.kinds[kind].items[itemID]. The loot window is read when it opens, so an item the
-- player leaves in the window is counted too (auto-loot makes this the exception).
-- Disenchanting additionally remembers the quality of the destroyed item (when the game tells us).
--
-- db.gathering = { version=1, kinds = { [kind] = { events, quantity, items={[id]={quantity,name,link}},
--                  byLevel={[level]=quantity}, bySource={[quality]=count} } } }

local Readable = MCF.Readable or function(v) return v end

local GATHER_KINDS = {"mining", "herbalism", "skinning", "fishing"}
local SALVAGE_KINDS = {"disenchant", "prospecting", "milling"}
MCF.GatherKinds, MCF.SalvageKinds = GATHER_KINDS, SALVAGE_KINDS

local PENDING_SECONDS = 12   -- a loot window this soon after the cast belongs to it
local DEBOUNCE_SECONDS = 0.5 -- one loot window can fire the event more than once

-- Spell IDs we know for sure; everything else is recognised by the spell name (both languages).
local SPELL_KINDS = {
    [2575] = "mining", [2366] = "herbalism", [8617] = "skinning", [7620] = "fishing",
    [13262] = "disenchant", [31252] = "prospecting", [51005] = "milling",
}
local NAME_WORDS = {
    mining = {"mining", "bergbau"},
    herbalism = {"herb gathering", "kräutersammeln", "kräuterkunde", "herbalism"},
    skinning = {"skinning", "kürschnerei", "häuten"},
    fishing = {"fishing", "angeln"},
    disenchant = {"disenchant", "entzaubern"},
    prospecting = {"prospecting", "sondieren"},
    milling = {"milling", "mahlen"},
}
local NAME_ORDER = {"disenchant", "prospecting", "milling", "herbalism", "skinning", "fishing", "mining"}

local function SpellName(spellID)
    if C_Spell and C_Spell.GetSpellName then
        local ok, name = pcall(C_Spell.GetSpellName, spellID)
        if ok and type(name) == "string" then return name end
    end
    if GetSpellInfo then
        local ok, name = pcall(GetSpellInfo, spellID)
        if ok and type(name) == "string" then return name end
    end
end

local kindCache = {}
-- Read-only view for the self test (/mcf selftest).
-- optional: spells that do not exist in every game version (prospecting and milling arrived after Classic Era);
-- the self test does not warn when they are unknown.
MCF.GatherSpells = {ids = SPELL_KINDS, words = NAME_WORDS, optional = {prospecting = true, milling = true}}

local function KindOfSpell(spellID)
    if type(spellID) ~= "number" then return nil end
    if SPELL_KINDS[spellID] then return SPELL_KINDS[spellID] end
    local cached = kindCache[spellID]
    if cached ~= nil then return cached or nil end
    local name = SpellName(spellID)
    local found = false
    if name then
        local low = name:lower()
        for _, kind in ipairs(NAME_ORDER) do
            for _, word in ipairs(NAME_WORDS[kind]) do
                -- whole-name match only: "Mining" must not match unrelated spells that merely contain the word
                if low == word then found = kind; break end
            end
            if found then break end
        end
    end
    kindCache[spellID] = found
    return found or nil
end
MCF.GatheringKindOfSpell = KindOfSpell -- for /mcf gather and tests

---------------------------------------------------------------------------
-- Storage
---------------------------------------------------------------------------
local function Store()
    local db = MyCharForeverDB
    if type(db) ~= "table" then return nil end
    if type(db.gathering) ~= "table" then db.gathering = {version = 1, kinds = {}} end
    local g = db.gathering
    g.kinds = type(g.kinds) == "table" and g.kinds or {}
    return g
end

local function KindStore(kind)
    local g = Store()
    if not g then return nil end
    local k = g.kinds[kind]
    if type(k) ~= "table" then k = {events = 0, quantity = 0, items = {}, byLevel = {}, bySource = {}}; g.kinds[kind] = k end
    k.items = k.items or {}; k.byLevel = k.byLevel or {}; k.bySource = k.bySource or {}
    return k
end

---------------------------------------------------------------------------
-- Cast tracking
---------------------------------------------------------------------------
local pending -- {kind, at, quality}
local lastHandled = 0

local function Remember(kind, target)
    local now = GetTime()
    -- SENT carries the target item, the later SUCCEEDED does not: keep what was learned from the first.
    local quality = pending and pending.kind == kind and now - pending.at <= PENDING_SECONDS and pending.quality or nil
    pending = {kind = kind, at = now, quality = quality}
    -- Disenchanting names the item as the cast target; its quality tells what kind of item was destroyed.
    if kind == "disenchant" and type(target) == "string" and target ~= "" and GetItemInfo then
        local ok, _, _, quality = pcall(GetItemInfo, target)
        if ok and type(quality) == "number" then pending.quality = quality end
    end
end

local function OnCast(event, ...)
    local unit, a, b, c = ...
    if Readable(unit) ~= "player" then return end
    local spellID, target
    if event == "UNIT_SPELLCAST_SENT" then
        target, spellID = Readable(a), Readable(c) -- args: unit, target, castGUID, spellID
    else
        spellID = Readable(b) -- args: unit, castGUID, spellID
    end
    local kind = KindOfSpell(spellID)
    if kind then Remember(kind, target) end
end

---------------------------------------------------------------------------
-- Loot
---------------------------------------------------------------------------
local function ReadLootWindow()
    local items = {}
    local n = GetNumLootItems and GetNumLootItems() or 0
    for slot = 1, n do
        local hasItem = true
        if LootSlotHasItem then hasItem = LootSlotHasItem(slot) and true or false end
        local link = hasItem and GetLootSlotLink and GetLootSlotLink(slot) or nil
        link = Readable(link)
        if type(link) == "string" then
            local id = tonumber(link:match("item:(%d+)"))
            if id then
                local _, name, quantity = GetLootSlotInfo(slot)
                quantity = tonumber(Readable(quantity)) or 1
                if quantity < 1 then quantity = 1 end
                items[#items + 1] = {id = id, quantity = quantity, link = link,
                    name = type(Readable(name)) == "string" and name or link:match("%[([^%]]+)%]")}
            end
        end
    end
    return items
end

local function Record(kind, items, quality)
    local k = KindStore(kind)
    if not k then return end
    local level = UnitLevel("player") or 0
    local total = 0
    for _, it in ipairs(items) do
        local entry = k.items[tostring(it.id)]
        if type(entry) ~= "table" then entry = {quantity = 0}; k.items[tostring(it.id)] = entry end
        entry.quantity = entry.quantity + it.quantity
        entry.name = it.name or entry.name
        entry.link = it.link or entry.link
        total = total + it.quantity
    end
    k.events = (k.events or 0) + 1
    k.quantity = (k.quantity or 0) + total
    k.byLevel[level] = (k.byLevel[level] or 0) + total
    if quality ~= nil then k.bySource[tostring(quality)] = (k.bySource[tostring(quality)] or 0) + 1 end
end

local function OnLootOpened()
    local now = GetTime()
    if now - lastHandled < DEBOUNCE_SECONDS then return end
    local kind, quality
    if IsFishingLoot and IsFishingLoot() then
        kind = "fishing"
    elseif pending and now - pending.at <= PENDING_SECONDS then
        kind, quality = pending.kind, pending.quality
    end
    if not kind then return end
    lastHandled = now
    pending = nil -- a second corpse looted right afterwards must not be counted again
    local items = ReadLootWindow()
    if #items == 0 then return end
    Record(kind, items, quality)
    if MCF.RefreshUI then MCF:RefreshUI() end
end

local frame = CreateFrame("Frame")
for _, e in ipairs({"UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_CHANNEL_START", "LOOT_OPENED"}) do
    pcall(function() frame:RegisterEvent(e) end)
end
frame:SetScript("OnEvent", function(_, event, ...)
    local ok, err
    if event == "LOOT_OPENED" then ok, err = pcall(OnLootOpened) else ok, err = pcall(OnCast, event, ...) end
    if not ok and MCF.DebugLog then pcall(MCF.DebugLog, MCF, "professions", "GATHER_TRACK_ERROR", tostring(err)) end
end)

-- Which profession (skill line ID) a kind belongs to; the single source for "does this player cover it".
local KIND_PROFESSION = {mining = 186, herbalism = 182, skinning = 393, fishing = 356,
    disenchant = 333, prospecting = 755, milling = 773}

-- A kind is shown when its profession is currently learned, or when something was recorded for it
-- before (a dropped profession keeps its history).
function MCF:IsGatheringKindRelevant(kind)
    local k = self:GetGatheringKind(kind)
    if k and (tonumber(k.events) or 0) > 0 then return true end
    local cur = MyCharForeverDB and MyCharForeverDB.professions and MyCharForeverDB.professions.current
    local p = cur and cur["id:" .. tostring(KIND_PROFESSION[kind])]
    return p ~= nil and not p.unlearned
end

---------------------------------------------------------------------------
-- Read access for the UI and the achievements
---------------------------------------------------------------------------
function MCF:GetGatheringKind(kind)
    local g = MyCharForeverDB and MyCharForeverDB.gathering
    return g and g.kinds and g.kinds[kind] or nil
end

-- Rows sorted by quantity: {name, quantity, id, link}
function MCF:GetGatheringItems(kind)
    local k = self:GetGatheringKind(kind)
    local rows = {}
    if not k then return rows end
    for key, e in pairs(k.items or {}) do
        local id = tonumber(key)
        local name = id and GetItemInfo and GetItemInfo(id) or nil
        name = name or e.name or (id and ("#" .. id)) or tostring(key)
        rows[#rows + 1] = {name = name, quantity = tonumber(e.quantity) or 0, id = id, link = e.link}
    end
    table.sort(rows, function(a, b)
        if a.quantity ~= b.quantity then return a.quantity > b.quantity end
        return a.name:lower() < b.name:lower()
    end)
    return rows
end

function MCF:GetGatheringTotal(kinds)
    local sum = 0
    for _, kind in ipairs(kinds) do
        local k = self:GetGatheringKind(kind)
        sum = sum + (k and tonumber(k.quantity) or 0)
    end
    return sum
end

MCF:AddCommand{group = "debug", usage = "/mcf gather", key = "gather",
    de = "Gesammelte und zerlegte Ressourcen anzeigen",
    en = "Show gathered and salvaged resources",
    run = function()
        local any = false
        for _, list in ipairs({GATHER_KINDS, SALVAGE_KINDS}) do
            for _, kind in ipairs(list) do
                local k = MCF:GetGatheringKind(kind)
                if k and (k.events or 0) > 0 then
                    any = true
                    print(string.format("|cff00ccffMyCharForever|r: %s: %d x, %d items", kind, k.events or 0, k.quantity or 0))
                end
            end
        end
        if not any then print("|cff00ccffMyCharForever|r: -") end
    end}
