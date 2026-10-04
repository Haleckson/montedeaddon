-- LibItemDB scoring rules — WoW The Burning Crusade (2.5.x)
--
-- Every statement about how TBC works lives here; LibItemDB-1.0.lua holds only mechanism and
-- knows nothing about any expansion. ItemDB_TBC.toc loads this file and no other, so a Vanilla
-- client never has these rules in memory — nothing here can change a Classic Era score.
--
-- WHY TBC NEEDS ITS OWN MODULE AT ALL. The two datasets barely share a vocabulary. Surveyed
-- from the shipped Data/<Version>/_core/ files:
--
--   Vanilla has, TBC does not:  CRIT_PCT  HIT_PCT  SPELL_HIT_PCT  DODGE_PCT  PARRY_PCT
--                               BLOCK_PCT  DEFENSE  BLOCK_VALUE  RANGED_HASTE_PCT
--                               WEAPON_SKILL_* (40 items)  AMMO_DAMAGE  WEAPON_SPEED
--   TBC has, Vanilla does not:  ITEM_MOD_*_RATING (14 keys, 6,000+ items) and
--                               EMPTY_SOCKET_* (2,687 items)
--
-- TBC replaced Vanilla's flat percentages with the COMBAT RATING system, so a TBC weight scale
-- is priced per RATING POINT, not per percent. Gear stats therefore need no conversion — the
-- rating key on the item is the key the scale weights. Conversion is only needed the other way,
-- for the handful of flat percentages that reach us from on-equip spell auras (build-equip-stats
-- reads auras 52/54/55 and emits CRIT_PCT / HIT_PCT / SPELL_HIT_PCT in every expansion). Those
-- fold onto the matching rating via `derived` below.
--
-- See LibItemDB-1.0.lua's "Scoring rules contract" comment for the shape registered at the end.

local lib = LibStub and LibStub("LibItemDB-1.0", true)
if not lib then return end

-- ---------------------------------------------------------------------------
-- Combat rating conversions at level 70
-- ---------------------------------------------------------------------------
-- Sourced, not remembered — WoWSims TBC (MIT, github.com/wowsims/tbc), whose
-- sim/core/base_stats_auto_gen.go is generated from game data:
--     DefenseRatingPerDefenseLevel          = 2.365385
--     DodgeRatingPerDodgePercent            = 18.923079
--     ParryRatingPerParryPercent            = 23.653847
--     BlockRatingPerBlockPercent            =  7.884615
--     PhysicalHitRatingPerHitPercent        = 15.769233
--     SpellHitRatingPerHitPercent           = 12.615385
--     PhysicalCritRatingPerCritPercent      = 22.076923
--     SpellCritRatingPerCritPercent         = 22.076923
--     PhysicalHasteRatingPerHastePercent    = 15.769233
--     SpellHasteRatingPerHastePercent       = 15.76923
--     ExpertisePerQuarterPercentReduction   =  3.942308   (sim/core, unused below — see note)
-- and sim/core/constants.go:
--     ResilienceRatingPerCritReductionChance = 39.4231
--     CharacterLevel = 70
-- These are level-70 values. TBC's rating curve scales with level, so they are correct for the
-- level cap (what gear scoring is for) and increasingly wrong below it — a levelling consumer
-- should not read EP as exact.
local RATING_PER_PERCENT = {
    CRIT        = 22.076923,
    SPELL_CRIT  = 22.076923,
    HIT         = 15.769233,
    SPELL_HIT   = 12.615385,
    HASTE       = 15.769233,
    SPELL_HASTE = 15.76923,
    DODGE       = 18.923079,
    PARRY       = 23.653847,
    BLOCK       =  7.884615,
    DEFENSE     =  2.365385,   -- rating per point of defense SKILL, not per percent
}

