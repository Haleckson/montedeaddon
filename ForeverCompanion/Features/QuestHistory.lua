--[[
  Forever Companion - Features/QuestHistory.lua
  The quests your characters completed, as a list with names.

  The game keeps a character's completed quests on the server and hands them
  to the client as plain IDs (Data/Characters.lua stores them), so they are
  known for quests done before the addon was installed, or while it was
  not. The count on the Progress page always came from there; this module
  turns the IDs into something to read:

    names     a quest's title comes from the client, from what the journal
              learned, or from the English titles the addon ships. A quest
              nobody can name yet waits in a queue: the client is asked for
              a few quests per tick, and answers with QUEST_DATA_LOAD_RESULT
              or, when that never comes, is looked at again after a few
              seconds. A quest the game has no title for stays in the list
              as "Unknown completed quest" with its ID, is asked for again
              later (a day after, or by /fc rescan), and takes its name as
              soon as there is one. An empty title is never saved.
    details   zone, level and quest giver from the reference data and the
              quest knowledge; the journal's own entry when the quest was
              accepted with the addon running; the date it was turned in
              when the journal watched.
    repair    after the completed quests are read at login, and with
              /fc rescan: journal quests turned in while the addon was away
              are marked done, quest chains filed as "Chain: #123" get their
              name, and two journal entries for one quest become one.

  What the game does not tell: when a quest was done and where. Quests the
  journal did not watch are listed without a date.

  Bus: QUEST_HISTORY_CHANGED() when names arrived or the lists changed.
]]

local _, FC = ...

local History = FC:NewModule("QuestHistory")

local U = FC.Utils
local L = FC.L
local Compat = FC.Compat

History.REPAIR_VERSION = 1

local TICK = 0.25             -- seconds between two rounds of requests
local BATCH = 10              -- quests asked for per round
local MAX_IN_FLIGHT = 40      -- requests waiting for an answer at most
local ANSWER_TIMEOUT = 6      -- an answer that did not come by then is looked for in the client
local MAX_TRIES = 2           -- requests per quest and session
local RETRY_AFTER = 20 * 3600 -- a quest the game could not name is asked for again after this long

local function vID(v)
    return type(v) == "number" and v > 0 and v < 2147483648 and v == math.floor(v)
end

function History:OnInitialize()
    local saved = type(FC.db.questHistory) == "table" and FC.db.questHistory or {}
    local unnamed = {}
    for questID, at in pairs(type(saved.unnamed) == "table" and saved.unnamed or {}) do
        if vID(questID) and type(at) == "number" then unnamed[questID] = at end
    end
    -- unnamed: quests the game had no title of its own for, and when it was last asked
    FC.db.questHistory = { unnamed = unnamed, repair = tonumber(saved.repair) or 0 }
    self.data = FC.db.questHistory
    self.queue, self.head, self.queued = {}, 1, {}
    self.pending, self.tries, self.failed, self.waiters = {}, {}, {}, {}
    self.version = 0
    self.run = nil
end

------------------------------------------------------------------------
-- Whose quests
------------------------------------------------------------------------

--- The quests some of your characters completed ({ [key] = true }; the one
--- you play by default): { [questID] = true }, and how many.
function History:Completed(keys)
    keys = keys or { [FC.Store.me] = true }
    local chars = FC.db.characters or {}
    local set, count = {}, 0
    for key in pairs(keys) do
        local char = chars[key]
        for questID in pairs(char and char.q or {}) do
            if not set[questID] then
                set[questID] = true
                count = count + 1
            end
        end
    end
    return set, count
end

--- The quests any of your characters completed.
function History:AllCompleted()
    local keys = {}
    for key in pairs(FC.db.characters or {}) do keys[key] = true end
    return self:Completed(keys)
end

--- Whether any of your characters completed a quest.
function History:CompletedByAny(questID)
    for _, char in pairs(FC.db.characters or {}) do
        if char.q and char.q[questID] then return true end
    end
    return false
end

--- Whether the character you play completed a quest: the game's own answer
--- when it gives one, else the stored list.
function History:IsCompleted(questID)
    if Compat.GetQuestStatus(questID) == "done" then return true end
    return FC.Characters:Me().q[questID] == true
end

------------------------------------------------------------------------
-- Names: the queue of quests the client is asked for
------------------------------------------------------------------------

