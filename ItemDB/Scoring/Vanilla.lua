-- LibItemDB scoring rules — WoW Vanilla (Classic Era / Hardcore / SoD / Anniversary 1.x)
-- AND WoW Forever, which loads this same file. See "Forever shares these rules" below.
--
-- Every statement about how VANILLA works lives here; LibItemDB-1.0.lua holds only mechanism
-- (the stat walk, weight lookup, breakdown rows, set/use/proc plumbing) and knows nothing about
-- any expansion. One TOC loads exactly one of these files, so a Vanilla client never has TBC's
-- rules in memory and vice versa — enriching one expansion cannot regress another.
--
-- See LibItemDB-1.0.lua's "Scoring rules contract" comment for the shape registered below.
--
-- ---------------------------------------------------------------------------
-- Forever shares these rules — deliberately, and with a stated trigger to stop
-- ---------------------------------------------------------------------------
-- ItemDB_Camelot.toc loads THIS file rather than a Scoring/Forever.lua, because every rule
-- stated below is a rule about level-60 Classic combat and Forever is level-60 Classic combat.
-- That is measured, not assumed, and re-measured over EVERY position on 2026-09-22 after an
-- audit found the first pass had generalised from a sample: cross-tabulating the two clients'
-- DB2 Talent + TalentTab, both carry 432 talent positions across the same 27 trees (the
-- earlier note said 367), every position exists in both at an identical class/tab/tier/column,
-- and maxRank differs at NONE of the 432.
--
-- FOREVER IS A RATING SYSTEM AND VANILLA IS NOT, and this paragraph used to say the opposite --
-- "Forever's items carry the same flat-percentage stat keys rather than a rating system" -- which
-- was wrong about the client and is the single most load-bearing sentence in this header. The
-- client settles it without a login: F:\Blizzard API Docs\wow-ui-source-forever declares the full
-- combat-rating index in Blizzard_UIPanels_Game/Camelot/PaperDollFrame.lua (CR_HIT_MELEE,
-- CR_CRIT_MELEE, CR_DEFENSE_SKILL, CR_EXPERTISE, CR_ARMOR_PENETRATION and the rest), and
-- Camelot/PaperDollFrameStats.lua:486 computes melee hit as
-- `GetCombatRatingBonus(CR_HIT_MELEE) + GetHitModifier()` -- the client itself ADDING the percent
-- DERIVED FROM A RATING to the flat percent, because they are different quantities.
--
-- WHY SHARING IS STILL SOUND: the conversion happens in the PIPELINE, not here.
-- build-core-wowsims.py divides each rating by the divisor WoWSims' own sim uses, so what reaches
-- these rules is already a flat percentage and the vocabulary below is written against the right
-- unit. Sharing is sound BECAUSE of that conversion, not because the two games agree -- and that
-- distinction is the thing to keep, since removing the conversion silently makes every rule here
-- wrong rather than making it error.
--
-- A copy was the obvious alternative and was rejected: 335 lines duplicated to say the same
-- thing twice is the "same behaviour implemented more than once" defect, and the copy would
-- start rotting the first time either side was touched.
--
-- THE TRIGGER TO SPLIT, so this does not become permanent by inertia: the first rule that is
-- true of one and false of the other. IT IS NO LONGER HYPOTHETICAL, and this paragraph used to
-- call it "only a hint" on the grounds that the effects behind the renamed talents "have not been
-- compared". They have been, and they differ: reading SpellEffect for every talent spell shared by
-- both shipped Talents.lua files, normalised across the two schemas, 30 of the 32 RENAMED talents
-- differ and -- the finding a name-based reader would never reach -- 265 of the 383 talents whose
-- name is UNCHANGED differ too, 147 of them structurally (a different aura, or a different number
-- of effects). The weapon specialisations these rules lean on are squarely in it: Axe 12700 and
-- Dagger 13706 move from aura 52 to aura 290, Mace 12284 and 13709 from 42 to 280, Rogue Sword
-- 13960 becomes three effects, and only Warrior Sword 12281 is unchanged. So per-weapon-skill
-- valuations on Forever are KNOWN WRONG rather than unverified.
--
-- That is a divergence in the DATA these rules price, not yet in the rules themselves, which is
-- why the file is still shared: splitting it today would produce two identical copies. The split
-- happens when a Forever-tuned scale exists to put in it. Whether Forever should keep serving
-- Classic-tuned scores until then is the operator's open question, and it is a one-line change
-- either way -- drop Scoring\Vanilla.lua from ItemDB_Camelot.toc and HasScoring() goes false.
-- When it is time: copy this file to Scoring/Forever.lua, point the TOC at it, and let the two
-- diverge -- exactly the isolation the one-file-per-expansion rule above exists to provide.

