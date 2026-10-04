-- QuestieSource.lua -- the OPTIONAL Questie data source for LibQuestDB-1.0 (MINOR 12, 13).
--
-- The operator's directive, 2026-09-22: "use questie if it's available, otherwise use questdb. i
-- want to make questie a soft dep and not use it if it's not there. this is why we need to get as
-- close to parity with questie as possible." So Questie's hand-curated rows answer where Questie
-- is installed, the library's shipped tables answer where it is not, and no consumer has to know
-- which -- lib:GetDataSource() says, and lib:RegisterSourceChanged() fires when it changes.
--
-- WHY THIS IS A SEPARATE FILE, and the one place in the addon that names Questie: Questie's
-- DATABASE IS NOT PART OF ITS PUBLIC API. Questie/Public/README.md:3 promises stability only for
-- `Questie.API`, which carries the ready handshake and nothing else; the rows come from
-- `QuestieLoader:ImportModule("QuestieDB")`, an internal that can change in any Questie release.
-- Keeping every such call here means a Questie change breaks one file with its own specs instead
-- of the library -- and if the feature detection below fails, this file registers nothing and
-- every consumer silently keeps the shipped data, which is the whole point of the fallback.
-- (Questbook's Modules/QuestieAdapter.lua reached the same conclusion first and its header
-- carries the same reasoning; the traps below are its findings, not re-derived.)
--
-- THREE TRAPS THIS FILE EXISTS TO CONTAIN, all of them Questbook's measurements:
--   * `QuestieLoader:ImportModule` CREATES an empty module for a name it does not know
--     (Questie/Modules/Libs/QuestieLoader.lua:165), so importing before Questie has loaded
--     returns a table with nothing in it. Only checking for the functions we call is honest.
--   * `QueryQuest(id, keys)` RETURNS ONE TABLE indexed 1..#keys, NOT one value per key
--     (Questie/Database/compiler.lua:1143-1160). Reading it as multiple returns puts the whole
--     table in the first variable; that shipped in a consumer once and the offline fake agreed
--     with the mistake, so the suite was green and the game was not.
--   * A row's ARRAY FIELD IS NIL AT COUNT ZERO (compiler.lua:174-183), never an empty table. So
--     Questie cannot distinguish "no prerequisite" from "nothing to say", and this file resolves
--     that: for a quest Questie HAS, nil means EMPTY, because Questie's row is the curated answer
--     for that quest. That is why the library's contract is "every key the source sets is
--     authoritative" -- the knowledge of what nil means lives here.
--
-- WHAT IS AND IS NOT TAKEN FROM QUESTIE. Taken: the fields where Questie's curation is the
-- difference, measured against this dump by tools/verify-parity.lua -- prerequisites (91.8%
-- exact), exclusivity (94.8%), chain pointers (95.1%), breadcrumbs (97.6%), givers, finishers,
-- objectives, level, zone and the masks (98-100%, so they mostly agree anyway); the NPC header
-- (MINOR 12); and the spawn tables with the `zoneID` that reads them (MINOR 13). NOT taken,
-- because Questie has no such concept and the shipped row is the only answer: `hidden`, and
-- everything outside GetQuest -- rewards, XP, the path graph, drop rates, trainer columns.
-- NOT taken because it was MEASURED AND WOULD LOSE: an object's `name` and `factionID` (see
-- source.object). "Questie has it" is not the test; "Questie's is better" is, and it is a number.

local lib = LibStub and LibStub("LibQuestDB-1.0", true)
if not lib then return end

-- Questie's quest fields this file reads, in the order QueryQuest wants them; the result table is
-- indexed by POSITION in this list (see the second trap above), so Q.name below is that position.
--
-- EVERY NAME HERE MUST BE A REAL KEY IN QuestieDB.questKeys. Questie does not ignore one it does
-- not know: its compiler calls Questie.Error("ERROR: Unhandled db key: " .. key) on each of its
-- six read paths (Questie/Database/compiler.lua:1104, 1156, 1200, 1234, 1262, 1291), so a wrong
-- name is error spam in the player's chat frame, once per key per query. `suggestedPlayers` was
-- in this list and is NOT one of Questie's 36 keys (questDB.lua:6-54); the operator saw it
-- repeating in game. Worse than the noise: Questie returns nil for the unknown key, num(nil) is
-- the NONE sentinel, and NONE means "the source says this is nil" -- so it was ERASING this
-- library's own suggestedPlayers on every Questie player rather than merely failing to improve
-- it. Leaving the name out is what keeps the shipped value, which is the rule for every field
-- Questie has no concept of. Tests/questie_source_spec.lua now asserts this list against
-- Questie's real key table, because a fake that answers any key it is asked cannot catch this.
local FIELDS = {
    "name", "startedBy", "finishedBy", "requiredLevel", "questLevel", "requiredRaces",
    "requiredClasses", "objectives", "preQuestSingle", "preQuestGroup", "exclusiveTo",
    "zoneOrSort", "requiredSkill", "requiredMinRep", "requiredMaxRep", "nextQuestInChain",
    "breadcrumbForQuestId", "specialFlags", "questFlags",
}
local Q = {}
for index, name in ipairs(FIELDS) do Q[name] = index end

