<!-- charset-ok: this file is developer documentation, rendered by GitHub and the
     CurseForge page and never by the WoW client. It ships inside the zip as a
     file, but nothing in the game reads it through the client's font engine, so
     the broken-glyph failure the charset law exists to prevent cannot occur
     here. The em dashes and ellipses below predate the law; declaring it is the
     mechanism the law itself provides, rather than rewriting twenty unrelated
     lines into a diff that is already 95 files wide. Declared 2026-08-20.
     NOTE this does NOT extend to Data/ or to any Lua string the client draws --
     those are exactly what the law is for. -->
# LibProfessionDB

A standalone, **offline profession & recipe database** for World of Warcraft. It
resolves a crafting recipe to its **name, reagents, skill-up difficulty tiers,
required skill, produced item, and enriched effect text** — without a trade
skill window being open, and without the recipe being known by the player.

WoW only exposes recipe data while a profession window is open, and only for
professions the character actually knows. LibProfessionDB ships that data
**pre-built** from the game's own client DBC tables, so any addon can read
recipe details for *any* profession at *any* time — guild crafters, alts,
recipes you haven't learned yet, all of it.

The folder on disk is `ProfessionDB`; the CurseForge project is
**LibProfessionDB**.

## Current state

Everything here is verified against the tree rather than remembered. If you are
reading this to orient yourself, start with this table and treat the rest of the
document as detail.

| | |
| --- | --- |
| Release | **v1.8.0** (2026-09-25) |
| LibStub | `LibProfessionDB-1.0`, **MINOR 12** — bumped only on a public API change |
| Flavours | Vanilla `11509`, TBC `20506`, Wrath `30405`, Cata `40402`, Mists `50504`, WoW Forever `16001` (its own `Data/Forever` tree). **No Retail.** |
| Locales | 12 shipped (`enGB` mirrors `enUS`; `itIT` cannot load on any Classic client — see below) |
| Data | `Data/<game>/` — generated, never hand-edited, **never merged across expansions** |
| Pipeline | `tools/`, entirely in this repo since v1.6.0; `.pkgmeta` keeps it out of the zip |
| Tests | `Tests/*_spec.lua` on the WoWAPITesting harness — **184 specs**, run locally, no CI |

**Two things bite newcomers, both documented at length further down.** A data file
that no `.toc` lists installs and never executes, with no error. And
`GetRecipeItem` returning `nil` is a *real answer* — roughly a third of recipes
are trainer-taught and have no teaching item — not missing data.

## Supported versions