local lib = LibStub and LibStub("LibItemDB-1.0", true)
if not lib then return end

-- ---------------------------------------------------------------------------
-- Stat vocabulary
-- ---------------------------------------------------------------------------
-- The DB's effect/gear data and the weight scales spell some stats differently; fold the
-- data key onto the key the weights actually carry. Without this, mp5 and spell-power
-- consumables score 0 (the scales have no ITEM_MOD_MANA_REGENERATION key at all).
local ALIAS = {
    ITEM_MOD_ATTACK_POWER = "ITEM_MOD_ATTACK_POWER_SHORT",
    ITEM_MOD_MELEE_ATTACK_POWER_SHORT = "ITEM_MOD_ATTACK_POWER_SHORT",
    ITEM_MOD_RANGED_ATTACK_POWER = "ITEM_MOD_RANGED_ATTACK_POWER_SHORT",
    ITEM_MOD_MANA_REGENERATION = "ITEM_MOD_POWER_REGEN0_SHORT",
    ITEM_MOD_SPELL_HEALING_DONE_SHORT = "ITEM_MOD_SPELL_HEALING_DONE",
    -- Effects/procs report spell damage (aura 13) as spell power; HawsJon weights it
    -- as spell damage. (Healing is a separate aura -> ITEM_MOD_SPELL_HEALING_DONE.)
    ITEM_MOD_SPELL_POWER = "ITEM_MOD_SPELL_DAMAGE_DONE",
    -- Feral attack power = melee AP for a druid who's always in form -> score as melee AP
    -- (so it also folds into the melee/ranged AP max-pairing).
    FERAL_ATTACK_POWER = "ITEM_MOD_ATTACK_POWER_SHORT",
}

-- Weapon DPS is one stat in our data but weighted per hand; pick by equip slot.
local DPS_SLOT = {
    INVTYPE_WEAPONMAINHAND = "DPS_MAINHAND", INVTYPE_2HWEAPON = "DPS_MAINHAND",
    INVTYPE_WEAPON = "DPS_MAINHAND", INVTYPE_WEAPONOFFHAND = "DPS_OFFHAND",
    INVTYPE_HOLDABLE = "DPS_OFFHAND", INVTYPE_SHIELD = "DPS_OFFHAND",
    INVTYPE_RANGED = "DPS_RANGED", INVTYPE_RANGEDRIGHT = "DPS_RANGED",
    INVTYPE_THROWN = "DPS_RANGED",
}

-- Generic "+X Attack Power" is stored as two separate boosts — melee AP and ranged AP —
-- because in-game generic AP raises both. A class only attacks one way and the weights are
-- calibrated for a single AP stat, so summing both double-counts. The core takes the better
-- of the pair instead: ranged for a hunter, melee for a warrior, and a same-magnitude
-- generic-AP pair collapses back to one boost.
local AP_PAIR = {
    melee  = "ITEM_MOD_ATTACK_POWER_SHORT",
    ranged = "ITEM_MOD_RANGED_ATTACK_POWER_SHORT",
}

