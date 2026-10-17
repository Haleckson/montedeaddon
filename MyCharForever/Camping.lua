local addonName, MCF = ...
-- Camping (new in WoW Forever): campfires with profession objects give group buffs that
-- look like class buffs; the Camp Tent grants rested XP and a "Boosted Rest" debuff.
--
-- We do not know the spell names/ids of these buffs in advance, so a buff counts as a camp buff if
--   1. its name contains one of CAMP_WORDS (object names, "camp", "rest" wording), or
--   2. its spell id was taught with `/mcf camp learn` (stand at a campfire and run it once).
-- Stored per character in MyCharForeverDB.camping:
--   seen    = {[key]=name}  every distinct camp buff ever active
--   learned = {[spellId]=name}
--   maxAtOnce = most camp buffs active at the same moment
--   tent    = times the "Boosted Rest" debuff started

local Readable = MCF.Readable or function(v) return v end
local SCAN_DELAY = 1.5 -- UNIT_AURA fires very often; a scan walks all auras

-- Seen in game (German client): "Lagerfeuer in der Nähe" (1283391) and "Lagervorteile" (1229741) are
-- presence markers of the campfire itself, not buffs of a camp object. They count as a campfire
-- visit, never as a camp buff (otherwise a bare campfire already looks like a stocked camp).
local PRESENCE_IDS = {[1283391] = true, [1229741] = true}
local PRESENCE_WORDS = {"lagerfeuer in der nähe", "campfire nearby", "nearby campfire", "lagervorteile", "camp benefits"}
local VISIT_GAP = 600
local CAMP_WORDS = {
    "mana well", "manaquelle", "sharpening wheel", "schleifstein",
    "enchanted lute", "verzauberte laute", "first aid kit", "erste-hilfe-set", "fish bowl", "fischglas",
    "incense candle", "räucherkerze", "lodestone", "camp chair", "lagerstuhl", "faction banner", "fraktionsbanner",
    "cookie's feast", "camp tent", "lagerzelt",
}
local TENT_WORDS = {"boosted rest", "verstärkte ruhe"}

local function Store()
    local db = MyCharForeverDB
    if type(db) ~= "table" then return nil end
    db.camping = db.camping or {}
    local c = db.camping
    c.seen = c.seen or {}; c.learned = c.learned or {}
    c.maxAtOnce = c.maxAtOnce or 0; c.tent = c.tent or 0; c.visits = c.visits or 0
    return c
end

