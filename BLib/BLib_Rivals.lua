-- BLib_Rivals.lua
-- Two addons that do the same job cannot both do it: each hides Blizzard's frames and draws its own, and
-- the second to start moves, hides or rebinds what the first just set up. EllesmereUI (a large suite that
-- also runs on Forever, docs/ellesmereui-comparison.md) has a module for most of the jobs our HUD addons
-- do, and players will run both. This is the one place that knows which of its modules does which of our
-- jobs, whether it is on, and what the player has said about it.
--
--   BLib.Rival.Present(job)        the rival's name if its module is on, else nil
--   BLib.Rival.Yield(job)          the rival's name if we should stand aside for it (it is on and the player
--                                  has not chosen ours), else nil. Ask this where the addon STARTS: before it
--                                  hides a Blizzard frame, binds a key or draws.
--   BLib.Rival.Choose(job, "ours") run ours anyway (saved for the account); Choose(job, nil) goes back to
--                                  standing aside
--   BLib.Rival.Chosen(job)         true if the player chose ours
--   BLib.Rival.Notice(job, ours, use)   one chat line per session saying why we stood aside or, when the
--                                  player chose ours, that both are on; `use` is the addon's own command
--
-- "On" means the module's addon is loaded, or (asked before it has loaded, which happens to an addon
-- that starts on ADDON_LOADED) enabled for this character with its parent addon enabled too. The
-- module folders are EllesmereUI's own names, read from its TOC files.

BLib = BLib or {}
local R = {}
BLib.Rival = R

local PARENT = "EllesmereUI"

-- Our job -> the module that does it.
R.JOBS = {
    actionbars  = { folder = "EllesmereUIActionBars",  name = "EllesmereUI Action Bars",
                    what = "replace Blizzard's action bars" },
    bags        = { folder = "EllesmereUIBags",        name = "EllesmereUI Bags",
                    what = "replace Blizzard's bags and bank" },
    groupframes = { folder = "EllesmereUIRaidFrames",  name = "EllesmereUI Raid Frames",
                    what = "replace Blizzard's party and raid frames" },
    unitframes  = { folder = "EllesmereUIUnitFrames",  name = "EllesmereUI Unit Frames",
                    what = "replace Blizzard's player and target frames" },
    -- The folder follows EllesmereUI's naming of its other modules; its TOC has not been read for this one.
    nameplates  = { folder = "EllesmereUINameplates",  name = "EllesmereUI Nameplates",
                    what = "restyle Blizzard's nameplates" },
    -- ClawFrames' party frames are a different job from Lifeline's healer frames, so their own choice.
    partyframes = { folder = "EllesmereUIRaidFrames",  name = "EllesmereUI Raid Frames",
                    what = "replace Blizzard's party frames" },
}

local function Loaded(folder)
    local fn = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    if not fn then return false end
    local ok, loaded = pcall(fn, folder)
    return ok and loaded and true or false
end

-- The character as GetAddOnEnableState knows it: its GUID, which is what Blizzard's own AddOns list passes
-- in game (Blizzard_AddOnList, UpdateDefaultAddOnCharacter). Not UnitName: on Forever it is the first name
-- alone, matches no character, and the answer comes back for all characters, so a module switched off for
-- this character still read as on and our addons stood aside for nothing (the user, 2026-10-02).
local function Character()
    local guid = UnitGUID and UnitGUID("player")
    if type(guid) ~= "string" or (issecretvalue and issecretvalue(guid)) then return nil end
    return guid
end
R.Character = Character

-- Installed, and not switched off for this character.
local function Enabled(folder)
    local api = C_AddOns
    if not (api and api.DoesAddOnExist and api.GetAddOnEnableState) then return false end
    local ok, exists = pcall(api.DoesAddOnExist, folder)
    if not (ok and exists) then return false end
    local ok2, state = pcall(api.GetAddOnEnableState, folder, Character())
    return ok2 and (tonumber(state) or 0) > 0
end

function R.Present(job)
    local def = R.JOBS[job]
    if not def then return nil end
    if Loaded(def.folder) then return def.name end
    if Enabled(def.folder) and (Loaded(PARENT) or Enabled(PARENT)) then return def.name end
    return nil
end

function R.Chosen(job)
    local db = BLibDB and BLibDB.rivals
    return db and db[job] == "ours" or false
end

function R.Choose(job, choice)
    if not R.JOBS[job] then return end
    BLibDB = BLibDB or {}
    BLibDB.rivals = BLibDB.rivals or {}
    BLibDB.rivals[job] = choice == "ours" and "ours" or nil
end

-- A choice of ours lapses once the rival's module is off: it was a choice to run both, and with the
-- rival gone there is nothing to choose between. Left set, the rival's return would find both running
-- and fighting (seen 2026-10-02: "/claw use ours", typed as the old notice said, stuck after EllesmereUI
-- went). So ours runs while the rival is off, and stands aside again by itself when it comes back.
function R.Yield(job)
    local name = R.Present(job)
    if not name then
        if R.Chosen(job) then R.Choose(job, nil) end
        return nil
    end
    if not R.Chosen(job) then return name end
    return nil
end

local told = {}

-- `ours` is our addon's name, `use` the command that flips the choice ("/fb use ours"). Once per job a session.
function R.Notice(job, ours, use)
    local def = R.JOBS[job]
    if not def or told[job] then return end
    local theirs = R.Present(job)
    if not theirs then return end
    told[job] = true
    local text
    if R.Chosen(job) then
        text = ("is running alongside %s, which also wants to %s. Two of them fight over the same frames: "
            .. "turn %s off in the AddOns list at the character screen, then /reload."):format(theirs, def.what, theirs)
    else
        -- Turning theirs off is all it takes: ours comes back by itself (Yield). The old line also said to
        -- type the use command, which read as needed and left a choice behind (2026-10-02).
        text = ("is standing aside because %s is on and would %s too. "
            .. "To use %s instead, turn %s off in the AddOns list and /reload: %s comes back by itself. "
            .. "(%s runs both at once, which fight over the same frames.)"):format(
            theirs, def.what, ours, theirs, ours, use)
    end
    local line = "|cffffd100" .. ours .. "|r " .. text
    if BLib.PrintLine then BLib.PrintLine(line) else print(line) end
end