-- ---------------------------------------------------------------------------
-- Stat vocabulary
-- ---------------------------------------------------------------------------
-- Fold the data's spelling onto the key the weight scales carry. TBC ships crit and hit in
-- both a generic and a school/attack-specific form; a scale prices the generic, so the
-- specific variants fold onto it. Without this, the 393 items carrying ITEM_MOD_CRIT_MELEE_RATING
-- and the 393 carrying ITEM_MOD_CRIT_RANGED_RATING would each score 0.
local ALIAS = {
    -- attack-type-specific crit -> generic crit rating
    ITEM_MOD_CRIT_MELEE_RATING  = "ITEM_MOD_CRIT_RATING",
    ITEM_MOD_CRIT_RANGED_RATING = "ITEM_MOD_CRIT_RATING",
    ITEM_MOD_HIT_MELEE_RATING   = "ITEM_MOD_HIT_RATING",
    ITEM_MOD_HIT_RANGED_RATING  = "ITEM_MOD_HIT_RATING",
    ITEM_MOD_HASTE_MELEE_RATING = "ITEM_MOD_HASTE_RATING",
    ITEM_MOD_HASTE_RANGED_RATING = "ITEM_MOD_HASTE_RATING",
    -- attack power spellings, as in Vanilla
    ITEM_MOD_ATTACK_POWER = "ITEM_MOD_ATTACK_POWER_SHORT",
    ITEM_MOD_MELEE_ATTACK_POWER_SHORT = "ITEM_MOD_ATTACK_POWER_SHORT",
    ITEM_MOD_RANGED_ATTACK_POWER = "ITEM_MOD_RANGED_ATTACK_POWER_SHORT",
    -- mp5 / healing spellings
    ITEM_MOD_MANA_REGENERATION = "ITEM_MOD_POWER_REGEN0_SHORT",
    ITEM_MOD_SPELL_HEALING_DONE_SHORT = "ITEM_MOD_SPELL_HEALING_DONE",
    -- TBC still separates spell damage from healing (the unified "spell power" is Wrath), and
    -- effects/procs report spell damage as ITEM_MOD_SPELL_POWER — same fold as Vanilla.
    ITEM_MOD_SPELL_POWER = "ITEM_MOD_SPELL_DAMAGE_DONE",
    FERAL_ATTACK_POWER = "ITEM_MOD_ATTACK_POWER_SHORT",
    -- Flat pools are weighted DIRECTLY on TBC (HawsJon carries Health/Mana weights), so gear's
    -- spelling folds onto the consumable spelling rather than being derived from Stamina/Int.
    ITEM_MOD_HEALTH_SHORT = "HEALTH",
    ITEM_MOD_MANA_SHORT   = "MANA",
}

-- Weapon DPS is one stat in our data but weighted per hand; pick by equip slot. Unchanged
-- from Vanilla — the slot tokens and the per-hand weighting are not expansion-specific.
local DPS_SLOT = {
    INVTYPE_WEAPONMAINHAND = "DPS_MAINHAND", INVTYPE_2HWEAPON = "DPS_MAINHAND",
    INVTYPE_WEAPON = "DPS_MAINHAND", INVTYPE_WEAPONOFFHAND = "DPS_OFFHAND",
    INVTYPE_HOLDABLE = "DPS_OFFHAND", INVTYPE_SHIELD = "DPS_OFFHAND",
    INVTYPE_RANGED = "DPS_RANGED", INVTYPE_RANGEDRIGHT = "DPS_RANGED",
    INVTYPE_THROWN = "DPS_RANGED",
}

-- Generic "+X Attack Power" is stored as a melee and a ranged boost because it raises both
-- in game; a class only attacks one way, so take the better rather than summing. Same rule
-- as Vanilla — TBC did not change how generic AP is stored or used.
local AP_PAIR = {
    melee  = "ITEM_MOD_ATTACK_POWER_SHORT",
    ranged = "ITEM_MOD_RANGED_ATTACK_POWER_SHORT",
}