-- Flat HP / mana POOLS. Consumable-only in practice — no gear, set bonus, on-equip aura or
-- raid buff in the Vanilla data carries these keys; it's Flask of the Titans (+1200 HP),
-- Flask of Distilled Wisdom (+2000 mana) and three minor health elixirs. No weight scale
-- prices a raw pool (HawsJon has no HEALTH/MANA key), so they'd score 0 forever. Value them
-- as the PRIMARY STAT that delivers the pool, at Vanilla's fixed conversion: 10 HP per
-- Stamina, 15 mana per Intellect. Both sourced, not remembered — WoWSims (MIT):
-- sim/core/character.go `AddStatDependency(stats.Stamina, stats.Health, 10)` and
-- sim/core/mana.go `AddStatDependency(stats.Intellect, stats.Mana, 15*modifier)`.
--
-- Known approximation: Intellect also buys spell crit (and a little spell power) for casters,
-- so a caster's Int weight prices more than the pool and slightly over-credits flat mana. It
-- is exact for physical specs, where Int is nothing but mana.
-- `per` reads as "this many units of the key equal one unit of the weighted stat".
local DERIVED = {
    HEALTH = { stat = "ITEM_MOD_STAMINA_SHORT",   per = 10 },
    MANA   = { stat = "ITEM_MOD_INTELLECT_SHORT", per = 15 },
}

-- Keys the flat stat walk must NOT price. Weapon skill is scored by a formula below;
-- ammo by its own scorer; weapon speed is informational only (ranged speed for consumers).
local SKIP_PREFIX = { "WEAPON_SKILL_" }
local SKIP_KEYS   = { AMMO_DAMAGE = true, WEAPON_SPEED = true }

-- ---------------------------------------------------------------------------
-- The stats a Vanilla weight scale can set, in display order
-- ---------------------------------------------------------------------------
-- An in-game weight editor renders one input per entry and builds { [key] = number } to hand
-- LoadBiSWeights. These are exactly the keys the scorer reads. Haste is absent because Vanilla
-- gear barely carries it (a TBC+ stat); expertise and resilience don't exist in Vanilla at all.
local WEIGHT_STATS = {
    { key = "ITEM_MOD_STRENGTH_SHORT",           label = "Strength" },
    { key = "ITEM_MOD_AGILITY_SHORT",            label = "Agility" },
    { key = "ITEM_MOD_STAMINA_SHORT",            label = "Stamina" },
    { key = "ITEM_MOD_INTELLECT_SHORT",          label = "Intellect" },
    { key = "ITEM_MOD_SPIRIT_SHORT",             label = "Spirit" },
    { key = "ITEM_MOD_ATTACK_POWER_SHORT",       label = "Attack Power" },
    { key = "ITEM_MOD_RANGED_ATTACK_POWER_SHORT", label = "Ranged Attack Power" },
    { key = "ITEM_MOD_SPELL_POWER",              label = "Spell Power" },
    { key = "ITEM_MOD_SPELL_DAMAGE_DONE",        label = "Spell Damage" },
    { key = "ITEM_MOD_SPELL_HEALING_DONE",       label = "Healing Power" },
    { key = "ITEM_MOD_SPELL_PENETRATION",        label = "Spell Penetration" },
    { key = "HIT_PCT",                           label = "Hit %" },
    { key = "CRIT_PCT",                          label = "Crit %" },
    { key = "SPELL_HIT_PCT",                     label = "Spell Hit %" },
    { key = "SPELL_CRIT_PCT",                    label = "Spell Crit %" },
    { key = "DEFENSE",                           label = "Defense" },
    { key = "DODGE_PCT",                         label = "Dodge %" },
    { key = "PARRY_PCT",                         label = "Parry %" },
    { key = "BLOCK_PCT",                         label = "Block %" },
    { key = "BLOCK_VALUE",                       label = "Block Value" },
    { key = "ITEM_MOD_POWER_REGEN0_SHORT",       label = "MP5" },
    { key = "RESISTANCE0_NAME",                  label = "Armor" },
    { key = "DPS_MAINHAND",                      label = "Main-hand Weapon DPS" },
    { key = "DPS_OFFHAND",                       label = "Off-hand Weapon DPS" },
    { key = "DPS_RANGED",                        label = "Ranged Weapon DPS" },
    { key = "RANGED_HASTE_PCT",                  label = "Ranged Haste %" },
    -- Weapon skill is scored by a FORMULA, not a flat weight (see below): +skill only helps the
    -- weapon TYPE you wield and its value is non-linear and caps ~308, so the scorer values it
    -- via opts.attack and the stat walk skips these keys. Listed here for display / breakdown
    -- labels only — putting a weight on them does nothing.
    { key = "WEAPON_SKILL_SWORD",                label = "Sword Skill" },
    { key = "WEAPON_SKILL_AXE",                  label = "Axe Skill" },
    { key = "WEAPON_SKILL_MACE",                 label = "Mace Skill" },
    { key = "WEAPON_SKILL_DAGGER",               label = "Dagger Skill" },
    { key = "WEAPON_SKILL_FIST",                 label = "Fist Weapon Skill" },
    { key = "WEAPON_SKILL_UNARMED",              label = "Unarmed Skill" },
    { key = "WEAPON_SKILL_2H_SWORD",             label = "Two-Handed Sword Skill" },
    { key = "WEAPON_SKILL_2H_AXE",               label = "Two-Handed Axe Skill" },
    { key = "WEAPON_SKILL_2H_MACE",              label = "Two-Handed Mace Skill" },
    { key = "WEAPON_SKILL_POLEARM",              label = "Polearm Skill" },
    { key = "WEAPON_SKILL_STAFF",                label = "Staff Skill" },
    { key = "WEAPON_SKILL_BOW",                  label = "Bow Skill" },
    { key = "WEAPON_SKILL_GUN",                  label = "Gun Skill" },
    { key = "WEAPON_SKILL_CROSSBOW",             label = "Crossbow Skill" },
    { key = "WEAPON_SKILL_THROWN",               label = "Thrown Skill" },
}

