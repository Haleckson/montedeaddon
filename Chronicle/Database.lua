local C = _G.Chronicle
local U = C.Util
local DB_VERSION = 8

local accountDefaults = {
    version = DB_VERSION, characters = {}, characterData = {},
    settings = { maxEvents = 750, maxLoot = 400, maxQuests = 500, maxEconomy = 500,
        showWelcome = true, windowWidth = 960, windowHeight = 650, language = "auto",
        minimapX = -.7071, minimapY = -.7071 },
}
local characterDefaults = {
    version = DB_VERSION, created = 0, lastLogin = 0, lastLogout = 0, lastSessionEnd = 0,
    ownerGUID = "", ownerName = "", ownerRealm = "", lastZone = "", lastSubZone = "", lastInstance = "", money = 0,
    events = {}, goals = {}, quests = {}, activeQuests = {}, zones = {}, npcs = {}, dungeons = {}, bosses = {},
    loot = {}, rares = {}, professions = {}, recipes = {}, inventory = {}, bank = {}, economy = {}, deaths = {}, notes = {}, noteTombstones = {}, stats = {},
    gathering = { ore = {}, herbs = {}, skinning = {}, oreNodes = 0, herbNodes = 0,
        skinNodes = 0 }, training = { services = {} },
}
local listFields = { "events", "goals", "quests", "loot", "economy", "deaths", "notes" }
local mapFields = { "zones", "npcs", "merchants", "dungeons", "bosses", "rares", "professions", "recipes", "inventory", "bank", "gathering", "training" }

local function noteKey(note)
    return tostring(note.id or note.created or 0) .. "\031" .. tostring(note.text or "")
end

