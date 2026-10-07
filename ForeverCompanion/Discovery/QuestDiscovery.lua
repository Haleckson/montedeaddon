--[[
  Forever Companion - Discovery/QuestDiscovery.lua
  Quests are recorded when accepted (where, from whom) and marked done when
  turned in. A quest accepted shortly after turning in another one is
  linked into a quest chain automatically; the chain gets its own entry with
  its quests as children. Quest discoveries are private by default; sharing
  them is a separate setting ("Share quest discoveries").

  Quest lore (Data/QuestLore.lua) is learned here too, for tooltips: the
  quests each NPC offers and takes (from its dialog), and the quest items
  creatures drop (from loot, or from the item that opened a quest).
]]

local _, FC = ...

local Engine = FC.DiscoveryEngine
local Compat = FC.Compat
local L = FC.L
local Categories = FC.Categories

local Quests = { lastTurnIn = nil, pendingGivers = {} }
FC.QuestDiscovery = Quests

local GIVER_WINDOW = 120 -- a quest accepted this soon after its details were shown came from that NPC

--- The NPC in the open dialog (never a player sharing a quest, never an object).
local function dialogNpc()
    local info = Compat.GetUnitInfo("npc")
    if info and not info.isPlayer and info.npcID then return info end
    return nil
end

local function questIDFromArgs(a, b)
    -- Retail sends (questID); older clients sent (questLogIndex, questID)
    if type(b) == "number" and b > 0 then return b end
    if type(a) == "number" and a > 0 then return a end
    return nil
end

local function chains()
    FC.cdb.chains = FC.cdb.chains or {}
    return FC.cdb.chains
end

--- Links questID to the chain of the quest turned in just before it.
function Quests:LinkChain(questID, questRec)
    if not FC.Config:Get("discovery.questChains") then return end
    local previous = self.lastTurnIn
    if not previous or GetTime() - previous.time > FC.C.DISCOVERY.CHAIN_WINDOW or previous.questID == questID then return end
    local map = chains()
    local root = map[previous.questID] or previous.questID
    map[previous.questID] = root
    map[questID] = root
    local chainID = "chain:" .. root
    local members = 0
    for _, r in pairs(map) do
        if r == root then members = members + 1 end
    end
    -- the chain is named after its first quest, also when that one was
    -- accepted before the journal watched (QuestHistory names it later if
    -- nobody can yet)
    local rootRec = FC.Store:Get("quest:" .. root)
    local rootTitle = (rootRec and rootRec.n) or FC.QuestLore:KnownTitle(root)
        or (root == previous.questID and previous.title) or ("#" .. root)
    local chain = FC.Store:Get(chainID)
    if not chain then
        local fields = Engine:LocationFields()
        fields.t = "questchain"
        fields.n = string.format(L.AUTO_CHAIN_TITLE, rootTitle)
        fields.d = string.format(L.AUTO_CHAIN, members, rootTitle)
        fields.v = questRec and questRec.v or nil
        fields.pa = nil
        fields.tg = { "quest-chain" }
        fields.ic = Categories:Get("questchain").icon
        Engine:Record(fields, { id = chainID, force = true })
    elseif FC.Store:IsMine(chain) then
        FC.Store:Update(chainID, { d = string.format(L.AUTO_CHAIN, members, rootTitle) }, "auto")
    end
    for quest, r in pairs(map) do
        if r == root then
            local rec = FC.Store:Get("quest:" .. quest)
            if rec and FC.Store:IsMine(rec) and rec.pa ~= chainID then
                FC.Store:Update(rec.id, { pa = chainID }, "auto")
            end
        end
    end
end

--- The NPC a quest was accepted from: remembered when its details were
--- shown, because the dialog is usually closed by the time it is accepted.
function Quests:GiverOf(questID)
    local pending = self.pendingGivers[questID]
    if pending and GetTime() - pending.time <= GIVER_WINDOW then return pending end
    local info = dialogNpc()
    if info then return { npcID = info.npcID, name = info.name } end
    return nil
end

-- Where and from whom a quest is accepted, as it is at this moment.
local function questFields(questID)
    local fields = Engine:LocationFields()
    fields.t = "quest"
    fields.q = questID
    fields.ic = Categories:Get("quest").icon
    local giver = Quests:GiverOf(questID)
    if giver then
        fields.gv = giver.name
        fields.gvi = giver.npcID
    end
    return fields
end

local function recordQuest(questID, title, fields)
    fields = fields or questFields(questID)
    fields.n = title
    local rec = Engine:Record(fields)
    Quests:LinkChain(questID, rec)
end