-- Breakdown labels for rows that are NOT weightable keys (derived or bucket rows). The core
-- supplies labels for its own bucket tokens; these are the Vanilla-specific ones.
local LABELS = {
    AMMO_DAMAGE = "Ammo (ranged DPS)",
    -- Flat pools are derived rows, not weightable keys, so they're labelled but stay OUT of
    -- WEIGHT_STATS — a weight editor must not offer a HEALTH slider.
    HEALTH = "Health", MANA = "Mana",
}

-- Our (MIT) scoring-model constants — the numbers HawsJon's licensed weights don't cover.
-- Shipped per class as data (LoadScoreModel / _core/ScoreModel.lua); this is the fallback.
-- usePremium: on-use burst multiplier (controlled effects out-value their uptime).
-- hitsPerSec: default proc trigger rate (a paperdoll overrides at score time).
-- epPerRawDPS / epPerHPS: proc damage / heal -> EP conversions.
--
-- epPerHPS = HEALING POWER PER 1 HPS, and it is DERIVED, not tuned. Classic's direct-spell
-- coefficient is castTime / 3.5 (the "3.5-second rule"), so +H healing power adds
-- H * (castTime / 3.5) per cast; cast back to back over castTime seconds that is H / 3.5 HPS.
-- Invert it and 1 HPS costs 3.5 healing power. The heal bucket then prices a proc as
-- HPS -> healing-power-equivalent -> the scale's ITEM_MOD_SPELL_HEALING_DONE weight, which is
-- the same route the stat itself takes, so a proc heal and +healing on gear agree.
--
-- ASSUMPTIONS, stated because the number is an approximation and not a measurement: a DIRECT
-- heal at full coefficient, cast back to back. A HoT is duration / 15 instead and would want a
-- different divisor; no shipped proc row distinguishes them, so one constant covers both.
--
-- IT WAS 0 UNTIL 2026-08-17, and that was a bug, not a policy -- docs/AUDIT.md finding 7. With
-- 0 here every heal proc in both flavours scored exactly zero, and three separate `~= 0` filters
-- meant it rendered as ABSENCE rather than as a zero: Bonescythe Armor's entire set value is one
-- heal proc, so the Rogue tier set contributed nothing and the breakdown said nothing about it.
-- The user's ruling: a heal has EP, and whether it lands on you makes no difference to that.
-- epPerRawDPS = SPELL DAMAGE PER 1 DPS, and it is the same derivation as epPerHPS: Classic's
-- direct-damage coefficient is also castTime / 3.5, so 1 DPS is worth about 3.5 spell damage.
-- It was 1 and READ BY NOTHING (docs/AUDIT.md finding 8) until 2026-08-17, because the route it
-- was written for did not exist: the damage bucket priced procs only through a weapon-DPS weight,
-- and no caster scale carries one, so every damage proc scored zero for every caster spec
-- (finding 11). It now carries that conversion in scoreProcEffects' caster branch.
local MODEL = { usePremium = 1.3, hitsPerSec = 0.5, epPerRawDPS = 3.5, epPerHPS = 3.5 }

