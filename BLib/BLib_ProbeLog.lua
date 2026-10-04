-- BLib_ProbeLog.lua
-- Probe output that survives without copy and paste.
--
-- A probe prints to chat, and a measurement made in a dungeon is only useful if it gets out of the game. Copying it means
-- scrolling a chat window mid-run. The game writes an addon's saved variables at /reload or logout, and the files can be
-- read from disk afterwards, so the answer is to keep what a probe printed in the addon's own saved variables as well.
--
--   BLib.ProbeLog.Wrap(slashName, dbName, opts)
--       slashName   the key in SlashCmdList ("LIFELINE")
--       dbName      the name of the addon's saved variable table, as a string ("LifelineDB"); made if it is not there
--       opts.words  the words that make a command a probe, default { "probe" }: a command containing one is recorded
--       opts.always record every command of this slash (an addon that IS a probe)
--
-- While a matching command runs, every line any addon prints to a chat frame is copied into
-- <db>.probeLog[n] = { when, cmd, context, lines }, colour codes removed. The lines the command prints at once are all
-- its own (a Lua call cannot be interrupted by chat). For LATE seconds after, lines that arrive (a timer, an event) are
-- kept too, marked "(later)", except chat from players. context says where and in what state the player was: the zone,
-- the instance type, the group size, whether in combat, level and class, because a probe's answer depends on them.
-- The last KEEP_RUNS runs are kept, each at most KEEP_LINES lines.
--
-- Written to the file when the game saves (/reload or logout), not before.

BLib = BLib or {}
local P = { wrapped = {}, wanted = {} }
BLib.ProbeLog = P

local KEEP_RUNS, KEEP_LINES, LATE = 40, 300, 8

local hooked = {}
local capture   -- the run being recorded: { run, sync, untilT }

local function Plain(v)
    if v ~= nil and issecretvalue and issecretvalue(v) then return nil end
    return v
end

local function Strip(text)
    text = tostring(text)
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", ""):gsub("|H.-|h(.-)|h", "%1"):gsub("|n", "\n")
    return (text)
end

local function Add(text)
    local c = capture
    if not c then return end
    text = Plain(text)
    if type(text) ~= "string" then return end
    if not c.sync then
        if GetTime() > c.untilT then capture = nil return end
        -- A player's chat line is not the probe's.
        if text:find("|Hplayer:", 1, true) or text:find("|Hchannel:", 1, true) then return end
    end
    local lines = c.run.lines
    if #lines >= KEEP_LINES then
        if #lines == KEEP_LINES then lines[#lines + 1] = ("(more than %d lines: the rest is not kept)"):format(KEEP_LINES) end
        return
    end
    lines[#lines + 1] = (c.sync and "" or "(later) ") .. Strip(text)
end

-- Every chat frame, once: the main one, the Addons tab BLib makes, and any other the output might go to.
local function HookFrames()
    local frames = {}
    for i = 1, (NUM_CHAT_WINDOWS or 10) do frames[#frames + 1] = _G["ChatFrame" .. i] end
    frames[#frames + 1] = DEFAULT_CHAT_FRAME
    if BLib.OutputFrame then frames[#frames + 1] = BLib.OutputFrame() end
    for _, frame in ipairs(frames) do
        if frame and not hooked[frame] and frame.AddMessage then
            hooked[frame] = true
            hooksecurefunc(frame, "AddMessage", function(_, text) Add(text) end)
        end
    end
end

local function Context()
    local ctx = {}
    pcall(function()
        ctx.zone = GetRealZoneText and Plain(GetRealZoneText()) or nil
        if IsInInstance then
            local inside, kind = IsInInstance()
            ctx.instance = inside and (kind or "instance") or "none"
        end
        ctx.group = GetNumGroupMembers and GetNumGroupMembers() or 0
        ctx.combat = InCombatLockdown and InCombatLockdown() and true or false
        ctx.level = UnitLevel and UnitLevel("player") or nil
        ctx.class = UnitClass and select(2, UnitClass("player")) or nil
    end)
    return ctx
end

local function Begin(dbName, cmd)
    local db = _G[dbName]
    if db == nil then
        db = {}
        _G[dbName] = db
    end
    if type(db) ~= "table" then return false end
    db.probeLog = type(db.probeLog) == "table" and db.probeLog or {}
    local run = { when = time and time() or 0, cmd = cmd, context = Context(), lines = {} }
    table.insert(db.probeLog, run)
    while #db.probeLog > KEEP_RUNS do table.remove(db.probeLog, 1) end
    HookFrames()
    capture = { run = run, sync = true, untilT = math.huge }
    return true
end

local function End()
    if capture then
        capture.sync = false
        capture.untilT = GetTime() + LATE
    end
end

local function Install(slashName)
    local want = P.wanted[slashName]
    local original = SlashCmdList and SlashCmdList[slashName]
    if not want or not original or P.wrapped[slashName] then return end
    P.wrapped[slashName] = true
    local word = _G["SLASH_" .. slashName .. "1"] or ("/" .. slashName:lower())
    SlashCmdList[slashName] = function(msg, editBox)
        local text = Plain(msg)
        local lower = type(text) == "string" and text:lower() or ""
        local record = want.always
        if not record then
            for _, w in ipairs(want.words) do
                if lower:find(w, 1, true) then record = true break end
            end
        end
        if not (record and Begin(want.db, (word .. " " .. (type(text) == "string" and text or "")):gsub("%s+$", ""))) then
            return original(msg, editBox)
        end
        local ok, err = pcall(original, msg, editBox)
        End()
        if not ok then error(err, 0) end
    end
end

function P.Wrap(slashName, dbName, opts)
    opts = opts or {}
    P.wanted[slashName] = { db = dbName, words = opts.words or { "probe" }, always = opts.always }
    if P.ready then Install(slashName) end
end

-- The slash commands exist by PLAYER_LOGIN (every addon has loaded), so they are wrapped then.
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    P.ready = true
    for slashName in pairs(P.wanted) do Install(slashName) end
end)
