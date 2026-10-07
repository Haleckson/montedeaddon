--[[
  Forever Companion - Features/ImportExport.lua
  Human-shareable text format for discoveries, full backups, themes and
  profiles:

      FC1:<base64 payload>:<checksum>      discoveries or backup
      FCT1:<base64 payload>:<checksum>     theme
      FCP1:<base64 payload>:<checksum>     profile

  The payload is the safe serializer output (never Lua code). Import verifies
  prefix, size, checksum, structure and every record through the same
  validator the store uses. Absolutely no loadstring anywhere.

  The same encoder is the extension point for future external tools (web
  atlas, Discord bots, companion apps): they read this format from a pasted
  string or from the SavedVariables file on disk.
]]

local _, FC = ...

local IO = FC:NewModule("ImportExport")

local C = FC.C
local U = FC.Utils
local L = FC.L
local Serializer = FC.Serializer

local FORMAT_VERSION = 1

local function encode(prefix, payload)
    local data, err = Serializer:Serialize(payload)
    if not data then return nil, err end
    local body = Serializer:Base64Encode(data)
    return prefix .. ":" .. body .. ":" .. Serializer:Hash(body)
end

local function decode(text)
    if type(text) ~= "string" then return nil, L.IMPORT_ERR_EMPTY end
    text = U.Trim(text):gsub("%s", "")
    if text == "" then return nil, L.IMPORT_ERR_EMPTY end
    if #text > C.LIMITS.IMPORT_CHARS then return nil, L.IMPORT_ERR_TOO_LARGE end
    local prefix, body, checksum = text:match("^(%w+):([%w%+/=]+):(%x+)$")
    if not prefix then return nil, L.IMPORT_ERR_FORMAT end
    if Serializer:Hash(body) ~= checksum then return nil, L.IMPORT_ERR_CHECKSUM end
    local data = Serializer:Base64Decode(body)
    if not data then return nil, L.IMPORT_ERR_FORMAT end
    local ok, payload = Serializer:Deserialize(data, { maxString = 65536, maxNodes = C.LIMITS.IMPORT_NODES })
    if not ok or type(payload) ~= "table" then return nil, L.IMPORT_ERR_FORMAT end
    if tonumber(payload.fv) ~= FORMAT_VERSION then return nil, L.IMPORT_ERR_VERSION end
    return prefix, payload
end

------------------------------------------------------------------------
-- Export
------------------------------------------------------------------------

local function exportable(rec, includePrivate)
    if rec.dev then return nil end
    if rec.v == "p" and not includePrivate then return nil end
    return U.CopyTable(rec)
end

