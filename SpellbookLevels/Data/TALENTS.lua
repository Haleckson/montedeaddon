-- SpellbookLevels - World of Warcraft: Forever talent heatmap data
-- Dataset scope: Forever Beta, Patch 1.60.1. Updated 2026-09-30.
-- This is recommendation/build data, NOT measured player-popularity data.
-- Sources are recorded as labels/URLs for provenance; the addon performs no network requests.
SBL_TALENT_HEAT = SBL_TALENT_HEAT or {}

SBL_TALENT_HEAT.SHAMAN = {
    Enhancement = {
        __meta = {
            profile = "Level 20",
            ruleset = "Forever Beta",
            patch = "1.60.1",
            updated = "2026-09-30",
            source = "Wowhead Forever - Level 20 Enhancement Shaman (Yebb, 2026-09-26)",
            sourceURL = "https://www.wowhead.com/forever/guide/classes/shaman/enhancement/level-20-dps-overview",
            note = "Exact recommended 0/11/0 talent order. Stormstrike is an optional Legacy-system extension."
        },
        ["Thundering Strikes"] = { heat=100, rank=5, label="Core", order=1 },
        ["Improved Ghost Wolf"] = { heat=92, rank=2, label="Core", order=2 },
        ["Mental Dexterity"] = { heat=84, rank=3, label="Core", order=3 },
        ["Shamanistic Focus"] = { heat=76, rank=1, label="Recommended", order=4 },
        ["Stormstrike"] = { heat=48, rank=1, label="Legacy extra", order=5,
            note="Reachable early with additional talent points from the Forever Legacy System." },
    },
    Elemental = {
        __meta = {
            profile = "Level 20",
            ruleset = "Forever Beta",
            patch = "1.60.1",
            updated = "2026-09-30",
            source = "Wowhead Forever - Level 20 Elemental Shaman (Lucenia, 2026-09-26)",
            sourceURL = "https://www.wowhead.com/forever/guide/classes/shaman/elemental/level-20-dps-overview",
            note = "Current guide recommends an early Restoration-tree mana build rather than an Elemental-tree build; no unsupported exact ranks are fabricated here."
        },
    },
    Restoration = {
        __meta = {
            profile = "Forever Beta",
            ruleset = "Forever Beta",
            patch = "1.60.1",
            updated = "2026-09-30",
            source = "Wowhead Forever - Restoration Shaman Overview (Woah, 2026-09-23)",
            sourceURL = "https://www.wowhead.com/forever/guide/classes/shaman/restoration/overview-pve-healer",
            note = "Overview confirms Forever talents such as Mindfulness and Riptide, but the retrieved source does not provide a complete point-by-point level-20 build; no ranks are invented."
        },
    },
}

-- v2.9 build profiles ---------------------------------------------------------
-- Build profiles are intentionally separate from tree datasets: a specialization
-- can recommend points in another tree. Only allocations explicitly supported by
-- current Forever Beta guides are included; no missing ranks are invented.
local function SBLBuild(classKey, buildName, meta, talents)
    SBL_TALENT_HEAT[classKey]=SBL_TALENT_HEAT[classKey] or {}
    local c=SBL_TALENT_HEAT[classKey]
    c.__builds=c.__builds or {}
    c.__builds[buildName]={__meta=meta,talents=talents}
end

SBLBuild("SHAMAN","Enhancement",{
 profile="Level 20",ruleset="Forever Beta",patch="1.60.1",updated="2026-09-30",
 source="Wowhead Forever - Level 20 Enhancement Shaman (Yebb, updated 2026-09-26)"
},{
 ["Thundering Strikes"]={tree="Enhancement",heat=100,rank=5,label="Core",order=1},
 ["Improved Ghost Wolf"]={tree="Enhancement",heat=92,rank=2,label="Core",order=2},
 ["Mental Dexterity"]={tree="Enhancement",heat=84,rank=3,label="Core",order=3},
 ["Shamanistic Focus"]={tree="Enhancement",heat=76,rank=1,label="Recommended",order=4},
})
SBLBuild("SHAMAN","Elemental Combat",{
 profile="Level 20",ruleset="Forever Beta",patch="1.60.1",updated="2026-09-30",
 source="Wowhead Forever - Level 20 Elemental Shaman (Lucenia, updated 2026-09-26)",
 note="The current level-20 Elemental guide intentionally spends its core points in Restoration for mana sustain."
},{
 ["Mindfulness"]={tree="Restoration",heat=100,rank=3,label="Core",note="Core mana-sustain talent in the current level-20 Elemental guide."},
 ["Water Shield"]={tree="Restoration",heat=92,rank=1,label="Core",note="Recommended for level-20 dungeon mana sustain."},

})

SBLBuild("SHAMAN","Restoration",{
 profile="Forever Beta",ruleset="Forever Beta",patch="1.60.1",updated="2026-09-30",
 source="Wowhead Forever - Restoration Shaman Overview (Woah, updated 2026-09-23)",
 note="Current Forever documentation confirms these Restoration talents. Exact level-20 point order is not published in the retrieved guide, so unsupported ranks are not fabricated."
},{
 ["Mindfulness"]={tree="Restoration",heat=100,rank=3,label="Core",order=1},
 ["Tidal Focus"]={tree="Restoration",heat=88,rank=5,label="Core"},
 ["Improved Reincarnation"]={tree="Restoration",heat=72,rank=2,label="Recommended"},
 ["Healing Way"]={tree="Restoration",heat=72,rank=3,label="Recommended"},
 ["Riptide"]={tree="Restoration",heat=65,rank=1,label="Capstone"},
})

