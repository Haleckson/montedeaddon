--[[
  Forever Companion - Core/Profiles.lua
  ElvUI-style profiles and the settings accessor.

  Profiles live in ForeverCompanionDB.profiles[name]; each character points at
  one through profileKeys["Name - Realm"]. Special names:
    "Default"                      shared default
    "Character: Name - Realm"      per character
    "Class: <Class>"               per class
  Anything else is a custom profile.

  All settings are read and written through FC.Config:Get / :Set with dotted
  paths ("map.iconScale"). Set emits SETTINGS_CHANGED(path) on the bus, which
  is how the UI, map and sync react live without a reload.
]]

local _, FC = ...

local Profiles = FC:NewModule("Profiles")
local Config = {}
FC.Config = Config

local U = FC.Utils
local DEFAULT = "Default"

--- The profile key of the character you play, and the key older versions
--- used for it; nil while the game has not named the character yet (at
--- ADDON_LOADED on a character's first login). On Forever the key carries
--- the surname: two characters of yours may share a first name.
local function characterKey()
    local name, surname
    if UnitName then name, surname = UnitName("player") end
    if type(name) ~= "string" or name == "" or name == "Unknown" or name == _G.UNKNOWNOBJECT then return nil end
    local realm = (GetRealmName and GetRealmName()) or ""
    local legacy = name .. " - " .. realm
    local separator = U.SurnameSeparator()
    if separator and type(surname) == "string" and surname ~= "" then
        return name .. separator .. surname .. " - " .. realm, legacy
    end
    return legacy, legacy
end

--- A key written while the character had no name: it belongs to nobody.
local function namelessKey(key)
    if type(key) ~= "string" then return true end
    local unknown = type(_G.UNKNOWNOBJECT) == "string" and _G.UNKNOWNOBJECT or "Unknown"
    return key:sub(1, #unknown + 3) == unknown .. " - " or key:sub(1, 10) == "Unknown - "
end

--- The character's profile key; nil until the game knows the character.
--- A key without the surname a Forever character has is asked again later.
function Profiles:CharacterKey()
    if not self.charKey or self.partialKey then
        self.charKey, self.legacyKey = characterKey()
        self.partialKey = self.charKey ~= nil and self.charKey == self.legacyKey and U.SurnameSeparator() ~= nil
    end
    return self.charKey
end

function Profiles:CharacterProfileName()
    return "Character: " .. (self:CharacterKey() or "?")
end

function Profiles:ClassProfileName()
    return "Class: " .. FC.Compat.GetClassName()
end

--- The profile this character points at, or nil while the game has not
--- named the character. A character seen for the first time under its full
--- name keeps the profile its first name pointed at.
function Profiles:Resolve()
    local key = self:CharacterKey()
    if not key then return nil end
    local db = FC.db
    local name = db.profileKeys[key]
    if name == nil and self.legacyKey ~= key then name = db.profileKeys[self.legacyKey] end
    if type(name) ~= "string" or type(db.profiles[name]) ~= "table" then name = DEFAULT end
    db.profileKeys[key] = name
    return name
end

function Profiles:OnInitialize()
    local db = FC.db
    if type(db.profiles[DEFAULT]) ~= "table" then
        db.profiles[DEFAULT] = U.CopyTable(FC.Defaults)
    end
    for key in pairs(db.profileKeys) do
        if namelessKey(key) then db.profileKeys[key] = nil end
    end
    -- without a name yet, the shared default serves until login (OnEnable)
    self:Activate(self:Resolve() or DEFAULT, true)
end

function Profiles:OnEnable()
    local name = self:Resolve()
    if not name or name == self.active then return end
    -- the character was nameless at ADDON_LOADED and has a profile of its own:
    -- switch before the other modules start, and tell them once they all run
    self:Activate(name, true)
    FC.Bus:On("ADDON_READY", self, function()
        FC.Bus:Off("ADDON_READY", self)
        FC.Bus:Emit("PROFILE_CHANGED", name)
        FC.Bus:Emit("SETTINGS_CHANGED", "*")
    end)
end

-- Stored positions come from disk or imports; drop any that cannot be anchored.
local function sanitize(profile)
    local window = profile.appearance.window
    if window.point ~= nil and not (U.IsAnchor(window.point) and U.IsAnchor(window.relPoint or window.point)
        and type(window.x or 0) == "number" and type(window.y or 0) == "number") then
        window.point, window.relPoint, window.x, window.y = nil, nil, nil, nil
    end
    local function validPoint(p)
        return type(p) == "table" and U.IsAnchor(p[1]) and U.IsAnchor(p[2] or p[1]) and type(p[3] or 0) == "number" and type(p[4] or 0) == "number"
    end
    if not validPoint(profile.notifications.point) then
        profile.notifications.point = U.CopyTable(FC.Defaults.notifications.point)
    end
    if profile.general.targetButton.point ~= nil and not validPoint(profile.general.targetButton.point) then
        profile.general.targetButton.point = nil
    end
    for role, hex in pairs(profile.appearance.colors) do
        if not U.IsValidHex(hex) then profile.appearance.colors[role] = nil end
    end
    for key, value in pairs(profile.map.hiddenGroups) do
        if type(value) ~= "boolean" then profile.map.hiddenGroups[key] = nil end
    end
end

function Profiles:Activate(name, silent)
    local db = FC.db
    if type(db.profiles[name]) ~= "table" then
        db.profiles[name] = U.CopyTable(FC.Defaults)
    end
    U.ApplyDefaults(db.profiles[name], FC.Defaults)
    sanitize(db.profiles[name])
    local key = self:CharacterKey()
    if key then db.profileKeys[key] = name end
    self.active = name
    FC.P = db.profiles[name]
    FC.Log:Configure(FC.P.debug.enabled, FC.P.debug.level)
    if not silent then
        FC.Bus:Emit("PROFILE_CHANGED", name)
        FC.Bus:Emit("SETTINGS_CHANGED", "*")
    end
end

function Profiles:GetActive()
    return self.active
end

function Profiles:List()
    local names = U.SortedKeys(FC.db.profiles)
    return names
end

function Profiles:Exists(name)
    return type(FC.db.profiles[name]) == "table"
end

local function validName(name)
    name = U.CleanText(name, 48)
    if not name or name == "" then return nil end
    return name
end

--- Creates a profile (optionally copied from another) and switches to it.
function Profiles:Create(name, copyFrom)
    name = validName(name)
    if not name then return false, FC.L.PROFILE_INVALID_NAME end
    if self:Exists(name) then return false, FC.L.PROFILE_EXISTS end
    local source = copyFrom and FC.db.profiles[copyFrom]
    FC.db.profiles[name] = source and U.CopyTable(source) or U.CopyTable(FC.Defaults)
    self:Activate(name)
    return true
end

--- Copies another profile's settings into the active one.
function Profiles:CopyFrom(sourceName)
    local source = FC.db.profiles[sourceName]
    if type(source) ~= "table" or sourceName == self.active then return false end
    FC.db.profiles[self.active] = U.CopyTable(source)
    self:Activate(self.active)
    return true
end

function Profiles:Rename(oldName, newName)
    newName = validName(newName)
    if not newName then return false, FC.L.PROFILE_INVALID_NAME end
    if oldName == DEFAULT then return false, FC.L.PROFILE_DEFAULT_LOCKED end
    if self:Exists(newName) then return false, FC.L.PROFILE_EXISTS end
    local db = FC.db
    if type(db.profiles[oldName]) ~= "table" then return false end
    db.profiles[newName] = db.profiles[oldName]
    db.profiles[oldName] = nil
    for key, value in pairs(db.profileKeys) do
        if value == oldName then db.profileKeys[key] = newName end
    end
    if self.active == oldName then
        self:Activate(newName)
    else
        FC.Bus:Emit("PROFILE_CHANGED", self.active)
    end
    return true
end

function Profiles:Delete(name)
    if name == DEFAULT then return false, FC.L.PROFILE_DEFAULT_LOCKED end
    if name == self.active then return false, FC.L.PROFILE_ACTIVE_LOCKED end
    local db = FC.db
    db.profiles[name] = nil
    for key, value in pairs(db.profileKeys) do
        if value == name then db.profileKeys[key] = DEFAULT end
    end
    FC.Bus:Emit("PROFILE_CHANGED", self.active)
    return true
end

function Profiles:Reset(name)
    name = name or self.active
    FC.db.profiles[name] = U.CopyTable(FC.Defaults)
    if name == self.active then
        self:Activate(name)
    end
    return true
end

function Profiles:ExportTable()
    return U.CopyTable(FC.P)
end

--- Adds an imported profile under a free name and returns that name.
function Profiles:ImportTable(settings, baseName)
    local name = validName(baseName) or "Imported"
    local candidate, n = name, 2
    while self:Exists(candidate) do
        candidate = name .. " " .. n
        n = n + 1
    end
    local profile = U.CopyTable(settings)
    U.ApplyDefaults(profile, FC.Defaults)
    FC.db.profiles[candidate] = profile
    FC.Bus:Emit("PROFILE_CHANGED", self.active)
    return candidate
end

------------------------------------------------------------------------
-- Config accessor
------------------------------------------------------------------------

local pathCache = {}
local function splitPath(path)
    local parts = pathCache[path]
    if not parts then
        parts = {}
        for piece in path:gmatch("[^%.]+") do parts[#parts + 1] = piece end
        pathCache[path] = parts
    end
    return parts
end

function Config:Get(path)
    local node = FC.P
    for _, key in ipairs(splitPath(path)) do
        if type(node) ~= "table" then return nil end
        node = node[key]
    end
    return node
end

function Config:Set(path, value)
    local parts = splitPath(path)
    local node = FC.P
    for i = 1, #parts - 1 do
        local key = parts[i]
        if type(node[key]) ~= "table" then node[key] = {} end
        node = node[key]
    end
    node[parts[#parts]] = value
    if path:find("^debug%.") then
        FC.Log:Configure(FC.P.debug.enabled, FC.P.debug.level)
    end
    FC.Bus:Emit("SETTINGS_CHANGED", path)
end

function Config:Default(path)
    local node = FC.Defaults
    for _, key in ipairs(splitPath(path)) do
        if type(node) ~= "table" then return nil end
        node = node[key]
    end
    return node
end

--- Resets a whole settings section (e.g. "appearance") to defaults.
function Config:ResetSection(section)
    if type(FC.Defaults[section]) == "table" then
        FC.P[section] = U.CopyTable(FC.Defaults[section])
        FC.Bus:Emit("SETTINGS_CHANGED", section .. ".*")
    end
end
