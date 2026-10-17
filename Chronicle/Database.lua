local C = _G.Chronicle
local U = C.Util
local DB_VERSION = 9
local requestedEquipmentItems = {}

local accountDefaults = {
    version = DB_VERSION, characters = {}, characterData = {}, companions = {},
    settings = { maxEvents = 750, maxLoot = 400, maxQuests = 500, maxEconomy = 500,
        showWelcome = true, windowWidth = 960, windowHeight = 650, language = "auto",
        minimapX = -.7071, minimapY = -.7071,
        hiddenPages = {}, showMinimapButton = true, showSuspiciousMoney = false,
        classHideCompleted = false, rareShowCoordinates = true,
        rareShowLoot = true, rareLevelRange = 5 },
}
local characterDefaults = {
    version = DB_VERSION, created = 0, lastLogin = 0, lastLogout = 0, lastSessionEnd = 0,
    ownerGUID = "", ownerName = "", ownerRealm = "", lastZone = "", lastSubZone = "", lastInstance = "", money = 0,
    events = {}, goals = {}, quests = {}, activeQuests = {}, zones = {}, npcs = {}, dungeons = {}, bosses = {},
    loot = {}, rares = {}, rareDeaths = {}, professions = {}, recipes = {}, inventory = {}, bank = {}, economy = {}, deaths = {}, notes = {}, noteTombstones = {}, stats = {},
    gathering = { ore = {}, herbs = {}, skinning = {}, oreNodes = 0, herbNodes = 0,
        skinNodes = 0 }, training = { services = {} },
}
local listFields = { "events", "goals", "quests", "loot", "economy", "deaths", "notes" }
local mapFields = { "zones", "npcs", "merchants", "dungeons", "bosses", "rares", "rareDeaths", "professions", "recipes", "inventory", "bank", "gathering", "training" }

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
    for data in pairs(candidates) do
        if data ~= character and type(data.rareDeaths) == "table" then
            for id, death in pairs(data.rareDeaths) do
                local current = character.rareDeaths[id]
                if type(death) == "table" and type(death.time) == "number" and
                    (not current or death.time > (tonumber(current.time) or 0)) then
                    character.rareDeaths[id] = death
                end
            end
        end
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

function C:UpdateEquipmentSnapshot()
    if not self.db or not self.characterKey or
        (not GetInventoryItemID and not GetInventoryItemLink) then return end
    local summary = self.db.characters and self.db.characters[self.characterKey]
    if not summary then
        self:UpdateCharacterSummary()
        summary = self.db.characters and self.db.characters[self.characterKey]
    end
    if not summary then return end
    local slots = {}
    local equipped = 0
    for slot = 1, 19 do
        local itemID, link, icon
        if GetInventoryItemID then
            local ok, value = pcall(GetInventoryItemID, "player", slot)
            if not ok or (issecretvalue and issecretvalue(value)) then return end
            if type(value) == "number" then itemID = value end
        end
        if GetInventoryItemLink then
            local ok, value = pcall(GetInventoryItemLink, "player", slot)
            if not ok or (issecretvalue and issecretvalue(value)) then return end
            if type(value) == "string" then
                link = value
                itemID = itemID or tonumber(value:match("item:(%d+)"))
            end
        end
        if itemID and itemID > 0 then
            if GetInventoryItemTexture then
                local iconOK, value = pcall(GetInventoryItemTexture, "player", slot)
                if not iconOK or (issecretvalue and issecretvalue(value)) then return end
                if type(value) == "string" or type(value) == "number" then icon = value end
            end
            local item = { id = itemID, link = link, icon = icon }
            if GetItemInfo then
                local infoOK, name, _, quality, itemLevel = pcall(GetItemInfo, link or itemID)
                if (not infoOK or not name) and link then
                    infoOK, name, _, quality, itemLevel = pcall(GetItemInfo, itemID)
                end
                if infoOK then
                    if not (issecretvalue and issecretvalue(name)) and type(name) == "string" then item.name = name end
                    if not (issecretvalue and issecretvalue(quality)) and type(quality) == "number" then item.quality = quality end
                    if not (issecretvalue and issecretvalue(itemLevel)) and type(itemLevel) == "number" then item.itemLevel = itemLevel end
                end
            end
            if not item.quality and C_Item and C_Item.GetItemQualityByID then
                local qualityOK, quality = pcall(C_Item.GetItemQualityByID, itemID)
                if qualityOK and not (issecretvalue and issecretvalue(quality)) and
                    type(quality) == "number" then item.quality = quality end
            end
            if not item.quality and link then
                item.quality = tonumber(link:match("|cnIQ(%d+):"))
                if not item.quality then
                    local hex = link:match("|cff(%x%x%x%x%x%x)")
                    item.quality = hex and ({
                        ["9d9d9d"] = 0, ["ffffff"] = 1, ["1eff00"] = 2,
                        ["0070dd"] = 3, ["a335ee"] = 4, ["ff8000"] = 5,
                    })[hex:lower()]
                end
            end
            if GetItemStats then
                local statsOK, stats = pcall(GetItemStats, link or ("item:" .. itemID))
                if (not statsOK or (issecretvalue and issecretvalue(stats)) or
                    type(stats) ~= "table" or not next(stats)) and link then
                    statsOK, stats = pcall(GetItemStats, "item:" .. itemID)
                end
                if statsOK and not (issecretvalue and issecretvalue(stats)) and type(stats) == "table" then
                    item.stats = {}
                    for stat, value in pairs(stats) do
                        if not (issecretvalue and issecretvalue(stat)) and
                            not (issecretvalue and issecretvalue(value)) and
                            type(stat) == "string" and type(value) == "number" then
                            item.stats[stat] = value
                        end
                    end
                end
            end
            if (not item.itemLevel or not item.stats or not next(item.stats)) and
                not requestedEquipmentItems[itemID] and
                C_Item and C_Item.RequestLoadItemDataByID then
                requestedEquipmentItems[itemID] = true
                pcall(C_Item.RequestLoadItemDataByID, itemID)
            end
            slots[slot] = item
            equipped = equipped + 1
        end
    end
    -- Inventory APIs may already be empty during logout or before equipment loads.
    -- Keep the last valid cross-character snapshot in that case.
    if equipped == 0 then return end
    summary.equipment = { slots = slots, updated = time() }
    self:UpdateCharacterStats()
    self:Fire("DATA_CHANGED", "equipment")
