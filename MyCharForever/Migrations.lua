local addonName, MCF = ...
-- Saved-data safety.
--   * MCF.Migrations lists every change to the layout of the saved data, one entry per db version.
--     MCF.DB_VERSION is derived from the list, so the version number exists exactly once.
--   * A migration declares the keys it touches (`touches`); they are copied in memory before it runs and
--     restored if it fails, so a broken migration never leaves half-converted data behind. A failed
--     migration is logged (/mcf errors) and tried again at the next login; nothing after it runs.
--   * Data written by a NEWER addon version (after a downgrade) is left alone: no migrations run.
--   * RepairDB replaces a top-level key that is not a table (damaged file, manual editing) by an empty
--     table. The old value is kept in db.recovered[key], so nothing is lost silently.
-- To change the data layout: append an entry below, never edit an old one.

MCF.Migrations = {
  {version = 2, name = "screenshot metadata, level snapshots, journal entries",
    run = function() end}, -- the new tables are created by InitializeDB; version 1 data stays untouched
  {version = 3, name = "location time, zone time, travel and duel tables",
    run = function() end}, -- created by InitializeDB as well
  {version = 4, name = "walking distance counter, retention limits",
    touches = {"travel"},
    run = function(db)
      db.travel = type(db.travel) == "table" and db.travel or {}
      db.travel.walkYards = tonumber(db.travel.walkYards) or 0
    end},
  {version = 5, name = "critter ID list for critter achievements",
    touches = {"combat"},
    run = function(db)
      db.combat = type(db.combat) == "table" and db.combat or {}
      db.combat.critterIDs = type(db.combat.critterIDs) == "table" and db.combat.critterIDs or {}
    end},
}

MCF.DB_VERSION = MCF.Migrations[#MCF.Migrations].version
local HISTORY_LIMIT = 20 -- entries of db.migrations

local function deepCopy(v, depth)
  if type(v) ~= "table" then return v end
  depth = depth or 0
  if depth > 12 then return nil end
  local out = {}
  for k, val in pairs(v) do out[k] = deepCopy(val, depth + 1) end
  return out
end

-- Top-level keys that must be tables: everything the export rules know as data (one list, see Export.lua).
local function expectedTables()
  local src = MCF.ExportSources or {}
  local keys = {}
  for _, list in pairs(src.groups or {}) do for _, k in ipairs(list) do keys[#keys + 1] = k end end
  for k in pairs(src.special or {}) do keys[#keys + 1] = k end
  for k in pairs(src.computed or {}) do keys[#keys + 1] = k end
  return keys
end

function MCF:RepairDB(db)
  if type(db) ~= "table" then return 0 end
  local repaired = 0
  for _, key in ipairs(expectedTables()) do
    local v = db[key]
    if v ~= nil and type(v) ~= "table" then
      db.recovered = type(db.recovered) == "table" and db.recovered or {}
      db.recovered[key] = v
      db[key] = nil
      repaired = repaired + 1
      self:LogError("Saved data repaired: '" .. tostring(key) .. "' was a " .. type(v) .. ", expected a table", nil, "RepairDB")
    end
  end
  return repaired
end

-- Brings db up to MCF.DB_VERSION. Returns true when the data is current afterwards.
function MCF:MigrateDB(db)
  if type(db) ~= "table" then return false end
  local version = tonumber(db.dbVersion) or 1
  if version > self.DB_VERSION then
    db.newerThanAddon = self.DB_VERSION
    self:LogError("Saved data is version " .. version .. ", this addon knows " .. self.DB_VERSION
      .. " (older addon after a newer one). Data is left untouched.", nil, "Migrate")
    return false
  end
  db.newerThanAddon = nil
  for _, m in ipairs(self.Migrations) do
    if version < m.version then
      local backup = {}
      for _, key in ipairs(m.touches or {}) do backup[key] = deepCopy(db[key]) end
      local ok, err = pcall(m.run, db)
      if not ok then
        for _, key in ipairs(m.touches or {}) do db[key] = backup[key] end
        self:LogError("Migration to version " .. m.version .. " failed: " .. tostring(err), nil, "Migrate")
        return false
      end
      version = m.version
      db.dbVersion = version
      db.migrations = type(db.migrations) == "table" and db.migrations or {}
      db.migrations[#db.migrations + 1] = {version = version, time = time(), addon = self.VERSION}
      while #db.migrations > HISTORY_LIMIT do table.remove(db.migrations, 1) end
    end
  end
  db.dbVersion = math.max(tonumber(db.dbVersion) or 1, version)
  return true
end
