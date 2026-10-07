--[[
  Forever Companion - Discovery/NPCDiscovery.lua
  Everything with a face:

    rares           target and nameplates, with sighting / death observations
    world bosses    outside instances
    kills           looting a rare or world boss announces it as defeated
    bestiary        every attackable creature you meet (target, mouseover,
                    nameplates): level range, type, classification, drops
    unusual NPCs    NPCs you talk to that are not part of the everyday game:
                    no quests, no service, not a guard, not in a town or inn
    trainers        when the trainer window opens
    flight masters  when the flight map opens
]]

local _, FC = ...

local Engine = FC.DiscoveryEngine
local Compat = FC.Compat
local U = FC.Utils
local L = FC.L
local Categories = FC.Categories

local RARE = { rare = true, rareelite = true }

local NPC = {}
FC.NPCDiscovery = NPC

------------------------------------------------------------------------
-- Ordinary NPCs
------------------------------------------------------------------------

-- Quest givers, guards, innkeepers, bankers and the other services are the
-- everyday game, not unusual NPCs. Once an NPC is known to be one of them it
-- is remembered (account-wide, NPC IDs are the same for every character),
-- so a quest giver whose quests are all done is not filed later just
-- because it still talks.
local function ordinarySet()
    FC.db.ordinaryNpcs = FC.db.ordinaryNpcs or {}
    return FC.db.ordinaryNpcs
end

function NPC.IsOrdinary(npcID)
    return npcID ~= nil and ordinarySet()[npcID] == true
end

--- An "unusual NPC" entry exactly as the detector wrote it: no icon (the
--- editor always sets one), never edited, not a world boss, and not
--- starred, noted or tagged since.
function NPC.IsUntouchedEntry(rec, state)
    if type(rec) ~= "table" or rec.t ~= "npc" or rec.del or rec.dev then return false end
    if rec.ic or rec.cls == "worldboss" or (tonumber(rec.r) or 1) > 1 then return false end
    return not (type(state) == "table" and (state.fav or state.note or state.tags))
end

--- Whether the reference data or the quest knowledge names this NPC as part
--- of the everyday game: it gives or takes quests, sells, trains or flies.
--- A quest giver with nothing to offer right now (its quests are done, or
--- not for this level yet) talks like any stranger; this tells them apart.
function NPC.KnownEveryday(npcID)
    if type(npcID) ~= "number" then return false end
    local Ref = FC.Reference
    if Ref and Ref.Index then
        local given = Ref:Index().givers[npcID]
        if given and #given > 0 then return true end
        if Ref:Is(npcID, "v") or Ref:Is(npcID, "t") or Ref:Is(npcID, "f") then return true end
    end
    local lore = FC.QuestLore and FC.QuestLore:GetNpc(npcID)
    return lore ~= nil and (lore.g ~= nil or lore.e ~= nil)
end

--- Remembers an ordinary NPC. Unless keepEntry is set, the automatic
--- "unusual NPC" entry an earlier version wrote for it is withdrawn.
function NPC.MarkOrdinary(npcID, keepEntry)
    if type(npcID) ~= "number" then return end
    ordinarySet()[npcID] = true
    if keepEntry then return end
    local store = FC.Store
    local id = "npc:" .. npcID
    local rec = store:Get(id)
    if rec and store:IsMine(rec) and NPC.IsUntouchedEntry(rec, store:GetState(id)) then
        store:Withdraw(id)
    end
end

--- A vendor, trainer, flight master or any other service window opened for
--- this NPC.
function Engine:MarkService(npcID)
    NPC.MarkOrdinary(npcID)
end

local wordLists = {}