-- ---------------------------------------------------------------------------
-- Weapon skill — a Vanilla-only mechanic, scored by formula
-- ---------------------------------------------------------------------------
-- A port of the Classic attack-table math (as WoWSims implements it in sim/core:
-- OutcomeMeleeWhite vs OutcomeMeleeSpecial vs OutcomeRangedHitAndCrit). +weapon skill helps
-- ONLY the weapon TYPE you wield, only vs a higher-level target, and its value is front-loaded
-- and caps ~308 skill — so it is NOT a flat weight. A player benefits on TWO fronts at once —
-- their melee weapon AND their ranged weapon — so opts.attack carries both and an item's +skill
-- is scored against whichever it matches (a stat-stick polearm grants +ranged skill;
-- Edgemaster's grants +melee skill; a bow grants +ranged skill for itself). Scoring only ONE
-- type silently zeroes the other — that is the bug this two-front form fixes.
-- opts.attack = {
--   weaponType   = melee / scored-weapon type: "SWORD"|"AXE"|"DAGGER"|... (or a ranged token
--                  when the scored item itself is a bow/gun/crossbow)
--   weaponSkill  = your CURRENT skill for that type, EXCLUDING this item (default 300)
--   weaponDPS    = that weapon's white DPS (default 90)
--   rangedType   = your equipped RANGED type ("BOW"|"GUN"|"CROSSBOW"|"THROWN"), so a stat-stick's
--                  ranged skill is valued even while weaponType is a melee weapon
--   rangedDPS / rangedSkill = that ranged weapon's white DPS / current ranged skill (default 300)
--   targetDefense = defender skill (default 315 = a level-63 raid boss) }.
--
-- MELEE skill is an effective-DPS gain (miss + dodge + stronger GLANCING blows) priced via
-- DPS_MAINHAND — self-calibrating: HawsJon rates a hunter's melee DPS ~0.75 (weaving) vs a
-- warrior's ~5, so the same +skill is small for a hunter and large for a warrior, no usage hint
-- needed. RANGED skill has no dodge/glance (OutcomeRangedHitAndCrit); its miss reduction helps
-- EVERY shot (auto + Aimed/Multi/Steady), so it is priced as ranged HIT% via the HIT_PCT weight —
-- NOT as auto-shot white DPS, which under-counts a hunter's shot rotation ~8x. Crit is untouched
-- (item weapon skill doesn't move crit suppression, which uses base 300).
local WS_BASE         = 300      -- player base weapon skill at 60 (attacker.Level * 5)
local WS_BOSS_DEFENSE = 315      -- level-63 raid boss (defender.Level * 5)
local WS_DEFAULT_DPS  = 90       -- representative endgame white DPS if the caller gives none
local RANGED_WS = { BOW = true, GUN = true, CROSSBOW = true, THROWN = true }

local function wsMissChance(diff)          -- BaseMissChance vs (defense - skill)
    if diff > 10 then return 0.05 + diff * 0.002 else return 0.05 + diff * 0.001 end
end
local function wsGlanceAvg(diff)           -- mean glance damage multiplier (the clamp = 308 cap)
    local lo = math.max(math.min(1.3 - 0.05 * diff, 0.91), 0.01)
    local hi = math.max(math.min(1.2 - 0.03 * diff, 0.99), 0.20)
    return (lo + hi) * 0.5
end

-- EP of an item's +N skill for ONE weapon type the player wields (0 if the item has no skill for
-- that type, or the class can't use it). `ranged` selects the model: ranged = miss-only, priced as
-- HIT% (helps every shot); melee = miss + dodge + stronger glancing, priced against white DPS.
local function scoreOneWeaponSkill(stats, w, wtype, ranged, dps, skill, defense, parts)
    if not wtype then return 0 end
    local key = "WEAPON_SKILL_" .. wtype
    local n = stats[key]
    if not n or n <= 0 then return 0 end
    skill, defense = skill or WS_BASE, defense or WS_BOSS_DEFENSE
    if ranged then
        -- only a class that actually DEALS ranged damage benefits — a warrior who carries a gun to
        -- pull does not — so gate on the ranged-DPS weight (hunters have it, melee classes don't),
        -- then price the miss reduction via the hit weight. This makes the lib self-gate regardless
        -- of whether the caller passed a rangedType for a melee class.
        if (w["DPS_RANGED"] or 0) == 0 then return 0 end
        local hitW = w["HIT_PCT"] or 0          -- ranged hit == HawsJon's (ranged-tuned) hit weight
        if hitW == 0 then return 0 end          -- class doesn't shoot
        local miss = 0
        for s = skill + 1, skill + n do
            local m = wsMissChance(defense - (s - 1)) - wsMissChance(defense - s)
            miss = miss + (m > 0 and m or 0)
        end
        local hitPct = miss * 100               -- fraction -> percent, to match HIT_PCT's per-1% weight
        local ep = hitPct * hitW
        if parts and ep ~= 0 then
            parts[#parts + 1] = { kind = "weaponskill", key = key, value = n, ep = ep,
                factors = { { label = "+"..n.." skill (hit%)", value = hitPct },
                            { label = "hit weight", value = hitW } } }
        end
        return ep
    end
    local dpsW = w["DPS_MAINHAND"] or 0
    if dpsW == 0 then return 0 end              -- class doesn't melee
    dps = dps or WS_DEFAULT_DPS
    local glanceChance = math.max(math.min(0.1 + (defense - WS_BASE) * 0.02, 0.99), 0)
    local frac = 0                              -- effective white-DPS gained (as a fraction)
    for s = skill + 1, skill + n do
        local dBefore, dAfter = defense - (s - 1), defense - s
        local m = wsMissChance(dBefore) - wsMissChance(dAfter)
        frac = frac + (m > 0 and m or 0)                                -- fewer misses
        frac = frac + ((dAfter > 0) and 0.001 or 0)                     -- fewer dodges
        local glance = glanceChance * (wsGlanceAvg(dAfter) - wsGlanceAvg(dBefore))
        frac = frac + (glance > 0 and glance or 0)                      -- stronger glances
    end
    local ep = frac * dps * dpsW
    if parts and ep ~= 0 then
        parts[#parts + 1] = { kind = "weaponskill", key = key, value = n, ep = ep,
            factors = { { label = "+"..n.." skill", value = frac, pct = true },
                        { label = "weapon DPS", value = dps },
                        { label = "DPS weight", value = dpsW } } }
    end
    return ep
end

-- Sum an item's weapon-skill EP over the weapon types the player wields: the melee/primary type
-- (attack.weaponType) and the equipped ranged type (attack.rangedType). Scoring BOTH is what lets
-- a melee weapon's +skill AND a stat-stick's +ranged skill each count without one zeroing the other.
local function scoreWeaponSkill(stats, w, opts, parts)
    local attack = opts and opts.attack
    if not attack then return 0 end
    local defense = attack.targetDefense or WS_BOSS_DEFENSE
    local ep = scoreOneWeaponSkill(stats, w, attack.weaponType, RANGED_WS[attack.weaponType] or false,
                                   attack.weaponDPS, attack.weaponSkill, defense, parts)
    if attack.rangedType and attack.rangedType ~= attack.weaponType then
        ep = ep + scoreOneWeaponSkill(stats, w, attack.rangedType, true, attack.rangedDPS,
                                      attack.rangedSkill or attack.weaponSkill, defense, parts)
    end
    return ep
end

-- ---------------------------------------------------------------------------
-- Ammo
-- ---------------------------------------------------------------------------
-- Ammo (AMMO_DAMAGE x DPS_RANGED) is the core-provided `lib.StatScorers.ammo`, registered below.
-- It lived here as a local until 2026-09-17; TBC has the same mechanic and the same stat rows,
-- so the arithmetic moved to the core and each flavour that has ammo opts in.

-- The weight-scale keys the PROC scorer reads, declared by the expansion instead of hardcoded in
-- the core -- docs/AUDIT.md finding 10. Every other vocabulary difference between expansions
-- already arrives through RULES (alias, dpsSlot, apPair, derived); these five were reaching past
-- it, so a new flavour inherited Vanilla's spellings whether or not they were its own.
--
-- WHY IT IS NOT COSMETIC: Wrath merged healing into spell power. A Scoring/Wrath.lua whose scale
-- keys spell power as ITEM_MOD_SPELL_POWER would leave w["ITEM_MOD_SPELL_HEALING_DONE"] nil, make
-- hw = 0, and zero every heal proc for a SECOND, independent reason on top of finding 7 -- and
-- since the finding-11 fix it would zero the caster DAMAGE route as well. ItemDB_Wrath.toc and
-- ItemDB_Cata.toc exist as empty placeholders by design, so this is waiting on the day one of
-- them gets data rather than being hypothetical.
local PROC_KEYS = {
    dpsMain     = "DPS_MAINHAND",
    dpsRanged   = "DPS_RANGED",
    spellDamage = "ITEM_MOD_SPELL_DAMAGE_DONE",
    healing     = "ITEM_MOD_SPELL_HEALING_DONE",
    mana        = "ITEM_MOD_POWER_REGEN0_SHORT",
}

-- The stat keys whose EP is SCHOOL-CONDITIONAL -- docs/AUDIT.md finding 20. Keys are
-- POST-ALIAS, so this one entry covers ITEM_MOD_SPELL_POWER too (ALIAS folds it here).
--
-- Declared by the expansion for the same reason procKeys is, and the same example proves it:
-- Wrath merged healing into spell power, so a Scoring/Wrath.lua gating only the damage key
-- would let a +Fire item keep its full HEALING credit for a spec that never casts fire.
-- Vanilla and TBC keep damage and healing as separate keys, so only damage is school-tagged.
--
-- HEALING IS DELIBERATELY ABSENT ON THIS EXPANSION, not overlooked: build-spell-schools.py
-- reads the aura-13 (spell DAMAGE) school mask, so a healing item never carries a school tag
-- and there is nothing here for a gate to act on.
local SCHOOL_GATED = {
    ITEM_MOD_SPELL_DAMAGE_DONE = true,
}

lib:RegisterScoring({
    name        = "Vanilla",
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
    statScorers = { scoreWeaponSkill, lib.StatScorers.ammo },
})
