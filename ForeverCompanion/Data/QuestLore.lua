--[[
  Forever Companion - Data/QuestLore.lua
  Reference knowledge about quests, learned from the game as you play and
  kept account-wide (NPC and quest IDs are the same for every character):

    npcs[npcID]    n  name          g  quests it offers (seen in its dialog)
                   e  quests turned in to it             d  quest items it dropped
                   o  quests it is an objective of (to kill, loot or talk to)
                   m, x, y, z  where you last talked to it (map, position, zone name)
    quests[id]     t  title         i  the item that starts it
    items[itemID]  n  name          q  the quest it starts   src  NPCs that dropped it

  Tooltips read it to list, like a collection addon would, what an NPC gives
  and takes and which quest items a creature drops, with your progress. It
  holds only what one of your characters saw: nothing is shipped with the
  addon. Journal quest entries shared by the guild add to it (see Store:QuestsByGiver).
]]

local _, FC = ...

local Lore = FC:NewModule("QuestLore")

local U = FC.Utils
local Compat = FC.Compat

Lore.LIMITS = {
    NPCS = 6000, QUESTS = 12000, ITEMS = 3000,
    PER_NPC = 40, DROPS = 12, SOURCES = 8, NAME = 64, TITLE = 80,
}
local LIM = Lore.LIMITS

local function vID(v)
    return type(v) == "number" and v > 0 and v < 2147483648 and v == math.floor(v)
end

-- A name or a title worth keeping: an empty one is no title at all (it
-- would be shown instead of the real one, which then is never asked for).
local function cleanName(value, limit)
    value = U.CleanText(value, limit)
    if value == nil or value == "" then return nil end
    return value
end

local function cleanSet(set, limit)
    if type(set) ~= "table" then return nil end
    local out, count = {}, 0
    for id, flag in pairs(set) do
        if vID(id) and flag == true and count < limit then
            out[id] = true
            count = count + 1
        end
    end
    return count > 0 and out or nil
end