--- Lowercase entries of a comma separated list from the locale (cached).
local function wordList(key)
    local list = wordLists[key]
    if not list then
        list = {}
        for _, word in ipairs(U.Split(L[key], ",")) do list[#list + 1] = word:lower() end
        wordLists[key] = list
    end
    return list
end

--- True when text contains one of the listed words or phrases as whole words.
local function hasWord(text, key)
    if type(text) ~= "string" or text == "" then return false end
    local padded = " " .. text:lower():gsub("[%p%s]+", " ") .. " "
    for _, word in ipairs(wordList(key)) do
        if padded:find(" " .. word .. " ", 1, true) then return true end
    end
    return false
end

--- A name or subtitle of the everyday game: guards, innkeepers, bankers,
--- stable masters, trainers, merchants ...
function NPC.LooksOrdinary(name, subtitle)
    return hasWord(subtitle, "NPC_ROLE_WORDS") or hasWord(name, "NPC_GUARD_WORDS")
end

local function subtitleOf(unit)
    local lines = Compat.GetUnitTooltipLines(unit)
    local line = lines[2]
    if line and not line:find("^" .. (LEVEL or "Level")) then return line end
    return nil
end

------------------------------------------------------------------------
-- Rares, world bosses and the bestiary
------------------------------------------------------------------------

local function extendLevels(rec, level)
    if not level or level < 1 or not FC.Store:IsMine(rec) then return end
    local low, high = rec.lvl or level, rec.lx or rec.lvl or level
    if level < low or level > high then
        FC.Store:Update(rec.id, { lvl = math.min(low, level), lx = math.max(high, level) }, "auto")
    end
end

local function recordCreature(unit, info)
    if not FC.Config:Get("discovery.creatures") then return end
    if not Compat.CanAttack(unit) then return end
    local fields = Engine:LocationFields()
    fields.t = "creature"
    fields.n = info.name
    fields.npc = info.npcID
    fields.lvl = info.level
    fields.lx = info.level
    fields.cls = info.classification
    fields.ct = info.creatureType
    fields.ic = Categories:Get("creature").icon
    Engine:Record(fields, {
        deferInCombat = false,
        onExisting = function(existing) extendLevels(existing, info.level) end,
    })
end

local function recordUnit(unit)
    local classification = Compat.SafeCall(UnitClassification, unit)
    if not classification then return end
    local wantRares = FC.Config:Get("discovery.rares")
    local isRare = RARE[classification]
    if isRare and not wantRares and not FC.Config:Get("discovery.creatures") then return end
    local info = Compat.GetUnitInfo(unit)
    if not info or info.isPlayer or not info.npcID or not info.name then return end
    local now = U.Now()
    if isRare and wantRares then
        local fields = Engine:LocationFields()
        fields.t = "rare"
        fields.n = info.name
        fields.npc = info.npcID
        fields.lvl = info.level
        fields.cls = classification
        fields.ct = info.creatureType
        fields.ic = Categories:Get("rare").icon
        local rec = Engine:Record(fields, { deferInCombat = false })
        if rec then
            FC.Store:AddObservation(rec.id, info.isDead and "d" or "s", now, "local")
        end
    elseif classification == "worldboss" and not Compat.GetInstance() then
        local fields = Engine:LocationFields()
        fields.t = "npc"
        fields.n = info.name
        fields.npc = info.npcID
        fields.lvl = info.level
        fields.cls = classification
        Engine:Record(fields, { deferInCombat = false })
    else
        recordCreature(unit, info)
    end
end
NPC.RecordUnit = recordUnit

local function anyCreatureDetector()
    return FC.Config:Get("discovery.rares") or FC.Config:Get("discovery.creatures")
end

Engine:RegisterDetector("units-target", {
    setting = anyCreatureDetector,
    events = {
        PLAYER_TARGET_CHANGED = function() recordUnit("target") end,
        UPDATE_MOUSEOVER_UNIT = function() recordUnit("mouseover") end,
    },
})

Engine:RegisterDetector("units-nameplates", {
    setting = function() return anyCreatureDetector() and FC.Config:Get("discovery.nameplates") end,
    events = {
        NAME_PLATE_UNIT_ADDED = function(_, _, unit)
            if type(unit) == "string" then recordUnit(unit) end
        end,
    },
})

------------------------------------------------------------------------
-- Rares and world bosses you defeat
------------------------------------------------------------------------

local KILL_DEDUPE = 600 -- one "defeated" toast per rare per ten minutes
local announcedKills = {}

--- The journal entry of a rare or a world boss, if this NPC is one.
local function killableRecord(npcID)
    local store = FC.Store
    local rec = store:Get("rare:" .. npcID)
    if rec then return rec end
    rec = store:Get("npc:" .. npcID)
    if rec and rec.cls == "worldboss" then return rec end
    return nil
end

--- Looting a rare or a world boss means it was just defeated: the death is
--- observed (respawn estimates) and a "defeated" toast is announced once.
local function onKillLoot()
    local npcIDs, sources = {}, 0
    for _, item in ipairs(Compat.GetLootItems()) do
        for _, source in ipairs(item.sources) do
            sources = sources + 1
            if source.guidType == "Creature" and source.id then npcIDs[source.id] = true end
        end
    end
    if sources == 0 then
        -- clients without loot sources: the dead target is what we loot. A
        -- chest or a herb names itself, and then the corpse of a rare that
        -- happens to be targeted was not defeated by opening it.
        local target = Compat.GetUnitInfo("target")
        if target and target.isDead and target.npcID then npcIDs[target.npcID] = true end
    end
    local now = GetTime()
    for npcID in pairs(npcIDs) do
        local rec = killableRecord(npcID)
        if rec and not (announcedKills[rec.id] and now - announcedKills[rec.id] < KILL_DEDUPE) then
            announcedKills[rec.id] = now
            FC.Store:AddObservation(rec.id, "d", U.Now(), "local")
            FC.Bus:Emit("RARE_DEFEATED", rec)
        end
    end
end

Engine:RegisterDetector("kills", {
    setting = "discovery.rares",
    events = {
        LOOT_OPENED = function() onKillLoot() end,
    },
})

------------------------------------------------------------------------
-- Services: trainers and flight masters
------------------------------------------------------------------------

Engine:RegisterDetector("trainers", {
    setting = "discovery.trainers",
    events = {
        TRAINER_SHOW = function()
            local info = Compat.GetUnitInfo("npc")
            if not info or not info.npcID or not info.name then return end
            Engine:MarkService(info.npcID)
            local subtitle = subtitleOf("npc")
            local fields = Engine:LocationFields()
            fields.t = "trainer"
            fields.n = info.name
            fields.npc = info.npcID
            fields.lvl = info.level
            fields.d = subtitle
            fields.pr = Categories:ProfessionFromText(subtitle)
            fields.ic = fields.pr and Categories:Profession(fields.pr).icon or Categories:Get("trainer").icon
            Engine:Record(fields)
        end,
    },
})

Engine:RegisterDetector("travel", {
    setting = "discovery.travel",
    events = {
        TAXIMAP_OPENED = function()
            local info = Compat.GetUnitInfo("npc")
            if not info or not info.npcID or not info.name then return end
            Engine:MarkService(info.npcID)
            local fields = Engine:LocationFields()
            fields.t = "travel"
            fields.n = info.name
            fields.npc = info.npcID
            fields.ic = Categories:Get("travel").icon
            Engine:Record(fields)
        end,
    },
})

------------------------------------------------------------------------
-- Conversations: unusual NPCs and interactive objects
------------------------------------------------------------------------

local SERVICE_TYPES = { "vendor", "trainer", "travel", "rare" }
local DIRECTORY_OPTIONS = 5 -- a guard's list of directions; a real conversation offers fewer choices

--- Why an NPC in conversation belongs to the everyday game, or nil when it
--- is an unusual NPC.
local function ordinaryReason(info, gossip)
    if gossip.quests > 0 then return "quest" end
    if NPC.KnownEveryday(info.npcID) then return "reference" end
    for _, kind in ipairs(gossip.kinds) do
        -- quests, services, and option icons we cannot name
        if kind ~= "gossip" then return kind end
    end
    if #gossip.kinds >= DIRECTORY_OPTIONS then return "directory" end
    if NPC.LooksOrdinary(info.name, info.subtitle) then return "role" end
    if Compat.IsResting() then return "town" end
    return nil
end

local function recordConversationNPC(info)
    if NPC.IsOrdinary(info.npcID) then return end -- a service window opened meanwhile
    if NPC.KnownEveryday(info.npcID) then return end -- its quest dialog taught it meanwhile
    for _, t in ipairs(SERVICE_TYPES) do
        if FC.Store:Get(t .. ":" .. info.npcID) then return end
    end
    local fields = Engine:LocationFields()
    fields.t = "npc"
    fields.n = info.name
    fields.npc = info.npcID
    fields.lvl = info.level
    local subtitle = info.subtitle
    local greeting = info.greeting
    if greeting and #greeting > 160 then greeting = greeting:sub(1, 157) .. "..." end
    if subtitle and greeting then
        fields.d = subtitle .. ". " .. greeting
    else
        fields.d = subtitle or greeting
    end
    Engine:Record(fields)
end

--- A quest board with nothing on it for you right now (every bounty done,
--- or none for your level) still opens its window: the reference data
--- knows it gives quests, so it is no secret.
local function givesQuests(objectID)
    local Ref = FC.Reference
    local given = Ref and Ref.Index and Ref:Index().objectGivers[objectID]
    return given ~= nil and #given > 0
end

local function recordInteractiveObject(objectID, name)
    if givesQuests(objectID) then return end
    local fields = Engine:LocationFields()
    local outdoors = not Compat.GetInstance() and not Compat.IsResting()
    fields.t = outdoors and "secret" or "object"
    fields.n = name
    fields.ic = Categories:Get(fields.t).icon
    local id = Engine:ObjectId("u:go:" .. objectID .. ":" .. (fields.m or 0) .. ":", fields.m, fields.x, fields.y)
    Engine:Record(fields, { id = id })
end

local function onConversation(_, event)
    local info = Compat.GetUnitInfo("npc")
    if not info or info.isPlayer or not info.name then return end
    local guidType, id = Compat.ParseGUID(info.guid)
    if guidType == "GameObject" and id then
        -- wanted posters and other quest boards are the everyday game, not secrets
        if event ~= "GOSSIP_SHOW" or Compat.GetGossipInfo().quests > 0 then return end
        recordInteractiveObject(id, info.name)
        return
    end
    if not info.npcID then return end
    if event ~= "GOSSIP_SHOW" then
        NPC.MarkOrdinary(info.npcID) -- a quest dialog: quest givers are everyday NPCs
        return
    end
    if NPC.IsOrdinary(info.npcID) then return end
    info.subtitle = subtitleOf("npc")
    local gossip = Compat.GetGossipInfo()
    local reason = ordinaryReason(info, gossip)
    if reason then
        -- a long list of choices can also be a submenu of a real conversation:
        -- remember the NPC, but keep an entry it may already have
        NPC.MarkOrdinary(info.npcID, reason == "directory")
        return
    end
    info.greeting = gossip.text
    -- give vendor / trainer / flight windows a moment to open first
    U.After(1.5, function() recordConversationNPC(info) end)
end

-- Turning in a quest: the NPC takes part in quests.
local function onQuestNPC()
    local info = Compat.GetUnitInfo("npc")
    if info and info.npcID and not info.isPlayer then NPC.MarkOrdinary(info.npcID) end
end

-- Any other service window (bank, stable, auction house ...) opened by an NPC.
local function onInteraction(_, _, interactionType)
    local types = Enum and Enum.PlayerInteractionType
    interactionType = Compat.Safe(interactionType)
    if not types or not types.Gossip or type(interactionType) ~= "number" then return end
    if interactionType == types.Gossip or interactionType == types.None then return end
    local info = Compat.GetUnitInfo("npc")
    if info and info.npcID and not info.isPlayer then Engine:MarkService(info.npcID) end
end

Engine:RegisterDetector("gossip", {
    setting = "discovery.gossip",
    events = {
        GOSSIP_SHOW = onConversation,
        QUEST_GREETING = onConversation,
        QUEST_DETAIL = onConversation,
        QUEST_PROGRESS = onQuestNPC,
        QUEST_COMPLETE = onQuestNPC,
        PLAYER_INTERACTION_MANAGER_FRAME_SHOW = onInteraction,
    },
})
