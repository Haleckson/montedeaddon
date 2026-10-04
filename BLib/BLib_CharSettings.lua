-- BLib_CharSettings.lua: settings that can be this character's own, or the global set every character shares (the
-- user, 2026-10-03: a "Use global settings" box on each character, on by default, so a new character needs no
-- setting up and one that should look different needs only that box ticked off).
--
-- An addon keeps its settings exactly where it does now: that is the global set, so nothing is migrated and nothing
-- changes for anyone until the box is turned off. A character that turns it off gets a copy of the global values
-- as they are at that moment, kept in BLibDB.charSettings[addon][GUID], and the addon's own table holds that
-- character's values while it plays (copied in place, so a table the addon holds on to stays the table). At logout
-- the character's values are put back in BLibDB and the global ones back in the addon's saved variable, so what the
-- game saves is the global set. Only the paths an addon names are swapped: what it has recorded (learned quests,
-- mail, saved waypoints) is never split by character.
--
--   local cs = BLib.CharSettings.Register("Forgemaster", {
--       name  = "Forgemaster",
--       root  = function() return ForgemasterDB.settings end,   -- the table the settings live in (nil: not yet)
--       paths = { "scale", "buyKeybind", "tooltip.enabled" },    -- dotted paths below root; or a function that
--                                                                -- returns the list (every key but some)
--       apply = function() end,                                  -- after a switch made while playing: redraw
--       fill  = function() end,   -- after a character's own values are put in: fill in what an update has added
--                                 -- since they were kept (the addon's own defaults and any migration of keys)
--   })
--   cs:Bind()                      -- once the addon has built its saved variables (and its defaults)
--   cs:IsGlobal()   cs:SetGlobal(true|false)   -- false: not in combat
--   BLib.CharSettings.Row(builder, "Forgemaster")   -- the box and its note, for the top of a settings page

BLib = BLib or {}
local CS = {}
BLib.CharSettings = CS

local handles, pending = {}, {}
local H = {}
H.__index = H

local function Copy(v)
    if type(v) ~= "table" then return v end
    local c = {}
    for k, x in pairs(v) do c[k] = Copy(x) end
    return c
end

-- dst becomes exactly src, keeping dst and the tables inside it.
local function Exact(dst, src)
    for k in pairs(dst) do if src[k] == nil then dst[k] = nil end end
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            Exact(dst[k], v)
        else
            dst[k] = v
        end
    end
end

local function Keys(path)
    local keys = {}
    for key in path:gmatch("[^.]+") do keys[#keys + 1] = key end
    return keys
end

local function GetAt(root, path)
    local node = root
    for _, key in ipairs(Keys(path)) do
        if type(node) ~= "table" then return nil end
        node = node[key]
    end
    return node
end

local function SetAt(root, path, value)
    local keys = Keys(path)
    local node = root
    for i = 1, #keys - 1 do
        if type(node[keys[i]]) ~= "table" then
            if value == nil then return end
            node[keys[i]] = {}
        end
        node = node[keys[i]]
    end
    local last = keys[#keys]
    if type(value) == "table" then
        if type(node[last]) ~= "table" then node[last] = {} end
        Exact(node[last], value)
    else
        node[last] = value
    end
end

local function PlayerGUID()
    local guid = UnitGUID and UnitGUID("player")
    return type(guid) == "string" and guid or nil
end

function CS.Register(key, spec)
    if type(key) ~= "string" or type(spec) ~= "table" or type(spec.root) ~= "function" then return nil end
    local h = setmetatable({ key = key, name = spec.name or key, spec = spec, mode = "global" }, H)
    handles[key] = h
    return h
end

function CS.Get(key) return handles[key] end

function H:Paths()
    local p = self.spec.paths
    if type(p) == "function" then return p() end
    return p or {}
end

-- { path = a copy of what is there now }
function H:Snapshot()
    local root = self.spec.root()
    local snap = {}
    if type(root) ~= "table" then return snap end
    for _, path in ipairs(self:Paths()) do snap[path] = Copy(GetAt(root, path)) end
    return snap
end

-- Puts a snapshot's values in the addon's table.
function H:Load(snap)
    local root = self.spec.root()
    if type(root) ~= "table" or type(snap) ~= "table" then return end
    local seen = {}
    for _, path in ipairs(self:Paths()) do seen[path] = true end
    for path in pairs(snap) do seen[path] = true end
    for path in pairs(seen) do SetAt(root, path, Copy(snap[path])) end
end

local function Record(self, create)
    if not BLibDB then return nil end
    local all = BLibDB.charSettings
    if not all then
        if not create then return nil end
        all = {}
        BLibDB.charSettings = all
    end
    local mine = all[self.key]
    if not mine then
        if not create then return nil end
        mine = {}
        all[self.key] = mine
    end
    local rec = mine[self.guid]
    if not rec and create then
        rec = {}
        mine[self.guid] = rec
    end
    return rec
end

-- A character's own values were kept by an earlier version of the addon: whatever an update has added since (a new
-- default) was missing from them and has just been removed by loading them, so the addon fills it in again.
function H:Fill()
    if self.spec.fill then
        local ok, err = pcall(self.spec.fill)
        if not ok and geterrorhandler then geterrorhandler()(err) end
    end
end

function H:IsGlobal() return self.mode ~= "own" end

-- Whether this character has a way to tell itself apart (its GUID is known).
function H:CanSwitch() return self.guid ~= nil end

local frame = CreateFrame("Frame")

function H:Bind()
    if type(self.spec.root()) ~= "table" then return end
    -- Once a session: a second call in own mode would take the character's values for the global ones.
    if self.mode == "own" then return end
    local guid = PlayerGUID()
    if not guid then
        pending[self.key] = self   -- PLAYER_LOGIN, when it is surely known
        return
    end
    pending[self.key] = nil
    self.guid = guid
    local rec = Record(self, false)
    if rec and rec.off and type(rec.own) == "table" then
        self.stash = self:Snapshot()
        self:Load(rec.own)
        self:Fill()
        self.mode = "own"
    else
        self.mode = "global"
    end
end

-- true: the global set. false: this character's own, kept from last time or, the first time, a copy of the global
-- values as they are now. Redraws through the addon's apply.
function H:SetGlobal(on)
    on = on and true or false
    if not self.guid then return false end
    if InCombatLockdown and InCombatLockdown() then
        if BLib.Print then BLib.Print("BLib", "Not in combat: " .. self.name .. "'s settings can be switched out of it.") end
        return false
    end
    if on == self:IsGlobal() then return true end
    local rec = Record(self, true)
    if on then
        rec.own = self:Snapshot()
        rec.off = nil
        self:Load(self.stash)
        self.stash = nil
        self.mode = "global"
    else
        self.stash = self:Snapshot()
        local kept = type(rec.own) == "table"
        if not kept then rec.own = Copy(self.stash) end
        rec.off = true
        if kept then self:Load(rec.own) self:Fill() end
        self.mode = "own"
    end
    if self.spec.apply then
        local ok, err = pcall(self.spec.apply)
        if not ok and geterrorhandler then geterrorhandler()(err) end
    end
    return true
end

-- Logout: this character's values back in BLibDB, the global ones back where the game will save them.
function H:Flush()
    if self.mode ~= "own" then return end
    -- Restoring the global values comes first and cannot be skipped by an error in keeping the character's: what
    -- the game saves must be the global set.
    local okSnap, own = pcall(self.Snapshot, self)
    local stash = self.stash
    self.stash = nil
    self.mode = "global"
    pcall(self.Load, self, stash)
    if okSnap then
        local okRec, rec = pcall(Record, self, true)
        if okRec and rec then rec.own = own end
    end
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        -- Listening for the logout from here, once every addon has loaded: an addon's own PLAYER_LOGOUT handler
        -- (booking a session, saving a place) is registered as its files load or when it loads, and a handler runs
        -- in the order it was registered, so ours is the last and what they write lands in the character's values,
        -- not the global set.
        frame:RegisterEvent("PLAYER_LOGOUT")
    end
    if event == "PLAYER_LOGOUT" then
        for _, h in pairs(handles) do pcall(h.Flush, h) end
        return
    end
    for key, h in pairs(pending) do
        h:Bind()
        if h.guid and not h:IsGlobal() and h.spec.apply then pcall(h.spec.apply) end
    end
end)

-- Several registrations that one box switches together (Lifeline and its aura board are two saved variables, one
-- choice for the player): the first key's state is shown, a switch is made on all of them.
local function Group(keys)
    local list = {}
    for _, key in ipairs(keys) do if handles[key] then list[#list + 1] = handles[key] end end
    return list
end

local function GroupIsGlobal(list) return list[1] == nil or list[1]:IsGlobal() end
local function GroupCanSwitch(list) return list[1] ~= nil and list[1]:CanSwitch() end

local function GroupSet(list, on)
    local all = true
    for _, h in ipairs(list) do
        if h:CanSwitch() and not h:SetGlobal(on) then all = false end
    end
    return all
end

local NOTE_ON = "On: every character with this on shares one set of settings, so a change here is made for all of them."
local NOTE_OFF = "Off: this character has settings of its own, started from the global ones, so a change here is made "
    .. "for this character only. Turn it back on to use the global set again; this character's own are kept."

-- The box for the top of a settings page, with what it does (builder rows). Keys: every registration it switches.
function CS.Row(b, ...)
    local list = Group({ ... })
    if #list == 0 or not b or not b.Toggle then return nil end
    b:Section("This character")
    local row = b:Toggle("Use global settings", function() return GroupIsGlobal(list) end, function(v) GroupSet(list, v) end)
    b:LiveNote(function()
        if not GroupCanSwitch(list) then return "Not available until the game has told the addon who you are." end
        return GroupIsGlobal(list) and NOTE_ON or NOTE_OFF
    end, 3)
    return row
end

-- A checkbox for a MenuUtil menu (root:CreateCheckbox), for an addon whose settings are a menu.
function CS.MenuCheckbox(root, ...)
    local list = Group({ ... })
    if #list == 0 or not root or not root.CreateCheckbox then return nil end
    return root:CreateCheckbox("Use global settings", function() return GroupIsGlobal(list) end, function()
        GroupSet(list, not GroupIsGlobal(list))
        return BLib.MENU_KEEP_OPEN
    end)
end

-- For an addon with no settings window: its slash command hands "global [on|off]" here. Says what it did.
-- Returns true when it was handled.
function CS.Command(prefix, arg, ...)
    local list = Group({ ... })
    local word = (arg or ""):lower():match("^%s*(%S*)")
    local function Say(text) if BLib.Print then BLib.Print(prefix, text) else print(prefix .. ": " .. text) end end
    if #list == 0 then Say("settings per character need BLib 1.10.0.") return true end
    if not GroupCanSwitch(list) then Say("not available until the game has told the addon who you are.") return true end
    if word == "on" or word == "off" then
        if GroupSet(list, word == "on") then
            Say(word == "on" and "using the global settings." or "this character has settings of its own.")
        end
        return true
    end
    Say((GroupIsGlobal(list) and "this character uses the global settings." or "this character has settings of its own.")
        .. " |cffffff00global on|r or |cffffff00global off|r changes it.")
    return true
end
