local addonName, MCF = ...
-- Death causes without a combat log. The game gives us no damage events here, so we
-- recognise the causes that leave a trace somewhere else:
--   drowned  - the BREATH mirror timer was running when we died
--   fatigue  - the EXHAUSTION mirror timer was running when we died
--   fall     - we were falling long enough to take damage and died right after landing
--   guard    - the killer found by the Death Recap is a city/zone guard
--   pvp      - the killer is a player
-- The result is stored as `cause` on the death row (levelActivity[level].deaths), on the DEATH
-- event and counted in db.combat.deathCauses / levelActivity[level].deathCauses.

local FALL_MIN_SECONDS = 1.2   -- free fall of ~14.5 yards (damage threshold) at 19.29 y/s^2
local FALL_LETHAL_WINDOW = 1.5 -- death this soon after landing counts as fall death
local POLL = 0.1
local SLOW_FALL_SPELLS = {130, 1706, 111759, 359816} -- Slow Fall, Levitate, ...
local GUARD_WORDS = {"guard", "sentinel", "wache", "wächter", "waechter", "stadtwache", "protector", "peacekeeper",
    "watchman", "defender", "garde", "centinela", "guardia", "stormwind city", "orgrimmar grunt"}

local Readable = MCF.Readable or function(v) return v end

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------
local breath = {active = false}
local fatigue = {active = false}
local fall = {active = false, start = 0, invalid = false, lastEnd = 0, lastDuration = 0, lastValid = false}

local function HasSlowFall()
    if not (C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID) then return false end
    for _, id in ipairs(SLOW_FALL_SPELLS) do
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, id)
        if ok and aura then return true end
    end
    return false
end

local function Mounted() return IsMounted and IsMounted() or false end

local function PollFall()
    local falling = IsFalling and IsFalling() or false
    local now = GetTime()
    if falling then
        if not fall.active then
            fall.active, fall.start, fall.invalid = true, now, false
        end
        -- anything that softens or prevents damage invalidates this fall
        if (IsFlying and IsFlying()) or (IsSwimming and IsSwimming()) or HasSlowFall()
            or (C_PlayerInfo and C_PlayerInfo.GetGlidingInfo and select(1, C_PlayerInfo.GetGlidingInfo())) then
            fall.invalid = true
        end
    elseif fall.active then
        fall.active = false
        fall.lastEnd = now
        fall.lastDuration = now - fall.start
        fall.lastValid = not fall.invalid and fall.lastDuration >= FALL_MIN_SECONDS
    end
end

local poller = CreateFrame("Frame")
local acc = 0
poller:SetScript("OnUpdate", function(_, elapsed)
    acc = acc + elapsed
    if acc < POLL then return end
    acc = 0
    PollFall()
end)

---------------------------------------------------------------------------
-- Classification
---------------------------------------------------------------------------
local function IsGuardName(name)
    if type(name) ~= "string" then return false end
    name = name:lower()
    for _, w in ipairs(GUARD_WORDS) do
        if name:find(w, 1, true) then return true end
    end
    return false
end
MCF.IsGuardName = IsGuardName

local function Count(cause)
    local db = MyCharForeverDB
    if type(db) ~= "table" then return end
    db.combat = db.combat or {}
    db.combat.deathCauses = db.combat.deathCauses or {}
    db.combat.deathCauses[cause] = (db.combat.deathCauses[cause] or 0) + 1
    local a = MCF.GetLevelActivity and MCF:GetLevelActivity(UnitLevel("player"))
    if a then
        a.deathCauses = a.deathCauses or {}
        a.deathCauses[cause] = (a.deathCauses[cause] or 0) + 1
    end
end

local function Uncount(cause)
    local db = MyCharForeverDB
    local c = db and db.combat and db.combat.deathCauses
    if c and c[cause] then c[cause] = math.max(0, c[cause] - 1) end
end

