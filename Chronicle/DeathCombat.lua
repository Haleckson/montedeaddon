local C = _G.Chronicle

local environmentalCauses = {
    DROWNING = "Ertrinken", FALLING = "Sturz", FATIGUE = "Erschöpfung",
    FIRE = "Feuer", LAVA = "Lava", SLIME = "Schleim",
}

local hits = {}
local fatalHit

function C:ObserveDeathCombat(kind, sourceName, destGUID, arg12, arg13, arg14, arg15, arg16)
    if kind ~= "SWING_DAMAGE" and kind ~= "SPELL_DAMAGE" and
        kind ~= "SPELL_PERIODIC_DAMAGE" and kind ~= "RANGE_DAMAGE" and
        kind ~= "DAMAGE_SHIELD" and kind ~= "ENVIRONMENTAL_DAMAGE" then return end
    if not destGUID or not UnitGUID or destGUID ~= UnitGUID("player") then return end
    local cause, amount, overkill, spellID
    if kind == "SWING_DAMAGE" then
        cause, amount, overkill = "Nahkampfangriff", arg12, arg13
    elseif kind == "SPELL_DAMAGE" or kind == "SPELL_PERIODIC_DAMAGE" or
        kind == "RANGE_DAMAGE" or kind == "DAMAGE_SHIELD" then
        spellID, cause, amount, overkill = arg12, arg13, arg15, arg16
    elseif kind == "ENVIRONMENTAL_DAMAGE" then
        cause, amount, overkill = environmentalCauses[arg12] or arg12, arg13, arg14
        sourceName = "Umgebung"
    else
        return
    end
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    local hit = {
        time = time(), killer = type(sourceName) == "string" and sourceName or "Umgebung",
        cause = type(cause) == "string" and cause or "Unbekannt",
        damage = amount, spellID = tonumber(spellID), kind = kind,
        fatal = type(overkill) == "number" and overkill >= 0,
    }
    hits[#hits + 1] = hit
    if #hits > 12 then table.remove(hits, 1) end
    if hit.fatal then fatalHit = hit end
end

function C:ConsumeDeathCombat(now)
    now = now or time()
    local recent = {}
    for _, hit in ipairs(hits) do
        if now - hit.time <= 12 then recent[#recent + 1] = hit end
    end
    local decisive = fatalHit and now - fatalHit.time <= 8 and fatalHit or
        (#recent > 0 and now - recent[#recent].time <= 5 and recent[#recent] or nil)
    local log = {}
    for index = math.max(1, #recent - 5), #recent do
        log[#log + 1] = recent[index]
    end
    hits, fatalHit = {}, nil
    if not decisive then return nil end
    return {
        killer = decisive.killer, cause = decisive.cause, damage = decisive.damage,
        spellID = decisive.spellID, combatLog = log,
    }
end

function C:ResetDeathCombat()
    hits, fatalHit = {}, nil
end