local function changed(self)
    self.version = self.version + 1
    U.Debounce("quest-history-changed", 0.5, function() FC.Bus:Emit("QUEST_HISTORY_CHANGED") end)
end

--- Whether a quest still waits for the client to name it.
function History:IsPending(questID)
    return self.queued[questID] == true or self.pending[questID] ~= nil
end

--- Whether the game was asked for a quest's name and had none.
function History:IsUnnamed(questID)
    return self.data.unnamed[questID] ~= nil or self.failed[questID] == true
end

-- A quest has a name now: it is kept, and whoever waited for it hears.
local function named(self, questID, title)
    FC.QuestLore:RememberTitle(questID, title)
    self.data.unnamed[questID] = nil
    self.failed[questID] = nil
    self.tries[questID] = nil
    if self.run then self.run.named = self.run.named + 1 end
    FC.Log:Trace("Quest %d is named: %s", questID, tostring(title))
    local waiting = self.waiters[questID]
    if waiting then
        self.waiters[questID] = nil
        for _, callback in ipairs(waiting) do FC:SafeCall("quest-title", callback, title) end
    end
    changed(self)
end

-- The game has no name for a quest right now. It stays listed by its ID (or
-- under the English title the addon ships) and is asked for again another
-- day; nothing empty is saved as its title.
local function giveUp(self, questID)
    self.failed[questID] = true
    self.tries[questID] = nil
    self.waiters[questID] = nil
    self.data.unnamed[questID] = U.Now()
    if not FC.QuestLore:KnownTitle(questID) then
        if self.run then self.run.failed = self.run.failed + 1 end
        FC.Log:Debug("Quest %d: the game has no title for it; kept as an unknown completed quest", questID)
    end
    changed(self)
end