Ships for every WoW flavour **except Retail** — Vanilla/Era, TBC, Wrath,
Cataclysm, Mists, and WoW Forever, each with its own `.toc`. Recipe data is
**point-in-time per game version** (difficulty tiers, required skill, reagents,
names, and effect text all change across expansions — so the database does NOT
merge versions; each flavour ships exactly that build's recipes).

**WoW Forever (v1.8.0+)** ships its own `Data/Forever` tree, built from
Forever's own client data: 2,511 recipes across 10 professions, 12 locales,
teaching items and acquisition flags. It has **no** recipe sources, **no**
never-implemented list and **no** trainer-derived `requiredSkill`: the emulator
and AllTheThings databases those come from carry no Forever data. On Forever,
`GetRecipeSources` returns `nil` and `IsHiddenRecipe` returns `false` for every
recipe -- and `false` there means "not on a list", not "proven obtainable". A
live-client capture is planned to fill the gap.

Recipe names and enchant effect text ship in **every official WoW locale** —
enUS, deDE, esES, esMX, frFR, itIT, koKR, ptBR, ruRU, zhCN, zhTW (enGB mirrors
enUS). Only the text is localized; the recipe set, difficulty, reagents, and
ids are identical across languages. Each data file guards on `GetLocale()`, so
a client loads only its own language.

**`itIT` is shipped but cannot load on any Classic client, and it is kept
deliberately as FORWARD-LOOKING.** Italian is a **Retail** WoW locale and is not
offered on any Classic flavour -- the original Mists of Pandaria shipped fully
localised in Italian in 2012 and [MoP Classic did
not](https://eu.forums.blizzard.com/en/wow/t/italian-language-mia/581809), which
is the clearest evidence available that this is the Classic pipeline rather than
missing source content. Every data file opens with a `GetLocale()` guard and
this library ships no Retail flavour, so the **62** Classic `Data/*/itIT/` files
can never execute for a player today. (Counted off disk 2026-08-20: 11 Vanilla,
12 TBC, 13 each for Wrath, Cata and Mists — the profession count differs per
flavour, plus one `RecipeScrollPrefixes.lua` each.) `Data/Forever/itIT/` adds
11 more; whether WoW Forever offers Italian has not been checked.

They are kept because Blizzard is being actively petitioned for Italian on
Classic, the files are already correct and current, and re-adding them after a
delete costs a full regeneration. The text in them is English, because the
upstream data has no Italian strings for these builds -- measured, not assumed:
the Italian export is byte-identical in size to `enUS` and contains no non-ASCII
characters at all, while German and French differ and are full of accented ones.

**If you are counting package size, this is the first thing that should go.**
Nothing else depends on it.

## Requirements

- **Ace3** and **VersionCheck-1.0** — hard dependencies (auto-installed by
  CurseForge). They back the optional guild version-check; the library's recipe
  lookups themselves don't depend on them.

## For addon authors

LibProfessionDB registers as a LibStub library. Depend on it (or list it as an
optional dependency) and query it:

```lua
local DB = LibStub("LibProfessionDB-1.0", true)
if DB and DB:IsReady() then
    -- Enchanting (333), Enchant Chest - Minor Stats (13626)
    local r = DB:GetRecipe(333, 13626)
    -- r.name        = "Enchant Chest - Minor Stats"
    -- r.effect      = "+1 All Stats"
    -- r.difficulty  = { 150, 175, 195, 215 }   -- orange, yellow, green, grey
    -- r.reagents    = { [11082] = 1, ... }      -- [itemId] = quantity

    for _, hit in ipairs(DB:Search({ query = "agility" })) do
        print(hit.profId, hit.recipeId, hit.name, hit.effect)
    end
end
```

### API

| Method | Returns |
| --- | --- |
| `DB:IsReady()` | `true` once data for this client is loaded |
| `DB:Count()` | total number of recipes in the database |
| `DB:GetMeta()` | `locale, game` the loaded data was captured for |
| `DB:GetGameVersion()` | current client flavour: `"Vanilla"/"TBC"/"Wrath"/"Cata"/"Mists"/"Forever"`, or `"Unknown"` on a client with no data tree (any other 16000-19999 interface, any future flavour) -- no data loads there and `IsReady()` is false |
| `DB:IsGameVersion(name)` | `true` if `name` matches the running client's flavour |
| `DB:GetProfessions()` | `{ profId, ... }` of professions present, ascending |
| `DB:HasProfession(profId)` | `true` if that profession has data loaded |
| `DB:ProfessionCount(profId)` | recipe count for one profession |
| `DB:GetRecipes(profId)` | raw `{ [recipeId] = entry }` table (read-only) |
| `DB:GetRecipe(profId, recipeId)` | a single recipe entry |
| `DB:HasRecipe(profId, recipeId)` | `true` if the recipe is known |
| `DB:GetName(profId, recipeId)` | recipe name |
| `DB:GetReagents(profId, recipeId)` | `{ [itemId] = quantity }` |
| `DB:GetEffect(profId, recipeId)` | enriched effect text (enchants), or nil |
| `DB:GetDifficulty(profId, recipeId)` | `{ orange, yellow, green, grey }` skill thresholds |
| `DB:GetRequiredSkill(profId, recipeId)` | skill needed to learn the recipe |
| `DB:GetItemID(profId, recipeId)` | recipe-scroll item id (nil for trainer-only) |
| `DB:GetCraftedItemID(profId, recipeId)` | item the recipe produces |
| `DB:GetEnchantId(profId, recipeId)` | `SpellItemEnchantment` id (the enchant number in an item link); enchant recipes only |
| `DB:GetEnchantSlot(profId, recipeId)` | target slot category for an enchant (`"HANDS"`, `"WRIST"`, `"WEAPON2H"`, …) |
| `DB:GetStats(profId, recipeId)` | structured `{ [GetItemStats-key] = amount }` stat deltas for an enchant |
| `DB:GetEnchant(enchantId)` | catalog entry for a `SpellItemEnchantment` id (craftable **or** item-applied) |
| `DB:EnchantsForSlot(slot)` | array of every enchant applicable to a slot (`"HEAD"`, `"WRIST"`, `"WEAPON2H"`, …) |
| `DB:IterateEnchants()` | `for enchantId, entry in DB:IterateEnchants() do` |
| `DB:Search(opts)` | array of matches; `opts = {query, profId, max}` |
| `DB:Iterate(profId?)` | `for profId, recipeId, entry in DB:Iterate() do` |

### Recipe scrolls (MINOR 8+)

Keyed by the recipe's **craft spell id**, the same key `recipes` uses — which is
why this data lives here rather than in an item library. Moved from
`LibItemDB-1.0` in v1.5.0.

| Method | Returns |
| --- | --- |
| `DB:GetRecipeItem(spellID)` | `itemID, isRankBook` — the item that **teaches** the recipe, or **nil** |
| `DB:GetSyntheticRecipeScroll(spellID)` | scroll-shaped descriptor for a recipe with no real scroll |
| `DB:GetRecipeScrollPrefix(skillLineID)` | `prefix, sampleCount` -- localized prefix, e.g. `"Plans: "`, plus how many real scrolls voted for it (second return is MINOR 11+) |
| `DB:GetRecipeItems()` | raw `{ [spellID] = itemID }` map (read-only) |

> **`AttachExternalRecipeInfo` is NOT part of this library and never has been.**
> It was listed in this table from v1.5.0 until v1.7.0 because the migration note
> that moved the recipe-scroll API here from `LibItemDB-1.0` said it came with
> the rest. The reasoning was sound; the method was never written.
> `git log -S AttachExternalRecipeInfo -- LibProfessionDB-1.0.lua` returns no
> commit. Calling it raises `attempt to call a nil value`. Recorded rather than
> quietly deleted, because a consumer may have copied the row.

### Where a recipe comes from (MINOR 10+)

| Call | Returns |
| --- | --- |
| `DB:GetRecipeSources(spellID)` | `{ trainer = {…}, vendor = {…}, quest = {…}, container = {…}, drop = {…} }`, or **nil** |
| `DB:GetRecipeSourceKinds(spellID)` | `{ trainer = true, … }` — the cheap form, one small table, no npc walk |
| `DB:GetSourceName(npcID)` | the English name of a source npc / object, or nil |

Each kind is an array of `{ id, name }`, and `name` is nil for an id the shipped
name table does not carry. Keyed by **craft spell id**, like everything else here.

**⚠ Each list carries `.total`, and it is NOT always `#list`.** The shipped lists
are capped at **12 ids**, because 1,649 recipes drop from 50+ creatures apiece —
*Rough Grinding Stone* from 912 — and the uncapped set costs ~8 MB to say "drops
from everything". So:

```lua
local src = DB.GetRecipeSources and DB:GetRecipeSources(spellID)
local drop = src and src.drop
if drop then
    -- name a few examples, then say how many more there really are
    local shown, more = #drop, drop.total - #drop
    print(drop[1].name, shown, more > 0 and ("and %d more"):format(more) or "")
end
```

Printing `#list` as the count tells a player *Rough Grinding Stone* drops from 12
creatures. Use `.total` for any number you show; iterate the list only for
examples.

**Names are English only.** They come from the emulator world databases'
`creature_template`, which is not localized — unlike recipe names, which ship in
12 languages. If your UI is localized, render the *kind* from your own strings and
treat the npc name as data.

**Use `GetRecipeSourceKinds` in list rows.** It exists because
`GetRecipeSources` allocates a table per npc, and a browser drawing hundreds of
rows a frame only wants the labels.

Feature-detect on the function, not on a version number:

```lua
if DB.GetRecipeSources then … end
```

### Never-implemented recipes (MINOR 9+)

| Call | Returns |
| --- | --- |
| `DB:IsHiddenRecipe(spellID)` | `true` if the recipe was **never obtainable** in the live game |
| `DB:GetHiddenRecipes()` | raw `{ [spellID] = true }` map (read-only) |

Some recipes shipped in the client's spell tables and nothing in the world ever
taught them — no trainer, no vendor, no drop, no quest. **No client signal reveals
this**: the spell resolves, the crafted item resolves, and the reagents resolve, so
they are indistinguishable from a recipe the player simply has not found yet.

| Flavour | Never-implemented ids shipped | Of those, recipes this library ships |
| --- | ---: | ---: |
| Vanilla | 67 | 25 of 1,564 |
| TBC | 87 | 37 of 2,170 |
| Wrath | 129 | 41 of 3,573 |
| Cata | 184 | 58 of 4,270 |
| Mists | 231 | 90 of 5,294 |
| Forever | none shipped | no source carries Forever data |

On Vanilla that includes all six Stormcloth pieces, Rune Edge, Blood Talon,
Thorium Greatsword and Elixir of Tongues. The ids that are *not* shipped recipes
are kept anyway, so adding recipes later cannot silently un-hide one. Each count
is the one written into the header of that flavour's `_core/HiddenRecipes.lua` by
the generator, so it cannot drift from the data it describes.

**If you list "recipes you have yet to learn", filter on this** — otherwise you
are telling the player to go and find something that does not exist. It is
deliberately narrower than "unobtainable": it does **not** cover recipes removed
in a later patch, nor holiday-gated ones, so an id absent from this list is not
thereby proven obtainable.

Feature-detect it, so the call is inert against an older ProfessionDB:

```lua
if DB.IsHiddenRecipe and DB:IsHiddenRecipe(spellID) then return end
```

### How a recipe is acquired (MINOR 9+)

| Call | Returns |
| --- | --- |
| `DB:IsAutoTaughtRecipe(spellID)` | `true` if it is granted when the profession is learned |
| `DB:GetAcquireMethod(spellID)` | `SkillLineAbility.AcquireMethod`, **0** by default |

If you show "where does this recipe come from", some rows have no trainer,
vendor, drop or quest anywhere — 87 of 1,261 on Vanilla. **26 of those are not a
data gap:** `AcquireMethod = 1` means the recipe arrives with the profession
itself, so nothing in the world teaches it. Minor Healing Potion, Rough
Sharpening Stone, Linen Bandage, Smelt Copper. Render them as *"Learned with
profession"* rather than *"Unknown"*.

The raw value is exposed rather than only a boolean because TBC and Wrath each
ship three recipes with `AcquireMethod = 3`; collapsing would discard that. `0`
is not stored — it is the default and the large majority.

**`nil` from `GetRecipeItem` is a real answer, not missing data** — roughly a
third of recipes are trainer-taught and no teaching item exists (571 of 1,645 on
Vanilla, 814 of 2,267 on TBC). `GetSyntheticRecipeScroll` is its exact
complement: every recipe answers one or the other, never both, so a consumer can
draw one tooltip shape throughout instead of a visible seam where real scrolls
run out. It returns `nil` for a **rank book**, which is not a recipe.

The synthetic descriptor:

```lua
{
  name          = "Plans: Barbaric Shoulders",  -- prefix .. spell name, or nil
  prefix        = "Plans: ",                    -- localized; nil on gathering lines
  useText       = "Teaches you how to make a Barbaric Shoulders.",  -- or nil
  professionID  = 165,
  craftedItemID = 15062,                        -- nil when the craft makes no item
  isSynthetic   = true,
}
```

`name` and `useText` are composed at **call time** from the client's own
`GetSpellInfo`, so both are `nil` for a spell this client does not know — check
them rather than assuming. There is no separate use-text getter; it arrives only
on this descriptor.

**Scroll data ships for every game version** -- all five Classic ones as of
v1.6.0, and WoW Forever from v1.8.0. It was Vanilla and
TBC only before that, and the failure mode is worth carrying: on the other three,
`GetRecipeItem` returned `nil, false` for *every* recipe, which reads exactly like
the legitimate "this one is trainer-taught" answer. Nothing errored. If you
consume this library on Wrath, Cata or Mists, require **v1.6.0 or newer**.

Coverage, which lands where the generator's own honesty notes say it should
(Mining ~5%, Herbalism and Skinning 0%, First Aid low):

| Flavour | Real teaching item | Rank books | Synthetic |
| --- | --- | ---: | ---: |
| Vanilla | 1,074 / 1,645 (65.3%) | 6 | 571 |
| TBC | 1,453 / 2,267 (64.1%) | 9 | 814 |
| Wrath | 2,026 / 3,710 (54.6%) | 10 | 1,684 |
| Cata | 2,520 / 4,406 (57.2%) | 10 | 1,886 |
| Mists | 3,026 / 5,456 (55.5%) | 6 | 2,430 |
| Forever | 1,859 / 2,664 (69.8%) | 3 | 805 |

Real and synthetic are exact complements and rank books are in neither, so every
recipe answers one or the other. The builder asserts that partition on every run
rather than trusting it.

**Known locale gap**, measured on Vanilla: enUS derives **9** prefixes, **esMX
8**, and **esES only 2** (Blacksmithing `164` and Enchanting `333`). A prefix is
derived from real scroll names in that locale, so a locale with no localized
scroll names for a profession yields no prefix — the upstream strings are simply
absent, and inventing one is the thing this pipeline refuses to do.
`GetRecipeScrollPrefix` returns `nil` for the rest, which makes `name` nil on the
synthetic descriptor. **Handle a nil prefix**; it is a normal answer in some
locales, not an error.

The one esMX is missing is **Mining (`186`)**, and that is the same recipe the
sample count exists for: enUS derives Mining's prefix from exactly **one** real
scroll, so a locale with even slightly thinner scroll naming has nothing to
derive it from at all.

The synthetic descriptor carries **no item id and never will** — a fabricated id
is permanently cache-cold and fails silently in every item API. Branch on which
of the two answered, never on a missing id. It also carries no `requiredSkill`:
read that from the recipe itself, which has the correct per-recipe value.

Prefixes are derived at build time from real scrolls rather than transcribed —
frFR is `"Plans : "` with a space *before* the colon and zhCN uses a full-width
one, so an English table would be wrong in two locales on day one.

**`GetRecipeScrollPrefix` returns a SAMPLE COUNT as a second value (MINOR 11+),
and the reason is Mining.** A prefix is derived by majority vote from real
scroll names, and Mining's vote has exactly **one** ballot -- a single smelting
scroll decides the header for 22 synthetic descriptors. That is not
self-evidently wrong, but a consumer could not previously *tell*:

```lua
local prefix, samples = DB:GetRecipeScrollPrefix(skillLineID)
if prefix and samples and samples < 5 then
    -- derived from very few real scrolls; draw your own header if you prefer
end
```

The **first return is unchanged**, so no existing call site moves. A nil prefix
yields a **nil** count rather than 0, so "no prefix at all" and "a prefix derived
from no samples" stay distinguishable. The library deliberately does not apply a
threshold -- that would decide for every consumer invisibly, which is the defect
the second return exists to fix.

A recipe **entry** is:

```lua
{
    name          = "…",
    difficulty    = { orange, yellow, green, grey },  -- skill thresholds
    teaches       = spellId,
    reagents      = { [itemId] = quantity, … },
    requiredSkill = n,           -- optional
    effect        = "+1 All Stats",  -- optional, enchants
    itemId        = n,           -- optional, recipe-scroll item
    craftedItemId = n,           -- optional, produced item
    phase         = n,           -- optional, content phase (>1)
    enchantId     = n,           -- optional, SpellItemEnchantment id (enchants)
    enchantSlot   = "HANDS",     -- optional, target slot category (enchants)
    stats         = { ["ITEM_MOD_AGILITY_SHORT"] = 7, ... },  -- optional, enchants
}
```

### `requiredSkill` is optional ON PURPOSE, and it changes how you read `difficulty`

**`requiredSkill` is omitted when no authoritative source has it.** The library
ships the gap rather than a guess: the priority chain is a hand-verified
override, then the recipe scroll's own `ItemSparse.RequiredSkillRank`, then
emulator trainer data -- and if none has it, the field is **absent**. It is never
back-filled from the DBC's `MinSkillLineRank`, which runs 0-10 points off the
real learn requirement for many recipes and would mask the gap behind a
plausible number. Render an absent value as `-`, not as `0`.

**A recipe's tiers are UNANCHORED -- `difficulty[1]` is a placeholder, not a
skill threshold -- exactly when `requiredSkill` is ABSENT and
`difficulty[1] == 1`.** It is the conjunction; neither condition alone will do,
and both one-field versions are wrong against the shipped data:

- `requiredSkill` absent but `difficulty[1] > 1` -- **61 recipes**, anchored by a
  real `MinSkillLineRank`. Good data. A rule keyed on "requiredSkill is absent"
  throws these away.
- `requiredSkill` present and **exactly 1** with `difficulty[1] == 1` -- **218
  recipes**, apprentice crafts genuinely learnable at skill 1 and genuinely
  orange from 1. Good data. A rule keyed on "`difficulty[1] == 1`" condemns
  these.

```lua
local r = DB:GetRecipe(profID, spellID)
local unanchored = r.requiredSkill == nil and r.difficulty and r.difficulty[1] == 1
-- unanchored: show the tiers as unknown rather than as thresholds
```

**All four combinations, so nothing is left to inference:**

| `requiredSkill` | `difficulty[1]` | verdict | population |
| --- | --- | --- | --- |
| absent | `== 1` | **unanchored** | Vanilla 373, TBC 3, Wrath 245, Cata 284, Mists 824, Forever 614 |
| absent | `> 1` | anchored | 61 (29 Vanilla, 18 Mists, 14 Forever) |
| present, `== 1` | `== 1` | anchored | 218 (26 of them Forever), all with `requiredSkill` exactly 1 |
| present, `> 1` | `== 1` | anchored | **empty, and enforced** |

**That last row is the one that would be dangerous if it were populated** -- a
recipe requiring skill 75 while claiming to be orange from 1 is the placeholder
shape, and the rule would call it anchored and let you render `1` as a real
threshold. **It cannot occur: the offline suite asserts across all six shipped
trees that no recipe ever ships `difficulty[1] == 1` beside a `requiredSkill`
above 1**, and that assertion is red-tested. So the rule errs only toward
calling a tier unanchored -- you may occasionally decline to show a threshold
that was real, which is the safe direction, **and the unsafe direction is closed
by machine rather than by observation.**

**What the offline suite actually guarantees, stated narrowly on purpose:** it
asserts across all six shipped trees that **no recipe ever ships
`difficulty[1] == 1` alongside a `requiredSkill` above 1** -- the invariant the
rule rests on -- and that **both counter-example classes above stay non-empty**,
so the conjunction cannot quietly collapse back into either one-field version.
It does **not** and cannot catch the one residual case: a recipe whose orange
tier is *genuinely* 1 while `requiredSkill` is absent reads as unanchored and is
not. That is undetectable from shipped data by construction, because
`MinSkillLineRank == 1` is both the placeholder and a legitimate value -- which
is the whole reason the rule needs two fields.

The last three fields are **enchant enrichment**, present only on recipes whose
craft applies a permanent enchant (all Enchanting recipes, plus Engineering
scopes / belt tinkers). All three are extracted **authoritatively from DBC** — no
recipe-name grepping, no effect-string parsing:

- **`enchantId`** — the `SpellItemEnchantment` id, i.e. the enchant number
  carried in an item link's enchant slot. Lets an addon map an enchant already
  applied to a worn item back to the recipe that produces it.
- **`enchantSlot`** — the target slot, from the recipe spell's
  `SpellEquippedItems` restriction (`"HANDS"`, `"WRIST"`, `"CHEST"`, `"BACK"`,
  `"SHIELD"`, `"FEET"`, `"HEAD"`, `"LEGS"`, `"WAIST"`, `"RANGED"`, `"WEAPON1H"`,
  `"WEAPON2H"`). `nil` for utility enchants with no slot.
- **`stats`** — structured `{ [key] = amount }` stat deltas, keyed by the game's
  own `GetItemStats` keys (`ITEM_MOD_AGILITY_SHORT`, `RESISTANCE0_NAME` = armor,
  `RESISTANCE2_NAME` = fire resistance, …) so they sum straight into item-stat
  totals. `nil` when the enchant carries no static stat (procs / on-use effects
  like Crusader).

## Enchant catalog

Recipes only cover enchants an **enchanter crafts**. Many permanent gear enchants
are applied by a **consumable item** instead — Dire Maul arcanums, the Zul'Gurub /
Zandalar head / shoulder / leg enchants, armor kits, shield spikes — and those
never appear in any profession. The **enchant catalog** exposes both kinds through
one slot-indexed view, so "what can I put on this slot?" is a single call:

```lua
for _, e in ipairs(DB:EnchantsForSlot("HEAD")) do
    print(e.name, e.effect, e.source)   -- "Presence of Might", "...", "item"
    -- e.stats -> { ITEM_MOD_STAMINA_SHORT = 10, ITEM_MOD_DEFENSE_SKILL_RATING = 7, ... }
end

local e = DB:GetEnchant(2583)           -- by SpellItemEnchantment id
```

A catalog **entry** is:

```lua
{
    id     = 2583,                 -- SpellItemEnchantment id
    name   = "Presence of Might",
    effect = "…",                  -- human-readable stat text
    slots  = { "HEAD", "LEGS" },   -- ALWAYS an array (item enchants can target several)
    stats  = { ITEM_MOD_STAMINA_SHORT = 10, … },  -- optional
    source = "item",               -- "item" (applied by a consumable) or "craft" (enchanter)
    itemId = 19782,                -- optional, the item that applies it (source == "item")
    profId = 333, recipeId = …,    -- present when source == "craft"
}
```

The catalog is built lazily from the recipe data (the craftable half) plus a
shipped **item-applied** set (extracted authoritatively from DBC: every
`ENCHANT_ITEM` effect not in a profession skill line, targeting an armor/shield
slot, granted by a real obtainable item — placeholders and dev/QA items are
filtered out). Item-applied enchants are **not** exposed as recipes, so
`GetProfessions()` / `GetRecipes()` are unaffected.

`Search` matches the query (case-insensitive substring) against both the recipe
**name and the effect text**, so `"agility"`, `"5 damage"`, or `"mining"` all
find matching recipes. Results are sorted by name with a `.capped` flag when the
result cap (`max`, default 300) is hit.

## Data layout

```text
Data/<game-version>/_core/<Profession>.lua           -- locale-independent, loaded once
Data/<game-version>/_core/RecipeItems.lua            -- scroll map (every flavour)
Data/<game-version>/_core/Sources.lua                -- where a recipe comes from, npc ids (not Forever)
Data/<game-version>/_core/SourceNames.lua            -- npc id -> English name (not Forever)
Data/<game-version>/_core/HiddenRecipes.lua          -- never-implemented recipe ids (not Forever)
Data/<game-version>/_core/AcquireMethods.lua         -- SkillLineAbility.AcquireMethod, 0 omitted
Data/<game-version>/<locale>/<Profession>.lua        -- name + effect, per locale
Data/<game-version>/<locale>/RecipeScrollPrefixes.lua -- prefixes + sample counts + use text
```

**Every `_core` file carries the wago build it was generated from** in a header
comment -- `-- build 1.15.9.69722 - 131 recipes` on a profession file,
`-- client build 1.15.9.69722 - …` on `RecipeItems.lua`. Until v1.8.0 only
`RecipeItems.lua` was stamped. The stamps are what prove a regeneration actually
ran, and `check-build-pins.py --stamps` checks every one. See *Build pins* below.

**`RecipeItems.lua` existed for Vanilla and TBC only until v1.6.0**, and the way
that failed is worth knowing if you consume this library: on Wrath, Cata and MoP
`GetRecipeItem` returned `nil, false` for *every* recipe, which is
indistinguishable from the legitimate "this one is trainer-taught" answer. Nothing
errored and nothing surfaced it. The visible symptom was downstream — skill-rank
books could not be filtered out, because `isRankBook` is what a consumer filters
on, so *Expert Cookbook* and the First Aid manuals rendered as craftable recipes.

The data is split **core + names** so the locale-independent fields (difficulty,
reagents, ids, …) aren't duplicated across every language:

- **`_core/<Profession>.lua`** — structural data, loaded **once** per game via
  `lib:LoadCore`; guarded by `IsGameVersion` only.
- **`<locale>/<Profession>.lua`** — just the localized `name` + `effect`, loaded
  via `lib:LoadNames`; guarded by `GetLocale()` + `IsGameVersion`.

The library stitches the two into one entry at lookup. A per-flavour `.toc` lists
its game's `_core` files first, then all locale name files, so each client loads
exactly its point-in-time recipe set with the bulky structural table parsed once.

### Ingestion API — what the shipped files call

Every file under `Data/` is a plain chunk that resolves the library through
LibStub and calls one of these. They are public because the data files are the
only callers, and they are worth knowing if you regenerate data or add a flavour.

| Loader | Fed by | Carries |
| --- | --- | --- |
| `lib:LoadCore(profId, t)` | `_core/<Profession>.lua` | difficulty, reagents, requiredSkill, ids |
| `lib:LoadNames(profId, t)` | `<locale>/<Profession>.lua` | localized `name` + `effect` |
| `lib:LoadRecipeItems(t)` | `_core/RecipeItems.lua` | spell → teaching-scroll item |
| `lib:LoadSkillRankBooks(t)` | `_core/RecipeItems.lua` | which of those are rank books, not recipes |
| `lib:LoadSyntheticRecipes(t)` | `_core/RecipeItems.lua` | the scroll-less complement |
| `lib:LoadRecipeScrollPrefixes(t)` | `<locale>/RecipeScrollPrefixes.lua` | localized `"Plans: "` per skill line |
| `lib:LoadRecipeScrollPrefixSamples(t)` | `<locale>/RecipeScrollPrefixes.lua` | how many real scrolls voted for each prefix (v1.7.0+) |
| `lib:LoadRecipeScrollUseText(t)` | `<locale>/RecipeScrollPrefixes.lua` | localized `"Teaches you how to …"` template |
| `lib:LoadEnchantsCore(t)` / `lib:LoadEnchantsNames(t)` | `_core/` + `<locale>/Enchanting.lua` | the applied-enchant catalogue |
| `lib:LoadSources(t)` | `_core/Sources.lua` | spell → npc ids per source kind, plus the `<key>n` true totals |
| `lib:LoadSourceNames(t)` | `_core/SourceNames.lua` | npc id → English name |
| `lib:LoadHiddenRecipes(t)` | `_core/HiddenRecipes.lua` | never-implemented spell ids |
| `lib:LoadAcquireMethods(t)` | `_core/AcquireMethods.lua` | `SkillLineAbility.AcquireMethod`, non-zero only |

`lib:LoadRecipes(profId, t)` is a back-compat shim that splits a self-contained
table into core + names. New data should not use it.

**A second load for a recipe already loaded MERGES** (MINOR 12+): `LoadCore`,
`LoadNames` and so `LoadRecipes` write only the fields the call supplies, so a
top-up carrying `{ name = "..." }` corrects the name and keeps the reagents,
difficulty and the rest. Before MINOR 12 it blanked every omitted field.

Three of those loaders share one file (`_core/RecipeItems.lua`) and **three**
share another (`<locale>/RecipeScrollPrefixes.lua` — prefixes, sample counts and
use text), so a parse anchored to the **file** rather than the **loader** will
sweep unrelated tables together — the mistake two independent scripts have
already made here.

That second count was `two` until v1.7.0 added `LoadRecipeScrollPrefixSamples`,
which is the failure this very warning describes, committed against the warning
itself. **If you add a loader, grep this file for the count before you finish.**

**Every data file must be listed in its flavour's `.toc`, and nothing checks that
for you at runtime.** An unlisted file ships inside the package, installs, and
never executes: no error, no data, and no spec looks at it because nothing loaded
it. All 13 Vanilla `Fishing.lua` files were in exactly that state until
2026-08-06. `Tests/shippeddata_spec.lua` now walks every TOC found on disk.

**The `.toc` flavour suffix must be one the client recognises** —
`_Vanilla`, `_TBC`, `_Wrath`, `_Cata`, `_Mists`, `_Mainline`. WoW Forever uses
`_Camelot` (the suffix the other TOG addons ship for it; Blizzard's Forever
source has no suffixed TOC to confirm it from). **`_BCC` is not**,
and a TOC the client does not recognise is silently skipped in favour of the base
`.toc`, which means the wrong expansion's data with no error. This library
shipped `ProfessionDB_BCC.toc` until 2026-08-06.

## Building / regenerating data

**The whole pipeline lives in this repo as of v1.6.0.** It used to live in
TOGProfessionMaster and write *across the repo boundary* into this one, which
meant ProfessionDB could not rebuild its own data — a consumer owned the
generator for the library it consumed. All eleven tools and their caches moved
here; `tools/pdb_common.py` holds the build pins and shared helpers once, and
`tools/build-recipe-items.py` could not even run here before the move because it
still imported ItemDB's `itemdb_common`. The move was verified by regenerating
the whole `Data/` tree and diffing it byte-for-byte against the previous output.

The data is generated offline from cached wago.tools DBC CSVs (SkillLineAbility,
SpellReagents, SpellEffect, SpellItemEnchantment, SpellEquippedItems, ItemSparse,
…). See `tools/README.md`.

```sh
# everything: regenerates the entire Data/ tree for one flavour
python tools/build_authoritative_data.py Vanilla

# recipe spell -> teaching item, via ItemEffect -> SpellEffect[Effect=36]:
python tools/build-recipe-items.py Vanilla

# where a recipe comes from, from the emulator world databases:
python tools/build_authoritative_sources.py Vanilla

# SkillLineAbility.AcquireMethod, non-zero entries only:
python tools/build-acquire-methods.py Vanilla

# never-implemented recipes, from an installed AllTheThings (must be installed to
# RUN this; it is not a dependency of the shipped library):
python tools/build-hidden-recipes.py Vanilla
```

**A generated file is not shipped until a TOC names it**, and nothing catches
that at runtime — the file installs and never executes. The generators write per
flavour × locale × profession while the TOC entries are a separate edit, five
times over. `Tests/shippeddata_spec.lua` walks `Data/` off disk and fails on any
`.lua` that no TOC lists; it caught all 36 new locale prefix files in v1.6.0
before they were wired.

### Build pins

`tools/pdb_common.py` `EXPANSION_BUILDS` pins the wago build each flavour's data
is generated from. Current, and each verified against its shipped stamp:

| Flavour | Pinned build | wago branch |
| --- | --- | --- |
| Vanilla | `1.15.9.69722` | `wow_classic_era` |
| TBC | `2.5.6.69795` | `wow_anniversary` |
| Wrath | `3.4.5.63697` | `wow_classic` |
| Cata | `4.4.2.60895` | `wow_classic` |
| Mists | `5.5.4.69934` | `wow_classic` |
| Forever | `1.60.1.69977` | `wow_classic_beta` |

Forever is pinned in `BRANCH_BUILDS`, not `EXPANSION_BUILDS`: it is its own
client on Classic-era content, not a point on the expansion axis, so it gets no
emulator trainer or source data. Its `Data/Forever` tree is built from its own
DBC: recipes, 12 locales, RecipeItems and AcquireMethods, with no
HiddenRecipes, Sources or trainer-derived `requiredSkill`.

```sh
python tools/check-build-pins.py --stamps   # offline: pin vs shipped stamp
python tools/check-build-pins.py            # the above, plus staleness vs wago
```

**Two questions, and they fail in opposite directions.** A *stale* pin ships
internally consistent data describing an older client — a question, not a defect.
A *mixed-build* tree ships data from a build the pin does not name, which means
nothing in the repo describes what players actually receive. The offline check
runs first and its verdict prints even when wago is unreachable, because a failed
bump and a wago outage arrive together far more often than either arrives alone.

**Never infer the branch from the version major.** `"3."` also matches
`wow_classic_titan` 3.80.2 (Titan Reforged — a different product that reads as a
14-build-newer Wrath), and `"2."` matches `wow_classic_era_ptr`, which carries
10.1 *Retail* builds. The branch is pinned per expansion in `WAGO_BRANCH`.

**Bump one pin at a time and validate before the next.** Bumping regenerates
every file for that expansion through both builders across 12 locales.
Half-bumping — pin moved, regeneration not completed — is worse than a
consistent old pin, and `--stamps` is what catches it.

**Check every locale before bumping.** `check-build-pins.py --locales <flavour>`
sweeps every locale on each candidate build. Mists sat on 5.5.3 from v1.7.0
until 2026-09-24 because no 5.5.4 build served all eleven (`69383` was short for
zhCN and zhTW, `69155` for ruRU and zhTW, `69078` for seven locales, `69032` for
four); `69934` is the first that does. `pdb_common._assert_not_short` refuses to
cache a short export, so a premature bump fails the build rather than silently
shipping a locale with entries missing.

## Credits

The **never-implemented recipe** list — recipes that exist in the client's spell
tables but were never obtainable by any means, in any expansion — is derived from
**[AllTheThings](https://github.com/ATTWoWAddon/AllTheThings)** (MIT), whose
curated catalog records something no client signal reveals: the spell resolves,
the crafted item resolves, and every generic "is this real on this client" check
passes, so without their curation a recipe nobody could ever learn is
indistinguishable from one a player simply has not found yet.

LibProfessionDB does not redistribute AllTheThings' files. `tools/att-nyi-extract.lua`
evaluates the installed addon's data at build time and only the resulting spell
ids are re-expressed in this library's own format. The project is gratefully
acknowledged.

All other data (recipe names, reagents, skill-up difficulty tiers, required skill,
produced items, enchant ids and stats, scroll prefixes and "Use:" text) is built
from Blizzard client data via [wago.tools](https://wago.tools).