--- Drops anything malformed and trims the tables to their limits, oldest first.
local function prune(map, limit)
    local list = {}
    for id, entry in pairs(map) do list[#list + 1] = { id = id, s = entry.s or 0 } end
    if #list <= limit then return end
    table.sort(list, function(a, b) return a.s < b.s end)
    for i = 1, #list - limit do map[list[i].id] = nil end
end

function Lore:Validate(lore)
    if type(lore) ~= "table" then lore = {} end
    for _, key in ipairs({ "npcs", "quests", "items" }) do
        if type(lore[key]) ~= "table" then lore[key] = {} end
    end
    for id, npc in pairs(lore.npcs) do
        if not vID(id) or type(npc) ~= "table" then
            lore.npcs[id] = nil
        else
            local x, y = tonumber(npc.x), tonumber(npc.y)
            local placed = vID(npc.m) and x and y and x >= 0 and x <= 1 and y >= 0 and y <= 1
            lore.npcs[id] = {
                n = cleanName(npc.n, LIM.NAME),
                g = cleanSet(npc.g, LIM.PER_NPC),
                e = cleanSet(npc.e, LIM.PER_NPC),
                d = cleanSet(npc.d, LIM.DROPS),
                o = cleanSet(npc.o, LIM.PER_NPC),
                m = placed and npc.m or nil,
                x = placed and x or nil,
                y = placed and y or nil,
                z = U.CleanText(npc.z, 64),
                s = tonumber(npc.s) or 0,
            }
        end
    end
    for id, quest in pairs(lore.quests) do
        if not vID(id) or type(quest) ~= "table" then
            lore.quests[id] = nil
        else
            lore.quests[id] = { t = cleanName(quest.t, LIM.TITLE), i = vID(quest.i) and quest.i or nil, s = tonumber(quest.s) or 0 }
        end
    end
    for id, item in pairs(lore.items) do
        if not vID(id) or type(item) ~= "table" then
            lore.items[id] = nil
        else
            lore.items[id] = { n = cleanName(item.n, LIM.NAME), q = vID(item.q) and item.q or nil, src = cleanSet(item.src, LIM.SOURCES), s = tonumber(item.s) or 0 }
        end
    end
    prune(lore.npcs, LIM.NPCS)
    prune(lore.quests, LIM.QUESTS)
    prune(lore.items, LIM.ITEMS)
    return lore
end

function Lore:OnInitialize()
    FC.db.questLore = self:Validate(FC.db.questLore)
    self.data = FC.db.questLore
    self.byName = nil
    self.outbox = {}
end

function Lore:OnEnable()
    FC.Events:Register("QUEST_DATA_LOAD_RESULT", self, function(_, _, questID, success) self:OnQuestLoaded(questID, success) end)
end

--- Joins lore from a backup into yours: entries you do not have are added,
--- sets are joined and names or places fill in what is missing.
function Lore:Merge(other)
    other = self:Validate(other)
    local data = self.data
    local function join(into, from, limit)
        if not from then return into end
        into = into or {}
        local n = 0
        for _ in pairs(into) do n = n + 1 end
        for id in pairs(from) do
            if not into[id] and n < limit then
                into[id] = true
                n = n + 1
            end
        end
        return into
    end
    for id, npc in pairs(other.npcs) do
        local mine = data.npcs[id]
        if not mine then
            data.npcs[id] = npc
        else
            mine.n = mine.n or npc.n
            mine.g = join(mine.g, npc.g, LIM.PER_NPC)
            mine.e = join(mine.e, npc.e, LIM.PER_NPC)
            mine.d = join(mine.d, npc.d, LIM.DROPS)
            mine.o = join(mine.o, npc.o, LIM.PER_NPC)
            if not mine.m and npc.m then mine.m, mine.x, mine.y, mine.z = npc.m, npc.x, npc.y, npc.z end
            mine.s = math.max(mine.s or 0, npc.s)
        end
    end
    for id, quest in pairs(other.quests) do
        local mine = data.quests[id]
        if not mine then
            data.quests[id] = quest
        else
            mine.t, mine.i = mine.t or quest.t, mine.i or quest.i
        end
    end
    for id, item in pairs(other.items) do
        local mine = data.items[id]
        if not mine then
            data.items[id] = item
        else
            mine.n, mine.q = mine.n or item.n, mine.q or item.q
            mine.src = join(mine.src, item.src, LIM.SOURCES)
        end
    end
    self:Validate(data)
    self.byName = nil
    FC.Bus:Emit("QUEST_LORE_CHANGED")
end

------------------------------------------------------------------------
-- Learning
------------------------------------------------------------------------

local function now() return U.Now() end

local function count(set)
    local n = 0
    for _ in pairs(set) do n = n + 1 end
    return n
end

local function addTo(entry, field, id, limit)
    local set = entry[field]
    if not set then
        set = {}
        entry[field] = set
    end
    if set[id] then return false end
    if count(set) >= limit then return false end
    set[id] = true
    return true
end

function Lore:Npc(npcID, name)
    if not vID(npcID) then return nil end
    local npcs = self.data.npcs
    local entry = npcs[npcID]
    if not entry then
        entry = {}
        npcs[npcID] = entry
    end
    name = U.CleanText(name, LIM.NAME)
    if name and name ~= "" and entry.n ~= name then
        entry.n = name
        self.byName = nil
    end
    entry.s = now()
    return entry
end

--- Where an NPC stands (from a position capture: m, x, y, z).
function Lore:SetPlace(npcID, loc)
    local npc = vID(npcID) and self.data.npcs[npcID]
    if not npc or type(loc) ~= "table" then return end
    if loc.m and loc.x and loc.y then
        npc.m, npc.x, npc.y = loc.m, loc.x, loc.y
    end
    if loc.z then npc.z = U.CleanText(loc.z, 64) end
end

--- NPCs you talked to on a map (or in a zone of that name) with quests.
function Lore:QuestNpcsIn(mapID, zone)
    local out = {}
    for id, npc in pairs(self.data.npcs) do
        if (npc.g or npc.e) and ((mapID and npc.m == mapID) or (zone and npc.z == zone)) then
            out[#out + 1] = { npcID = id, npc = npc }
        end
    end
    return out
end

function Lore:NoteQuest(questID, title)
    if not vID(questID) then return nil end
    local quests = self.data.quests
    local entry = quests[questID] or {}
    quests[questID] = entry
    title = U.CleanText(title, LIM.TITLE)
    if title and title ~= "" then entry.t = title end
    entry.s = now()
    return entry
end

--- The NPC offers this quest (seen in its dialog, or accepted from it).
function Lore:AddGiven(npcID, name, questID, title)
    local npc = self:Npc(npcID, name)
    if not npc or not self:NoteQuest(questID, title) then return false end
    local added = addTo(npc, "g", questID, LIM.PER_NPC)
    if added then
        self:Share(npcID, "g", questID)
        FC.Bus:Emit("QUEST_LORE_CHANGED", npcID)
    end
    return added
end

--- The quest is turned in to (or progressed at) this NPC.
function Lore:AddEnder(npcID, name, questID, title)
    local npc = self:Npc(npcID, name)
    if not npc or not self:NoteQuest(questID, title) then return false end
    local added = addTo(npc, "e", questID, LIM.PER_NPC)
    if added then
        self:Share(npcID, "e", questID)
        FC.Bus:Emit("QUEST_LORE_CHANGED", npcID)
    end
    return added
end

--- itemID starts questID. npcID (optional) is a creature that dropped it.
function Lore:AddStarter(itemID, itemName, questID, questTitle, npcID, npcName)
    if not vID(itemID) then return false end
    local items = self.data.items
    local item = items[itemID] or {}
    items[itemID] = item
    itemName = U.CleanText(itemName, LIM.NAME)
    if itemName and itemName ~= "" then item.n = itemName end
    if vID(questID) then
        if item.q ~= questID then self:Share(itemID, "s", questID) end
        item.q = questID
        local quest = self:NoteQuest(questID, questTitle)
        if quest then quest.i = itemID end
    end
    item.s = now()
    if vID(npcID) then
        addTo(item, "src", npcID, LIM.SOURCES)
        local npc = self:Npc(npcID, npcName)
        if npc and addTo(npc, "d", itemID, LIM.DROPS) then self:Share(npcID, "d", itemID) end
    end
    FC.Bus:Emit("QUEST_LORE_CHANGED", npcID)
    return true
end

------------------------------------------------------------------------
-- Sharing with the guild
------------------------------------------------------------------------
-- What one character learns travels to the guild as small facts
-- { a, kind, b }:  g  NPC a offers quest b       e  quest b is turned in to NPC a
--                  o  creature a is needed for quest b
--                  d  creature a dropped item b   s  item a starts quest b
-- with the names, titles and places they need alongside. Facts that arrive
-- are learned like your own and are not sent again, so every member's
-- journal grows into the guild's quest database.

local FACT_KINDS = { g = true, e = true, o = true, d = true, s = true }
local OUTBOX_LIMIT = 200
local MAX_FACTS = 100

function Lore:Share(a, kind, b)
    if self.receiving then return end
    local box = self.outbox
    if #box >= OUTBOX_LIMIT then table.remove(box, 1) end
    box[#box + 1] = { a, kind, b }
    FC.Bus:Emit("QUEST_LORE_LEARNED")
end

--- The facts learned since the last call.
function Lore:TakeOutbox()
    local facts = self.outbox
    self.outbox = {}
    return facts
end

--- A message for some facts: the facts, plus names, titles and places.
function Lore:Pack(facts)
    local names, titles, places, items = {}, {}, {}, {}
    local data = self.data
    local function quest(id)
        local q = data.quests[id]
        if q and q.t then titles[id] = q.t end
    end
    local function item(id)
        local i = data.items[id]
        if i and i.n then items[id] = i.n end
    end
    for _, f in ipairs(facts) do
        local a, kind, b = f[1], f[2], f[3]
        if kind == "s" then
            item(a)
            quest(b)
        else
            local npc = data.npcs[a]
            if npc then
                names[a] = npc.n
                if npc.m and npc.x and npc.y then places[a] = { npc.m, npc.x, npc.y, npc.z } end
            end
            if kind == "d" then item(b) else quest(b) end
        end
    end
    return { f = facts, n = names, t = titles, p = places, i = items }
end

local function text(map, id, limit)
    local v = type(map) == "table" and map[id]
    return type(v) == "string" and U.CleanText(v, limit) or nil
end

--- Learns the facts a guild member sent. Names and titles only fill gaps
--- (yours may be in another language). Returns how many facts were new.
function Lore:ApplyFacts(payload)
    if type(payload) ~= "table" or type(payload.f) ~= "table" then return 0 end
    local data, learned = self.data, 0
    self.receiving = true
    for i = 1, math.min(#payload.f, MAX_FACTS) do
        local f = payload.f[i]
        local a, kind, b
        if type(f) == "table" then a, kind, b = f[1], f[2], f[3] end
        if vID(a) and vID(b) and FACT_KINDS[kind] then
            if kind == "s" then
                local entry = data.items[a] or {}
                data.items[a] = entry
                entry.n = entry.n or text(payload.i, a, LIM.NAME)
                if not entry.q then
                    entry.q = b
                    learned = learned + 1
                end
                entry.s = now()
                local quest = self:NoteQuest(b, not (data.quests[b] and data.quests[b].t) and text(payload.t, b, LIM.TITLE) or nil)
                if quest and not quest.i then quest.i = a end
            else
                local known = data.npcs[a]
                local npc = self:Npc(a, not (known and known.n) and text(payload.n, a, LIM.NAME) or nil)
                local place = type(payload.p) == "table" and payload.p[a]
                if not npc.m and type(place) == "table" and vID(place[1]) then
                    local x, y = tonumber(place[2]), tonumber(place[3])
                    if x and y and x >= 0 and x <= 1 and y >= 0 and y <= 1 then
                        npc.m, npc.x, npc.y = place[1], x, y
                        npc.z = npc.z or (type(place[4]) == "string" and U.CleanText(place[4], 64) or nil)
                    end
                end
                if kind == "d" then
                    if addTo(npc, "d", b, LIM.DROPS) then learned = learned + 1 end
                    local entry = data.items[b] or {}
                    data.items[b] = entry
                    entry.n = entry.n or text(payload.i, b, LIM.NAME)
                    addTo(entry, "src", a, LIM.SOURCES)
                    entry.s = now()
                else
                    if addTo(npc, kind, b, LIM.PER_NPC) then learned = learned + 1 end
                    self:NoteQuest(b, not (data.quests[b] and data.quests[b].t) and text(payload.t, b, LIM.TITLE) or nil)
                end
            end
        end
    end
    self.receiving = false
    if learned > 0 then
        self.byName = nil
        FC.Bus:Emit("QUEST_LORE_CHANGED")
    end
    return learned
end

--- The newest change in the quest knowledge (for the guild's catch-up).
function Lore:Newest()
    local newest = 0
    for _, npc in pairs(self.data.npcs) do
        if (npc.s or 0) > newest then newest = npc.s end
    end
    for _, item in pairs(self.data.items) do
        if (item.s or 0) > newest then newest = item.s end
    end
    return newest
end

--- Everything known about NPCs and items changed since a time, as facts,
--- most recent first, up to a limit.
function Lore:FactsSince(since, limit)
    local changed = {}
    for id, npc in pairs(self.data.npcs) do
        if (npc.s or 0) > since then changed[#changed + 1] = { id = id, s = npc.s } end
    end
    table.sort(changed, function(x, y) return x.s > y.s end)
    local facts = {}
    for _, c in ipairs(changed) do
        local npc = self.data.npcs[c.id]
        for _, kind in ipairs({ "g", "e", "o", "d" }) do
            for value in pairs(npc[kind] or {}) do
                if #facts >= limit then return facts end
                facts[#facts + 1] = { c.id, kind, value }
            end
        end
    end
    for id, item in pairs(self.data.items) do
        if (item.s or 0) > since and vID(item.q) then
            if #facts >= limit then return facts end
            facts[#facts + 1] = { id, "s", item.q }
        end
    end
    return facts
end

------------------------------------------------------------------------
-- Reading
------------------------------------------------------------------------

function Lore:GetNpc(npcID)
    return npcID and self.data.npcs[npcID] or nil
end

--- NPC IDs known under a name (for units whose GUID the client keeps secret).
function Lore:NpcIDsByName(name)
    if type(name) ~= "string" or name == "" then return {} end
    if not self.byName then
        local index = {}
        for id, npc in pairs(self.data.npcs) do
            if npc.n then
                local key = npc.n:lower()
                index[key] = index[key] or {}
                table.insert(index[key], id)
            end
        end
        self.byName = index
    end
    return self.byName[name:lower()] or {}
end

--- A quest's title as far as it is known right now, and where it comes
--- from; nil when nobody can name the quest yet. Nothing is asked for.
---   "client"     the game's own title, in the player's language
---   "learned"    kept from an earlier session, a dialog or a guild member
---   "reference"  the English title the addon ships
function Lore:KnownTitle(questID)
    if not vID(questID) then return nil end
    local title = Compat.GetQuestTitle(questID)
    if title then return title, "client" end
    local quest = self.data.quests[questID]
    if quest and quest.t then return quest.t, "learned" end
    title = FC.Reference:QuestTitle(questID)
    if title then return title, "reference" end
    return nil
end

--- Keeps a title the client gave, so it is there at the next login before
--- the client has loaded the quest again. A title equal to the one the
--- addon ships is not stored twice.
function Lore:RememberTitle(questID, title)
    title = cleanName(title, LIM.TITLE)
    if not vID(questID) or not title then return false end
    local quest = self.data.quests[questID]
    if quest then
        if quest.t == title then return false end
        quest.t = title
        return true
    end
    if FC.Reference:QuestTitle(questID) == title then return false end
    self.data.quests[questID] = { t = title, s = now() }
    return true
end

--- A quest's title: from the client, learned, or the one the addon ships;
--- for a quest nobody can name yet, "Quest #ID" (and the client is asked).
function Lore:Title(questID)
    local title, source = self:KnownTitle(questID)
    if title then
        if source == "client" then
            local quest = self.data.quests[questID]
            if quest and not quest.t then quest.t = cleanName(title, LIM.TITLE) end
        elseif source == "reference" and FC.Locale.client ~= "enUS" then
            Compat.RequestQuestData(questID) -- the client's title is in the player's language
        end
        return title
    end
    Compat.RequestQuestData(questID)
    return string.format(FC.L.TIP_QUEST_ID, tonumber(questID) or 0), true
end

--- A quest the client just loaded: keep its title and tell the tooltips.
function Lore:OnQuestLoaded(questID, success)
    questID = Compat.Safe(questID)
    if not vID(questID) or Compat.Safe(success) == false then return end
    local title = Compat.GetQuestTitle(questID)
    if not title then return end
    local quest = self.data.quests[questID]
    if quest and not quest.t then quest.t = cleanName(title, LIM.TITLE) end
    FC.Bus:Emit("QUEST_TITLE_LOADED", questID)
end

--- A creature the tooltip names as a quest objective: remember which quests
--- (they stay known after the quest is done, and for your other characters).
--- quests: from Compat.ReadQuestLines. Returns true when something was new.
function Lore:LearnTargets(npcID, name, quests)
    if not vID(npcID) or type(quests) ~= "table" or #quests == 0 then return false end
    local learned = false
    for _, q in ipairs(quests) do
        if vID(q.questID) then
            local entry = self:Npc(npcID, name)
            if addTo(entry, "o", q.questID, LIM.PER_NPC) then
                learned = true
                entry.s = now()
                self:Share(npcID, "o", q.questID)
            end
            self:NoteQuest(q.questID, q.title)
        end
    end
    if learned then FC.Bus:Emit("QUEST_LORE_CHANGED", npcID) end
    return learned
end

--- Reads a unit's tooltip data (nameplates, mouseover) and learns from it.
function Lore:LearnFromUnit(unit, lines)
    local info = Compat.GetUnitInfo(unit)
    if not info or info.isPlayer or not info.npcID then return false end
    return self:LearnTargets(info.npcID, info.name, Compat.ReadQuestLines(lines))
end

--- The quest an item starts, and the NPC names that dropped it.
function Lore:ItemStarter(itemID)
    local item = itemID and self.data.items[itemID]
    if not item then return nil end
    local droppers = {}
    for npcID in pairs(item.src or {}) do
        local npc = self.data.npcs[npcID]
        droppers[#droppers + 1] = npc and npc.n or ("#" .. npcID)
    end
    table.sort(droppers)
    return { questID = item.q, name = item.n, droppers = droppers }
end

local STATUS_ORDER = { ready = 1, active = 2, open = 3, done = 4 }

local function sortQuests(list)
    table.sort(list, function(a, b)
        local sa, sb = STATUS_ORDER[a.status] or 5, STATUS_ORDER[b.status] or 5
        if sa ~= sb then return sa < sb end
        return a.title < b.title
    end)
    return list
end

--- Quests an NPC gives, with this character's progress, best first:
--- ready to turn in, in progress, not done, done. Also returns done / total.
function Lore:QuestsGivenBy(npcID, name)
    local list, seen = {}, {}
    local function add(questID, title)
        if not vID(questID) or seen[questID] then return end
        seen[questID] = true
        list[#list + 1] = { questID = questID, title = title or self:Title(questID), status = Compat.GetQuestStatus(questID) }
    end
    local npc = self:GetNpc(npcID)
    for questID in pairs(npc and npc.g or {}) do add(questID) end
    -- journal quest entries (yours and shared ones) that name this giver
    for _, rec in ipairs(FC.Store:QuestsByGiver(npcID, name)) do
        if FC.Store:IsKnown(rec) then add(rec.q, rec.n) end
    end
    -- and every quest the reference data knows for it, that you can take
    for _, questID in ipairs(FC.Reference:QuestsGivenBy(npcID)) do add(questID) end
    local done = 0
    for _, entry in ipairs(list) do
        if entry.status == "done" then done = done + 1 end
    end
    return sortQuests(list), done
end

--- Quests a creature is an objective of, with your progress, best first.
function Lore:QuestsTargeting(npcID)
    local list, seen = {}, {}
    local function add(questID)
        if seen[questID] then return end
        seen[questID] = true
        list[#list + 1] = { questID = questID, title = self:Title(questID), status = Compat.GetQuestStatus(questID) }
    end
    local npc = self:GetNpc(npcID)
    for questID in pairs(npc and npc.o or {}) do add(questID) end
    for _, questID in ipairs(FC.Reference:QuestsTargeting(npcID)) do add(questID) end
    return sortQuests(list)
end

--- Quests that start from something this creature drops, with your progress.
function Lore:QuestsFromLoot(npcID)
    local list = {}
    for _, questID in ipairs(FC.Reference:QuestsFromLoot(npcID)) do
        list[#list + 1] = { questID = questID, title = self:Title(questID), status = Compat.GetQuestStatus(questID) }
    end
    return sortQuests(list)
end

--- Quests turned in to this NPC that are not among the ones it gives.
function Lore:QuestsEndedAt(npcID, except)
    local list = {}
    local npc = self:GetNpc(npcID)
    for questID in pairs(npc and npc.e or {}) do
        if not (except and except[questID]) then
            list[#list + 1] = { questID = questID, title = self:Title(questID), status = Compat.GetQuestStatus(questID) }
        end
    end
    return sortQuests(list)
end

--- Quest-starting items a creature dropped, with the quest and its progress.
function Lore:StarterDrops(npcID)
    local list = {}
    local npc = self:GetNpc(npcID)
    for itemID in pairs(npc and npc.d or {}) do
        local item = self.data.items[itemID] or {}
        local name = Compat.GetItemName(itemID) or item.n or ("item:" .. itemID)
        list[#list + 1] = {
            itemID = itemID,
            name = name,
            questID = item.q,
            title = item.q and self:Title(item.q) or nil,
            status = item.q and Compat.GetQuestStatus(item.q) or nil,
        }
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end
