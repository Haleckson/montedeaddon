--[[
  Forever Companion - Core/Database.lua
  Loads, migrates and structurally validates the SavedVariables.

  ForeverCompanionDB      account-wide (discoveries, profiles, personal state,
                          NPCs known to be ordinary, what each of your
                          characters found and the progress mode)
  ForeverCompanionCharDB  per character (quest chains, last outdoor position)

  Record-level validation is done by the DiscoveryStore on initialize, so a
  single corrupted entry is dropped with a warning instead of breaking the addon.
]]

local _, FC = ...

local Database = {}
FC.Database = Database

local U = FC.Utils

local ACCOUNT_TABLES = {
    "meta", "profileKeys", "profiles", "discoveries", "userState",
    "tagColors", "customThemes", "myChars", "sync", "milestones", "ordinaryNpcs", "gatherObjects",
    "found", "charMilestones",
}

-- { ["Name-Realm"] = { [key] = time } }: what each character found, and the
-- milestones each one unlocked. Anything else is dropped.
local function cleanPerCharacter(list)
    for charKey, entries in pairs(list) do
        if type(charKey) ~= "string" or type(entries) ~= "table" then
            list[charKey] = nil
        else
            for key, ts in pairs(entries) do
                if type(key) ~= "string" or type(ts) ~= "number" then entries[key] = nil end
            end
        end
    end
end

local function ensureStructure(db)
    for _, key in ipairs(ACCOUNT_TABLES) do
        if type(db[key]) ~= "table" then db[key] = {} end
    end
    cleanPerCharacter(db.found)
    cleanPerCharacter(db.charMilestones)
    -- "account" | "character"; nil until the player chose (they are asked at login)
    if db.progressMode ~= "account" and db.progressMode ~= "character" then db.progressMode = nil end
    if type(db.meta.created) ~= "number" then db.meta.created = U.Now() end
    if type(db.sync.peers) ~= "table" then db.sync.peers = {} end
    for npcID, known in pairs(db.ordinaryNpcs) do
        if type(npcID) ~= "number" or known ~= true then db.ordinaryNpcs[npcID] = nil end
    end
    -- world objects known to be herbs, ore or fishing spots: never treasure
    for objectID, profession in pairs(db.gatherObjects) do
        if type(objectID) ~= "number" or type(profession) ~= "string" or #profession > 16 then db.gatherObjects[objectID] = nil end
    end
end

local function ensureCharStructure(cdb)
    if type(cdb.discovered) ~= "table" then cdb.discovered = {} end
    if type(cdb.chains) ~= "table" then cdb.chains = {} end
    for questID, root in pairs(cdb.chains) do
        if type(questID) ~= "number" or type(root) ~= "number" then cdb.chains[questID] = nil end
    end
    if cdb.lastOutdoor ~= nil and type(cdb.lastOutdoor) ~= "table" then cdb.lastOutdoor = nil end
end

function Database:Load()
    if type(ForeverCompanionDB) ~= "table" then
        ForeverCompanionDB = { schema = 0 }
        self.freshInstall = true
    end
    if type(ForeverCompanionCharDB) ~= "table" then
        ForeverCompanionCharDB = { schema = 0 }
    end

    local db, cdb = ForeverCompanionDB, ForeverCompanionCharDB
    FC.Migration:RunAccount(db)
    FC.Migration:RunCharacter(cdb)
    ensureStructure(db)
    ensureCharStructure(cdb)

    db.meta.lastAddonVersion = FC.version
    FC.db = db
    FC.cdb = cdb
end

function Database:ClearCharacterData()
    local cdb = FC.cdb
    wipe(cdb.discovered)
    wipe(cdb.chains)
    cdb.lastOutdoor = nil
    local me = FC.Store and FC.Store.me
    if me then
        FC.db.found[me] = nil
        FC.db.charMilestones[me] = nil
    end
end

--- Rough size of the account database in bytes (serialized form).
function Database:EstimateSize()
    local ok, text = pcall(FC.Serializer.Serialize, FC.Serializer, {
        d = FC.db.discoveries, u = FC.db.userState,
    })
    if ok and type(text) == "string" then return #text end
    return 0
end