-- All helpful auras of the player as {name, id}; secret values are skipped.
local function PlayerAuras(filter)
    local out = {}
    if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return out end
    for i = 1, 80 do
        local ok, a = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, filter or "HELPFUL")
        if not ok or type(a) ~= "table" then break end
        local name, id = Readable(a.name), Readable(a.spellId)
        if type(name) == "string" and name ~= "" then out[#out + 1] = {name = name, id = tonumber(id)} end
    end
    return out
end

local function HasWordPlain(name, words)
    name = name:lower()
    for _, w in ipairs(words) do if name:find(w, 1, true) then return true end end
    return false
end
local function HasWord(name, words)
    name = name:lower()
    for _, w in ipairs(words) do if name:find(w, 1, true) then return true end end
    return false
end

local function IsPresence(a)
    return (a.id and PRESENCE_IDS[a.id]) or HasWordPlain(a.name, PRESENCE_WORDS)
end

local function IsCamp(c, a)
    if IsPresence(a) then return false end
    return (a.id and c.learned[a.id] ~= nil) or HasWord(a.name, CAMP_WORDS)
end

local tentActive = false
local lastVisit = nil
local function Scan()
    local c = Store(); if not c then return end
    local active, n, present = {}, 0, false
    for _, a in ipairs(PlayerAuras("HELPFUL")) do
        if IsPresence(a) then present = true end
        if IsCamp(c, a) then
            local key = a.id and tostring(a.id) or a.name
            if not active[key] then active[key] = true; n = n + 1 end
            c.seen[key] = a.name
        end
    end
    if n > c.maxAtOnce then c.maxAtOnce = n end
    if present then
        local now = GetTime()
        if not c.presenceActive and (not lastVisit or now - lastVisit > VISIT_GAP) then c.visits = (c.visits or 0) + 1 end
        lastVisit = now
    end
    c.presenceActive = present
    -- Boosted Rest is a debuff
    local tent = false
    for _, a in ipairs(PlayerAuras("HARMFUL")) do if HasWord(a.name, TENT_WORDS) then tent = true end end
    if tent and not tentActive then c.tent = c.tent + 1 end
    tentActive = tent
end

local pending = false
local frame = CreateFrame("Frame")
pcall(function() frame:RegisterUnitEvent("UNIT_AURA", "player") end)
frame:SetScript("OnEvent", function()
    if pending then return end
    pending = true
    C_Timer.After(SCAN_DELAY, function()
        pending = false
        if InCombatLockdown and InCombatLockdown() then return end -- camp buffs are not gained in combat
        pcall(Scan)
    end)
end)

function MCF:GetCampingSummary()
    local c = Store() or {seen = {}, maxAtOnce = 0, tent = 0, visits = 0}
    local n = 0
    for _ in pairs(c.seen) do n = n + 1 end
    return {distinct = n, maxAtOnce = c.maxAtOnce, tent = c.tent, visits = c.visits or 0}
end

local function Say(msg) print("|cff00ccffMyCharForever|r: " .. msg) end
MCF:AddCommand{group="debug", usage="/mcf camp [learn|reset]", example="/mcf camp learn",
    match=function(msg) return msg=="camp" or msg:match("^camp%s+%a+$")~=nil end,
    de="Camping-Buffs prüfen; 'learn' merkt die aktuellen Buffs am Lagerfeuer als Camping-Buffs, 'reset' vergisst sie",
    en="Check camping buffs; 'learn' remembers your current buffs at a campfire as camp buffs, 'reset' forgets them",
    run=function(msg)
        local c = Store(); if not c then return end
        local arg = (msg or ""):lower():gsub("^camp%s*","")
        if arg:find("reset") then wipe(c.learned); wipe(c.seen); c.maxAtOnce = 0; c.visits = 0; Say("camping data cleared"); return end
        local list = PlayerAuras("HELPFUL")
        if arg:find("learn") then
            local n = 0
            for _, a in ipairs(list) do
                if a.id and not c.learned[a.id] and not IsPresence(a) then
                    c.learned[a.id] = a.name; n = n + 1
                    Say("  learned: " .. a.name .. " (" .. a.id .. ")")
                end
            end
            Say(n .. " buffs learned as camp buffs. Only use this while you have no other buffs (food, tracking ...); '/mcf camp reset' undoes it.")
            Scan(); return
        end
        Scan()
        for _, a in ipairs(list) do
            Say((IsPresence(a) and "[campfire] " or IsCamp(c, a) and "[camp] " or "       ") .. a.name .. " (" .. tostring(a.id) .. ")")
        end
        local s = MCF:GetCampingSummary()
        Say("distinct " .. s.distinct .. ", max at once " .. s.maxAtOnce .. ", tent " .. s.tent .. ", visits " .. s.visits)
    end}

-- One-time cleanup: version 0.14.0 counted the campfire presence markers as camp buffs and could
-- unlock the camp achievements too easily. Start those counters and unlocks fresh.
local migrate = CreateFrame("Frame")
migrate:RegisterEvent("PLAYER_LOGIN")
migrate:SetScript("OnEvent", function()
    local c = Store(); if not c or c.version == 2 then return end
    c.version = 2
    wipe(c.seen); wipe(c.learned); c.maxAtOnce = 0; c.visits = 0
    local ach = MyCharForeverDB.achievements
    if ach and ach.unlocked then
        for _, id in ipairs({"camp_1", "camp_4", "camp_8", "camp_variety", "camp_max"}) do ach.unlocked[id] = nil end
    end
end)