end

function C:UpdateCharacterStats()
    local summary = self.db and self.db.characters and self.db.characters[self.characterKey]
    if not summary then return end
    local function safeCall(func, ...)
        if type(func) ~= "function" then return nil end
        local ok, value = pcall(func, ...)
        if ok and not (issecretvalue and issecretvalue(value)) and type(value) == "number" then return value end
        return nil
    end
    local stats = { updated = time() }
    stats.health = safeCall(UnitHealthMax, "player")
    if not stats.health or stats.health <= 0 then return end
    stats.mana = safeCall(UnitPowerMax, "player", 0)
    for index, name in ipairs({ "strength", "agility", "stamina", "intellect", "spirit" }) do
        if UnitStat then
            local ok, _, effective = pcall(UnitStat, "player", index)
            if ok and not (issecretvalue and issecretvalue(effective)) and type(effective) == "number" then
                stats[name] = effective
            end
        end
    end
    if UnitArmor then
        local ok, _, effective = pcall(UnitArmor, "player")
        if ok and not (issecretvalue and issecretvalue(effective)) and type(effective) == "number" then
            stats.armor = effective
        end
    end
    if UnitDamage then
        local ok, minimum, maximum = pcall(UnitDamage, "player")
        if ok and type(minimum) == "number" and type(maximum) == "number" and
            not (issecretvalue and (issecretvalue(minimum) or issecretvalue(maximum))) then
            stats.damageMin, stats.damageMax = minimum, maximum
        end
    end
    if UnitAttackPower then
        local ok, base, positive, negative = pcall(UnitAttackPower, "player")
        if ok and type(base) == "number" and type(positive) == "number" and type(negative) == "number" and
            not (issecretvalue and (issecretvalue(base) or issecretvalue(positive) or issecretvalue(negative))) then
            stats.attackPower = base + positive + negative
        end
    end
    stats.crit = safeCall(GetCritChance)
    stats.meleeHit = safeCall(GetHitModifier)
    stats.spellHit = safeCall(GetSpellHitModifier)
    stats.dodge = safeCall(GetDodgeChance)
    stats.parry = safeCall(GetParryChance)
    stats.block = safeCall(GetBlockChance)
    stats.spellPower = safeCall(GetSpellBonusDamage, 2)
    stats.healing = safeCall(GetSpellBonusHealing)
    stats.spellCrit = safeCall(GetSpellCritChance, 2)
    summary.characterStats = stats
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
    U.PushLimited(self.char.events, entry, self.db.settings.maxEvents or 750)
    self:Fire("CHRONICLE_EVENT_ADDED", entry)
    self:Fire("DATA_CHANGED", kind)
    return entry
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