-- Keys no TBC weight scale prices directly, valued through one it does.
-- `per` reads as "this many units of the key equal one unit of the weighted stat".
--
--  * Flat percentages from on-equip spell auras. build-equip-stats.py decodes auras 52/54/55
--    into CRIT_PCT / HIT_PCT / SPELL_HIT_PCT in EVERY expansion, but a TBC scale is keyed by
--    rating — so 1% crit is priced as 22.076923 crit rating (per = 1/22.076923). Without this
--    those auras would silently score 0 on TBC while scoring correctly on Vanilla.
-- Flat HP / mana pools are NOT here, unlike Vanilla: HawsJon's TBC scale carries `Health` and
-- `Mana` weights directly, so `HEALTH` / `MANA` are priced straight from the scale and deriving
-- them from Stamina/Intellect would override the real weight with an approximation. The two
-- agree anyway — HawsJon's Health=0.01 is exactly Stamina 0.1 / 10 HP-per-point — which is a
-- useful cross-check on Vanilla's derivation.
local DERIVED = {
    CRIT_PCT       = { stat = "ITEM_MOD_CRIT_RATING",       per = 1 / RATING_PER_PERCENT.CRIT },
    SPELL_CRIT_PCT = { stat = "ITEM_MOD_CRIT_SPELL_RATING", per = 1 / RATING_PER_PERCENT.SPELL_CRIT },
    HIT_PCT        = { stat = "ITEM_MOD_HIT_RATING",        per = 1 / RATING_PER_PERCENT.HIT },
    SPELL_HIT_PCT  = { stat = "ITEM_MOD_HIT_SPELL_RATING",  per = 1 / RATING_PER_PERCENT.SPELL_HIT },
    DODGE_PCT      = { stat = "ITEM_MOD_DODGE_RATING",      per = 1 / RATING_PER_PERCENT.DODGE },
    PARRY_PCT      = { stat = "ITEM_MOD_PARRY_RATING",      per = 1 / RATING_PER_PERCENT.PARRY },
    BLOCK_PCT      = { stat = "ITEM_MOD_BLOCK_RATING",      per = 1 / RATING_PER_PERCENT.BLOCK },
    DEFENSE        = { stat = "ITEM_MOD_DEFENSE_SKILL_RATING", per = 1 / RATING_PER_PERCENT.DEFENSE },
}