-- v3.0 Aggregate Heatmap Dataset ---------------------------------------------
-- selectionPct = percentage of sampled published build variants containing talent.
-- avgRank = average selected rank among those sampled builds.
-- This is source-frequency visualization, not a claim about the player population.
local function SBL_Aggregate(classKey,spec,meta,talents)
 SBL_TALENT_HEAT[classKey]=SBL_TALENT_HEAT[classKey] or {}
 local c=SBL_TALENT_HEAT[classKey]; c.__builds=c.__builds or {}
 c.__builds[spec]={__meta=meta,talents=talents}
end
local function A(p,r,n,tree) return {selectionPct=p,heat=p,avgRank=r,sample=n,tree=tree,label="Aggregate"} end

SBL_Aggregate("SHAMAN","Enhancement",{profile="Aggregate",patch="1.60.1",updated="2026-09-30",sample=1,source="Wowhead Forever level-20 Enhancement guide"},{
 ["Thundering Strikes"]=A(100,5,1,"Enhancement"),["Improved Ghost Wolf"]=A(100,2,1,"Enhancement"),
 ["Mental Dexterity"]=A(100,3,1,"Enhancement"),["Shamanistic Focus"]=A(100,1,1,"Enhancement")})
SBL_Aggregate("PALADIN","Retribution",{profile="Aggregate",patch="1.60.1",updated="2026-09-30",sample=2,source="Wowhead Forever level-20 Retribution guide; Shockadin + Seal Twist variants"},{
 ["Divine Strength"]=A(50,5,2,"Holy"),["Divine Intellect"]=A(50,3,2,"Holy"),["Improved Seals"]=A(50,3,2,"Holy"),
 ["Benediction"]=A(50,5,2,"Retribution"),["Improved Judgement"]=A(50,2,2,"Retribution"),["Conviction"]=A(50,3,2,"Retribution"),["Seal of Command"]=A(50,1,2,"Retribution")})
SBL_Aggregate("PALADIN","Holy",{profile="Aggregate",patch="1.60.1",updated="2026-09-30",sample=1,source="Wowhead Forever level-20 Holy guide"},{
 ["Divine Intellect"]=A(100,5,1,"Holy"),["Healing Light"]=A(100,3,1,"Holy"),["Improved Seals"]=A(100,2,1,"Holy"),["Reverence"]=A(100,1,1,"Holy")})
SBL_Aggregate("HUNTER","Beast Mastery",{profile="Aggregate",patch="1.60.1",updated="2026-09-30",sample=1,source="Wowhead Forever level-20 Beast Mastery guide"},{
 ["Deadly Aspects"]=A(100,5,1,"Beast Mastery"),["Focused Fire"]=A(100,2,1,"Beast Mastery"),["Lethal Attacks"]=A(100,4,1,"Marksmanship")})
SBL_Aggregate("PRIEST","Holy",{profile="Aggregate",patch="1.60.1",updated="2026-09-30",sample=1,source="Wowhead Forever level-20 Holy guide"},{
 ["Wand Specialization"]=A(100,2,1,"Discipline"),["Improved Renew"]=A(100,3,1,"Holy"),["Holy Specialization"]=A(100,2,1,"Holy"),["Divine Fury"]=A(100,4,1,"Holy")})
SBL_Aggregate("WARLOCK","Affliction",{profile="Aggregate",patch="1.60.1",updated="2026-09-30",sample=1,source="Wowhead Forever level-20 Affliction guide; core picks only"},{
 ["Improved Corruption"]=A(100,5,1,"Affliction"),["Suppression"]=A(100,4,1,"Affliction")})
SBL_Aggregate("DRUID","Restoration",{profile="Aggregate",patch="1.60.1",updated="2026-09-30",sample=2,source="Wowhead Forever level-20 Restoration guide; Reflective + Splendid variants"},{
 ["Reflection"]=A(50,1,2,"Restoration"),["Nature's Splendor"]=A(50,1,2,"Balance"),["Nature's Majesty"]=A(50,3,2,"Balance")})

-- v3.2 RC1: observed popularity, not authored recommendations.
-- Source snapshot: WoW Forever Talent Shaman page, updated 2026-09-29 12:50 UTC.
-- Sample: 27,357 complete build records. Only explicitly published rates are included.
SBL_TALENT_HEAT.SHAMAN=SBL_TALENT_HEAT.SHAMAN or {}
SBL_TALENT_HEAT.SHAMAN.__aggregate={
 __meta={profile="Observed popularity",ruleset="Forever Beta",patch="1.60.1",updated="2026-09-29",sample=27357,source="WoW Forever Talent - Shaman popularity"},
 ["Thundering Strikes"]={tree="Enhancement",selectionPct=90,heat=90,sample=27357,label="Observed"},
 ["Ancestral Knowledge"]={tree="Enhancement",selectionPct=75,heat=75,sample=27357,label="Observed"},
 ["Shamanistic Focus"]={tree="Enhancement",selectionPct=73,heat=73,sample=27357,label="Observed"},
 ["Improved Ghost Wolf"]={tree="Enhancement",selectionPct=71,heat=71,sample=27357,label="Observed"},
 ["Concussion"]={tree="Elemental Combat",selectionPct=69,heat=69,sample=27357,label="Observed"},
 ["Restorative Totems"]={tree="Restoration",selectionPct=13,heat=13,sample=27357,label="Observed"},
 ["Improved Reincarnation"]={tree="Restoration",selectionPct=12,heat=12,sample=27357,label="Observed"},
 ["Improved Lightning Shield"]={tree="Enhancement",selectionPct=11,heat=11,sample=27357,label="Observed"},
 ["Earth's Grasp"]={tree="Enhancement",selectionPct=7,heat=7,sample=27357,label="Observed"},
 ["Natural Grace"]={tree="Restoration",selectionPct=6,heat=6,sample=27357,label="Observed"},
}