local function mergeNotes(target, source, tombstones)
    if type(source) ~= "table" then return end
    local seen = {}
    for _, note in ipairs(target) do if type(note) == "table" then seen[noteKey(note)] = true end end
    for _, note in ipairs(source) do
        if type(note) == "table" and type(note.text) == "string" and not seen[noteKey(note)] and not tombstones[noteKey(note)] then
            target[#target + 1] = note
            seen[noteKey(note)] = true
        end
    end
    table.sort(target, function(a, b) return (a.created or 0) > (b.created or 0) end)
    while #target > 250 do table.remove(target) end
end

local function applyNoteTombstones(notes, tombstones)
    for i = #notes, 1, -1 do
        if type(notes[i]) == "table" and tombstones[noteKey(notes[i])] then table.remove(notes, i) end
    end
end

local function mergeDeaths(target, source)
    if type(source) ~= "table" then return end
    local seen = {}
    for _, row in ipairs(target) do
        if type(row) == "table" and type(row.time) == "number" then seen[row.time] = true end
    end
    for _, row in ipairs(source) do
        if type(row) == "table" and type(row.time) == "number" and not seen[row.time] then
            target[#target + 1] = row
            seen[row.time] = true
        end
    end
    table.sort(target, function(a, b) return (a.time or 0) > (b.time or 0) end)
    while #target > 250 do table.remove(target) end
end

local function dataScore(data)
    if type(data) ~= "table" then return -1 end
    local score = 0
    for _, field in ipairs(listFields) do score = score + #(type(data[field]) == "table" and data[field] or {}) * 10 end
    for _, field in ipairs(mapFields) do score = score + U.Count(type(data[field]) == "table" and data[field] or {}) end
    if data.created and data.created > 0 then score = score + 1 end
    return score
end

function C:GetIdentity()
    local name = UnitName and UnitName("player")
    local realm = GetRealmName and GetRealmName()
    local guid = UnitGUID and UnitGUID("player")
    if not name or name == "" or not realm or realm == "" then return nil end
    return { name = name, realm = realm, guid = guid, legacyKey = name .. "-" .. realm, key = guid or (name .. "-" .. realm) }
end

function C:CharacterKey()
    local identity = self:GetIdentity()
    return identity and identity.key or "unbound"
end

function C:InitializeAccountDatabase()
    ChronicleDB = U.CopyDefaults(type(ChronicleDB) == "table" and ChronicleDB or {}, accountDefaults)
    ChronicleNotesDB = type(ChronicleNotesDB) == "table" and ChronicleNotesDB or {}
    ChronicleDB.version = DB_VERSION
    self.db = ChronicleDB
    return ChronicleDB
end

function C:BindCharacterDatabase()
    local db = self:InitializeAccountDatabase()
    local identity = self:GetIdentity()
    if not identity then return false end
    local normalizedName, normalizedRealm = identity.name:lower(), identity.realm:lower()
    local function belongsToCurrent(data, storedKey)
        if type(data) ~= "table" then return false end
        local ownerName = tostring(data.ownerName or ""):lower()
        local ownerRealm = tostring(data.ownerRealm or ""):lower()
        -- Realm display names can change without changing the character GUID.
        -- Match the stable GUID before comparing localized realm names.
        if identity.guid and data.ownerGUID == identity.guid then return true end
        if ownerName ~= "" and ownerName ~= normalizedName then return false end
        if ownerRealm ~= "" and ownerRealm ~= normalizedRealm then return false end
        if ownerName == normalizedName and ownerRealm == normalizedRealm then return true end
        if storedKey == identity.key or storedKey == identity.legacyKey then return true end
        local lowerKey = tostring(storedKey or ""):lower()
        return lowerKey:find(normalizedName, 1, true) ~= nil and lowerKey:find(normalizedRealm, 1, true) ~= nil
    end
    local candidates, candidateKeys = {}, {}
    local function consider(data, sourceKey)
        if not belongsToCurrent(data, sourceKey) or candidates[data] then return end
        candidates[data], candidateKeys[data] = dataScore(data), sourceKey
    end
    consider(db.characterData[identity.key], identity.key)
    consider(db.characterData[identity.legacyKey], identity.legacyKey)
    consider(ChronicleCharDB, nil)

    local storedCount = 0
    for storedKey, storedData in pairs(db.characterData) do
        if type(storedData) == "table" then
            storedCount = storedCount + 1
            consider(storedData, storedKey)
        end
    end
    if storedCount == 0 and type(ChronicleCharDB) == "table" and
        not ChronicleCharDB.ownerName and not ChronicleCharDB.ownerGUID then
        candidates[ChronicleCharDB] = dataScore(ChronicleCharDB)
    end

    local character, bestScore, sourceKey = nil, -1, nil
    for data, score in pairs(candidates) do
        if score > bestScore then character, bestScore, sourceKey = data, score, candidateKeys[data] end
    end
    character = U.CopyDefaults(character or {}, characterDefaults)
    -- Older versions stored merchants twice. Preserve any merchant-only history
    -- in the NPC journal before dropping the redundant map.
    for name, merchant in pairs(type(character.merchants) == "table" and character.merchants or {}) do
        if type(name) == "string" and type(merchant) == "table" then
            local npc = type(character.npcs[name]) == "table" and character.npcs[name] or {}
            npc.merchant = true
            npc.zone = npc.zone or merchant.zone
            npc.npcID = npc.npcID or merchant.npcID
            npc.firstSeen = npc.firstSeen or merchant.lastSeen
            local lastSeen = math.max(tonumber(npc.lastSeen) or 0, tonumber(merchant.lastSeen) or 0)
            if lastSeen > 0 then npc.lastSeen = lastSeen end
            character.npcs[name] = npc
        end
    end
    character.merchants = nil
    if type(character.deaths) == "number" then character.stats.deathCount, character.deaths = character.deaths, {} end
    for data in pairs(candidates) do
        if data ~= character then mergeDeaths(character.deaths, data.deaths) end
    end
    if type(ChronicleDeathRecovery) == "table" then
        mergeDeaths(character.deaths, ChronicleDeathRecovery[identity.key])
        mergeDeaths(character.deaths, ChronicleDeathRecovery[identity.legacyKey])
    end
    for data in pairs(candidates) do
        if type(data.noteTombstones) == "table" then
            for key, deleted in pairs(data.noteTombstones) do
                if deleted then character.noteTombstones[key] = true end
            end
        end
    end
    applyNoteTombstones(character.notes, character.noteTombstones)
    for data in pairs(candidates) do
        if data ~= character then mergeNotes(character.notes, data.notes, character.noteTombstones) end
    end
    local notesStore = type(ChronicleNotesDB[identity.key]) == "table" and ChronicleNotesDB[identity.key] or nil
    local legacyStore = type(ChronicleNotesDB[identity.legacyKey]) == "table" and ChronicleNotesDB[identity.legacyKey] or nil
    mergeNotes(character.notes, notesStore, character.noteTombstones)
    mergeNotes(character.notes, legacyStore, character.noteTombstones)
    ChronicleNotesDB[identity.key] = character.notes
    if identity.legacyKey ~= identity.key then ChronicleNotesDB[identity.legacyKey] = nil end
    character.stats.deathCount = math.max(tonumber(character.stats.deathCount) or 0, #character.deaths)
    character.version, character.ownerGUID = DB_VERSION, identity.guid or character.ownerGUID
    character.ownerName, character.ownerRealm = identity.name, identity.realm
    if character.created == 0 then character.created = time() end

    db.characterData[identity.key] = character
    if sourceKey and sourceKey ~= identity.key and db.characterData[sourceKey] == character then db.characterData[sourceKey] = nil end
    ChronicleCharDB = character
    self.char, self.characterKey, self.identity = character, identity.key, identity
    return true
end

function C:InitializeDatabase()
    self:InitializeAccountDatabase()
    return self:BindCharacterDatabase()
end

function C:UpdateCharacterSummary()
    if not self.db or not self.char or not self.identity then return end
    local key, summary = self.characterKey, self.db.characters[self.characterKey] or {}
    local localizedClass, classFile = UnitClass("player")
    local localizedRace, raceFile
    if UnitRace then localizedRace, raceFile = UnitRace("player") end
    summary.name, summary.realm, summary.guid = self.identity.name, self.identity.realm, self.identity.guid
    summary.class, summary.className = classFile or localizedClass, localizedClass
    summary.race, summary.raceName = raceFile or localizedRace, localizedRace
    summary.level, summary.faction = UnitLevel("player") or 0, UnitFactionGroup and UnitFactionGroup("player") or ""
    summary.zone, summary.money, summary.lastSeen = GetZoneText and GetZoneText() or self.char.lastZone, GetMoney and GetMoney() or self.char.money, time()
    summary.deaths = self.char.stats.deathCount or #self.char.deaths
    if GetGuildInfo then
        local ok, guildName, guildRank = pcall(GetGuildInfo, "player")
        if ok and type(guildName) == "string" and guildName ~= "" then
            summary.guild, summary.guildRank = guildName, guildRank
        end
    end
    for otherKey, other in pairs(self.db.characters) do
        if otherKey ~= key and type(other) == "table" then
            local sameGUID = self.identity.guid and other.guid == self.identity.guid
            local sameName = other.name == self.identity.name and other.realm == self.identity.realm
            if sameGUID or sameName then self.db.characters[otherKey] = nil end
        end
    end
    self.db.characters[key] = summary
end

function C:RefreshTalentSnapshot()
    if not self.char or not self.characterKey or not self.API.TalentSnapshot then return end
    local ok, snapshot = pcall(self.API.TalentSnapshot)
    if not ok or type(snapshot) ~= "table" then return end
    local summary = self.db.characters[self.characterKey]
    if not summary then self:UpdateCharacterSummary(); summary = self.db.characters[self.characterKey] end
    if summary then
        snapshot.updated = time()
        summary.talents = snapshot
        self:Fire("DATA_CHANGED", "talents")
    end
end

function C:AddEvent(kind, text, details)
    if not self.char then return end
    local entry = { time = time(), kind = kind or "event", text = U.SafeText(text, "Ereignis"), details = details }
    U.PushLimited(self.char.events, entry, self.db.settings.maxEvents or 750); self:Fire("DATA_CHANGED", kind); return entry
end
function C:AddGoal(text)
    self:BindCharacterDatabase()
    text = U.Trim(text); if text == "" or not self.char then return end
    U.PushLimited(self.char.goals, { text = text, done = false, created = time(), updated = time() }, 100); self:AddEvent("goal", "Neues Ziel: " .. text)
end
function C:ToggleGoal(index)
    local goal = self.char and self.char.goals[index]; if not goal then return end
    goal.done, goal.updated = not goal.done, time(); self:AddEvent("goal", (goal.done and "Ziel erreicht: " or "Ziel reaktiviert: ") .. goal.text)
end
function C:DeleteGoal(index) if self.char and self.char.goals[index] then table.remove(self.char.goals, index); self:Fire("DATA_CHANGED") end end
function C:AddNote(text, category)
    self:BindCharacterDatabase()
    text = U.Trim(text); if text == "" or not self.char then return false end
    self.char.stats.nextNoteID = (self.char.stats.nextNoteID or 0) + 1
    U.PushLimited(self.char.notes, { id = "note-" .. tostring(self.char.stats.nextNoteID), text = text, category = category or "Allgemein", created = time(), updated = time() }, 250)
    ChronicleNotesDB[self.characterKey] = self.char.notes
    self:AddEvent("note", "Notiz erstellt: " .. text); return true
end
function C:UpdateNote(note, text)
    if not self:BindCharacterDatabase() then return false end
    text = U.Trim(text)
    if text == "" then return false end
    for _, existing in ipairs(self.char.notes) do
        if existing == note then
            if existing.text ~= text then
                self.char.noteTombstones[noteKey(existing)] = true
                existing.text, existing.updated = text, time()
            end
            ChronicleNotesDB[self.characterKey] = self.char.notes
            self:Fire("DATA_CHANGED")
            return true
        end
    end
    return false
end
function C:DeleteNote(note)
    if not self:BindCharacterDatabase() then return false end
    for index, existing in ipairs(self.char.notes) do
        if existing == note then
            self.char.noteTombstones[noteKey(existing)] = true
            table.remove(self.char.notes, index)
            ChronicleNotesDB[self.characterKey] = self.char.notes
            self:Fire("DATA_CHANGED")
            return true
        end
    end
    return false
end
