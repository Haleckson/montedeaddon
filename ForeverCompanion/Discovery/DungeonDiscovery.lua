--[[
  Forever Companion - Discovery/DungeonDiscovery.lua
  Dungeons and raids: the instance itself, its entrance (last outdoor
  position before zoning in), bosses defeated (ENCOUNTER_END) and boss
  mechanics taken from the emotes and yells during each encounter.

  Everything documented while inside an instance (rares, notes, mechanics,
  secrets, quests, loot) automatically gets the dungeon as its parent, which
  builds the dungeon hierarchy shown in the detail panel.
]]

local _, FC = ...

local Engine = FC.DiscoveryEngine
local Compat = FC.Compat
local Categories = FC.Categories

local Dungeon = {}
FC.DungeonDiscovery = Dungeon

local INSTANCE_TYPES = { party = true, raid = true }

function Dungeon:CheckInstance()
    local instance = Compat.GetInstance()
    if not instance or not INSTANCE_TYPES[instance.type] or not instance.instanceID then
        self.current = nil
        return
    end
    if self.current == instance.instanceID then return end
    self.current = instance.instanceID

    local dungeonID = "dungeon:" .. instance.instanceID
    local outdoor = FC.cdb.lastOutdoor
    local fields = {
        t = "dungeon",
        n = instance.name,
        ["in"] = instance.instanceID,
        inn = instance.name,
        ic = Categories:Get("dungeon").icon,
        -- the location lives on the entrance child, so the map shows one pin
        z = outdoor and outdoor.z,
    }
    local dungeonRec = Engine:Record(fields, { id = dungeonID })

    if outdoor and outdoor.m and outdoor.x and dungeonRec then
        Engine:Record({
            t = "entrance",
            n = string.format(FC.L.AUTO_ENTRANCE_TITLE, instance.name or "?"),
            m = outdoor.m, x = outdoor.x, y = outdoor.y, z = outdoor.z,
            ["in"] = instance.instanceID,
            inn = instance.name,
            pa = dungeonID,
            ic = Categories:Get("entrance").icon,
        }, { id = "entrance:" .. instance.instanceID })
    end
end

Engine:RegisterDetector("dungeons", {
    setting = "discovery.dungeons",
    events = {
        PLAYER_ENTERING_WORLD = function() FC.Utils.After(2, function() Dungeon:CheckInstance() end) end,
        ZONE_CHANGED_NEW_AREA = function() Dungeon:CheckInstance() end,
    },
})

------------------------------------------------------------------------
-- Encounters and their mechanics
------------------------------------------------------------------------

-- Boss emotes and yells during an encounter are the game's own
-- description of a mechanic ("The ground begins to tremble!").
local function cleanText(text)
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", ""):gsub("|H.-|h(.-)|h", "%1")
    text = text:gsub("%%s", "..."):gsub("%s+", " ")
    return FC.Utils.Trim(text)
end

function Dungeon:OnBossText(text, speaker)
    text, speaker = Compat.Safe(text), Compat.Safe(speaker)
    local encounter = self.encounter
    if not encounter or type(text) ~= "string" or text == "" then return end
    if encounter.count >= FC.C.DISCOVERY.MAX_MECHANICS then return end
    text = cleanText(text)
    if #text < 8 then return end
    local key = FC.Utils.NormalizeTitle(text):sub(1, 40)
    if encounter.seen[key] then return end
    encounter.seen[key] = true
    encounter.count = encounter.count + 1
    local short = #text > 60 and (text:sub(1, 57) .. "...") or text
    local fields = Engine:LocationFields()
    fields.t = "mechanic"
    fields.n = (encounter.name or speaker or "?") .. ": " .. short
    fields.d = (type(speaker) == "string" and (speaker .. ": ") or "") .. text
    fields.tg = { "mechanic" }
    fields.ic = Categories:Get("mechanic").icon
    Engine:Record(fields, { id = "mech:" .. encounter.id .. ":" .. key, deferInCombat = false })
end

Engine:RegisterDetector("mechanics", {
    setting = "discovery.mechanics",
    events = {
        ENCOUNTER_START = function(_, _, encounterID, encounterName)
            encounterID, encounterName = Compat.Safe(encounterID), Compat.Safe(encounterName)
            if type(encounterID) ~= "number" then return end
            Dungeon.encounter = { id = encounterID, name = encounterName, count = 0, seen = {} }
        end,
        ENCOUNTER_END = function() Dungeon.encounter = nil end,
        RAID_BOSS_EMOTE = function(_, _, text, speaker) Dungeon:OnBossText(text, speaker) end,
        RAID_BOSS_WHISPER = function(_, _, text, speaker) Dungeon:OnBossText(text, speaker) end,
        CHAT_MSG_MONSTER_YELL = function(_, _, text, speaker) Dungeon:OnBossText(text, speaker) end,
        CHAT_MSG_MONSTER_EMOTE = function(_, _, text, speaker) Dungeon:OnBossText(text, speaker) end,
        CHAT_MSG_RAID_BOSS_EMOTE = function(_, _, text, speaker) Dungeon:OnBossText(text, speaker) end,
    },
})

Engine:RegisterDetector("bosses", {
    setting = "discovery.bosses",
    events = {
        ENCOUNTER_END = function(_, _, encounterID, encounterName, _, _, success)
            encounterID, encounterName, success = Compat.Safe(encounterID), Compat.Safe(encounterName), Compat.Safe(success)
            if success ~= 1 or type(encounterID) ~= "number" or type(encounterName) ~= "string" then return end
            local fields = Engine:LocationFields()
            fields.t = "boss"
            fields.n = encounterName
            fields.ic = Categories:Get("boss").icon
            Engine:Record(fields, { id = "boss:" .. encounterID })
        end,
    },
})