--- Exports a list of records (a selected discovery or a whole category).
function IO:ExportRecords(records, includePrivate)
    local list = {}
    for _, rec in ipairs(records) do
        local copy = exportable(rec, includePrivate)
        if copy then list[#list + 1] = copy end
    end
    if #list == 0 then return nil, L.EXPORT_NOTHING end
    return encode(C.EXPORT_PREFIX, { fv = FORMAT_VERSION, k = "d", t = U.Now(), a = FC.Store.me, recs = list }), #list
end

--- Full personal backup: every record (including private), personal state,
--- tag colors, custom themes, the quest knowledge, your characters' flight
--- paths, what each of them found and the milestones each unlocked, and
--- their autobiographies.
function IO:ExportBackup()
    local list, state = {}, {}
    for id, rec in pairs(FC.Store.records) do
        if not rec.dev then
            list[#list + 1] = U.CopyTable(rec)
            if FC.db.userState[id] then state[id] = U.CopyTable(FC.db.userState[id]) end
        end
    end
    local chars, nodes = FC.Characters:BackupCopy()
    return encode(C.EXPORT_PREFIX, {
        fv = FORMAT_VERSION, k = "b", t = U.Now(), a = FC.Store.me,
        recs = list, state = state, tagColors = U.CopyTable(FC.db.tagColors),
        themes = U.CopyTable(FC.db.customThemes),
        lore = U.CopyTable(FC.db.questLore), chars = chars, nodes = nodes, bio = FC.Biography:BackupCopy(),
        found = U.CopyTable(FC.db.found), charMs = U.CopyTable(FC.db.charMilestones),
    }), #list
end

-- Joins { ["Name-Realm"] = { [key] = time } } lists (what each character
-- found, the milestones each unlocked): the earliest time wins.
local function mergePerCharacter(target, incoming)
    if type(incoming) ~= "table" then return end
    for charKey, entries in pairs(incoming) do
        if type(charKey) == "string" and type(entries) == "table" then
            local mine = target[charKey] or {}
            for key, ts in pairs(entries) do
                if type(key) == "string" and type(ts) == "number" and (mine[key] == nil or ts < mine[key]) then
                    mine[key] = ts
                end
            end
            target[charKey] = mine
        end
    end
end

function IO:ExportTheme(name, colors)
    return encode(C.THEME_EXPORT_PREFIX, { fv = FORMAT_VERSION, k = "t", name = name, colors = colors })
end

function IO:ExportProfile()
    return encode(C.PROFILE_EXPORT_PREFIX, { fv = FORMAT_VERSION, k = "p", name = FC.Profiles:GetActive(), settings = FC.Profiles:ExportTable() })
end

------------------------------------------------------------------------
-- Import
------------------------------------------------------------------------

local function importRecords(payload)
    if type(payload.recs) ~= "table" then return nil, L.IMPORT_ERR_FORMAT end
    if #payload.recs > C.LIMITS.IMPORT_RECORDS then return nil, L.IMPORT_ERR_TOO_LARGE end
    local counts = { added = 0, updated = 0, verified = 0, unchanged = 0, rejected = 0 }
    for _, rec in ipairs(payload.recs) do
        local _, result = FC.Store:Upsert(rec, "import")
        counts[result or "rejected"] = (counts[result or "rejected"] or 0) + 1
    end
    return counts
end

local function importBackup(payload)
    local counts, err = importRecords(payload)
    if not counts then return nil, err end
    if type(payload.state) == "table" then
        for id, state in pairs(payload.state) do
            if type(id) == "string" and FC.Store:Get(id) and type(state) == "table" and not FC.db.userState[id] then
                FC.db.userState[id] = state
            end
        end
        FC.Store:ValidateAll()
    end
    if type(payload.tagColors) == "table" then
        for tag, hex in pairs(payload.tagColors) do
            if type(tag) == "string" and U.IsValidHex(hex) and not FC.db.tagColors[tag] then
                FC.db.tagColors[tag] = hex
            end
        end
    end
    if type(payload.themes) == "table" and FC.Theme then
        for name, colors in pairs(payload.themes) do
            FC.Theme:SaveCustom(name, colors, true)
        end
    end
    if type(payload.lore) == "table" then FC.QuestLore:Merge(payload.lore) end
    if type(payload.chars) == "table" or type(payload.nodes) == "table" then
        FC.Characters:Merge(payload.chars, payload.nodes)
    end
    if type(payload.bio) == "table" then
        for key, stats in pairs(payload.bio) do FC.Biography:Merge(key, stats) end
    end
    mergePerCharacter(FC.db.found, payload.found)
    mergePerCharacter(FC.db.charMilestones, payload.charMs)
    FC.Store:RebuildIndexes()
    FC.Bus:Emit("STORE_RESET")
    return counts
end

--- Imports any supported string. Returns a summary table or nil + error.
function IO:Import(text)
    local prefix, payload = decode(text)
    if not prefix then return nil, payload end
    if prefix == C.EXPORT_PREFIX then
        if payload.k == "d" then
            local counts, err = importRecords(payload)
            if counts then return { kind = "records", counts = counts } end
            return nil, err
        elseif payload.k == "b" then
            local counts, err = importBackup(payload)
            if counts then return { kind = "backup", counts = counts } end
            return nil, err
        end
    elseif prefix == C.THEME_EXPORT_PREFIX and payload.k == "t" then
        local name = FC.Theme:SaveCustom(payload.name, payload.colors)
        if not name then return nil, L.IMPORT_ERR_FORMAT end
        return { kind = "theme", name = name }
    elseif prefix == C.PROFILE_EXPORT_PREFIX and payload.k == "p" then
        if type(payload.settings) ~= "table" then return nil, L.IMPORT_ERR_FORMAT end
        local name = FC.Profiles:ImportTable(payload.settings, payload.name)
        return { kind = "profile", name = name }
    end
    return nil, L.IMPORT_ERR_FORMAT
end

--- Short, localized summary of an import result for the UI.
function IO:Describe(result)
    if result.kind == "theme" then return string.format(L.IMPORT_OK_THEME, result.name) end
    if result.kind == "profile" then return string.format(L.IMPORT_OK_PROFILE, result.name) end
    local c = result.counts
    return string.format(L.IMPORT_OK_RECORDS, c.added or 0, (c.updated or 0) + (c.verified or 0), c.rejected or 0)
end