-- ---------------------------------------------------------------------------
-- Gem sockets — a TBC mechanic Vanilla has no concept of
-- ---------------------------------------------------------------------------
-- 2,687 TBC items carry an EMPTY_SOCKET_* count. A socket is worth whatever you put in it, so
-- ignoring them under-values every socketed item; the honest valuation is the BEST GEM that
-- fits, under the same weights the item itself is being scored with. That is spec-dependent by
-- construction — a red socket is worth a Bold Living Ruby to a warrior and a Runed one to a
-- mage — which is why it is computed here at score time rather than baked into the data.
--
-- Gem facts come from Pawn (CC BY-NC, github.com/VgerMods/Pawn) via tools/build-gems.py, already
-- mapped into our key space, so a gem's stats price with a plain weight lookup.
--   R / Y / B  a gem fits those socket colours (several for a hybrid gem)
--   M          a meta gem; only a meta socket takes it
-- A PRISMATIC socket takes any colour. Socket BONUSES (the item's "matching colours" reward) are
-- NOT modelled: honouring one means choosing off-colour gems to chase it, which is a gearing
-- decision, not an item fact — so this is an upper bound on socket value, stated rather than hidden.
local SOCKET_COLOUR = {
    EMPTY_SOCKET_RED = "R", EMPTY_SOCKET_YELLOW = "Y", EMPTY_SOCKET_BLUE = "B",
    EMPTY_SOCKET_META = "M", EMPTY_SOCKET_PRISMATIC = "*",
}

-- best[weights][colour] = EP of the best-scoring gem for that colour. Cached per weight table:
-- GetSlotRanking over thousands of items would otherwise re-scan every gem for every socket.
local bestGemCache = setmetatable({}, { __mode = "k" })

local function bestGemEP(w, colour)
    local byColour = bestGemCache[w]
    if not byColour then
        byColour = {}
        for _, gem in pairs(lib:GetGems()) do
            local ep = 0
            for k, v in pairs(gem.stats) do ep = ep + v * (w[k] or 0) end
            if ep > 0 then
                local fits = gem.colours
                if fits == "M" then
                    if ep > (byColour.M or 0) then byColour.M = ep end
                else
                    for c in fits:gmatch("%a") do
                        if ep > (byColour[c] or 0) then byColour[c] = ep end
                    end
                    if ep > (byColour["*"] or 0) then byColour["*"] = ep end
                end
            end
        end
        bestGemCache[w] = byColour
    end
    return byColour[colour] or 0
end

local function scoreSockets(stats, w, _opts, parts)
    if not next(lib.gems) then return 0 end
    local total = 0
    for key, colour in pairs(SOCKET_COLOUR) do
        local n = stats[key]
        if n and n > 0 then
            local ep = bestGemEP(w, colour) * n
            if ep > 0 then
                total = total + ep
                if parts then
                    parts[#parts + 1] = { kind = "socket", key = key, value = n, ep = ep,
                        factors = { { label = "sockets", value = n },
                                    { label = "best gem", value = ep / n } } }
                end
            end
        end
    end
    return total
end

-- Keys the flat walk must not price.
--  * EMPTY_SOCKET_* is a gem SLOT, not a stat — its value is whatever you socket, so a flat
--    weight would be inventing a number. It is kept out of the FLAT walk because `scoreSockets`
--    above prices it SEPARATELY, at bestGemEP x the socket count, emitting its own
--    { kind = "socket" } breakdown row. This paragraph used to say sockets contribute 0 and
--    that closing the gap meant adding a scorer here; that was true before scoreSockets existed
--    and has been false since, and a comment describing a live branch as absent is exactly what
--    sends the next reader hunting for a gap that already closed (Peer Review, 2026-09-21).
--  * WEAPON_SKILL_* / AMMO_DAMAGE / WEAPON_SPEED never appear in the TBC dataset, but they are
--    listed so a stray key from a shared builder can never be priced as a flat stat by accident.
local SKIP_PREFIX = { "WEAPON_SKILL_", "EMPTY_SOCKET_" }
local SKIP_KEYS   = { AMMO_DAMAGE = true, WEAPON_SPEED = true, ITEM_MOD_CR_UNUSED_0 = true }

-- ---------------------------------------------------------------------------
-- The stats a TBC weight scale can set, in display order
-- ---------------------------------------------------------------------------
-- Priced per RATING POINT for everything TBC made a rating. A weight editor renders one input
-- per entry; note there is no weapon-skill block (a Vanilla mechanic) and no flat crit/hit/haste
-- percentages — offering those on TBC would be offering sliders the data can never populate.
local WEIGHT_STATS = {
    { key = "ITEM_MOD_STRENGTH_SHORT",            label = "Strength" },
    { key = "ITEM_MOD_AGILITY_SHORT",             label = "Agility" },
    { key = "ITEM_MOD_STAMINA_SHORT",             label = "Stamina" },
    { key = "ITEM_MOD_INTELLECT_SHORT",           label = "Intellect" },
    { key = "ITEM_MOD_SPIRIT_SHORT",              label = "Spirit" },
    { key = "ITEM_MOD_ATTACK_POWER_SHORT",        label = "Attack Power" },
    { key = "ITEM_MOD_RANGED_ATTACK_POWER_SHORT", label = "Ranged Attack Power" },
    { key = "ITEM_MOD_SPELL_DAMAGE_DONE",         label = "Spell Damage" },
    { key = "ITEM_MOD_SPELL_HEALING_DONE",        label = "Healing Power" },
    { key = "ITEM_MOD_SPELL_PENETRATION",         label = "Spell Penetration" },
    { key = "ITEM_MOD_POWER_REGEN0_SHORT",        label = "MP5" },
    { key = "ITEM_MOD_HIT_RATING",                label = "Hit Rating" },
    { key = "ITEM_MOD_CRIT_RATING",               label = "Crit Rating" },
    { key = "ITEM_MOD_HASTE_RATING",              label = "Haste Rating" },
    { key = "ITEM_MOD_EXPERTISE_RATING",          label = "Expertise Rating" },
    { key = "ITEM_MOD_HIT_SPELL_RATING",          label = "Spell Hit Rating" },
    { key = "ITEM_MOD_CRIT_SPELL_RATING",         label = "Spell Crit Rating" },
    { key = "ITEM_MOD_HASTE_SPELL_RATING",        label = "Spell Haste Rating" },
    { key = "ITEM_MOD_DEFENSE_SKILL_RATING",      label = "Defense Rating" },
    { key = "ITEM_MOD_DODGE_RATING",              label = "Dodge Rating" },
    { key = "ITEM_MOD_PARRY_RATING",              label = "Parry Rating" },
    { key = "ITEM_MOD_BLOCK_RATING",              label = "Block Rating" },
    { key = "ITEM_MOD_RESILIENCE_RATING",         label = "Resilience Rating" },
    { key = "RESISTANCE0_NAME",                   label = "Armor" },
    { key = "DPS_MAINHAND",                       label = "Main-hand Weapon DPS" },
    { key = "DPS_OFFHAND",                        label = "Off-hand Weapon DPS" },
    { key = "DPS_RANGED",                         label = "Ranged Weapon DPS" },
}

-- Breakdown labels for rows that are not weightable keys.
local LABELS = {
    HEALTH = "Health", MANA = "Mana",
    ITEM_MOD_HEALTH_SHORT = "Health", ITEM_MOD_MANA_SHORT = "Mana",
    EMPTY_SOCKET_RED = "Red socket", EMPTY_SOCKET_YELLOW = "Yellow socket",
    EMPTY_SOCKET_BLUE = "Blue socket", EMPTY_SOCKET_META = "Meta socket",
    EMPTY_SOCKET_PRISMATIC = "Prismatic socket",
}

-- Scoring-model constants. Same shape as Vanilla's; kept separate because the tuning is
-- per-expansion — a proc rate or on-use premium calibrated for Vanilla is not TBC's. These
-- carry Vanilla's values as a starting point and are superseded per class the moment
-- Data/TBC/_core/ScoreModel.lua ships (build-score-model.py TBC).
-- epPerHPS: see the derivation above Vanilla's MODEL. 3.5 healing power per 1 HPS, from the
-- direct-spell coefficient castTime / 3.5, which TBC keeps. It was 0 here too until 2026-08-17
-- (docs/AUDIT.md finding 7) and that zeroed every heal proc in this flavour as well.
local MODEL = { usePremium = 1.3, hitsPerSec = 0.5, epPerRawDPS = 3.5, epPerHPS = 3.5 }

-- statScorers: sockets (TBC's own, above) and ammo (the core's `lib.StatScorers.ammo`). NOT
-- weapon skill: a Vanilla-only stat, absent from every TBC item, and an expansion simply not
-- having a mechanic is expressed by not registering a scorer for it — the core sums what is
-- registered. Until 2026-09-17 this comment also excluded ammo, claiming AMMO_DAMAGE "is not
-- captured in the TBC walk". It never came from the walk: build-equip-stats.py reads it from
-- wago ItemSparse, Data/TBC/_core/EquipStats.lua carries 63 ammo rows, and every TBC hunter's
-- ammo scored 0 on the strength of that comment (Dibs' DIBSREQ-IDB-003).
-- Weight-scale keys the proc scorer reads; see the block above Vanilla's for why these are
-- declared per expansion rather than hardcoded in the core (docs/AUDIT.md finding 10). TBC's
-- spellings happen to match Vanilla's -- healing is still its own key here and does not merge
-- into spell power until Wrath -- so this table is a copy today and is NOT redundant: it is the
-- declaration that makes the match deliberate rather than inherited.
local PROC_KEYS = {
    dpsMain     = "DPS_MAINHAND",
    dpsRanged   = "DPS_RANGED",
    spellDamage = "ITEM_MOD_SPELL_DAMAGE_DONE",
    healing     = "ITEM_MOD_SPELL_HEALING_DONE",
    mana        = "ITEM_MOD_POWER_REGEN0_SHORT",
}

-- School-conditional keys -- docs/AUDIT.md finding 20. Same reasoning as PROC_KEYS directly
-- above, including why an identical copy is the right shape: TBC still keeps spell damage and
-- healing as separate keys, and stating that here is what makes the match a decision.
--
-- TBC IS WHERE THIS MATTERS MOST. Vanilla's school-specific items are a handful of caster
-- off-hands; TBC ships whole school-tagged sets, so a shadow priest scoring a +Fire piece at
-- full spell-damage EP is a routine mis-rank rather than an edge case.
local SCHOOL_GATED = {
    ITEM_MOD_SPELL_DAMAGE_DONE = true,
}

lib:RegisterScoring({
    name        = "TBC",
    alias       = ALIAS,
    schoolGated = SCHOOL_GATED,
    dpsSlot     = DPS_SLOT,
    apPair      = AP_PAIR,
    procKeys    = PROC_KEYS,
    derived     = DERIVED,
    skipPrefix  = SKIP_PREFIX,
    skipKeys    = SKIP_KEYS,
    weightStats = WEIGHT_STATS,
    labels      = LABELS,
    model       = MODEL,
    statScorers = { scoreSockets, lib.StatScorers.ammo },
})
