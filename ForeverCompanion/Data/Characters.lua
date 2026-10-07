--[[
  Forever Companion - Data/Characters.lua
  Your characters, account-wide: name, class, level and the quests each one
  has completed, so tooltips and the journal can say which of your other
  characters already did a quest.

    FC.db.characters["Name-Realm"] = { n, c (class file), l (level), s (last seen),
                                       g (the character's GUID), qs (when the game last listed its quests),
                                       q = { [questID] = true }, qd = { [questID] = turned in at },
                                       fp = { [nodeID] = true },
                                       rk = { [npcID] = true } (rares and world bosses defeated) }
    FC.db.flightNodes[nodeID]      = { n = name, npc = flight master's NPC ID }

  Completed quests come from the game (the server keeps them), so they are
  known for a character the journal never watched: at login the client's
  list is joined with what is already stored. A quest never becomes "not
  completed", and a list the client has not filled yet wipes nothing. Only
  quests turned in while the addon runs have a date (qd). QuestHistory turns
  the IDs into names.

  Flight paths are learned from the flight map: every node it lists as
  reachable is known to the character, and the node you stand at belongs to
  the flight master you talk to.
]]

local _, FC = ...

local Characters = FC:NewModule("Characters")

local U = FC.Utils
local Compat = FC.Compat

local MAX_QUESTS = 20000
local SCAN_RETRIES = { 5, 15, 45, 120 } -- seconds after login: the completed list can arrive late

local function vID(v)
    return type(v) == "number" and v > 0 and v < 2147483648 and v == math.floor(v)
end

-- A quest ID as a number: a hand-edited or imported file may hold it as text.
local function questKey(id)
    if type(id) == "string" then id = tonumber(id) end
    return vID(id) and id or nil
end

function Characters:Validate(list)
    if type(list) ~= "table" then return {} end
    for key, char in pairs(list) do
        if type(key) ~= "string" or type(char) ~= "table" then
            list[key] = nil
        else
            local quests, count = {}, 0
            for id, done in pairs(type(char.q) == "table" and char.q or {}) do
                id = questKey(id)
                if id and done == true and not quests[id] and count < MAX_QUESTS then
                    quests[id] = true
                    count = count + 1
                end
            end
            local dates = {}
            for id, at in pairs(type(char.qd) == "table" and char.qd or {}) do
                id = questKey(id)
                if id and quests[id] and type(at) == "number" and at > 0 then dates[id] = math.floor(at) end
            end
            local nodes, rares = {}, {}
            for id, known in pairs(type(char.fp) == "table" and char.fp or {}) do
                if vID(id) and known == true then nodes[id] = true end
            end
            for id, killed in pairs(type(char.rk) == "table" and char.rk or {}) do
                if vID(id) and killed == true then rares[id] = true end
            end
            list[key] = {
                n = U.CleanText(char.n, 48) or key,
                c = type(char.c) == "string" and char.c:sub(1, 24) or nil,
                l = tonumber(char.l),
                s = tonumber(char.s) or 0,
                g = type(char.g) == "string" and #char.g <= 64 and char.g or nil,
                qs = tonumber(char.qs),
                q = quests,
                qd = dates,
                fp = nodes,
                rk = rares,
            }
        end
    end
    return list
end

function Characters:OnInitialize()
    FC.db.characters = self:Validate(FC.db.characters)
    self.list = FC.db.characters
    local nodes = type(FC.db.flightNodes) == "table" and FC.db.flightNodes or {}
    for id, node in pairs(nodes) do
        if not vID(id) or type(node) ~= "table" then
            nodes[id] = nil
        else
            nodes[id] = { n = U.CleanText(node.n, 64), npc = vID(node.npc) and node.npc or nil }
        end
    end
    FC.db.flightNodes = nodes
    self.nodeByNpc = nil
    self.scan = { state = "pending", tries = 0 }
end

--- Your characters as they go into a backup: names, classes, levels, flight
--- paths, the rares they defeated and the quests they completed (the game
--- lists a character's quests again when it logs in, but not their dates,
--- and nothing tells again which rares it defeated).
function Characters:BackupCopy()
    local chars = {}
    for key, char in pairs(self.list) do
        chars[key] = {
            n = char.n, c = char.c, l = char.l, s = char.s, g = char.g,
            fp = U.CopyTable(char.fp), rk = U.CopyTable(char.rk), q = U.CopyTable(char.q), qd = U.CopyTable(char.qd),
        }
    end
    return chars, U.CopyTable(FC.db.flightNodes)
end

--- Joins characters and flight path nodes from a backup into yours.
function Characters:Merge(chars, nodes)
    for key, char in pairs(self:Validate(type(chars) == "table" and chars or {})) do
        local mine = self.list[key]
        if not mine then
            self.list[key] = char
        elseif mine.g and char.g and mine.g ~= char.g then
            -- the backup's character of this name is another one: nothing of it is this one's
            mine.c, mine.l = mine.c or char.c, mine.l or char.l
        else
            mine.c, mine.l = mine.c or char.c, mine.l or char.l
            for id in pairs(char.fp) do mine.fp[id] = true end
            for id in pairs(char.rk) do mine.rk[id] = true end
            for id in pairs(char.q) do mine.q[id] = true end
            for id, at in pairs(char.qd) do
                if not mine.qd[id] or at < mine.qd[id] then mine.qd[id] = at end
            end
        end
    end
    for id, node in pairs(type(nodes) == "table" and nodes or {}) do
        if vID(id) and type(node) == "table" and not FC.db.flightNodes[id] then
            FC.db.flightNodes[id] = { n = U.CleanText(node.n, 64), npc = vID(node.npc) and node.npc or nil }
        end
    end
    self.nodeByNpc = nil
    FC.Bus:Emit("QUESTS_COMPLETED_CHANGED", 0, "merge")
end

function Characters:Me()
    local key = FC.Store.me
    local char = self.list[key]
    if not char then
        char = { q = {}, qd = {}, fp = {}, rk = {} }
        self.list[key] = char
    end
    return char, key
end

function Characters:Snapshot()
    local char = self:Me()
    char.n = U.ShortName(FC.Store.me)
    char.c = Compat.GetClassFile()
    char.l = Compat.SafeCall(_G.UnitLevel, "player") or char.l
    char.s = U.Now()
end

--- A deleted character's name can be taken by a new one: the game tells
--- them apart by their GUID. What the old one completed, learned and
--- defeated is not the new one's.
function Characters:CheckIdentity()
    local char = self:Me()
    local guid = Compat.SafeCall(_G.UnitGUID, "player")
    if type(guid) ~= "string" or guid == "" then return false end
    local replaced = char.g ~= nil and char.g ~= guid
    if replaced then
        FC.Log:Info("Another character now has the name %s: its completed quests, flight paths and defeated rares start over", tostring(FC.Store.me))
        char.q, char.qd, char.fp, char.rk, char.qs = {}, {}, {}, {}, nil
    end
    char.g = guid
    return replaced
end

--- Reads every quest this character has completed (when the client can list
--- them) and joins it with what is already known. Returns the state, how
--- many quests were new to the journal and how many the client listed:
---   "ok"           the list was read
---   "empty"        the client listed nothing (not filled yet, or a new character)
---   "unavailable"  the client cannot list completed quests
function Characters:ScanQuests()
    local scan = self.scan
    scan.tries = scan.tries + 1
    local list = C_QuestLog and C_QuestLog.GetAllCompletedQuestIDs and Compat.SafeCall(C_QuestLog.GetAllCompletedQuestIDs)
    if type(list) ~= "table" then
        scan.state = "unavailable"
        FC.Log:Debug("Completed quests: the client gave no list (attempt %d)", scan.tries)
        return "unavailable", 0, 0
    end
    local char = self:Me()
    local known = char.q
    local listed, added = 0, 0
    for i = 1, math.min(#list, MAX_QUESTS) do
        local id = Compat.Safe(list[i])
        if vID(id) then
            listed = listed + 1
            if not known[id] then
                known[id] = true
                added = added + 1
            end
        end
    end
    if listed == 0 then
        -- nothing yet: what is stored stays, and the list is asked for again
        scan.state = "empty"
        FC.Log:Debug("Completed quests: the client's list is empty (attempt %d); %d stored quests kept", scan.tries, U.Count(known))
        return "empty", 0, 0
    end
    scan.state, scan.listed, scan.added = "ok", listed, (scan.added or 0) + added
    char.qs = U.Now()
    FC.Log:Debug("Completed quests: the client listed %d, %d new to the journal, %d known in all (attempt %d)", listed, added, U.Count(known), scan.tries)
    if added > 0 then FC.Bus:Emit("QUESTS_COMPLETED_CHANGED", added, "scan") end
    return "ok", added, listed
end

--- The state of this session's reading of the completed quests:
--- { state = "pending" | "ok" | "empty" | "unavailable", tries, listed, added }.
function Characters:ScanState()
    return self.scan
end

--- Reads the open flight map: the nodes this character can fly to, and the
--- node of the flight master in front of you.
function Characters:ScanFlightMap()
    local T = _G.C_TaxiMap
    if not (T and T.GetAllTaxiNodes) then return end
    local mapID = Compat.SafeCall(_G.GetTaxiMapID) or Compat.GetPlayerMapID()
    local ok, nodes = pcall(T.GetAllTaxiNodes, mapID)
    if not ok or type(nodes) ~= "table" then return end
    local states = Enum and Enum.FlightPathState or {}
    local current, unreachable = states.Current or 0, states.Unreachable or 2
    local known = self:Me().fp
    local npc = Compat.GetUnitInfo("npc")
    for _, node in ipairs(nodes) do
        local nodeID, state = Compat.Safe(node.nodeID), Compat.Safe(node.state)
        if vID(nodeID) and state ~= unreachable then
            known[nodeID] = true
            local entry = FC.db.flightNodes[nodeID] or {}
            entry.n = U.CleanText(Compat.Safe(node.name), 64) or entry.n
            if state == current and npc and npc.npcID and not npc.isPlayer then
                entry.npc = npc.npcID
                self.nodeByNpc = nil
            end
            FC.db.flightNodes[nodeID] = entry
        end
    end
end

--- The flight path node of a flight master, if the journal has seen its map.
function Characters:FlightNodeOf(npcID)
    if not npcID then return nil end
    if not self.nodeByNpc then
        local index = {}
        for nodeID, node in pairs(FC.db.flightNodes) do
            if node.npc then index[node.npc] = nodeID end
        end
        self.nodeByNpc = index
    end
    return self.nodeByNpc[npcID]
end

--- Whether the character you play defeated a rare or world boss.
function Characters:Defeated(npcID)
    return npcID ~= nil and self:Me().rk[npcID] == true
end

--- Whether the character you play knows a flight master's path: true,
--- false, or nil when that flight master's node is not known yet.
function Characters:KnowsFlightPath(npcID)
    local nodeID = self:FlightNodeOf(npcID)
    if not nodeID then return nil end
    return self:Me().fp[nodeID] == true
end

--- "New flight path discovered!": announced once, with the place it was learned.
function Characters:OnGameMessage(text)
    text = Compat.Safe(text)
    local learned = _G.ERR_NEWTAXIPATH
    if type(text) ~= "string" or type(learned) ~= "string" or text ~= learned then return end
    local now = GetTime()
    if self.lastPathLearned and now - self.lastPathLearned < 5 then return end
    self.lastPathLearned = now
    local zone, subzone = Compat.GetZoneTexts()
    local place = subzone ~= "" and subzone or zone
    FC.Bus:Emit("FLIGHT_PATH_LEARNED", place ~= "" and place or nil)
end

--- The login scan: tried a few times, because the client can list the
--- completed quests a little after the character enters the world.
function Characters:ScanAtLogin(attempt)
    local state = self:ScanQuests()
    if state == "ok" or state == "unavailable" or not SCAN_RETRIES[attempt + 1] then
        -- an empty list after the last try is a character without quests
        if state == "empty" then self.scan.state = "ok" end
        FC.Bus:Emit("QUESTS_SCANNED", self.scan.state)
        return
    end
    U.After(SCAN_RETRIES[attempt + 1] - SCAN_RETRIES[attempt], function() self:ScanAtLogin(attempt + 1) end)
end

function Characters:OnEnable()
    self:CheckIdentity()
    self:Snapshot()
    FC.Events:Register("TAXIMAP_OPENED", self, function()
        FC:SafeCall("Characters:ScanFlightMap", self.ScanFlightMap, self)
    end)
    FC.Events:Register("UI_INFO_MESSAGE", self, function(_, _, _, text) self:OnGameMessage(text) end)
    FC.Events:Register("CHAT_MSG_SYSTEM", self, function(_, _, text) self:OnGameMessage(text) end)
    U.After(SCAN_RETRIES[1], function() self:ScanAtLogin(1) end)
    FC.Events:Register("QUEST_TURNED_IN", self, function(_, _, questID)
        questID = Compat.Safe(questID)
        if not vID(questID) then return end
        local char = self:Me()
        local new = not char.q[questID]
        char.q[questID] = true
        -- the first time it is turned in (a repeatable quest keeps that date)
        if not char.qd[questID] then char.qd[questID] = U.Now() end
        if new then FC.Bus:Emit("QUESTS_COMPLETED_CHANGED", 1, "turnin", questID) end
    end)
    FC.Events:Register("PLAYER_LEVEL_UP", self, function() U.After(1, function() self:Snapshot() end) end)
    FC.Bus:On("RARE_DEFEATED", self, function(_, rec)
        if rec and vID(rec.npc) then self:Me().rk[rec.npc] = true end
    end)
end

function Characters:OnLogout()
    self:Snapshot()
end

--- Your other characters that completed a quest: { { name, class } }.
function Characters:CompletedBy(questID)
    local out = {}
    local me = FC.Store.me
    for key, char in pairs(self.list) do
        if key ~= me and char.q and char.q[questID] then
            out[#out + 1] = { name = char.n or key, class = char.c }
        end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

--- When a character of yours (the one you play by default) turned a quest
--- in, if the journal was watching; nil for a quest it only knows as done.
function Characters:CompletedAt(questID, key)
    local char = self.list[key or FC.Store.me]
    return char and char.qd and char.qd[questID] or nil
end
