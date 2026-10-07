--[[
  Forever Companion - Features/Milestones.lua
  Addon-side exploration milestones (not Blizzard achievements). They count
  only the player's own discoveries and verifications, celebrate progress with
  a notification, and can be turned off in Settings > Journal.

  With account-wide progress the milestones belong to the account; with
  progress per character every character unlocks its own. A character's
  first check fills in what it had reached before, without toasts.
]]

local _, FC = ...

local Milestones = FC:NewModule("Milestones")

local U = FC.Utils

Milestones.list = {
    { id = "first", label = "MS_FIRST", desc = "MS_FIRST_DESC", icon = "Interface\\Icons\\INV_Misc_Map_01", goal = 1, stat = "personal" },
    { id = "ten", label = "MS_TEN", desc = "MS_TEN_DESC", icon = "Interface\\Icons\\INV_Misc_Book_09", goal = 10, stat = "personal" },
    { id = "fifty", label = "MS_FIFTY", desc = "MS_FIFTY_DESC", icon = "Interface\\Icons\\INV_Misc_Book_11", goal = 50, stat = "personal" },
    { id = "explorer", label = "MS_EXPLORER", desc = "MS_EXPLORER_DESC", icon = "Interface\\Icons\\INV_Misc_Spyglass_03", goal = 10, stat = "zones" },
    { id = "rarehunter", label = "MS_RAREHUNTER", desc = "MS_RAREHUNTER_DESC", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01", goal = 5, stat = "rares" },
    { id = "cartographer", label = "MS_CARTOGRAPHER", desc = "MS_CARTOGRAPHER_DESC", icon = "Interface\\Icons\\INV_Misc_Map_02", goal = 15, stat = "secrets" },
    { id = "archivist", label = "MS_ARCHIVIST", desc = "MS_ARCHIVIST_DESC", icon = "Interface\\Icons\\INV_Scroll_03", goal = 10, stat = "verified" },
    { id = "bestiary", label = "MS_BESTIARY", desc = "MS_BESTIARY_DESC", icon = "Interface\\Icons\\Ability_Hunter_Pet_Wolf", goal = 50, stat = "creatures" },
    { id = "scout", label = "MS_SCOUT", desc = "MS_SCOUT_DESC", icon = "Interface\\Icons\\INV_Scroll_04", goal = 10, stat = "recipes" },
}

--- Counts the own contributions of some of your characters ({ [key] = true };
--- by default those of the progress mode: the character you play, or all of
--- them) in a single pass. Your discoveries count when one of them found it;
--- a guild member's find counts once one of them confirmed it.
function Milestones:Progress(keys)
    local store = FC.Store
    keys = keys or FC.Progress:Scope()
    local p = { personal = 0, zones = 0, rares = 0, secrets = 0, verified = 0, recipes = 0, creatures = 0 }
    local zones = {}
    for _, rec in store:Iterate() do
        if store:IsMine(rec) then
            if FC.Progress:FoundByAny(rec, keys) then
                p.personal = p.personal + 1
                local zone = rec.z or rec.m
                if zone and not zones[zone] then
                    zones[zone] = true
                    p.zones = p.zones + 1
                end
                if rec.t == "rare" then p.rares = p.rares + 1 end
                if rec.t == "creature" then p.creatures = p.creatures + 1 end
                local group = FC.Categories:Get(rec.t).group
                if group == "secrets" or rec.t == "note" then p.secrets = p.secrets + 1 end
                if rec.t == "recipe" or rec.t == "profession" or rec.t == "trainer" then p.recipes = p.recipes + 1 end
            end
        elseif rec.ver then
            for key in pairs(keys) do
                if rec.ver[key] then
                    p.verified = p.verified + 1
                    break
                end
            end
        end
    end
    return p
end

-- The unlocked milestones of the progress mode, { [id] = time }: the
-- account's, or the character's (created on demand; the second value tells
-- that it was just created).
local function unlockedTable(create)
    local store = FC.Store
    if not store:PerCharacter() then return FC.db.milestones, false end
    local list, key = FC.db.charMilestones, store.me
    if list[key] or not create then return list[key], false end
    list[key] = {}
    return list[key], true
end

--- When a milestone was unlocked in the current progress mode, or nil.
function Milestones:UnlockedAt(id)
    local unlocked = unlockedTable(false)
    return unlocked and unlocked[id] or nil
end

function Milestones:Evaluate(silent)
    if not FC.P.milestones.enabled then return end
    local progress = self:Progress()
    local unlocked, fresh = unlockedTable(true)
    for _, ms in ipairs(self.list) do
        if not unlocked[ms.id] and (progress[ms.stat] or 0) >= ms.goal then
            unlocked[ms.id] = U.Now()
            -- a character's first check only fills in what it had reached before
            if not (silent or fresh) then FC.Bus:Emit("MILESTONE_UNLOCKED", ms) end
        end
    end
end

function Milestones:OnEnable()
    local function evaluateSoon() U.Debounce("milestones", 2, function() self:Evaluate() end) end
    FC.Bus:On("DISCOVERY_ADDED", self, function(_, _, source)
        if source == "local" or source == "auto" then evaluateSoon() end
    end)
    FC.Bus:On("DISCOVERY_VERIFIED", self, function(_, _, _, source)
        if source == "local" or source == "auto" then evaluateSoon() end
    end)
    -- a find of another of your characters counts once this one comes across it
    FC.Bus:On("DISCOVERY_STATE", self, evaluateSoon)
    FC.Bus:On("PROGRESS_MODE_CHANGED", self, function() self:Evaluate(true) end)
    U.After(5, function() self:Evaluate() end)
end