--- Puts a quest in the queue. force asks again for a quest the game could
--- not name earlier (a manual rescan). Returns whether it was added.
function History:Enqueue(questID, force)
    if not vID(questID) or self:IsPending(questID) then return false end
    if not force then
        if self.failed[questID] then return false end
        local last = self.data.unnamed[questID]
        if last and U.Now() - last < RETRY_AFTER then return false end
    end
    self.failed[questID] = nil
    self.queued[questID] = true
    self.queue[#self.queue + 1] = questID
    return true
end

--- The client answered about a quest (success true or false), or stayed
--- silent for too long (nil).
function History:Settle(questID, success)
    self.pending[questID] = nil
    local title = Compat.GetQuestTitle(questID)
    if title then
        named(self, questID, title)
        return true
    end
    -- loaded, and it has no title: asking again changes nothing
    if success ~= true and (self.tries[questID] or 0) < MAX_TRIES then
        self.queued[questID] = true
        self.queue[#self.queue + 1] = questID
        return false
    end
    giveUp(self, questID)
    return false
end

--- One round: answers that never came are settled, then a few more quests
--- are asked for. Stops by itself when nothing is left.
function History:Pump()
    local now = GetTime()
    local inFlight = 0
    local late
    for questID, askedAt in pairs(self.pending) do
        if now - askedAt >= ANSWER_TIMEOUT then
            late = late or {}
            late[#late + 1] = questID
        else
            inFlight = inFlight + 1
        end
    end
    for _, questID in ipairs(late or {}) do self:Settle(questID, nil) end

    local queue, sent = self.queue, 0
    while sent < BATCH and inFlight < MAX_IN_FLIGHT and self.head <= #queue do
        local questID = queue[self.head]
        self.head = self.head + 1 -- the entry stays (no holes in the array) until the queue is drained
        self.queued[questID] = nil
        local title = Compat.GetQuestTitle(questID)
        if title then
            named(self, questID, title) -- loaded in the meantime
        elseif Compat.LoadQuest(questID) then
            self.tries[questID] = (self.tries[questID] or 0) + 1
            self.pending[questID] = now
            inFlight = inFlight + 1
            sent = sent + 1
        else
            giveUp(self, questID)
        end
    end
    if self.head > #queue then
        self.queue, self.head = {}, 1
        if next(self.pending) == nil then self:Finish() end
    end
end

function History:StartPump()
    if self.ticker or self.head > #self.queue then return end
    self.run = self.run or { named = 0, failed = 0, asked = 0 }
    if not Compat.CanLoadQuests() then
        -- this client cannot be asked: what it has not loaded stays unnamed for now
        for i = self.head, #self.queue do
            local questID = self.queue[i]
            self.queued[questID] = nil
            giveUp(self, questID)
        end
        self.queue, self.head = {}, 1
        self:Finish()
        return
    end
    self.ticker = C_Timer.NewTicker(TICK, function() FC:SafeCall("QuestHistory:Pump", self.Pump, self) end)
end

--- Every quest in the queue was answered or let go.
function History:Finish()
    if self.ticker then
        self.ticker:Cancel()
        self.ticker = nil
    end
    local run = self.run
    self.run = nil
    if not run then return end
    FC.Log:Debug("Quest names: %d asked for, %d named, %d the game has no title for", run.asked, run.named, run.failed)
    if run.manual then
        -- for the character the report was about (the queue names every character's quests)
        local known, _, unnamed = self:NameCounts()
        FC:Print(L.MSG_RESCAN_NAMES, math.max(0, known - (run.knownBefore or known)), unnamed)
    end
    changed(self)
end

--- How the quests of some of your characters stand ({ [key] = true }; the
--- one you play by default): how many have a name, how many are being
--- asked for, how many the game has no name for.
function History:NameCounts(keys)
    local Lore = FC.QuestLore
    local known, asked, unnamed = 0, 0, 0
    for questID in pairs((self:Completed(keys))) do
        if Lore:KnownTitle(questID) then
            known = known + 1
        elseif self:IsPending(questID) then
            asked = asked + 1
        else
            unnamed = unnamed + 1
        end
    end
    return known, asked, unnamed
end

--- Looks at every quest your characters completed and asks the client for
--- the ones nobody can name (force: also the ones it could not name
--- earlier). Returns how many have a name, how many are being asked for
--- and how many stay unnamed for now.
function History:Resolve(force)
    local Lore = FC.QuestLore
    local english = FC.Locale.client == "enUS"
    local known, asked, parked, queued = 0, 0, 0, 0
    for questID in pairs((self:AllCompleted())) do
        local title, source = Lore:KnownTitle(questID)
        if title then
            known = known + 1
            if source == "reference" and not english then
                -- the client's title is in the player's language: asked for like a
                -- quest without a name, a day apart when the game has none
                if self:Enqueue(questID, force) then queued = queued + 1 end
            else
                self.data.unnamed[questID] = nil
                if source == "client" then Lore:RememberTitle(questID, title) end
            end
        elseif self:IsPending(questID) then
            asked = asked + 1
        elseif self:Enqueue(questID, force) then
            asked, queued = asked + 1, queued + 1
        else
            parked = parked + 1
        end
    end
    if self.head <= #self.queue then
        self:StartPump()
        if self.run then self.run.asked = self.run.asked + queued end
    end
    FC.Log:Debug("Completed quests: %d named, %d waiting for the game, %d without a name for now", known, asked, parked)
    return known, asked, parked
end

--- Calls callback(title) once a quest has a name: at once when it has one,
--- otherwise when the client names it (never, if the game has no title).
function History:WhenTitled(questID, callback)
    local title = FC.QuestLore:KnownTitle(questID)
    if title then
        callback(title)
        return true
    end
    if not vID(questID) then return false end
    local waiting = self.waiters[questID] or {}
    self.waiters[questID] = waiting
    waiting[#waiting + 1] = callback
    self:Enqueue(questID, true)
    self:StartPump()
    return false
end

------------------------------------------------------------------------
-- The list
------------------------------------------------------------------------

-- quest -> the NPC seen offering it (the quest knowledge of your characters and guild)
local function learnedGivers(self)
    if self.givers then return self.givers end
    local index = {}
    for npcID, npc in pairs(FC.QuestLore.data.npcs) do
        for questID in pairs(npc.g or {}) do
            -- two NPCs can offer one quest: the lower ID, so the answer never changes
            if not index[questID] or npcID < index[questID] then index[questID] = npcID end
        end
    end
    self.givers = index
    return index
end

--- Everything known about one completed quest:
--- { questID, title (nil while unknown), pending, level, mapID, zone,
---   start ("npc" | "object" | "item": what gives it, when anyone knows),
---   giverID (the NPC) or objectID, giver (its name, as far as known),
---   itemID (an item that starts it, too or instead),
---   sm, sx, sy (where it starts), rec (the journal's entry),
---   at (turned in, when known) }.
--- Names are the ones known right now: the game is not asked here (a list
--- has thousands of rows); the page asks for the rows it draws.
function History:Describe(questID)
    local Ref, Lore, store = FC.Reference, FC.QuestLore, FC.Store
    local row = { questID = questID }
    row.title = Lore:KnownTitle(questID)
    row.pending = row.title == nil and self:IsPending(questID) or nil
    local _, level = Ref:QuestTitle(questID)
    local q = Ref.quests[questID]
    row.level = level or (q and q.l) or nil
    row.mapID, row.zone = Ref:QuestZone(questID)
    local start = Ref:QuestStart(questID)
    if start then
        row.start, row.giver = start.kind, start.name
        row.sm, row.sx, row.sy = start.m, start.x, start.y
        row.itemID = start.item
        if start.kind == "npc" then
            row.giverID = start.id
        elseif start.kind == "object" then
            row.objectID = start.id
        end
    else
        -- what your characters and your guild saw in play
        local npcID = learnedGivers(self)[questID]
        local npc = npcID and Lore:GetNpc(npcID)
        if npc then
            row.start, row.giverID, row.giver = "npc", npcID, npc.n
            if npc.m and npc.x then row.sm, row.sx, row.sy = npc.m, npc.x, npc.y end
            if not row.mapID then row.mapID, row.zone = npc.m, npc.z or (npc.m and Compat.GetMapName(npc.m)) end
        end
    end
    local rec = store:Get("quest:" .. questID)
    if rec and rec.t == "quest" and store:IsKnown(rec) and not store:IsRumored(rec) then
        row.rec = rec
        row.title = row.title or rec.n
        -- accepted while the journal watched: it saw who gave the quest, and where
        if not row.start and (rec.gv or rec.gvi) then
            row.start = "npc"
            if rec.m and rec.x then row.sm, row.sx, row.sy = rec.m, rec.x, rec.y end
        end
        if row.start == "npc" then
            row.giver = row.giver or rec.gv
            row.giverID = row.giverID or rec.gvi
        end
        if not row.zone then row.mapID, row.zone = rec.m, rec.z or (rec.m and Compat.GetMapName(rec.m)) end
    end
    return row
end

--- The completed quests of some of your characters ({ [key] = true }; the
--- one you play by default) as rows (see Describe; `by` counts how many of
--- them did the quest), and what the list holds:
--- { total, named, unnamed, pending, journal, dated }.
function History:List(keys)
    keys = keys or { [FC.Store.me] = true }
    local chars = FC.db.characters or {}
    local rows, byQuest = {}, {}
    for key in pairs(keys) do
        local char = chars[key]
        if char then
            for questID in pairs(char.q or {}) do
                local row = byQuest[questID]
                if not row then
                    row = self:Describe(questID)
                    row.by = 0
                    byQuest[questID] = row
                    rows[#rows + 1] = row
                end
                row.by = row.by + 1
                local at = char.qd and char.qd[questID]
                if at and (not row.at or at < row.at) then row.at = at end
            end
        end
    end
    local counts = { total = #rows, named = 0, unnamed = 0, pending = 0, journal = 0, dated = 0 }
    for _, row in ipairs(rows) do
        if row.title then counts.named = counts.named + 1 else counts.unnamed = counts.unnamed + 1 end
        if row.pending then counts.pending = counts.pending + 1 end
        if row.rec then counts.journal = counts.journal + 1 end
        if row.at then counts.dated = counts.dated + 1 end
    end
    return rows, counts
end

--- How many quests the character you play completed that the journal did
--- not watch: no entry of their own and no date.
function History:Unwatched()
    local char = FC.Characters:Me()
    local store = FC.Store
    local count = 0
    for questID in pairs(char.q) do
        if not char.qd[questID] and not store:Get("quest:" .. questID) then count = count + 1 end
    end
    return count
end

------------------------------------------------------------------------
-- Repair: the journal follows what the game says is completed
------------------------------------------------------------------------

-- "Chain: #819" -> "Chain: The Glowing Shard", once the first quest has a name.
local function nameChain(store, rec, root, title)
    local placeholder = "#" .. root
    local changes = { n = string.format(L.AUTO_CHAIN_TITLE, title) }
    if type(rec.d) == "string" then
        local at = rec.d:find(placeholder, 1, true)
        if at then changes.d = rec.d:sub(1, at - 1) .. title .. rec.d:sub(at + #placeholder) end
    end
    return store:Update(rec.id, changes, "repair", true)
end

--- Brings the journal in line with the completed quests: quests turned in
--- while the addon was away are marked done, chains filed without a name
--- get it, and two entries of yours for one quest become one. Returns
--- { records, marked, chains, duplicates }.
function History:SyncJournal()
    local store = FC.Store
    local done = self:AllCompleted()
    local result = { records = 0, marked = 0, chains = 0, duplicates = 0 }
    local byQuest, chains = {}, {}
    for id, rec in store:Iterate() do
        if rec.t == "quest" and rec.q then
            result.records = result.records + 1
            if store:IsMine(rec) then
                byQuest[rec.q] = byQuest[rec.q] or {}
                table.insert(byQuest[rec.q], id)
            end
            if done[rec.q] then
                local state = store:GetState(id)
                if not (state and state.done) then
                    store:EnsureState(id).done = true
                    result.marked = result.marked + 1
                end
            end
        elseif rec.t == "questchain" and store:IsMine(rec) then
            local root = tonumber(id:match("^chain:(%d+)$"))
            if root and rec.n == string.format(L.AUTO_CHAIN_TITLE, "#" .. root) then chains[#chains + 1] = { rec = rec, root = root } end
        end
    end
    for _, chain in ipairs(chains) do
        local id, root = chain.rec.id, chain.root
        local fix = function(title)
            local rec = store:Get(id)
            if rec and rec.n == string.format(L.AUTO_CHAIN_TITLE, "#" .. root) then return nameChain(store, rec, root, title) end
            return false
        end
        local title = FC.QuestLore:KnownTitle(root)
        if title then
            if fix(title) then result.chains = result.chains + 1 end
        else
            self:WhenTitled(root, fix)
        end
    end
    -- one quest, one entry: the one filed under the quest's own ID stays
    for questID, ids in pairs(byQuest) do
        if #ids > 1 then
            local keep = "quest:" .. questID
            if not store:Get(keep) then
                table.sort(ids, function(a, b)
                    local ca, cb = store:Get(a).c or 0, store:Get(b).c or 0
                    if ca ~= cb then return ca < cb end
                    return a < b
                end)
                keep = ids[1]
            end
            for _, id in ipairs(ids) do
                if id ~= keep and FC.WorldDiscovery:IsUntouched(store:Get(id)) and store:MergeInto(id, keep) then
                    result.duplicates = result.duplicates + 1
                end
            end
        end
    end
    if result.marked > 0 then
        store:MarkDirty()
        FC.Bus:Emit("STORE_RESET")
    end
    return result
end

--- The whole pass: the completed quests are read again, the journal follows
--- and the names are asked for. manual (/fc rescan) also asks again for the
--- quests the game could not name, and prints what was found. Returns the
--- report { state, detected, added, records, known, asked, unnamed, marked,
--- chains, duplicates }.
function History:Repair(manual)
    local chars = FC.Characters
    local state, added = chars:ScanQuests()
    local sync = self:SyncJournal()
    self:Resolve(manual)
    -- the report is about the character you play; the queue names every character's quests
    local known, asked, parked = self:NameCounts()
    local _, detected = self:Completed()
    if self.data.repair < self.REPAIR_VERSION then
        FC.Log:Info("Quest history repaired after the update (repair %d)", self.REPAIR_VERSION)
        self.data.repair = self.REPAIR_VERSION
    end
    local report = {
        state = state, detected = detected, added = added or 0, records = sync.records,
        known = known, asked = asked, unnamed = parked,
        marked = sync.marked, chains = sync.chains, duplicates = sync.duplicates,
    }
    FC.Log:Debug("Quest repair: %d completed (%d new), %d journal quests, %d marked done, %d chains named, %d duplicates removed",
        report.detected, report.added, report.records, report.marked, report.chains, report.duplicates)
    if manual then
        if self.run then self.run.manual, self.run.knownBefore = true, known end
        self:PrintReport(report)
    end
    changed(self)
    return report
end

function History:PrintReport(report)
    local function line(text, ...)
        DEFAULT_CHAT_FRAME:AddMessage("  " .. string.format(text, ...))
    end
    FC:Print(L.RESCAN_HEADER)
    if report.state ~= "ok" then line(report.state == "unavailable" and L.RESCAN_UNAVAILABLE or L.RESCAN_NOT_YET) end
    line(L.RESCAN_DETECTED, report.detected, report.added)
    line(L.RESCAN_RECORDS, report.records)
    line(L.RESCAN_NAMES, report.known, report.asked)
    line(L.RESCAN_UNRESOLVED, report.unnamed)
    line(L.RESCAN_FIXED, report.duplicates, report.chains, report.marked)
end

--- /fc rescan: the completed quests and the explored areas, read again from
--- what the game remembers. Nothing in the journal is deleted.
function History:Rescan()
    local report = self:Repair(true)
    if FC.WorldDiscovery.RecoverExplored then FC.WorldDiscovery:RecoverExplored(true) end
    return report
end

--- After the completed quests were read at login.
function History:AfterScan()
    self:SyncJournal()
    self:Resolve(false)
    if self.data.repair < self.REPAIR_VERSION then
        FC.Log:Info("Quest history repaired after the update (repair %d)", self.REPAIR_VERSION)
        self.data.repair = self.REPAIR_VERSION
    end
    -- told once per character: where the quests done without the journal are
    local unwatched = self:Unwatched()
    if unwatched > 0 and not FC.cdb.questNotice then
        FC.cdb.questNotice = true
        local _, total = self:Completed()
        FC:Print(L.MSG_QUESTS_RECOVERED, total, unwatched)
    end
    changed(self)
end

--- What a developer or a bug report needs (/fc debug quests): the state of
--- the scan and of the queue, and the quests that have no name.
function History:Diagnose()
    local scan = FC.Characters:ScanState()
    local _, mine = self:Completed()
    local _, all = self:AllCompleted()
    local out = {}
    local function add(text, ...) out[#out + 1] = string.format(text, ...) end
    add("scan: %s, %d attempts, the client listed %s, %d new this session", tostring(scan.state), scan.tries or 0, tostring(scan.listed or "-"), scan.added or 0)
    add("completed: %d this character, %d all characters; repair version %d of %d", mine, all, self.data.repair, self.REPAIR_VERSION)
    local event = "?"
    if C_EventUtils and C_EventUtils.IsEventValid then
        local ok, valid = pcall(C_EventUtils.IsEventValid, "QUEST_DATA_LOAD_RESULT")
        event = ok and tostring(valid) or "?"
    end
    add("client: load requests %s, QUEST_DATA_LOAD_RESULT valid %s", tostring(Compat.CanLoadQuests()), event)
    local function ids(set, limit)
        local list = U.SortedKeys(set)
        table.sort(list)
        local shown = {}
        for i = 1, math.min(#list, limit) do shown[i] = tostring(list[i]) end
        return #list, table.concat(shown, " ") .. (#list > limit and " ..." or "")
    end
    local waiting = {}
    for i = self.head, #self.queue do waiting[self.queue[i]] = true end
    for _, entry in ipairs({ { "queued", waiting }, { "asked, no answer yet", self.pending }, { "no title this session", self.failed }, { "no title from the game", self.data.unnamed } }) do
        local n, text = ids(entry[2], 40)
        add("%s: %d%s", entry[1], n, n > 0 and (" (" .. text .. ")") or "")
    end
    return out
end

function History:OnEnable()
    FC.Events:Register("QUEST_DATA_LOAD_RESULT", self, function(_, _, questID, success)
        questID, success = Compat.Safe(questID), Compat.Safe(success)
        if not vID(questID) then return end
        if self.pending[questID] then
            self:Settle(questID, success and true or false)
        elseif success and self:IsUnnamed(questID) then
            -- named at last, by a request someone else made (a tooltip)
            local title = Compat.GetQuestTitle(questID)
            if title then named(self, questID, title) end
        end
    end)
    FC.Bus:On("QUESTS_SCANNED", self, function() FC:SafeCall("QuestHistory:AfterScan", self.AfterScan, self) end)
    FC.Bus:On("QUESTS_COMPLETED_CHANGED", self, function(_, _, source, questID)
        if source == "turnin" and questID then
            local title, from = FC.QuestLore:KnownTitle(questID)
            if title and from == "client" then FC.QuestLore:RememberTitle(questID, title) end
            if not title then
                self:Enqueue(questID, true)
                self:StartPump()
            end
        end
        changed(self)
    end)
    FC.Bus:On("QUEST_LORE_CHANGED", self, function() self.givers = nil end)
end