-- Questie's NPC fields this file reads, the same positional contract as FIELDS above.
-- `npcFlags` (npcDB.lua:22) and `friendlyToFaction` (:20) are the two a townsfolk list needs;
-- `spawns` (:14) and `zoneID` (:16) arrived together in MINOR 13 -- see the header of source.npc.
local NPC_FIELDS = { "name", "subName", "minLevel", "maxLevel", "rank", "npcFlags",
                     "friendlyToFaction", "spawns", "zoneID" }
local N = {}
for index, name in ipairs(NPC_FIELDS) do N[name] = index end

-- Questie's object fields, same contract (objectDB.lua:5-12). ONLY `spawns` and `zoneID` are
-- read: `name` and `factionID` were measured and are not worth taking -- see source.object.
local OBJECT_FIELDS = { "name", "spawns", "zoneID" }
local O = {}
for index, name in ipairs(OBJECT_FIELDS) do O[name] = index end

local source = {}
local db                        -- the validated QuestieDB module
local cache = {}                -- [questId] = resolved partial result, or false for "no row"
local npcCache = {}             -- [npcId] = the same, for source.npc
local objectCache = {}          -- [objectId] = the same, for source.object
local npcSpawnCache = {}        -- [npcId] = the converted spawn table, or false for "no row"
local objectSpawnCache = {}
local ids                       -- the id list, built once
local npcIds, objectIds         -- the same for NPCs and objects

-- One of Questie's id arrays as a fresh list of numbers; {} for the nil it stores at count zero.
local function idList(slot)
    local out = {}
    if type(slot) ~= "table" then return out end
    for index = 1, #slot do
        if type(slot[index]) == "number" then out[#out + 1] = slot[index] end
    end
    return out
end

-- Questie's absolute prerequisite ids: it stores preQuestGroup SIGNED (questDB.lua:73,
-- "u8s24array"), and a negative entry is the same quest, not another one.
local function absList(slot)
    local out = idList(slot)
    for index = 1, #out do
        if out[index] < 0 then out[index] = -out[index] end
    end
    return out
end

-- Questie's { {id, text, icon}, ... } objective rows as this library's { {id=, count=}, ... }.
-- QUESTIE CARRIES NO COUNT: its objective is "kill these", the number comes from the player's
-- quest log. The shipped row has the real count, so the count is taken from `mine` where the id
-- matches and defaults to 1 where Questie names an objective this dump does not.
local function objectives(slot, mine)
    local out = {}
    if type(slot) ~= "table" then return out end
    local count = {}
    for _, entry in ipairs(mine or {}) do count[entry.id] = entry.count end
    for _, entry in ipairs(slot) do
        local id = type(entry) == "table" and entry[1] or entry
        if type(id) == "number" then
            out[#out + 1] = { id = id, count = count[id] or 1, alsoCounts = nil }
        end
    end
    return out
end

-- THREE ANSWERS, NOT TWO, and the third is why this reads the way it does (Peer Review, thread
-- 12bd1814). A coercion here can mean:
--
--   a value            -> use it
--   lib.NONE           -> "Questie positively says there is none". Erases the shipped value, which
--                         is the whole point of the sentinel: curation that REMOVES a value has to
--                         be expressible, or a plain nil would silently ignore it.
--   nil                -> "I could not read an answer". Leaves the key absent, so the shipped
--                         value stands.
--
-- The `suggestedPlayers` defect was the second and third being the SAME answer: an unknown key
-- returned nil, nil became NONE, and this library erased its own good column on every Questie
-- player rather than merely failing to improve it. The field-list spec closes the way a nil got
-- there THAT time -- it asserts every name against Questie's real key tables -- but it does not
-- close the class, because ANY surprise still arrives as a value these functions have to read.
--
-- So the rule is: an ABSENT value is Questie's row saying none, and that erases; a value of the
-- WRONG SHAPE is not an answer at all, and keeps what we have. A shape surprise must never be
-- more destructive than no source at all.
--
-- WHAT THIS DOES NOT SETTLE, said plainly rather than implied: for a key Questie really has,
-- nil still means NONE, and whether Questie omits such a key to mean "none" or to mean "not
-- recorded" is a property of Questie's compiler that I have NOT read (not verified). If it ever
-- means "not recorded", these four fields erase on a Questie player and nothing here would say
-- so. The field-list spec is what makes the reading defensible today, not a check of Questie's
-- own semantics.
-- A faction/skill pair. A TABLE is the right shape, so an empty one is Questie's row saying none
-- and still erases; only a non-table is unreadable. Narrowed exactly this far on purpose: every
-- table shape keeps the meaning it had before, so nothing rests on how Questie spells an absent
-- requiredSkill -- which I have not read (not verified).
local function pair(slot, k1, k2)
    if slot == nil then return lib.NONE end
    if type(slot) ~= "table" then return nil end
    if type(slot[1]) ~= "number" then return lib.NONE end
    return { [k1] = slot[1], [k2] = slot[2] or 0 }
end

-- A nullable scalar: the number, NONE when Questie's row carries nothing (or a 0, which is its
-- spelling of "none"), and nil when the answer is not a number at all.
local function num(value)
    if value == nil then return lib.NONE end
    if type(value) ~= "number" then return nil end
    if value == 0 then return lib.NONE end
    return value
