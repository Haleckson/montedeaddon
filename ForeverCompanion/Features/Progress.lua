--[[
  Forever Companion - Features/Progress.lua
  How progress counts when you play more than one character, and what each
  of your characters found.

    account-wide    your characters share one progress: a discovery any of
                    them made is not announced again when another one comes
                    across it, but it still counts for that character
    per character   every character has its own progress and gets the
                    toasts as if everything were new to it

  Everyone chooses once: new players in the welcome guide, players who had
  the addon before in a question at login; the Progress page and
  Settings > General change it.
  The Progress page shows the whole account and any of your characters,
  alone or together, whatever the choice.
]]

local _, FC = ...

local Progress = FC:NewModule("Progress")

local U = FC.Utils

Progress.MODES = { "account", "character" }

--- "account" or "character" ("account" until the player chose).
function Progress:Mode()
    return FC.db.progressMode or "account"
end

function Progress:IsChosen()
    return FC.db.progressMode ~= nil
end

function Progress:SetMode(mode)
    if mode ~= "account" and mode ~= "character" then return false end
    local changed = FC.db.progressMode ~= mode
    FC.db.progressMode = mode
    if changed then
        FC.Store:MarkDirty()
        FC.Bus:Emit("PROGRESS_MODE_CHANGED", mode)
        -- what is "yours" changed everywhere: journal, map, zone guide
        FC.Bus:Emit("STORE_RESET")
    end
    return true
end

--- Every character of yours the addon has seen: { key, name, class, level,
--- seen (last login), current, tracked }. tracked is false for a character
--- that has not logged in since its finds are counted account-wide; until
--- then only what it recorded first counts for it. The character you play
--- comes first, then by last login.
function Progress:Characters()
    local chars = FC.db.characters or {}
    local keys = {}
    for key in pairs(FC.db.myChars) do keys[key] = true end
    for key in pairs(chars) do keys[key] = true end
    for key in pairs(FC.db.found) do keys[key] = true end
    local me = FC.Store.me
    local list = {}
    for key in pairs(keys) do
        local char = chars[key] or {}
        list[#list + 1] = {
            key = key,
            name = U.ShortName(key),
            class = char.c,
            level = char.l,
            seen = char.s or 0,
            current = key == me,
            tracked = FC.db.found[key] ~= nil,
        }
    end
    table.sort(list, function(a, b)
        if a.current ~= b.current then return a.current end
        if a.seen ~= b.seen then return a.seen > b.seen end
        return a.name < b.name
    end)
    return list
end

--- All of your characters, { [key] = true }.
function Progress:AllKeys()
    local set = {}
    for _, char in ipairs(self:Characters()) do set[char.key] = true end
    return set
end

--- The characters whose finds are "yours" in the current mode: the one you
--- play, or all of them.
function Progress:Scope()
    if FC.Store:PerCharacter() then return { [FC.Store.me] = true } end
    return self:AllKeys()
end

--- Whether one of these characters ({ [key] = true }) found a discovery.
function Progress:FoundByAny(rec, keys)
    if keys[rec.a] then return true end
    local store = FC.Store
    for key in pairs(keys) do
        if store:FoundAt(rec.id, key) then return true end
    end
    return false
end

--- How many discoveries each of your characters found, and the whole
--- account together (every discovery once, hidden ones left out):
--- { total = n, byChar = { [key] = n } }. Kept until the journal changes.
function Progress:FoundCounts()
    local store = FC.Store
    if self.counts and self.countsVersion == store.version then return self.counts end
    local chars = self:AllKeys()
    local byChar, union = {}, {}
    local function visible(rec)
        local state = store:GetState(rec.id)
        return not (state and state.hidden)
    end
    for _, rec in store:Iterate() do
        if chars[rec.a] and visible(rec) then
            byChar[rec.a] = (byChar[rec.a] or 0) + 1
            union[rec.id] = true
        end
    end
    for key in pairs(chars) do
        for id in pairs(FC.db.found[key] or {}) do
            local rec = store:Get(id)
            if rec and visible(rec) then
                if rec.a ~= key then byChar[key] = (byChar[key] or 0) + 1 end
                union[id] = true
            end
        end
    end
    self.counts = { total = U.Count(union), byChar = byChar }
    self.countsVersion = store.version
    return self.counts
end

--- Progress of some of your characters together ({ [key] = true }, nil for
--- all): what they found (every discovery once, hidden ones left out) by
--- type and zone, the quests they completed, the rares and world bosses they
--- defeated, the flight paths they know, and optionally the milestone counters.
function Progress:Compute(keys, withMilestones)
    keys = keys or self:AllKeys()
    local store = FC.Store
    local result = { found = 0, byType = {}, zones = 0, quests = 0, rares = 0, flights = 0 }
    local seen, zones = {}, {}
    local function add(rec)
        if seen[rec.id] then return end
        seen[rec.id] = true
        local state = store:GetState(rec.id)
        if state and state.hidden then return end
        result.found = result.found + 1
        result.byType[rec.t] = (result.byType[rec.t] or 0) + 1
        local zone = rec.z or (rec.m and tostring(rec.m))
        if zone and not zones[zone] then
            zones[zone] = true
            result.zones = result.zones + 1
        end
    end
    for _, rec in store:Iterate() do
        if keys[rec.a] then add(rec) end
    end
    for key in pairs(keys) do
        for id in pairs(FC.db.found[key] or {}) do
            local rec = store:Get(id)
            if rec then add(rec) end
        end
    end
    local quests, rares, flights = {}, {}, {}
    local chars = FC.db.characters or {}
    for key in pairs(keys) do
        local char = chars[key]
        if char then
            for id in pairs(char.q or {}) do quests[id] = true end
            for id in pairs(char.rk or {}) do rares[id] = true end
            for id in pairs(char.fp or {}) do flights[id] = true end
        end
    end
    result.quests, result.rares, result.flights = U.Count(quests), U.Count(rares), U.Count(flights)
    if withMilestones then result.milestones = FC.Milestones:Progress(keys) end
    return result
end