-- Sets the cause on the newest death row/event. `override` lets a stronger finding replace a weaker one.
local function Assign(cause, level, deathTime, override)
    local pending = MCF._pendingMobDeath
    local row
    local a = MCF.GetLevelActivity and MCF:GetLevelActivity(level or UnitLevel("player"))
    if a and a.deaths then
        for i = #a.deaths, 1, -1 do
            local r = a.deaths[i]
            if r.time and deathTime and math.abs(r.time - deathTime) <= 3 then row = r; break end
        end
        if not row then row = a.deaths[#a.deaths] end
    end
    if row then
        if row.cause and not override then return false end
        if row.cause then Uncount(row.cause) end
        row.cause = cause
    end
    if pending and pending.event then pending.event.cause = cause end
    Count(cause)
    return true
end

local function Classify()
    local now = GetTime()
    if breath.active then return "drowned" end
    if fatigue.active then return "fatigue" end
    if fall.active and not fall.invalid and (now - fall.start) >= FALL_MIN_SECONDS then return "fall" end
    if fall.lastValid and (now - fall.lastEnd) <= FALL_LETHAL_WINDOW then return "fall" end
    return nil
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local frame = CreateFrame("Frame")
for _, e in ipairs({"MIRROR_TIMER_START", "MIRROR_TIMER_STOP", "PLAYER_DEAD", "PLAYER_UNGHOST", "PLAYER_ALIVE"}) do
    pcall(function() frame:RegisterEvent(e) end)
end

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "MIRROR_TIMER_START" then
        local timer = Readable((...))
        if timer == "BREATH" then breath.active = true
        elseif timer == "EXHAUSTION" then fatigue.active = true end
    elseif event == "MIRROR_TIMER_STOP" then
        local timer = Readable((...))
        if timer == "BREATH" then breath.active = false
        elseif timer == "EXHAUSTION" then fatigue.active = false end
    elseif event == "PLAYER_DEAD" then
        PollFall() -- the landing may have happened since the last poll
        local cause = Classify()
        local t, lvl = time(), UnitLevel("player")
        -- Core's own PLAYER_DEAD handler creates the row; wait a moment so it exists in any order.
        C_Timer.After(0.2, function()
            if cause then Assign(cause, lvl, t, false) end
        end)
        fall.lastValid = false
        breath.active, fatigue.active = false, false
    end
end)

-- Killer found by the Death Recap: guards and players.
local function HookRecap()
    if type(MCF.RecordDeathRecapKiller) ~= "function" or MCF._deathCauseHooked then return end
    MCF._deathCauseHooked = true
    local orig = MCF.RecordDeathRecapKiller
    MCF.RecordDeathRecapKiller = function(self, name, sourceGUID, ...)
        local pending = self._pendingMobDeath
        local t, lvl = pending and pending.time, pending and pending.level
        local ok = orig(self, name, sourceGUID, ...)
        if ok then
            local guid = Readable(sourceGUID)
            if MCF.OnIconicDeath then pcall(MCF.OnIconicDeath, MCF, name) end
            if IsGuardName(name) then
                Assign("guard", lvl, t, true)
            elseif type(guid) == "string" and guid:find("^Player%-") then
                Assign("pvp", lvl, t, false)
                if MCF.OnPvPDeath then pcall(MCF.OnPvPDeath, MCF, guid) end
            end
        end
        return ok
    end
end
HookRecap()

-- Everything we know about one death, found by its time (the map pin carries the time of the journey point):
-- the death row (killerName, cause) and the screenshot taken for it, if any.
-- Returns killer, causeLabel, screenshotFileName (each may be nil).
function MCF:GetDeathInfo(deathTime)
    local db = MyCharForeverDB
    if type(db) ~= "table" or not deathTime then return nil end
    local row
    for _, a in pairs(db.levelActivity or {}) do
        for _, r in ipairs(a.deaths or {}) do
            if r.time and math.abs(r.time - deathTime) <= 5 then row = r; break end
        end
        if row then break end
    end
    local shot
    for _, s in ipairs(db.screenshots or {}) do
        if s.reason == "DEATH" and s.time and math.abs(s.time - deathTime) <= 20 then shot = s; break end
    end
    local cause = row and row.cause and self:T("Cause " .. row.cause) or nil
    return row and row.killerName, cause, shot and shot.expectedFileName
end

function MCF:GetDeathCauses()
    local c = MyCharForeverDB and MyCharForeverDB.combat and MyCharForeverDB.combat.deathCauses
    return c or {}
end

MCF:AddCommand{group="debug", usage="/mcf deathcause", key="deathcause",
    de="Todesursachen (Ertrinken, Sturz, Wachen ...) anzeigen",
    en="Show death causes (drowning, falls, guards ...)",
    run=function()
        local parts = {}
        for k, v in pairs(MCF:GetDeathCauses()) do parts[#parts + 1] = k .. " " .. v end
        table.sort(parts)
        print("|cff00ccffMyCharForever|r: " .. (#parts > 0 and table.concat(parts, ", ") or "-")
            .. string.format(" | fall: last %.1fs%s, breath=%s", fall.lastDuration or 0, fall.lastValid and " (valid)" or "",
                tostring(breath.active)))
    end}