end

-- The same for a value that is already either a string / table or nothing. There is no wrong
-- shape to detect here -- the library takes whatever it is -- so absent is the only NONE.
local function orNone(value)
    if value == nil then return lib.NONE end
    return value
end

--- The QuestieDB module, or nil when it cannot be used yet. Checks the functions and tables this
--- file actually calls, because ImportModule fabricates an empty module for an unknown name.
local function questieDB()
    if db then return db end
    if not (QuestieLoader and QuestieLoader.ImportModule) then return nil end
    local module = QuestieLoader:ImportModule("QuestieDB")
    if type(module) ~= "table" or type(module.QueryQuest) ~= "function"
        or type(module.QuestPointers) ~= "table" then
        return nil
    end
    db = module
    return db
end

--- Questie's curated view of one quest as a partial GetQuest result, or nil when it has no row.
--- Cached: a pane that reads one quest repeatedly must not re-walk Questie's compiled row, and
--- Questie's own returned object is mutable shared state that must never be handed out.
function source.quest(questId)
    local id = tonumber(questId)
    if not id then return nil end
    local hit = cache[id]
    if hit ~= nil then return hit or nil end
    local module = questieDB()
    local row = module and module.QueryQuest(id, FIELDS)
    if type(row) ~= "table" or type(row[Q.name]) ~= "string" then
        cache[id] = false
        return nil
    end
    local started = row[Q.startedBy] or {}
    local finished = row[Q.finishedBy] or {}
    local objective = row[Q.objectives] or {}
    -- The shipped row, for the counts Questie does not carry. GetShippedQuest, NEVER GetQuest:
    -- GetQuest consults this very resolver, so calling it here re-enters us (~200 stack frames
    -- per first read, terminating only because fromSource's pcall swallowed the overflow).
    local mine = lib:GetShippedQuest(id)
    local resolved = {
        name             = row[Q.name],
        requiredLevel    = row[Q.requiredLevel] or 0,
        questLevel       = num(row[Q.questLevel]),
        zoneOrSort       = num(row[Q.zoneOrSort]),
        requiredRaces    = row[Q.requiredRaces] or 0,
        requiredClasses  = row[Q.requiredClasses] or 0,
        questFlags       = row[Q.questFlags] or 0,
        specialFlags     = row[Q.specialFlags] or 0,
        -- NO suggestedPlayers: Questie has no such key, so the shipped column stands. See FIELDS.
        startedBy        = { npcs = idList(started[1]), objects = idList(started[2]), items = idList(started[3]) },
        finishedBy       = { npcs = idList(finished[1]), objects = idList(finished[2]) },
        preQuestSingle   = absList(row[Q.preQuestSingle]),
        preQuestGroup    = absList(row[Q.preQuestGroup]),
        exclusiveTo      = idList(row[Q.exclusiveTo]),
        nextQuestInChain = num(row[Q.nextQuestInChain]),
        breadcrumbForQuestId = num(row[Q.breadcrumbForQuestId]),
        requiredSkill    = pair(row[Q.requiredSkill], "skill", "value"),
        requiredMinRep   = pair(row[Q.requiredMinRep], "faction", "value"),
        requiredMaxRep   = pair(row[Q.requiredMaxRep], "faction", "value"),
        objectives       = {
            npcs    = objectives(objective[1], mine and mine.objectives.npcs),
            objects = objectives(objective[2], mine and mine.objectives.objects),
            items   = objectives(objective[3], mine and mine.objectives.items),
            spells  = mine and mine.objectives.spells or {},
            explore = mine and mine.objectives.explore or {},
            rep     = pair(objective[4], "faction", "value"),
        },
    }
    -- preQuestActive is the dump's signed PrevQuestId and has no Questie counterpart: Questie
    -- folds an "active" prerequisite into preQuestGroup as a negative id, which absList() has
    -- already made positive above. Leaving the key out keeps the shipped row's answer.
    cache[id] = resolved
    return resolved
end

--- Questie's curated view of one NPC's HEADER as a partial GetNPC result, or nil when it has no
--- row. Cached, and for the same two reasons as source.quest: a list that walks every NPC must
--- not re-walk Questie's compiled rows, and Questie's own returned object is mutable state.
---
--- `zoneID` IS TAKEN AS OF MINOR 13, and only because `spawns` is: zoneID names the area a thing
--- is most often placed in, so it is a reading of the spawn row. Taking one without the other
--- would have the header naming Questie's zone while GetNPCSpawns returned this library's points,
--- or the reverse. Questie's own zoneID is "guess as to where this NPC is most common"
--- (npcDB.lua:16) -- the same meaning -- and on Era every placed row carries one and it is always
--- one of that row's own spawn areas (measured 2026-09-22, 7,520 placed NPCs, 4,896 objects).
--- `killCredit` and the trainer columns are still not taken -- Questie has no counterpart.
function source.npc(npcId)
    local id = tonumber(npcId)
    if not id then return nil end
    local hit = npcCache[id]
    if hit ~= nil then return hit or nil end
    local module = questieDB()
    local row = module and type(module.QueryNPC) == "function" and module.QueryNPC(id, NPC_FIELDS)
    if type(row) ~= "table" or type(row[N.name]) ~= "string" then
        npcCache[id] = false
        return nil
    end
    local resolved = {
        name = row[N.name],
        subName = orNone(row[N.subName]),
        minLevel = row[N.minLevel] or 0,
        maxLevel = row[N.maxLevel] or 0,
        rank = row[N.rank] or 0,
        npcFlags = row[N.npcFlags] or 0,
        -- nil here is Questie's "hostile to both" (npcDB.lua:20), which is this library's nil
        -- too -- and it has to be SAID, or the shipped side's value would stand instead.
        friendlyToFaction = orNone(row[N.friendlyToFaction]),
        zoneID = orNone(row[N.zoneID]),
    }
    npcCache[id] = resolved
    return resolved
end

--- Questie's curated view of one object's header, or nil when it has no row. ONLY `zoneID`, and
--- that is a measurement, not an omission: on Era Questie's object `name` differs from the
--- shipped one on 83 of 6,645 shared ids and 80 of those are Questie holding an EMPTY STRING
--- where this dump has a name, and its `factionID` is absent on 681 ids the dump gives a faction
--- for, present on 7 it does not, and disagrees on NONE. So its names would blank 80 objects to
--- gain 3, and its factions would gain 7 while splitting the pair with the derived
--- `friendlyToFaction` this library computes from the client's FactionTemplate. `zoneID` is here
--- only because source.objectSpawns moved the points (measured 2026-09-22, verify-parity.lua).
function source.object(objectId)
    local id = tonumber(objectId)
    if not id then return nil end
    local hit = objectCache[id]
    if hit ~= nil then return hit or nil end
    local module = questieDB()
    local row = module and type(module.QueryObject) == "function" and module.QueryObject(id, OBJECT_FIELDS)
    if type(row) ~= "table" or type(row[O.name]) ~= "string" then
        objectCache[id] = false
        return nil
    end
    local resolved = { zoneID = orNone(row[O.zoneID]) }
    objectCache[id] = resolved
    return resolved
end

--- Where Questie places one NPC / object, in GetNPCSpawns' shape -- which is Questie's own shape:
--- { [areaId] = { {x, y}, ... } }, x and y 0..100, and {-1, -1} for a placement inside an
--- instance. VERIFIED rather than assumed, because the whole table is handed over unconverted:
--- on Era the only negative coordinates in Questie's rows are exactly -1,-1 (2,125 NPC points,
--- 718 object points) and the largest is 95.96, so both conventions are this library's already.
---
--- A FRESH TABLE, never Questie's own: its returned row is mutable shared state, and this
--- library's contract says a spawn table is read-only and cached, so handing Questie's out would
--- let one consumer's mistake corrupt Questie for every other addon in the session.
local function spawnsOf(row, slot)
    if type(row) ~= "table" or type(row[slot]) ~= "table" then return nil end
    local out = {}
    for area, points in pairs(row[slot]) do
        if type(area) == "number" and type(points) == "table" then
            local list = {}
            for index = 1, #points do
                local p = points[index]
                if type(p) == "table" and type(p[1]) == "number" and type(p[2]) == "number" then
                    list[#list + 1] = { p[1], p[2] }
                end
            end
            out[area] = list
        end
    end
    return out
end

--- Cached like the headers, and for one more reason than they have: the library's contract says
--- a spawn table is SHARED and read-only, so a fresh table per call would make that contract a
--- lie for a source-backed answer -- two calls would hand out two tables.
function source.npcSpawns(npcId)
    local id = tonumber(npcId)
    if not id then return nil end
    local hit = npcSpawnCache[id]
    if hit ~= nil then return hit or nil end
    local module = questieDB()
    local row = module and type(module.QueryNPC) == "function" and module.QueryNPC(id, NPC_FIELDS)
    local spawns = spawnsOf(row, N.spawns)
    npcSpawnCache[id] = spawns or false
    return spawns
end

function source.objectSpawns(objectId)
    local id = tonumber(objectId)
    if not id then return nil end
    local hit = objectSpawnCache[id]
    if hit ~= nil then return hit or nil end
    local module = questieDB()
    local row = module and type(module.QueryObject) == "function" and module.QueryObject(id, OBJECT_FIELDS)
    local spawns = spawnsOf(row, O.spawns)
    objectSpawnCache[id] = spawns or false
    return spawns
end

-- The numeric keys of one of Questie's id maps as a list, or nil when the map is not there.
local function idsOf(map)
    if type(map) ~= "table" then return nil end
    local out = {}
    for id in pairs(map) do
        if type(id) == "number" then out[#out + 1] = id end
    end
    return out
end

--- Every quest id Questie holds. `QuestPointers` is what Questie itself walks
--- (Questie/Database/QuestieDB.lua:295); there is no iterator. Built once.
function source.questIds()
    if ids then return ids end
    local module = questieDB()
    if not module then return nil end
    ids = idsOf(module.QuestPointers)
    return ids
end

--- Every NPC / object id Questie holds, from `NPCPointers` / `ObjectPointers`, which Questie 12
--- binds beside QuestPointers (Questie/Database/QuestieDB.lua:450-452). Questie 12 knows NPCs this
--- dump does not (185333-185335 on Era), so GetNPCIds must list them for HasNPC to agree with it.
--- Nil, not an empty list, when an older Questie has no such map: the library then lists its own.
function source.npcIds()
    if npcIds then return npcIds end
    local module = questieDB()
    npcIds = module and idsOf(module.NPCPointers)
    return npcIds
end
function source.objectIds()
    if objectIds then return objectIds end
    local module = questieDB()
    objectIds = module and idsOf(module.ObjectPointers)
    return objectIds
end

--- Register as the library's source. Separate from the ready handshake so a spec can drive it.
--- False when Questie's internals are not what this file reads, in which case nothing changes
--- and the shipped tables keep answering.
--- EVERY cache is dropped here, not just the quest one. Re-installing means Questie's rows may
--- have been rebuilt underneath us, so a surviving entry would serve the previous database --
--- and the npc cache was surviving exactly that way before MINOR 13 added the rest.
function source.install()
    if not questieDB() then return false end
    cache, npcCache, objectCache = {}, {}, {}
    npcSpawnCache, objectSpawnCache, ids = {}, {}, nil
    npcIds, objectIds = nil, nil
    return lib:RegisterDataSource("questie", source) == true
end

lib._questieSource = source     -- named so the spec can drive install() without Questie's events

-- Questie's own documented handshake (Public/README.md:9): its data is not valid until
-- `Questie.API.isReady`, and RegisterOnReady fires once it is. Nothing here polls, nothing
-- guesses a delay, and a Questie too old to carry the hook simply never registers.
if Questie and Questie.API then
    if Questie.API.isReady then
        source.install()
    elseif type(Questie.API.RegisterOnReady) == "function" then
        Questie.API.RegisterOnReady(function() source.install() end)
    end
end