Engine:RegisterDetector("quests", {
    setting = "discovery.quests",
    events = {
        QUEST_ACCEPTED = function(_, _, a, b)
            local questID = questIDFromArgs(a, b)
            if not questID then return end
            local title = Compat.GetQuestTitle(questID)
            if title then
                recordQuest(questID, title)
            else
                -- the client has not named the quest yet: the place and the
                -- giver are taken now, the entry is written when the title is
                -- there (at once with a learned or shipped title)
                local fields = questFields(questID)
                FC.QuestHistory:WhenTitled(questID, function(late) recordQuest(questID, late, fields) end)
            end
        end,
        QUEST_TURNED_IN = function(_, _, questID)
            questID = Compat.Safe(questID)
            if type(questID) ~= "number" then return end
            local id = "quest:" .. questID
            local rec = FC.Store:Get(id)
            if rec then FC.Store:SetDone(id, true) end
            Quests.lastTurnIn = { questID = questID, time = GetTime(), title = (rec and rec.n) or FC.QuestLore:KnownTitle(questID) }
        end,
    },
})

------------------------------------------------------------------------
-- Quest lore: who offers and takes which quest, which items start one
------------------------------------------------------------------------

local function learnDialog()
    local npc = dialogNpc()
    if not npc then return end
    local Lore = FC.QuestLore
    local quests = Compat.GetDialogQuests()
    for _, q in ipairs(quests.available) do Lore:AddGiven(npc.npcID, npc.name, q.questID, q.title) end
    -- quests of yours an NPC lists are the ones you bring to it
    for _, q in ipairs(quests.active) do Lore:AddEnder(npc.npcID, npc.name, q.questID, q.title) end
    Lore:SetPlace(npc.npcID, FC.Location:Capture())
end

local function learnDetail(startItemID)
    local questID, title = Compat.GetShownQuest()
    if not questID then return end
    local Lore = FC.QuestLore
    startItemID = Compat.Safe(startItemID)
    if type(startItemID) == "number" and startItemID > 0 then
        Lore:AddStarter(startItemID, Compat.GetItemName(startItemID), questID, title)
        return
    end
    local npc = dialogNpc()
    if not npc then return end
    local now = GetTime()
    for id, pending in pairs(Quests.pendingGivers) do
        if now - pending.time > GIVER_WINDOW then Quests.pendingGivers[id] = nil end
    end
    Quests.pendingGivers[questID] = { npcID = npc.npcID, name = npc.name, time = now }
    Lore:AddGiven(npc.npcID, npc.name, questID, title)
    Lore:SetPlace(npc.npcID, FC.Location:Capture())
end

local function learnTurnIn()
    local questID, title = Compat.GetShownQuest()
    local npc = dialogNpc()
    if questID and npc then
        FC.QuestLore:AddEnder(npc.npcID, npc.name, questID, title)
        FC.QuestLore:SetPlace(npc.npcID, FC.Location:Capture())
    end
end

--- Loot that starts a quest: remembered with the creature that dropped it.
local function learnStarterLoot()
    for _, item in ipairs(Compat.GetLootItems()) do
        if item.questID then
            local npcID
            for _, source in ipairs(item.sources) do
                if source.guidType == "Creature" and source.id then npcID = source.id break end
            end
            -- a client that names no loot source at all: the dead target is
            -- what was looted. A chest or a herb names itself as the source,
            -- and then a corpse that happens to be targeted dropped nothing.
            if not npcID and #item.sources == 0 then
                local target = Compat.GetUnitInfo("target")
                if target and target.isDead and target.npcID then npcID = target.npcID end
            end
            local npcName
            if npcID then
                local target = Compat.GetUnitInfo("target")
                npcName = target and target.npcID == npcID and target.name or nil
            end
            FC.QuestLore:AddStarter(item.itemID, item.name, item.questID, Compat.GetQuestTitle(item.questID), npcID, npcName)
        end
    end
end

Engine:RegisterDetector("quest-lore", {
    events = {
        GOSSIP_SHOW = function() learnDialog() end,
        QUEST_GREETING = function() learnDialog() end,
        QUEST_DETAIL = function(_, _, startItemID) learnDetail(startItemID) end,
        QUEST_PROGRESS = function() learnTurnIn() end,
        QUEST_COMPLETE = function() learnTurnIn() end,
        QUEST_ACCEPTED = function(_, _, a, b)
            local questID = questIDFromArgs(a, b)
            local giver = questID and Quests:GiverOf(questID)
            if giver then FC.QuestLore:AddGiven(giver.npcID, giver.name, questID, Compat.GetQuestTitle(questID)) end
        end,
        LOOT_OPENED = function() learnStarterLoot() end,
    },
})
