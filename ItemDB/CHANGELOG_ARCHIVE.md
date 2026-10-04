# Changelog archive

<!-- charset-ok: this is CHANGELOG.md's overflow and inherits its declaration verbatim. No WoW
     client font ever renders it -- nothing loads a .md -- and every section here is a RELEASED
     entry moved across unchanged, which repo law forbids editing. Transliterating the em dashes
     would mean rewriting release history to satisfy a rule about in-game glyphs. New prose is
     written ASCII; the declaration exists so the linter's report stays about current text
     instead of being permanently non-empty, which is how a report stops being read. -->

Older ItemDB / LibItemDB releases, moved out of [CHANGELOG.md](CHANGELOG.md) to keep it under
GitHub's 125,000-character release-body limit. Newest first; nothing here is edited, only moved.

## [v1.0.0] - 2026-09-23

_WoW Forever support, and the first release to call itself 1.0._

### Fixed -- the walk reader skipped Weapon and Armor for three sessions, and it was blamed on another addon

`build-core.py` read **8,498 of 24,069** records from a walk that was complete and correct, and the
missing part was the equippable gear this database mostly exists for. It now reads **24,127 of
24,127** -- an exact match with the walk's own tally -- with Weapon at 3,028 records and Armor at
11,619.

**A Lua table has an array part and a hash part, and this reader only knew the hash part.** The
SavedVariables writer emits integer keys that form a consecutive run from 1 as an **array** -- bare
`"<records>",` lines, in order, with a literal `nil,` holding the slot of an empty one -- while keys
outside that run keep their `[n] =` form. The walk files items by classID, and classes **1 through
7** are exactly such a run. So a pattern matching only `[n] =` dropped precisely Container, Weapon,
Gem, Armor, Reagent, Projectile and Trade Goods, while classes 0, 9, 11, 12, 13 and 15 came through
and made the result look merely incomplete rather than structurally wrong. A second miss on the same
pattern: `[-1]`, the walk's bucket for items whose class it could not resolve, was rejected because
`\d+` does not match a minus sign.

**The reason it survived three sessions is the part worth keeping.** Two independent measurements
agreed -- the parser said 6 classes, and pattern searches over the file also found 6 class keys --
so each corroborated the other. They were the same defect seen twice: the missing blobs are single
lines of up to **523,072 characters**, and the search tool returns only short lines, while the
parser was blind to unkeyed ones. Agreement between two instruments that share a blind spot is
indistinguishable from confirmation. It was written into the todo list as settled fact, and a bug
report against TOG Tools was drafted and very nearly sent; their write path was never at fault.

**What actually broke it open was making the parser report what it could NOT classify.** Three
sessions had read only what it _did_ classify. `--dry-run` now prints the per-class breakdown **and**
every line inside the table the parser walked past, with its length and first seventy characters --
and those characters read `Brute Hammer … INVTYPE_2HWEAPON` and `Cured Leather Armor …
INVTYPE_CHEST`. That is also why `--dry-run` exists at all: asking "what does this walk hold?" used
to require running the builder for real, which is the one thing you must not do while unsure,
because every class file it touches is replaced wholesale.

`Tests/walk_parse_check.py` pins all of it against a fixture carrying both halves: the array part,
that `nil,` **consumes** a slot (otherwise every later class is filed one place too low -- silent,
plausible, and invisible to any total), that an explicit key does **not** consume one, that a
negative key parses, and that the unclaimed-line report actually reports. Red-checked by restoring
the shipped defect, which left only the two explicitly-keyed classes standing.

**`Data/Vanilla` was rebuilt from that walk and the item coverage did not change**, which is the
honest result and worth stating because it was first reported as a gain of 6,445 items. It was not:
the real diff across `Data/Vanilla` is **+319 / -168 lines over 57 files**, nearly all of it header
stamps. The shipped data was already complete at 24,127 -- it had been built from the legacy
storage shape before TOG Tools migrated -- and what the fix restores is the ability to rebuild it
at all, not items that were missing. The seasonal partition was re-run immediately after and the
split still holds, so Era realms see only Era content.

**The 6,445 was an apples-to-oranges comparison, and the builder was making it too.** Its guard
measured the walk against `core_ids`, which reads `Data/<V>/_core` -- the **base** half only --
while a walk carries everything including seasonal items. `itemdb_common` already had
`shipped_ids` for exactly this (base plus the `_seasonal` overlay) and the guard now uses it, so
all three numbers agree: 24,127 declared, 24,127 read, 24,127 shipped. Besides being wrong in the
report, the old comparison made the guard **too lenient** -- a walk carrying 18,000 items would
have cleared a 17,682 "shipped" bar while actually being 6,000 short of what the version ships.

Two files in `provenance_spec`'s `KNOWN_UNSTAMPED` list were struck as a result --
`Data/Vanilla/enUS/Names.lua` and `Data/Vanilla/_seasonal/enUS/Names.lua` now carry a build stamp.
The list is asserted exactly and in both directions, so fixing them went red until they were
removed, which is what it is for. Seven remain, and every one needs an input nobody has.

### Fixed -- the seasonal split aborted on a file with two tables in one loader call

`split-seasonal.py` died with `IndexError: list index out of range` partway through, leaving ten
files partitioned and the rest not -- the worst possible state for a step whose whole job is keeping
two halves consistent.

`_labelled` identifies each data block by the `lib:Load*` call that opens it, so that a base file and
its overlay match up table-for-table rather than by position. **One call can open more than one
table**: `Reagents.lua` is `lib:LoadReagentUses({ [itemID]=professions }, { [skillLineID]=name })`.
Both blocks carried the same label, the dict collapsed them to one, and the rebuild step -- which
consumes one block per data segment -- ran off the end. Repeats now take an occurrence suffix, with
the first keeping the bare label so overlays written before a file grew a second table still match.

**And it refuses instead of crashing.** A mismatch between data segments and table labels now exits
naming the file and both counts, because the failure it replaces was a traceback three frames deep
with no file name in it -- the file had to be identified by elimination. Nothing is written for a
file in that state, since putting its rows back in the wrong order would scatter one table across
two.

Worth knowing for anyone extending the split: only the **first** of those two tables is keyed by
item id. The second is skill-line ids (129-333 on Vanilla), far below the 25,000 threshold, so they
stay in the base -- correct today, but by position rather than by design.

### New -- a builder for the Forever-only instances, from an upstream that declares no licence

`build-sources-wowsims.py` says in its own header that neither wowsims dataset names any of the
maps Forever added, so those instances are **absent** rather than empty. `tools/build-sources-imenso.py`
fills exactly that hole: it reads `Reference.lua` from
[Imenso/AtlasLootForeverImenso](https://github.com/Imenso/AtlasLootForeverImenso) and emits
`SourcesImenso.lua` + `SourceNamesImenso.lua` under `lib:LoadSources("imenso", ...)`, which merges
with the existing rows rather than replacing them.

**It emits only instances the shipped `Sources.lua` does not already cover**, resolved through the
client's own `AreaTable`, so the two builders cannot fight over a zone and re-running either is
safe. An instance name that resolves to no area is skipped **by name in the output** rather than
silently dropped.

**The upstream declares no licence, and it ships anyway with that said out loud.** The repository
carries no `LICENSE` file and GitHub reports `"license": null`. Every other upstream here is
credited _by licence_ in the generated header -- AtlasLoot GPL-2.0, wowsims MIT, Pawn CC BY-NC,
CMaNGOS GPL-3.0 -- so this one is credited by name and URL with the absence stated, on the
pipeline's existing position that which boss drops which item is a fact about the game rather than
an authored work, re-expressed here in this library's own schema.

**Encounter ids are synthetic, and that is the one thing this builder invents.** The upstream names
bosses and carries no npc ids, while `GetSources` reads encounter keys through `tonumber` and
silently drops anything else -- and Forever's new bosses have no npc id anywhere available offline
(DB2 has no creature table; neither wowsims file names these maps). The ids are
`crc32("<instance>|<boss>")` folded into a band at 90,000,000, far above any real Classic npc id
and greppable as synthetic. They are stable across runs because crc32 is, and a collision halts the
build rather than merging two bosses.

**What the upstream says about itself is carried into the generated header**, because a consumer
should see it: `Reference.lua` is a scrape of `foreverchanges.pro`, and its own comment says only
beta-observed drops carry Forever tooltips while "the others Classic's for now". These rows are
evidence, not a server dump like CMaNGOS.

`Tests/imenso_reference_check.py` pins the parser: the refusal on an unclassifiable line, the
optional wing third field, bosses with empty loot tables, and the stability of a synthetic id.
Red-checked by narrowing the boss pattern to the two-element form -- the real defect, not an
inverted expectation -- which made every wing boss unclassifiable and fired the refusal naming the
exact line.

**The "which instances are already covered" reader is pinned against the real shipped file**, not a
fixture, because that is the function whose failure is silent: if it under-reads, this builder emits
rows for a zone `Sources.lua` already has, `LoadSources` **merges** them, and every boss in that
instance is listed twice with nothing raising. It is asserted against the generator's own header
tally (`381 items across 24 instances`) rather than a literal, so a legitimate regeneration cannot
make the check stale while still requiring the parse and the header to agree. Red-checked by making
it collect from the item table instead of the instance table: 405 keys instead of 24, with the
leak assertion firing independently.

**It has now been run end to end, and it ships NOTHING, because the upstream's value is blocked on
something else entirely.** Of the 23 instances in the reference, 17 are already covered by
`Sources.lua`, two carry no shipped items, three are genuinely new and refuse to resolve (below),
and the one that does resolve -- The Hall of Thanes -- contributes **a single item**. The reason is
not the join: **`Data/Forever/_core` does not carry the new dungeons' item ids at all.** Forever's
item table is built from wowsims, which has no more knowledge of those dungeons than its drop data
does, so rows like `270227` and `271096` have nothing to attach to. The generated files were deleted
rather than shipped -- two data files and two TOC entries carrying one row between them, under
headers promising to cover the Forever-only instances, would claim coverage that does not exist. The
builder and its tests stay; it will yield properly the day a Forever client walk fills that core,
which is its own open item.

**The zone-name join was wrong twice before it was right**, and both mistakes are worth recording
because the tests now pin them. First too loose: an exact lowercase match silently missed the two
genuinely new dungeons, because the client's `AreaTable` calls them "**The** Hall of Thanes" (16919)
and "Excavation Site**: Wetlands**" (16732) while the upstream drops the article and the qualifier.
Then too strict: refusing every ambiguous name broke **nine instances that had been resolving
correctly**, because a name matching two areas is the ordinary case -- an instance usually has an
outer zone area and an inner instance area (Stratholme is 2017 and 2279). The rule now normalises
the article, accepts a uniquely colon-qualified variant, and settles a genuine ambiguity by asking
which candidate the shipped `Sources.lua` already uses -- that file defines the id space being
joined to, so it is the authority rather than a heuristic. Where nothing settles it, the builder
**refuses and names the candidates** instead of taking the lowest id, which would be a guess that is
right often enough to be dangerous. Three instances sit there today: City of Dalaran, Excavation
Site and Ruins of Lordaeron.

**And the skip report is one line per instance with its reason**, because the first run printed the
two new dungeons inside a comma-separated list of fifteen skips, where the whole point of the
builder disappeared into what looked like routine noise.

### Fixed -- the locale guard refused an improvement, because it compared against a number instead of the shipped file

`build-locales.py` refused Forever's Italian names for a "7.3% English fallback rate" against a 5%
limit, and that refusal had been recorded as a blocker twice, re-measured once, and left standing.
It was wrong, and the guard's own comment says why: its stated purpose is **"A DEGRADED FETCH MUST
NOT OVERWRITE GOOD NAMES"** -- a claim about the file on disk, which a percentage never looks at.

**Every `itIT` file this library ships is the English list.** `Data/Vanilla/itIT/Names.lua` is
555,376 characters against `enUS`'s 555,353 over the same 17,614 lines, and carries **zero**
non-ASCII bytes where `deDE` at the same ids carries 5,318 -- Italian is heavily accented, so a
genuinely Italian list cannot be pure ASCII. TBC and Mists are the same. So Italian had nothing to
lose, a build that came back **92.7% localized** was refused, and the 100%-English file it would
have replaced sat there untouched. The limit punished the improvement, and the reported reason
("it refused to ship a mostly-English Italian file") described the opposite of what was measured.

**The refusal is now a regression check against the names already on disk.** A build is refused
when it carries fewer localized names than the shipped file, naming both counts and the loss. That
catches the incident the limit was written for -- zhTW arriving with 37,465 localized over 41,777
already shipped is a loss of 4,312 and is refused on the numbers rather than on a threshold
somebody had to guess -- and it stops punishing a locale that has nothing to lose. A locale with no
file yet has nothing to regress from, so a first build is allowed. The rate is still computed and
still printed when it exceeds `--max-fallback-pct`; it no longer decides anything.

**And the underlying fact is documented rather than carried as a blocker**, which is what it always
was: Blizzard did not translate these items into Italian. An Italian client shows English names in
game, and this library returning English for `itIT` is correct behaviour, not missing data.
`README.md` now says so instead of promising Italian "appears when that export is complete".

### Fixed -- the shrink guard covered one builder of thirty, and its baseline moved toward accepting damage

The refusal added to `build-core.py` below is one write site in one builder. `tools/` holds **30
`build-*.py`**, several of them writing more than one shipped `Data/` file, and **every one
replaces the file it writes rather than merging into it** -- so a short input never adds nothing, it
deletes. Guarding them one at a time needs per-builder knowledge of what "too short" means for that
builder's input; the property that actually matters is on the **output** side and needs none of it.

So it is one check at the gate instead: **`Tests/data_shrink_check.py`**, run after any builder. It
reads the shipped tree, so it covers every write site without knowing where they are -- including
every side table no spec pairs up, and every builder not yet written.

**Two baselines, because a relative check with a mutable baseline is not a guard.** The first cut
compared only against `HEAD`, and `HEAD` moves in the direction of accepting damage: let a damaged
tree be committed once -- by exactly the session this check exists for -- and 8,545 becomes the
floor, every later run compares 8,545 against 8,545, and nothing in the repository remembers
17,604.

- **`Tests/data_baseline.json` is the real guard** -- 256 files and their row counts, moved only
  when a human runs `--record`. Committing damage does not lower it.
- **`HEAD` stays as the second signal**, because it catches a shrink in the working tree before any
  commit and prints the before/after a reviewer wants. It cannot be the only one.

Red-checked on the committed-damage scenario specifically rather than on a shrink in general -- a
plain shrink fires both clauses and proves nothing about their independence. Raising one recorded
count above the tree's made the floor fire **alone**, naming `1000 lost against the recorded
floor`, while git reported no row change at all. `ITEMDB_ALLOW_SHRINK=1` lets a single understood
shrink through without re-recording, printing what it would have refused.

**This corrects a claim made below, and the correction matters more than the check.** That entry
says every check in the repo stayed green while the data was gone. Driven with the damage actually
in the tree, **the suite goes red with 8 failures** -- `seasonal_split_spec` catches all seven split
pairs and names the remedy, `provenance_spec` catches the stamp. The original claim came from
running the suite _before_ the builder and describing the state _after_ it. What remains true, and
is this file's narrower honest value, is that **nothing else names the row loss itself**: no other
check says `17,604 -> 8,545`. It also covers the flavours `seasonal_split_spec` cannot, since only
Vanilla has a `_seasonal` overlay, and a row count alone would have reported the six rewritten
class files as fine, because they _grew_ (991 -> 1,688) when a rebuild wrote the unsplit set over a
base the split had emptied.

### Fixed -- the suites file was validated by text matching, and "the harness has no JSON reader" closed the question

`Tests/suites_spec.lua` asserts `.writ-suites.json` from the Lua suite, but the harness has no JSON
reader, so it matches **text**: every quoted string ending `.py` / `.lua` / `.html` is checked as a
path. That is a smoke test. It cannot see a missing `argv`, a malformed entry, a label where a
marker belongs or a suppression with no reason, and it would wrongly flag a prose `label` that
happened to end in a path-like token.

That was filed as stuck, on the grounds that the fix "needs a JSON reader the harness does not
have" -- a true statement about one tool, closing a question while the route sat open beside it.
**The check does not have to be Lua.** This repository already runs Python checks, one of them added
in the same session that filed the excuse, and the standard library has `json`.

**`Tests/suites_check.py`** is the structural half, run as a checklist item; the Lua spec stays,
because it rides the always-run suite and catches the case that actually happened -- the file absent
entirely. Red-checked with a `command` key where `argv` belongs, a shape the text matcher
structurally cannot see, and writ's own offered-suite list **silently dropped** that entry, which is
exactly the failure it guards.

### Fixed -- a probe's headings named values where it had grouped declaration lines

`tools/probe-combat-constants.py` reported its groupings as though they compared constant _values_;
it groups **declaration lines**. That is what made a reading of "0 identical" look plausible when it
should have looked wrong, and a wrong reading of this probe is what produced the "every melee score
on Forever is affected" claim corrected below. The headings now say what they count.

**Archived v1.0.0's oldest entries into `CHANGELOG_ARCHIVE.md`.** The live file had reached 109,844
characters with 10,156 under the 120,000 working ceiling for the GitHub release body. Every
released section had already moved, so the only boundary left was **between entries inside the
unreleased v1.0.0** -- 548 lines / 41,548 bytes moved byte-for-byte, newest-first, with both sides
of the join read back (the `---` separator travelled with the span and was put back). The live file
came down to 68,582 characters. The earlier conclusion that a single-version file had no boundary to
split at was wrong: an entry is a boundary.

### Changed -- the eligibility calls document their live-player default, which alt planning gets wrong

`RaceUsable`, `ClassUsable` and `CanUse` all default their subject to the **logged-in** character.
That is right for a bag or a vendor list and wrong for a stored profile: it would judge a saved
night elf by whoever happens to be at the keyboard, silently, returning a plausible boolean either
way. `README.md` now states it as a contract — pass the id explicitly whenever the subject is not
the live character, and **skip the check** when a stored profile has no race recorded, because
failing open is honest where judging a character by a different character is not.

Found by a consumer adopting the race check into alt planning, which a delivery here could not have
seen: the defaulting is correct for the call it was designed for, and the case where it is wrong
returns a boolean either way. Written once and referenced from the other two rows rather than
repeated, because the defect is the class of player-defaulting calls and not the one that was
reported.

### Fixed -- the core builder could not read the walk it is built on, and would have deleted data if it could

`build-core.py` reported "no itemDB.classes data found" against a **fully walked** client, and that
report was wrong twice over. Three separate defects, each of which alone made the walk unreadable
or unsafe:

- **TOG Tools moved its storage and this builder never followed.** The walk now saves
  `itemDB.classesBlob` — one string per class, whole item records joined by RS — and the migration
  ends with `wipe(store.classes)`. So the old key is not stale, it is **deliberately emptied**, and
  a reader that only knows it sees a complete walk as an empty one. Both shapes are now read,
  current first.
- **`str.splitlines()` shredded the blob.** Python splits on `\x1c`, `\x1d`, `\x1e`, `\x85`,
  ` ` and ` ` as well as newlines — and `\x1e` is exactly the record separator the walk
  uses. Every `classesBlob` string was cut into one fragment per item before any pattern saw it, so
  the table's own `[classID] = "..."` line never matched. Now splits on `\n` only.
- **The walk-file selector was ranking by another addon's number.** It searched
  `["itemDB"] … ["count"]` with `DOTALL` and a lazy quantifier, which matches the first `["count"]`
  anywhere after `["itemDB"]` — whichever module happened to serialize next. It now ranks by
  counting RS bytes, which nothing but the walk writes.

**And a guard, because fixing the read exposed something worse.** Every class file this builder
touches is replaced wholesale, so a short walk does not add nothing — it **deletes**. Run against a
walk carrying 8,545 items, it cut `Data/Vanilla/enUS/Names.lua` from 17,604 names to 8,545 and
rewrote six class files. _(This paragraph first said every check in the repo stayed green. It does
not -- driven with the damage in the tree the suite goes red with 8 failures; see the shrink-guard
entry above, which corrects it and says what no check did catch.)_ It now refuses when the walk
carries fewer items than the walk itself reports finding, **or** fewer than `Data/<Version>/_core`
already ships, naming both numbers; `--allow-partial` is the deliberate override.

### Changed -- Forever's scoring exposure is measured at last: one item, not "every melee score"

Forever ships Classic's scoring rules because no Forever stat scale exists anywhere, and that
reuse carried an unanswered question: those rules encode a **combat model**, not just weights, and
nobody had checked whether it holds there. Measured against the cached WoWSims trees with a new
`tools/probe-combat-constants.py`:

**It does not hold.** WoWSims' Classic sim derives its whole melee table from
`targetDefense - weaponSkill`; the Forever sim has **no weapon-skill dimension at all** — every
entry is a flat level lookup. But the two agree on three of four at a level-63 boss: Classic
_computes_ 0.08 miss, 0.065 dodge and 0.14 parry, and Forever's constants **are** 0.08, 0.065 and
0.14. Only glancing differs — 0.40 against 0.24.

**And the divergence reaches one item.** The differing arithmetic is reachable only through the
weapon-skill rule, which returns zero for any item without a `+N weapon skill` stat, and Forever's
data carries exactly one: Devilsaur Claws, +4 unarmed — scored only when the caller declares an
unarmed attack. The earlier filing said a mismatch would mean "every melee score on Forever is
affected"; that was wrong, as was the separate earlier claim that the per-weapon-skill _weights_
were known wrong (there are no such weights).

`Tests/forever_scoring_spec.lua` pins that population exactly, in both directions, so adding or
removing a weapon-skill stat on Forever goes red rather than silently switching a foreign combat
model on or off.

**The spec was written asserting zero and went red on its first run**, which is why it exists
rather than the conclusion being filed. Three searches had reported none; all three used
`WEAPON_SKILL_` as a whole word, which matches **nothing** in any flavour because every real key
continues past the underscore. That false zero read as "Forever has none" _and_ as "Vanilla has
none" — and Vanilla plainly has the mechanic, which should have been the tell. The spec now carries
a Vanilla control for exactly that reason.

### Fixed -- the reagent tooltip's classic fallback is under test again, and the package is back to 100%

`Tooltip.lua`'s default-target resolution — the two lines that resolve `GameTooltip` and
`ItemRefTooltip` when the modern `TooltipDataProcessor` route is unavailable — went uncovered when
the harness began modelling that API. The load-time hook then succeeded and latched, so every later
no-argument call returned early and a call naming frames skipped the resolution by definition:
within one load of the file the branch was genuinely unreachable.

**The recorded fix was to nil the modern API before loading the file, and it was the wrong trade** —
it would have bought the branch by giving up the three examples that watch the _real_ registration
against the modelled API, which is better evidence than a stub. The recorded alternative was a
second Lua state or a new harness affordance.

**Neither was needed.** `loadAddonFile` runs the chunk afresh, so a **second load** gets new
upvalues and `hooked` starts false again — both halves, no trade. The second load also nils
`GameTooltip` and `ItemRefTooltip`, so the frame list resolves to nothing and **no live handler is
attached to the harness's real tooltip** for every later example to carry; the four functions the
file defines are restored to the first load's closures afterwards, so nothing downstream sees a
different `Tooltip.lua` than the one the manifests load.

It buys two real assertions rather than a coverage number: on a client with neither surface,
`EnableReagentTooltip()` reports **false** rather than claiming an attachment it did not make (the
documented contract — finding nothing is not an error), and it registers **nothing**. That is the
path a client without the modern API takes, which is why the fallback exists at all and why the
deliberately-empty Wrath and Cata manifests matter.

**3,417 of 3,417 executable lines, 100% across all nine shipped files**, `Tooltip.lua` 86/86. The
test harness pin moved to `b818c74dd5f5` in the same pass, with the whole suite green before and
after.

### Fixed -- the repo's own test suites were declared where the repo could not see them

The whole-tree `ruff` sweep added below was declared through writ's desk, which stores the
declaration in **writ's bank rather than in this repository**. The tree carried no
`.writ-suites.json` at all, so a clone, a fresh checkout or any other machine got no ruff suite —
and "ruff clean" quietly went back to meaning whatever somebody had typed. The gate line claiming
"ruff clean over all of `tools` and `Tests` as a declared suite" was true for exactly one session
on exactly one machine.

**The declaration is now a file at the repo root**, and the bank copy is cleared so there is one
source. Eight one-off builder invocations had also accumulated there as permanent "suites" —
including one that regenerates shipped data — and they are gone with it; a builder run is not a
test.

**`.busted` is `suppress`ed in that file**, which closes a hazard this repo had been handling with
prose alone. Running busted here is a documented false green (the file is an inert shim; with no
config it collects recursively and drags in the harness's own `spec/`), and a tool _offering_ it is
the worst form of the trap because it reaches the forbidden runner without anybody typing the word.
It is now refused, with the reason, instead of listed.

**`Tests/suites_spec.lua` keeps it that way**: the file exists, it names only paths that are on
disk, `.busted` is suppressed, and every Python check `CLAUDE.md` tells a session to run is
declared — so documenting a new check without declaring it goes red. Both the path and the
cross-file assertions were red-checked against real defects rather than inverted expectations.

Found by review globbing for `**/.*-suites.json`, which returned one hit belonging to the harness
submodule. **A bank-stored suite runs, passes and reports success the entire time it is
invisible**, which is why nothing inside the repo could catch it, and the desk printed "Stored in
writ's bank, NOT in the repository" on all ten calls that made one.

### Fixed -- the Forever stat-weight file told consumers a weaker thing than we knew

`Data/Forever/_core/BiSWeights.lua` shipped a header saying the effects behind Forever's renamed
talents "has not been compared, so treat the per-weapon-skill valuations here as unverified".
They had been compared, and they differ -- 30 of 32 renamed talents and 265 of 383 same-named
ones, 147 structurally. The comparison landed in `Scoring/Vanilla.lua`'s header and the builder
that writes the shipped file was never updated, so the file a consumer actually reads carried the
older, weaker claim. Corrected and regenerated.

**A per-stat "not applicable on Forever" marking was built and backed out the same day**, and the
reason is worth more than the feature would have been: **there is nothing to mark.** HawsJon's
scale carries no `WEAPON_SKILL_*` weight at all -- its melee vocabulary is `DPS_MAINHAND`,
`HIT_PCT`, `CRIT_PCT` and the primary stats. Weapon skill is priced by a _rule_ in
`Scoring/Vanilla.lua`, which reads the item's own `+N` skill and values it through a
miss-and-glancing model. The plan had conflated a scoring rule with a stat weight; the emitted
list came out empty, which is how it was caught. `authoredFor = "Vanilla"` already states the
honest fact at the level the evidence supports: the whole scale is Classic's.

### Fixed -- the reagent tooltip's own specs were removed for a reason that was wrong twice over

Two specs driving `Tooltip.lua`'s `TooltipUtil.GetDisplayedItem` read and its
`TooltipDataProcessor.AddTooltipPostCall` registration were removed with a declaration saying the
test harness could not hold either global -- evidenced by a precondition reading one back as `nil`
immediately after setting it. Both halves of that were wrong, and the harness established it.

**The assignment always worked.** The `nil` was the harness's own `finally`, which ran its
function immediately, so the line after a save-and-restore saw the cleanup instead of the value.
That is fixed; the specs were restored and passed unchanged, taking `Tooltip.lua` to 100% (86/86).

**Then the harness modelled the API for real, and that was better again.** With
`TooltipDataProcessor` and `TooltipUtil` in the environment, the reagent tooltip's load-time hook
takes the branch a real client takes, so three examples now watch the _actual_ registration
instead of a stub of our own. Two specs went red on that pin and both reds were right: one was
asserting the environment's _absence_ of an API and reporting it as a property of this library,
and the other could no longer reach a branch the successful load-time hook had already taken.

One cost, stated rather than buried: `Tooltip.lua` sits at **84/86**, and the two lines are the
fallback's default-target resolution, reachable only by a hook attempt that fails to take the
modern path. That path stays — it is what a client without `TooltipDataProcessor` uses, which the
deliberately-empty Wrath and Cata manifests exist to support. Everything else is at 100%:
**3,415 of 3,417 lines.**

**And the flavour premise was false.** The request called that path "modern" and said Classic Era
lacks it. Era has it: `TooltipDataProcessor.AddTooltipPostCall` is defined in Era's own
`Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua` at line 199, and Era's UI calls it for
`Item` tooltips. So this is the path **every** shipped flavour takes.

Nothing in the shipped code was wrong: `Tooltip.lua` feature-detects and never branches on
flavour, so Era already took the right path. The falsehood lived only in the request's prose and a
spec comment, both corrected. Worth recording because of what it nearly cost -- the harness had
been asked to make those globals _absent_ on Era, and had they built it, a green spec would have
pinned the false belief permanently. They refused for exactly that reason.

### New -- Mists ships a gem table: 605 gems (MINOR 34)

`Data/Mists/_core/Gems.lua` did not exist, so `GetGem` and `GetGems` answered nothing on a
client that very much has sockets -- 7,406 red, 6,339 yellow, 5,728 blue, 2,307 meta and 67
prismatic sockets across the shipped Mists items, and no way to ask what could go in one.

Surfaced answering an inbox question from Dibs about whether `Data/TBC` ships gems, where the
one-character difference between `Gem.lua` (the item-CLASS core file, gem items and their stats)
and `Gems.lua` (the gem table) was about to make a consumer's published defect account wrong.
Mists has the first and lacked the second.

It was never a missing SOURCE: Pawn publishes `GemsMists.lua` and `build-gems.py`'s `GEM_FILE`
has always named it. What was missing was `STAT_MAP["Mists"]`, without which the builder exits.
Every one of the 15 mappings was checked to exist in the shipped Mists item data before being
written, by counting distinct `ITEM_MOD_*` keys in the class cores -- a gem stat landing on a key
nothing else uses would be a silent zero. `MetaSocketEffect` is deliberately unmapped: it is a
flag (`= 1`) meaning "this gem has a meta effect", not a stat with a magnitude, and the builder
reports it as unmapped rather than dropping it silently. The 80 meta gems still ship, with their
real stats and a colour of `M`; the meta effect itself is not modelled.

**Mists has no scoring module**, so unlike TBC this does not feed `GetItemScore` -- there it
still returns nil and `HasScoring()` is false. The gem table serves a picker and a tooltip, not
an automatic socket valuation. An earlier note of mine claimed socket scoring was returning 0 on
Mists; that was wrong, because `scoreSockets` lives in `Scoring/TBC.lua`, which Mists never loads.

**And TBC's `Gems.lua` was regenerated**, because it carried no `-- source` fingerprint although
its builder has emitted one for a month -- the file predated that change and had never been
rebuilt. The diff is exactly one added line and no data moved, which was checked rather than
assumed.

### Fixed -- both per-instance attribute maps are constrained to instances that exist (MINOR 34)

`LoadSources` stored the `expansions` and `kinds` tables without reference to the `instances`
table beside them, so a builder emitting an attribute for a key its `instances` table never
mentioned left `GetInstanceKind(key)` answering `"raid"` for a place `GetInstances()` does not
list. A consumer iterating the list and a consumer holding a key then disagreed about whether an
instance existed at all, with nothing raising. `srcInstExp` had that property since MINOR 16 and
nothing noticed for seventeen versions; `srcInstKind` inherited it at MINOR 33 by being written
next to it.

`instances` is now stored FIRST and both attribute maps are filtered against it -- an attribute
for an unknown key is dropped, matching the value filter already on `kinds`. **No shipped data
changes**: all four `Sources.lua` files were measured and carry zero attribute keys outside their
own instances table (Vanilla 33, TBC 59, Mists 80, Forever 24, each with matching key SETS rather
than merely matching counts). The within-call ordering this now depends on is itself pinned by a
spec, because reversing it would drop every attribute in every shipped file and read as nil.

Found in a self-audit, and filed naming only the NEW map. Peer Review rejected that split: finding
a second instance of a class while filing the first is the moment to sweep, not to defer.

### Fixed -- every builder now refuses an unknown version, and a check keeps it that way

The guard below first shipped in three builders out of twenty-nine, which is not a migration --
it is the files that happened to be open. Worse, that state was invisible: finding the ratio took
a throwaway probe, so "filed" and "forgotten" were the same state, and this repo has lost a month
to that exact route before.

**The guard moved into the shared helpers** — `core_ids`, `shipped_ids` and
`wago_build_for_version` validate the version they are handed, which reaches twenty-six builders
with no per-file placement, because they already pass it straight through.

**That was not enough, and the second fix is the one that matters.** Twenty of those builders
called the helper like this:

```python
build = args.wago_build or wago_build_for_version(args.version)
```

`or` short-circuits, so supplying `--wago-build` skipped the helper and with it the check.
`build-talents.py Forver --wago-build <b>` created `Data/Forver/_core/`, wrote two files whose
headers read "WoW Forver", and exited 0. The override is now a **parameter** —
`wago_build_for_version(args.version, override=args.wago_build)` — so the call always happens,
and the precedence rule that was copied into twenty files lives in the one function that owns it.

**And the check was blind to it**, because counting call sites cannot tell that a call sits behind
a short-circuit. It now asserts both: that every version-taking builder reaches validation, and
that no branch can skip a validating helper.

**That assertion took three cuts, and the middle one is the instructive failure.** The first
banned `or`/`and` beside the call — the shape that had just bitten us, and nothing else. The
second claimed the general property and did not have it: it tested the _text to the left of the
call on its own line_ and accepted "indentation, then `name =`", so a ternary was caught while
this identical bypass was not:

```python
build = args.wago_build
if not build:
    build = wago_build_for_version(args.version)
```

Driven rather than reasoned about: with that edit in place the check exited 0, while its own
comment asserted it covered an `if`/`else` branch. **A green check naming the right property is
read as coverage**, which makes a false claim there worse than the narrow ban it replaced. The
third cut reads the **syntax tree**: a call is flagged when it sits inside an `if`/`else` body, a
ternary's branches, a loop, a `try`/`except`, a later operand of `or`/`and`, a comprehension or a
lambda. Red-checked against all four shapes in turn — each named `build-talents.py` and the line —
and green on the real tree, so no legitimate conditional call was swept up. Reading the tree also
retired the two prose false positives the line-based cut had to special-case, a comment in
`build-hidden.py` and a docstring line in `build-vendor-prices.py`.

Two residuals are stated in the check with no claim of coverage: a `return` or `sys.exit` growing
_above_ the call, and a call inside a function that is itself only reached conditionally.

**And the drive itself is now a check rather than something to remember.** Everything above reads
the builders' _source_; none of it runs one, so none of it can say the guard refuses rather than
merely that it is reached — a distinction that went unspent through three consecutive reviews
because everything around it was green. `Tests/version_guard_drive_check.py` runs
`build-talents.py` and `build-score-model.py` with a typo'd version and asserts the refusal end to
end: exit 1 rather than argparse's 2, the typed spelling and the meant spelling both named, no
traceback, and — the assertion carrying the original defect's actual signature — **no directory
created for the typo'd version**. It found something on its first run: `build-score-model.py`
accepts no `--wago-build`, so driving both builders with a uniform flag was testing argparse
rather than the guard. Each builder is now driven with the arguments it accepts.

Found by review reading one builder rather than trusting the sweep that claimed to have fixed
this — and the tell was in the sweep's own note that the call sites were "read-and-reasoned, not
driven".

**`ruff` clean now describes the repository rather than the diff.** The gate had been running over
the edited set, so pre-existing findings were only ever surfaced by touching a file — six of the
twenty-one edited in the sweep above carried some. Swept over all of `tools` and `Tests`: three
more, in two files nobody had opened (`audit-sources.py`'s import block, two placeholder-free
f-strings in `wago_probe.py`). All fixed.

Each site says what its own silent failure would have been, because they differ: `core_ids`
returns an empty set that every caller reports as "no core built yet", `wago_build_for_version`
returns `nil` that is indistinguishable from Wrath and Cata's correct `nil`, and
`build-proc-rates` has a defaulted lookup that would quietly write Vanilla's filename for
whatever was typed.

### Fixed -- a builder invoked with the wrong CASE halted on its own safety table

`build-sources-wowsims.py` looks `EXPECTED_LEAK_ZONES` up with `args.version`, and that table is
keyed by the exact string `"Forever"`. Invoked as `forever`, the lookup missed and the build
stopped on the two cross-expansion leaks that table exists to declare as _expected_ -- so a command
line argument's casing was silently load-bearing on a safety table.

Fixed at the ENTRY rather than at the lookup: `itemdb_common.validate_version` refuses an unknown
version by name, and names the correct spelling when the only difference is case. Both source
builders call it before reading anything. Case-folding the one lookup would have fixed that table
and left the next exact-string table (`FROZEN_BUILD`, `ATLAS_FILES`) with the same trap.

### New -- the suite can tell a data file that did not get REBUILT (`Tests/provenance_spec.lua`)

`Data/Mists/_core/Sources.lua` shipped Vanilla's 33 instances as the whole Mists drop graph for
months. Every check in this repo stayed green throughout, and all of them were correct: the file
existed, the TOC named it, it parsed, it loaded, and it returned real data. An item-count floor
would not have caught it either -- a stale file still has its old, plausible count.

What catches it is cross-file provenance. Every generated file already stamps what it was built
from, so the new spec asserts those stamps agree where they must: within a flavour every file
states the same build, both in the `-- client build` line `itemdb_common.header()` writes and in
`lib:SetBuild`, and the two agree wherever a file carries both; a flavour's `Sources.lua` and
`SourceNames.lua`, which one builder writes in one run, declare identical `-- source ... sha256:`
fingerprints; a shared upstream is the same snapshot in every flavour that reads it; and the
AtlasLoot inputs are cumulative, so no version is built from fewer inputs than the expansion
before it -- which is the Mists defect stated directly. A header-vs-content recount rides along as
the second net, for a build that RAN and produced almost nothing, which the stamps cannot see
because they would be current.

**Red-checked rather than assumed**, three times and each against the real condition rather than a
flipped expectation: a shipped header count, a sibling fingerprint and one locale's build stamp
were each corrupted in turn, each produced exactly the one failure naming the file and the remedy,
everything else stayed green, and all three were reverted.

**It found a real one on its first widened run.** Vanilla ships two different wago builds: its
`_core` side tables are `1.15.9.69722`, refreshed to the live Era build as a deliberate change
earlier in this unreleased version, while its twelve locale directories are still `1.15.9.69109`.
The cost was measured before the assertion was relaxed, rather than assumed small: the number of
item ids in the class cores that NO locale can name is **zero** on all four flavours (Vanilla
24,127 of 24,127, TBC 30,032, Mists 88,259, Forever 19,171), because `build-locales.py` takes its
id set from the built core and falls back to the English name. A lagging locale export therefore
degrades a translation rather than losing an item. Locale files and core files are consequently
compared as separate groups -- but one locale left behind while its eleven siblings rebuilt still
goes red, which is the case worth having.

**One label, two quantities** -- recorded rather than silently normalised. `-- client build 11508`
in the item-class files is a client interface number; `-- client build 1.15.9.69722` in the side
tables is a wago build string. Forever proves they are distinct, carrying `1.60.1.69913` in files
that also say `lib:SetBuild(16001)`. The spec compares within a kind and never across.

**What it does NOT cover, so nobody reads it as broader than it is.** It protects against a file
going stale, not against the building rule being wrong. Extending the cumulative rule from TBC to
Mists remains an inference that nothing here tests.

### Fixed -- two stale claims that a shipped flavour classifies no instances

The `GetInstanceKind` row in `README.md` and a spec comment both still gave Mists as the live
example of a version shipping no kinds. Mists has carried 80 of 80 since its rebuild earlier in
this same unreleased version. The `nil` branch stays -- the contract is about what the data
guarantees, not what today's coverage happens to be -- but the example was simply false.

**Archived v0.9.0 into `CHANGELOG_ARCHIVE.md`.** The entries above took the live file to 113,410
characters, 6,590 under the 120,000 working ceiling for the GitHub release body -- thin enough
that the next batch this size would breach it. The v0.9.0 section (6,158 bytes) moved across
unchanged and newest-first, both sides of the join were read back, and the pointer line now reads
"v0.9.0 and earlier".

### New -- buff auras carry a mutual-exclusion slot, and the weapon imbues finally carry one too (DIBSREQ-IDB-008, MINOR 31)

Two halves of one contract from Dibs, whose "Full raid" preset ticks one buff per exclusion token
and is gated on `AuraExclusivityKnown()` -- so the button does not appear until this ships.

**Auras.** Every `GetAuraBuff` / `GetAuraBuffs` / `GetBuffsInCategory` row now carries
**`exclGroup`**, and `lib:GetAuraGroup(name)` answers for a single buff. Keyed by buff NAME, since
every rank shares the slot. The two groupings that matter: `Blessing of Kings` and `Greater
Blessing of Kings` are both `blessing-of-kings`, and all eight `Sayge's Dark Fortune of ...` are
`sayges-fortune` -- previously two rows and eight rows that a preset counted separately. Everything
else gets a token of its own, which is the positive statement that nothing shares its slot; `nil`
survives only for the two hunter aspects, and means unknown rather than "stacks with everything".

**Where it comes from, and the wrong answer that looks right.** The client does NOT encode aura
exclusivity. Kings 20217 and Greater Kings 25898 _do_ share a `SpellCategories` row, which reads
exactly like confirmation -- but so do Mark of the Wild and Gift of the Wild, and the shared values
are Category 0 plus the global-cooldown `StartRecoveryCategory` that nearly every buff carries.
Grouping on it would have bundled unrelated buffs and looked correct on the one pair anybody would
spot-check, which is the same trap as the consumable `categoryId`. The real source is WoWSims' buff
protos, which have ONE FIELD PER SLOT: `IndividualBuffs.blessing_of_kings` is a single bool, and
`sayges_fortune` is a single field typed by the enum `SaygesFortune` -- one value at a time. Both
enums were read rather than inferred from the field shape, including `TristateEffect`
(Missing/Regular/Improved), which is the model stating that a buff's regular and improved forms
share one slot. Tokens are the field name, kebab-cased, so a reader can find the source.

Each version reads its own WoWSims model first, then wowsims/classic for a buff its own does not
name. That fallback is narrow and deliberate: it is rejected for consumable groups, which are a
claim about ITEMS, but every buff it reaches here is literally the same spell id on every version
that ships it (Sayge's is 23735-23769, Spirit of Zandalar 24425, Songflower 15366 -- identical
across all three generated files, checked row by row). The reference repo is fixed rather than
"whatever is cached", so two machines cannot generate different data from the same inputs, and
every borrowed slot is listed in the build output. Vanilla ends with 39 of 41 buffs tokened, TBC
38 of 40, Forever 28 of 30.

**Totems each keep their own token and never share one.** Two shamans give two different totems, so
there is no static exclusion between them to state, and Dibs asked us not to invent one.

**Weapon imbues -- a defect in this pipeline, not a gap in the source.** Vanilla's oils, sharpening
stones and weightstones had no `exclGroup` at all, so a grouped picker never showed them.
`build-consumable-groups.py` matched only WoWSims' plain-const config shape
(`export const X: ConsumableInputConfig<Flask> = { actionId: ... }`), and an input that depends on
which slot it applies to has to be a function of that slot
(`export const BrilliantWizardOil = (slot: ItemSlot): ConsumableInputConfig<WeaponImbue> => { return {`).
Every imbue is written the second way, so all sixteen were skipped silently -- and a pattern that
misses is indistinguishable from a source that says nothing, which is how this read as "WoWSims
does not type imbues". Vanilla goes from 78 tokened consumables to 94, the sixteen new rows all
`weapon-imbue`; TBC and Forever data rows are unchanged. One token covers both hands: WoWSims
models main-hand and off-hand imbues as two independent fields, so an off-hand oil does apply
alongside a main-hand one, but how many weapon slots a player has is the consumer's rule. The
shaman and rogue imbues stay out because they are spells rather than items.

**Corrected while here:** the README said eight of Forever's modelled consumables ship untokened.
Five do. Eight carry no `Consumable.type`, but three of those are still tokened by the hand-listed
arrays -- Demonic Rune 12662 is `conjured` -- and "no db type" was being reported as "no token".
Read off the shipped file, which is the authority.

### New -- what a material is FOR: the reagent → professions direction (MINOR 32), the first half of folding SmexyMats in

`GetReagentUses(itemID)` answers which professions use an item as a crafting material, and
`IsReagent(itemID)` is the cheap boolean a tooltip hook needs when it asks of every item the player
looks at. This was the one direction the database could not answer: `GetSources` says where an item
comes from and LibProfessionDB says what a recipe needs, but nothing said what a stack of Mageweave
is _for_. SmexyMats existed to answer exactly that and is abandoned.

**Derived from the client, not from LibProfessionDB's tables.** The fact is a join of
`SpellReagents` (spell → up to 8 reagent items), `SkillLineAbility` (spell → skill line) and
`SkillLine`, all of which this pipeline already fetches. LibProfessionDB models the same recipes
_recipe-first_ and carries no reverse index; deriving ours from the shared upstream means neither
library depends on the other's schema and neither holds a copy of the other's data. They are two
projections of one source, which is not the duplication the repo rules warn about.

**Which skill lines count as professions is read from the client.** `SkillLine.CategoryID` separates
them identically on every version measured: 11 is the primary professions, 9 the secondary ones
(Cooking, First Aid, Fishing), and **7 is class spell trees** — Arcane, Demonology, Subtlety,
Poisons, Engraving. Category 7 is why a filter is needed at all: those spells have "reagents" too,
but they are spell components, and without it the library would answer "which professions use this"
with "Shadow Magic". A name list would have worked today and rotted.

`SkillLine.CanLink` was tried as the filter and is wrong — it reads 0 for **every** profession on
Vanilla and TBC, so it would have emptied both files, and on Forever it reads 1 for
`Test Profession [DNT]`. That is recorded in the builder so nobody tries it twice.

Three narrower rules, each reported on every run rather than applied silently: skill lines carrying
Blizzard's `[DNT]` test marker are dropped (the same marker `build-hidden.py` already filters items
on, and Forever's test line consumes Copper Ore); **duplicate profession lines collapse to the
lowest id**, because Forever re-declares its professions and ids 171 and 2937 are both "Alchemy", so
an item would otherwise list Alchemy twice; and a skill line contributing fewer than two reagent
items is dropped. That last one is a **declared heuristic, the only one here** — category 9 holds a
few non-professions that carry a single reagent row (Vanilla's "Survival", Forever's
"Comprehension"), and excluding them by name is the list that rots, while "a real crafting
profession uses more than one material" holds everywhere measured, the smallest genuine one being
First Aid at 10. Its cost is stated in the builder: a profession genuinely using exactly one
material would vanish.

Ships for Vanilla (469 reagent items, 9 professions), TBC (618 / 10), Mists (969 / 17) and Forever
(579 / 13). Names are enUS beside the ids, exactly as `SourceNames.lua` does it, and localisation is
the same follow-up.

**And the library now shows it, on the game's own tooltips.** `Tooltip.lua` adds a
"Used by: Alchemy, Tailoring" line, on by default, with `SetReagentTooltipEnabled(false)` to turn it
off persistently. This is the library's **first tooltip hook** and that was previously a deliberate
absence, so it is written to fail quiet: a tooltip is drawn on every mouseover and an error there is
unusable spam rather than a useful report.

Two rules in it are load-bearing, and both come straight from the defect in the addon it replaces.
SmexyMats' own handler read `_G["GameTooltipTextLeft1"]` and latched a file-local `isTooltipDone`, so
it only ever behaved on `GameTooltip` itself. So: **never name a tooltip** — every function here
operates on the frame it is handed, and `AddReagentLines(tooltip, id)` works on one a consumer drew
itself; and **never latch in a file-local** — de-duplication is keyed by the tooltip FRAME in a weak
table, because two tooltips can be open at once and a single boolean makes the second silently skip
its line. Both are pinned by specs, including one that opens two tooltips and checks they each get
their line.

**Removed: `GetExternalMaterialInfo`**, the SmexyMats bridge, shipped since v0.6.0. The operator,
2026-09-22: _"i don't want a smexymats bridge, i want full feature parity IN ItemDB, that addon is
abandoned."_ A bridge to an abandoned addon for a fact we now hold ourselves would have left the
better answer behind whenever that addon was absent. A caller switches to `GetReagentUses`, which
answers regardless of what else is installed. SmexyMats is out of `OptionalDeps` in all six TOCs too.

**Known gap, stated rather than hidden:** `Tooltip.lua` is at **90.70%** (78/86) line coverage,
not 100%, and it is the only file in the package under 100%.
The eight uncovered lines are its two modern-client branches — `TooltipUtil.GetDisplayedItem` and
`TooltipDataProcessor.AddTooltipPostCall` — and they cannot be driven, because the test harness
provides neither global and a spec's assignment to them does not stick. That was established by a
precondition assertion inside the tests, not guessed. The branches stay: Blizzard's classic tree
defines `AddTooltipPostCall`, so Mists takes that path, and deleting them to reach 100% would break
the flavour they exist for. The three specs that drove them are removed with a declared reason, and
the gap is filed with the harness rather than papered over with a lowered gate.

### Fixed -- Forever is a RATING system, and we were shipping raw ratings as percentages

The worst data defect in this release, and it was an assumption written as a comment.
`build-core-wowsims.py` mapped WoWSims' `StatMeleeHitRating` / `StatMeleeCritRating` /
`StatDodgeRating` / `StatParryRating` / `StatBlockRating` straight onto `HIT_PCT` / `CRIT_PCT` /
`DODGE_PCT` / `PARRY_PCT` / `BLOCK_PCT`, which mean **percent** everywhere else in this library,
above a comment reading _"the rating stats are flat PERCENTAGES in a level-60 game"_. Nobody had
checked. Classic Era genuinely is flat percentages, and that is what made the wrong reading look
consistent.

WoWSims' own constants settle it. In `wowsims/classic` every `…RatingPer…` constant is **1** and
the `Stat` enum has **no** `*Rating*` entries. In `wowsims/forever` they are
`PhysicalHitRatingPerHitPercent = 10`, `PhysicalCritRatingPerCritPercent = 14`,
`DodgeRatingPerDodgePercent = 12`, `ParryRatingPerParryPercent = 15`,
`BlockRatingPerBlockPercent = 5`, and the enum has **12** rating stats. The direction was read from
`sim/core/unit.go` rather than guessed from the names --
`AddStatDependency(stats.MeleeHitRating, stats.PhysicalHitPercent, 1/PhysicalHitRatingPerHitPercent)`
and `return unit.stats[stats.DodgeRating] / DodgeRatingPerDodgePercent / 100` -- so each constant is
"rating per one percent" and the conversion is a division.

So every affected Forever item was over-valued: **hit by 10x, crit by 14x, dodge by 12x, parry by
15x, block by 5x.** An item granting 2% hit shipped claiming 20%. Measured across the 13 packed
class files after the fix, the values are now `HIT_PCT` 1-2, `CRIT_PCT` 1, `DODGE_PCT` 0.5-1,
`PARRY_PCT` 1-1.4 -- where they previously read 10-20, 14, 6-12 and 15-21.

The divisors are **read from the repo's own `sim/core/base_stats_auto_gen.go`** at build time, by
constant name, for the same reason the `Stat` and `Profession` enums are read rather than copied: a
hand-written table keeps answering confidently after WoWSims retunes it. A repo whose constants are
all 1 converts nothing, so the same code path serves both games and neither needs a version name --
**Classic output cannot move**, because there is nothing to divide by.

Two stats are deliberately **not** converted, and both are noted in the builder so the next reader
sees they were considered: `StatDefenseRating` maps to `DEFENSE`, and `unit.go` floors
`rating / DefenseRatingPerDefenseLevel` (which is 1) to a defense **level** -- the raw value is
already what our key means. `StatExpertiseRating` keeps its raw rating because Forever's
`ExpertisePerQuarterPercentReduction = 2.5` is per _quarter_ percent, a different shape, and no
shipped scoring module prices `EXPERTISE` at all -- it is one of the keys `GetItemScoreBreakdown`
reports as `unpriced`.

### Fixed -- Forever's drop data attributed six rows to zones that game does not have

Both WoWSims drop datasets cover **every** expansion -- `atlasloot_db.json` carries 578 Vanilla,
248 TBC and 1583 Wrath drops -- and they join to ours by item id alone, so a Forever item id that
collides with a later expansion's item inherited that item's drops. Items 3 and 4 shipped attributed
to **Trial of the Crusader**, a Wrath raid.

The obvious filter is WoWSims' own `expansion` field and it is wrong, which is worth stating because
it looks right: that field says which expansion the DATA came from, not what the zone is. Forever's
Naxxramas is zone 3456 and reads `expansion=3`; Onyxia's Lair is 2159 and also reads 3. Filtering on
it would have deleted the largest instance in the dataset (76 items) plus Onyxia.

The client's own `AreaTable` settles it, and the two are one id space -- measured on 1.60.1.69913:
of the 26 zones the shipped items reach, **24 are in Forever's AreaTable** (Naxxramas, Ahn'Qiraj and
Onyxia among them) and exactly the leaks are not. `Map` is the wrong table: only 1 of 74 zones
appears there, because these are area ids rather than map ids. The filter runs on the boss path as
well as the object-drop path, since an id collision brings in whatever the other game's item dropped
from.

Result: **6 drop rows refused across 2 zones** -- Trial of the Crusader (4) and The Shattered Halls
(2), so three items rather than the two first reported. `Sources.lua` goes to 381 items over 24
instances, `ItemLocations.lua` to 1,858 items. If the AreaTable cannot be read the builder filters
**nothing** and says so, because a provenance filter that silently empties the dataset on a failed
fetch would be far worse than the rows it removes.

### Changed -- Forever's talent effects are measured now, and "unverified" was too kind

The docs said the per-weapon-skill EP valuations on Forever were **unverified** rather than
known-wrong, because nobody had compared the effects behind the renamed talent spells. They have
been compared: `SpellEffect` read for every talent spell id shared by both shipped `Talents.lua`
files, on each client's own build, with magnitudes normalised across the two schemas (Forever stores
the value itself in `EffectBasePointsF`; Classic stores value − 1 in `EffectBasePoints`, and
comparing the raw columns reports every row as differing by exactly one -- a bug in the reader, not
a change in the game, and the first run of this comparison had it).

**30 of the 32 renamed talents differ, 24 structurally** -- a different aura or a different number
of effects rather than a retuned magnitude. The renaming turns out not to be the signal: among the
**383 talents whose name is unchanged, 265 differ and 147 differ structurally.** A same spell id is
not the same talent on Forever either way, which is exactly what the "same spell id is not same
effect" warning was about, now with numbers.

The weapon specialisations the EP weights lean on are squarely in that set: Axe Specialization
(12700) and Rogue Dagger Specialization (13706) move from aura 52 to aura 290, Mace Specialization
(12284, 13709) from aura 42 to aura 280, and Rogue Sword Specialization (13960) becomes three
separate effects. Only Warrior Sword Specialization (12281) is unchanged. `README.md` now says
per-weapon-skill valuations on Forever are **known wrong** rather than unverified.

Also corrected there: the count of renamed talents read **35**, which was true of an earlier build
of the data. It is **32** renamed, plus 17 shipping an empty name.

### Fixed -- a multi-table data file's header stated a row count true of neither half, and guessing which table it meant got it wrong

`split-seasonal.py` divides a generated file into a base and a seasonal overlay and has to restate
each half's counts. For a single-table file it finds the number and rewrites it. For a file holding
MORE THAN ONE table it could not, and both halves shipped the pre-split number: `Effects.lua` said
"295 use-effect consumables" over 249 rows in one half and 47 in the other.

The obvious fix -- offer each table's pre-split count as a candidate and let the existing
exactly-once rule pick -- was tried, and it is wrong in a way worth recording, because it produced a
plausible number rather than an error. `Effects.lua`'s 295 is the builder's `LoadEffects` count, and
295 is ALSO the pre-split total of the SECOND table, `LoadConsumableTypes`, because exactly one
seasonal item (232433) carries an effect and no category. The number matched the wrong table and
wrote **46 into a table holding 47**. Both readings are arithmetically sound; nothing in the header
distinguishes them, and a rule that resolves it by ordering is deciding by luck.

So the builder names its tables instead. `header()` takes `rows={...}` and emits a canonical
`-- rows lib:LoadEffects=249 lib:LoadConsumableTypes=249`; the split rewrites that line by NAME,
joining each label to the block its `lib:Load*` call opens, which it already tracked. Nothing is
inferred and there is no candidate to mis-attribute. `_recount` keeps its old first-match-wins
behaviour unchanged for single-table files, and still declines multi-table prose counts -- which is
now correct rather than merely cautious.

`build-effects.py` and `build-use-effects.py` are the two multi-table builders and both moved their
counts out of the prose `detail` into `rows`. `UseEffects.lua` has three tables and carried three
numbers; it has no seasonal overlay today, so it was the latent case rather than the live one.
Verified by running the split twice and diffing: 249/47 effects and 249/46 categories, summing to
the 296 and 295 the two tables actually hold, stable across runs.

### Fixed -- off-hand weapons were weighted as main hands, in the API and in the data (DIBSREQ-IDB-007)

Two halves, and the second is the one a player sees.

**The API.** `GetItemScore` and `GetItemScoreBreakdown` now honour **`opts.equipLoc`**, scoring an
item as the slot it is being planned _into_ rather than the slot it reports. A one-hander is
`INVTYPE_WEAPON`, which every scale's `dpsSlot` maps to `DPS_MAINHAND`, so the same item planned
into the off-hand scored as a main hand and the caller had no way to say otherwise. The override
feeds both the per-hand DPS weight and the proc damage bucket, because a proc on an off-hand
weapon fires at the off-hand's rate. `lib.SCORE_OPTS_EQUIPLOC` is the capability flag; omit the
option and nothing changes. One helper feeds both scorers deliberately -- they already duplicate
this whole sequence, and an override that applied in one and not the other would disagree
silently.

**The data, which is why the API alone would have looked like nothing.** Every shipped scale had
`DPS_OFFHAND` **equal to** `DPS_MAINHAND`, in every spec -- arms 5.31/5.31, fury 5.22/5.22, rogue
3/3, enhancement 3/3. HawsJon publishes one `MeleeDps` weight and the generator copied it into
both hands, which asserts that a point of off-hand weapon DPS is worth as much as a point of
main-hand. That is false in this game, and it made the library's own `DPS_OFFHAND` key
decorative. Dibs found it while wiring the off-hand planner: their plumbing was correct and the
Planner showed no difference, because there was none to show.

`DPS_OFFHAND` is now `DPS_MAINHAND x 0.5` -- fury 5.22/2.61, combat 3/1.5. The 0.5 is the
engine's base off-hand damage multiplier taken from WoWSims' own sim rather than from memory:
`sim/core/attack.go:169` returns `0.5 * unit.AutoAttacks.oh.CalculateWeaponDamage(...)`.
**Deliberately untalented** -- Dual Wield Specialization raises it to 62.5-75%, but these scales
model no talents at all and every other weight in them is likewise the untalented value, so
baking one spec's build into a shared scale would be the larger error. The generated header says
so.

### New -- MINOR 30: race-locked gear ships as data (Dibs' DIBSREQ-IDB-006)

`Data/<Version>/_core/Races.lua`, from `ItemSparse.AllowableRace`, with `lib:LoadRaceRestrictions`,
`lib:GetItemRaces(id)`, `lib:RaceUsable(id, raceID)` and `lib:GetPlayerRace()`. Built for all four
versions that ship data: **Vanilla 114, TBC 156, Mists 2,580, Forever 105** restricted items.

**Why it has to be data.** Dibs gates class through `ClassUsable` but read the race off the
tooltip's "Races:" line via `C_TooltipInfo`. On Classic Era that namespace has **no functions at
all**, so the read is feature-detected off and race-locked gear passes for every race. Their TBC
build scans and is correct; Era silently is not.

**The mask is 64-bit, and that is the whole engineering content.** wago exports it as two signed
32-bit columns. On Vanilla and TBC the high word is always zero and the values are small (1101 is
the five Alliance races, 690 the five Horde). WoW Forever runs a modern client whose `ChrRaces`
has 58 rows reaching id 96, and its faction masks set 30 bits each up to bit 64 --
**6130900294268439629** as one number. WoW's Lua 5.1 has only doubles, exact to 2^53, so that
literal would **round**, and every bit test against it would be wrong with nothing to announce
it. So it is stored and tested as two halves, and `RaceUsable` picks the half -- no consumer does
64-bit arithmetic. This is not a Forever curiosity: **Mists needs the high word on 2,545 of its
2,580** restricted items.

`GetItemRaces` returns `low, high`, and on Vanilla/TBC `high` is always `nil` -- so a consumer on
those flavours reads the first return exactly as it reads `GetItemClasses`, which is the shape
the contract asked for.

**Two things are omitted, both failing open on purpose**: an all-races mask (the overwhelming
majority, and not a restriction), and a mask of **zero**, which reads as "no race may use this"
and is not credible for a shipped item -- 18 such on TBC. Recording zero would make `RaceUsable`
answer false for everybody, and this library's restriction getters fail open, because a filter
must never hide gear a player can really use. Unknown and unrestricted are therefore deliberately
indistinguishable; ask `GetItemRaces` and test for `nil` to tell them apart.

### New -- Forever gets reputation and battleground reward gear: 451 items

`GetSources` answers `{ instance = <faction or battleground>, source = "reputation" | "pvp" }`
for **451 reward items across 12 sources** on Forever (3 PvP, 9 reputation), where it answered
nothing before. `build-rep-loot.py` simply had no `ATLAS_FILE` entry for the version, so it
returned early.

Forever reads AtlasLoot's **Vanilla** tables deliberately: its content base is Classic (it ships
the Classic instances and the Classic PvP and reputation sets), AtlasLoot publishes no Forever
module, and the parse is intersected with that version's own `_core` -- so an item Forever does
not ship is dropped rather than invented. Same posture `build-sources-wowsims.py` already takes
toward WoWSims' Classic drop tables. Forever's own new rewards are not in this source and are
absent, not empty.

Loaded **after** `Factions.lua` in the TOC, matching Vanilla: this file also carries faction
tags and `LoadFactions` is last-write-wins per item id, so the reward data has to win.

One incidental fix while in the file: a `%`-format string in the emitter became an f-string to
satisfy the linter. Vanilla's `RepLoot.lua` was rebuilt and diffed to prove that was cosmetic --
470 reward items, 259 faction-restricted, not one data row changed.

### New -- consumable exclusion groups ship for Forever, from its own ConsumesSpec model

`GetConsumableGroup(id)` now answers on Forever for **28 consumables in six slots** --
`potions` (8), `flask` (7), `food` (5), `explosive` (4), `weapon-imbue` (3), `conjured` (1).

I had first concluded there was nothing to build here, on the grounds that the only obvious
candidate (`db.json`'s `categoryId`) is a shared-cooldown category and not an exclusion group --
which is true, and was the wrong conclusion to stop at. The right question was what Forever
_does_ use, and it has a complete answer: WoWSims restructured, so the per-item typed inputs
Vanilla is built from are gone, but `ConsumesSpec` still carries **one int field per slot**
(`pot_id`, `flask_id`, `battle_elixir_id`, `guardian_elixir_id`, `food_id`, `pet_food_id`,
`conjured_id`, `explosive_id`, `mhImbue_id`, `ohImbue_id`) and one field holding one item id
_is_ "one active per slot". `ConsumesPicker/utils.ts` is where the halves meet: it fills each
picker with `db.getConsumablesByTypeAndStats(ConsumableType.X)` and writes the choice to field
`Y`. So the slot is `Consumable.type` in `db.json` for the typed groups, and the UI's hand-listed
`*_CONFIG` arrays for the ones the database does not type (conjured, explosive, drums, imbues).

The tokens match Vanilla's vocabulary wherever the two name the same slot, so a consumer needs
no per-version table. Vanilla's finer tokens (`agility-elixir`, `zanza-buff`, …) have no Forever
equivalent because nothing publishes one.

**Detected by the old path being absent, not by a version name**, so the day `wowsims/classic`
restructures the same way, this needs no edit. The `ConsumableType` enum is read from the repo's
own proto and mapped by NAME, so renumbering it cannot silently re-file every consumable.

**What is deliberately NOT guessed:** 8 of Forever's 29 modelled consumables carry no `type` at
all -- Arcane Elixir, Greater Arcane Elixir, Elixir of the Mongoose, Gift of Arthas among them,
which are exactly the battle/guardian elixirs WoWSims has not classified yet. They ship with no
token. `nil` means unclassified, never "stacks with everything", and the generated header says
so. Assigning them a slot would be inventing a constraint in a consumer that is gated on
trusting this file.

Vanilla is untouched -- rebuilt and diffed: 78 consumables across the same 19 groups, not one
row changed.

### New -- Forever gets CRAFTED provenance too, with the profession named

The same `ItemLocations` path now carries wowsims' crafted sources: **1,669 crafted rows**
beside the 201 zone drops, 1,860 items in all. Vanilla files a crafted item under the bare
place `"Crafted"` because CMaNGOS's create-item spells know no profession; wowsims records one,
so Forever ships `{ instance = "Blacksmithing", source = "crafted" }` where Vanilla ships
`{ instance = "Crafted", source = "crafted" }`. The `source` kind is identical on both, which is
what a consumer filters on; the place string was always free-form and version-specific.

The profession numbers are read from the repo's own `proto/common.proto` `Profession` enum,
the way `build-core-wowsims.py` reads its `Stat` enum -- these are wowsims' numbers, they are
free to renumber them, and a hand-copied table would keep answering confidently after they did.
No enum, no crash: every crafted row falls back to Vanilla's bare `"Crafted"` and the run says
so.

**A known defect, shipped deliberately and measured rather than waved at.** wowsims'
`atlasloot_db.json` is not a Forever-specific file -- it carries object drops for every
expansion (578 Vanilla, 248 TBC, 1,583 Wrath), and they are filtered out only by not matching a
shipped item id. Two rows survive that filter on an id collision: items **3** and **4**, which
Forever ships unnamed and unhidden, are attributed to **Trial of the Crusader**, a Wrath raid.
That is wrong and it is 2 rows of 1,860.

It is not fixed by the obvious filter, and that is the part worth recording: dropping rows whose
zone is tagged to a later expansion **would delete Naxxramas**, the largest instance in the
dataset at 76 items, because wowsims' AtlasLoot input tags zone 3456 as Wrath while Forever's
Naxxramas is that same zone. The `expansion` field describes where the DATA came from, not what
the zone is. A correct filter needs the client's own zone set, which is a separate piece of
work; deleting 76 real rows to remove 2 bad ones is the worse trade.

### New -- Forever's chest, object and trash drops are placed: 198 more items, no schema invention

`build-sources-wowsims.py` counted 216 drops and threw them away, because a `Sources` row hangs
off an encounter and these have a zone and no boss. Zul'Gurub was the worst hit -- 124 items in
the source data, 23 placed.

The todo asked how Vanilla's schema represents a zone-wide drop so Forever could do the same
rather than invent a pseudo-boss. **It already had one, and `GetSources` has been returning it
all along:** a CMaNGOS location comes back as `{ instance = <place>, source = <kind> }` with no
`boss` and no `encounterID`, which is exactly what a zone-wide drop is. Vanilla reaches that
path through `build-item-sources.py`; Forever has no CMaNGOS database, so it now reaches it from
the WoWSims builder instead. No new loader, no new shape for a consumer to learn, and no
pseudo-boss.

All 216 are placed -- **198 items**, with **zero** drops now skipped for want of somewhere to
put them (some items drop from more than one object). A consumer that wants only boss kills
branches on `encounterID` being present rather than on the entry existing.

One thing measured on the way and worth stating, because it is the opposite of what the todo
assumed: Vanilla's own `Sources.lua` has **no** zone-wide entries at all. All 306 of its source
tokens are encounter ids and every one resolves to a boss name in `SourceNames.enc`. So
"do what Vanilla does" could not be answered by copying Vanilla's drop data -- the answer was in
the library's reader, not in the shipped file.

### New -- MINOR 29: a stat the scoring rules cannot see is REPORTED instead of scoring 0 in silence

Audit `ecc7fe5466f2` finding 3. `build-core-wowsims.py` emits `EXPERTISE`, `ARMOR_PENETRATION`
and `MELEE_HASTE_PCT` for Forever, because WoWSims' database carries them. Forever loads
**Vanilla's** scoring rules, whose vocabulary has none of the three -- Vanilla the game has
neither expertise nor armor penetration. So the flat stat walk resolved each to `w[key] or 0`,
added nothing, and pushed no breakdown row at all because of the `if c ~= 0` guard. Seven items
ship `EXPERTISE` and one ships `ARMOR_PENETRATION`; all of it priced at zero with no error, no
warning and nothing in the breakdown to say so. That is finding 7's silent-zero shape arriving
by a different route, and the blast radius being small today is not the point.

`GetItemScoreBreakdown` now emits a `kind = "unpriced"` row -- `{kind, key, value, ep = 0}` --
for any stat the active rules have no vocabulary for. `lib.SCORE_REPORTS_UNPRICED` is the
capability flag, because this adds no function for a consumer to feature-detect on.

**The distinction it draws, which is the whole design.** A key the rules KNOW and this spec
weights at 0 stays silent: that is a judgement about the spec, and reporting it would bury the
real signal under every stat a fury warrior does not care about. A key the rules have never
heard of is data the scorer cannot see, and only that gets a row. The vocabulary is taken from
the registered rules' own `weightStats`, `alias` targets, `derived` and `skipKeys`, precomputed
at registration so the test is a table lookup rather than a scan per stat per item.

**`labels` is deliberately NOT a fifth source**, and the self-audit is what caught it: a label
is a display string for a derived or bucket row, not a claim that the rules can price the key,
so reading it as vocabulary would mean adding a label to make one breakdown read nicely
silently switches the warning off for that stat -- the exact failure this feature exists to
catch. Nothing is lost by refusing it: every `LABELS` entry in both shipped modules is already
covered (Vanilla's `AMMO_DAMAGE` via `skipKeys`, `HEALTH` / `MANA` via `derived`).

Nothing is re-priced: the rows carry `ep = 0`, so `total` is unchanged and `Σ parts.ep == total`
still holds. The data keeps shipping as facts, which was the settled call -- discarding a true
stat to match a scorer that cannot read it is backwards -- and this is the half that was
missing, which is making the gap visible.

### Fixed -- two claims about Forever's talent trees were generalised from a partial read

An audit flagged both, and re-measuring over every position rather than a sample changed both
answers. The comparison now cross-tabulates the two clients' DB2 `Talent` + `TalentTab` by
(class, tab, tier, column) across the whole tree.

**The structural claim was understated, and is now stronger.** It said "367 talents across 27
trees, every one at an identical tier, column and maxRank", generalised after reading 12 of the
46 that differ. The real figure is **432 talent positions**, every one present in both clients
at an identical class/tab/tier/column, with maxRank differing at **zero** of the 432 -- all 432
read this time, not 12. 432 is also what `build-talents.py` has been printing and what
`Data/Vanilla/_core/Talents.lua` ships, so 367 never matched the repo's own data.

**The claim that Polearm Specialization is "gone" was wrong, and the way it was wrong matters.**
Its `Talent` row is present on Forever at the same Warrior tier 5 / column 0, carrying the same
spell 12165 and the same maxRank 5. What is missing is a `SpellName` row for that spell, so the
name reads empty -- and it is **not special**: seventeen talents are in exactly that state,
Dark Pact, Elemental Mastery, Defiance and Iron Will among them. Nobody would claim Forever
removed Dark Pact. Polearm Specialization was singled out because it was the one that got
looked at, and an absent name was read as a removed talent.

**"Sword / Mace / Axe Specialization collapse into a single Weaponmaster" was also wrong, and
the repo's own shipped data said so.** `Data/Forever/_core/Talents.lua` carries **three**
separate Weaponmaster entries, at tier 4 columns 0, 2 and 3, with spells 12700, 12284 and
12281. They share a display name; nothing merged. Rogue's Dagger / Mace / Sword Specialization
are the same shape, all displaying "Hack and Slash". The true figure is 35 talents **renamed in
place**, each keeping its position and its spell id.

The knock-on is that the "per-weapon-skill valuations do not describe Forever" warning was
stated more firmly than the evidence supports. The effects behind those spell ids have **not**
been compared -- the same id is not the same effect -- so the shipped scale is now documented as
**unverified** for Forever rather than known-wrong. Corrected in `README.md`, `CHANGELOG.md`,
`Scoring/Vanilla.lua`'s header, `Tests/toc_spec.lua`, `tools/build-bis-weights.py` and both
regenerated `BiSWeights.lua` headers.

### Changed -- `Data/Vanilla` refreshed to the live Era build 1.15.9.69722, and it moved no data

Vanilla is deliberately unpinned -- `wago_build_for_version`'s own comment says "the client IS
the era" -- so its shipped tables had simply drifted behind the installed client. All fifteen
wago-sourced builders were re-run at 69722, then `split-seasonal.py` last, as the README's
pipeline order requires. The walk-sourced class files (`Armor.lua`, `Weapon.lua`, ... stamped
with an INTERFACE version rather than a wago build) are untouched: they come from an in-game
TOGTools walk and only a new walk can move them.

**Result: every single change under `Data/Vanilla` is a header line.** 27 files, +33 -27, and
not one data row differs between 69109 and 69722. One thing genuinely arrived -- ten new
class-restricted seasonal items, which `split-seasonal.py` partitioned into a brand-new
`Data/Vanilla/_seasonal/Classes.lua`, now listed in `ItemDB.toc`.

**The todo this closes recorded a defect that does not exist, and the correction is the useful
part.** It said a rebuild at 69722 "adds ~46 seasonal-id consumables to `Effects.lua` that the
shipped 69109 data lacks", and that those ids might need the `_seasonal` split rather than the
base file. They did not: `build-effects.py` writes the whole union into the base file and
`split-seasonal.py` moves the seasonal ids back out afterwards, so a diff taken between those
two steps shows 92 lines that the finished pipeline does not. The earlier session diffed the
intermediate state. Running the pipeline to its end leaves `Effects.lua` byte-identical but for
its build stamp.

The manifest check is what caught the new file, exactly as this repo's checklist says it would:
`Tests/toc_spec.lua` asserts every TOC entry exists on disk, and the failure that actually
happens is the reverse -- a generated file no TOC names, which loads nowhere and silently.

### Fixed -- a split data file carried a breakdown of a number it no longer states

`split-seasonal.py`'s `_recount` rewrites a header's row total for each half of a split, and
left any parenthesised decomposition of that total untouched. So the new
`_seasonal/Classes.lua` shipped `10 items (1825 by flag, 271 by set, 4 by item)` -- parts
summing to 2,100 beside a total of 10. Nothing in the split can recompute the parts (it knows
which rows moved, not which rule put each one in the file), so the parts are now dropped rather
than carried as a false claim.

Removed only when PROVEN to decompose the replaced total, on the same principle as `_recount`'s
exactly-once rule: the parts must sum to exactly the number that was rewritten. A number counts
as a part only when it opens a comma-separated clause, so `build-hidden.py`'s
`17 by RequiredLevel > 60` contributes 17 and not 60 -- counting every digit run there would
have deleted a correct breakdown -- and `build-factions.py`'s `(348 A / 338 H)`, having no
comma, fails the test and is left alone.

### Changed -- proc rates get a third source, for a version CMaNGOS does not cover

Scoring a chance-on-hit effect needs a rate, and the client carries only _what_ procs, never
_how often_. `build-use-effects.py` and `build-sets.py` both got that rate from a CMaNGOS world
database; there is none for WoW Forever, so every Forever proc was left unscored. Both builders
now fall back to WoWSims' own modelled rates -- `itemEffects[].proc`, read by a new
`itemdb_common.wowsims_proc_rates(repo)` that keys them **both** by item id (an item proc) and
by buff spell id (a set-bonus proc), in the same `{ppm, ch, cd}` shape `build-proc-rates.py`
emits, so each call site joins it the way it already did.

It is a third tier, consulted only where CMaNGOS produced nothing, so Vanilla/TBC/Wrath output
cannot move -- proven by rebuilding both Vanilla files and diffing: not one data row changed.
The read is cache-only and never fetches, so a Vanilla run does not start a 9 MB download for a
question it can live without. A `procChance` of exactly `1.0` is dropped: that is WoWSims'
"applies whenever the trigger fires", the same thing wago's `ProcChance` 100/101 means, and
both builders already refuse to price that.

**What it actually bought, measured, because the honest answer is "not much".** Forever's
`UseEffects.lua` goes from 12 scored procs to **14**, and `Sets.lua` stays at **0 of 24**
-- none of the 25 spell rates WoWSims carries is a Forever set-bonus spell. The 38 item rates
it does carry mostly attach to effects that do not resolve to a scoreable bucket. The one place
CMaNGOS and WoWSims both hold a tuned figure for the same item they agree exactly (Annihilator,
1.0 ppm), but the overlap is a single item, so that is corroboration and not validation.

So the source is real and correctly tiered, and it does not close the gap: 62 Forever proc
effects still have a scoreable effect and no rate at all. Which is now a number the build
prints rather than something to re-derive -- `build-use-effects.py` reports its unscored procs
split into "no scoreable effect (debuff / CC / utility)" versus "has one but no rate source",
because only the second column is what a better rate source would fix. Vanilla, which has
CMaNGOS, reads 76 and 24.

## [v1.0.0] - earlier entries of the release in progress

**These are v1.0.0's own entries, moved here while that version is still unreleased**, which is the
one case the archive rule has to handle differently: a single-version `CHANGELOG.md` has no second
version heading to split at, so the boundary is between ENTRIES inside the version. Nothing is
edited and nothing is dropped -- the newest v1.0.0 entries stay in
[CHANGELOG.md](CHANGELOG.md) and become the GitHub release body; these older ones live here so that
body stays under the 125,000-character limit. Read the two together for the whole release.

### Fixed -- `build-sets.py` read VANILLA's CMaNGOS database for any unknown version

Its DB lookup ended `.get(args.version, "classicmangos.sqlite")`, so WoW Forever -- which has no
CMaNGOS database at all -- silently opened vanilla's `spell_proc_event` and stamped
`source classicmangos.sqlite` into a Forever data file. The paragraph directly above that line
forbids exactly this, in its own words: reading one expansion's DB for another "would price TBC
set procs with vanilla numbers, quietly". It priced nothing today only because Forever's
set-bonus spell ids happen not to collide with vanilla's; one collision and a Forever set proc
would have carried a vanilla rate with nothing to notice it. A version with no known DB now
gets none.

### New -- WoW Forever support: `ItemDB_Camelot.toc`, 19,171 items, 11 languages

Forever ships as product `wow_classic_beta` at version 1.60.x, installing to `_classic_beta_`.
`ItemDB_Camelot.toc` declares Interface **16001** -- that is 1.60.1 under WoW's
`major*10000 + minor*100 + patch` encoding, and the BigWigs packager agrees, routing `16???` to
the forever flavour and `11???` to classic (so the plausible-looking 11601 would have been
packaged as a Classic Era build). The `_Camelot` suffix is the client's own game-type token:
Blizzard's forever UI source gates shared files with `[AllowLoadGameType camelot]`.

Data: `Data/Forever/_core/` carries 19,171 items across 13 class files plus 15 side tables --
Factions (467 items), Classes (2,839), ReqLevels (9,856), Hidden (1,637), Sets (150 sets /
407 bonus thresholds), Effects (320 consumables), EquipStats (310), Mounts (149), Talents (432
across 9 classes), VendorPrices (849) and SellPrices (11,823). Names in 11 of the 12 client
languages at ~99.99% localized.

### Fixed -- six builders read a SpellEffect column Forever renamed, and one applied a wrong +1

Forever spells `EffectBasePoints` as **`EffectBasePointsF`** (a float) and drops `EffectDieSides`
entirely. Six builders read the old name, got nothing, and wrote nothing -- which is why four
Forever side tables first built empty, with `build-aura-buffs` reporting Mark of the Wild and
Power Word: Fortitude as having "no flat stats". That was never credible as a real absence.

The dropped `EffectDieSides` matters as much as the rename: Classic computes an effect's amount
as `base + 1`, and Forever's float **is** the amount. Measured against wowsims/forever's resolved
item effects, `EffectBasePointsF` equals the published value in **31 of 31** comparable cases and
wants the +1 in none (The Green Tower 50, Earthstrike 280, Slayer's Crest 260, Annihilator -165).
`build-effects.py` already had an `EffectBasePointsF` fallback and applied the +1 to it, so every
Forever consumable buff it produced was over-stated by exactly one -- silently.

One `itemdb_common.spell_effect_base_points()` now normalises both schemas. Its legacy branch
returns byte-for-byte what the six call sites read before, so Classic output cannot move; that
was checked by rebuilding all of Data/Vanilla and diffing -- nine of ten files came back
identical but for the build stamp, and the tenth differed only because the rebuild had moved
Vanilla to a newer Era build, which was then reverted as out of scope for this change.

Forever's tables after the fix: AuraBuffs 0 -> **100 ranks across 30 buffs**, TalentEffects
0 -> **37**, UseEffects 0/0 -> **12 on-use and 12 procs**, EquipStats 310 -> **331**.
`SpellSchools` is still 0 and is now the only empty one.

### New -- Forever drop sources and spell schools, from data that was already on disk

The first pass shipped Forever with `GetSources` empty and `SpellSchools` empty, and said so as if
no source existed. That was wrong, and it was reached without opening the files: the wowsims/forever
tarball this pipeline already downloads for stats carries `assets/db_inputs/atlasloot_db.json` and
`assets/database/db.json`, both with per-item drop sources (npcId + zoneId) and named npcs and zones,
and its per-item stats already name each spell-damage bonus's school. The operator asked whether I
was sure the data was not in our sources; reading them settled it in one probe.

- New `tools/build-sources-wowsims.py` emits Forever's `Sources.lua` and `SourceNames.lua` in
  exactly build-sources.py's schema: **381 items, 24 instances, 143 bosses** (after the AreaTable
  filter below; it was 382 / 25 / 144 with the cross-expansion leaks in). Classic instances
  only -- neither file names the 14 maps Forever's own Map table adds (The Hall of Thanes, Manor
  Mistmantle, Zephras Isle, ...), so those are absent, not empty. 216 chest/object/trash drops with
  no npcId are skipped because the schema hangs every drop off a boss. No drop rates.
- `build-core-wowsims.py` now emits `SpellSchools.lua` (**171 items**) from WoWSims' per-school
  stats, because Forever carries no on-equip aura 13 for `build-spell-schools.py` to read. That
  builder now **refuses** to write zero rows instead of silently overwriting the file with an empty
  table -- the same shape as the ItemEffect join guard.
- FIXED, found by the same work: school-specific spell damage was SUMMED. A multi-school item is one
  aura with one value (Vanilla's convention, and the one Scoring/Vanilla.lua prices), so Robe of
  Winter Night shipped at 80 spell damage when it is 40 to either of frost or shadow, and Cloak of
  Earth and Sky at 45 when it is 15. Measured over every shipped item: all five multi-school items
  carry an identical value in each school, so the combined value is that value, and the school
  list becomes the tag.
- `build-score-model.py Forever` now runs (`ScoreModel.lua`, 9 classes x 4 trigger rates) -- it had
  simply never been tried. `build-consumable-groups.py` gained a `forever` repo mapping but still
  cannot build, because wowsims/forever moved and gutted the `consumables.ts` it reads; the
  exclusion key it needs is `categoryId` on db.json's consumables, which is filed as the next step.

### New -- `GetBiSWeightsInfo` (MINOR 28): a weight scale says which game version it was authored for

Asked for by Dibs, and the reasoning is worth keeping because it is the exact test for when a
capability flag earns its place. They declined flags for three earlier Forever differences
because each was already self-reporting -- `HasScoring`, `GetRandomProperties()[1]` and
`GetItemSchools` all announce their own absence. This one they could not detect at all: on
Forever `HasScoring()` is true, `GetItemScore` returns a number, and nothing in what a consumer
reads distinguishes a scale authored for the running flavour from one authored for another.

`lib:LoadBiSWeights(source, data, meta)` takes an optional third argument, `{ authoredFor =
"<Version>" }`; `lib:GetBiSWeightsInfo(source)` returns `{ source, authoredFor }`. The third
argument is additive, so every shipped data file and every player scale using the two-argument
form keeps working, and a scale that declares nothing reports `authoredFor = nil` -- **unknown**,
never "matches what you are running".

TWO FACTS AND NO VERDICT, at Dibs' insistence and correctly: there is no `tuned` or
`trustworthy` boolean. Whether Classic's weights are good enough for a Forever raider is the
player's call and the guild's, not the library's, and a boolean would bake one answer into data
every consumer has to accept. Forever's generated scale declares `authoredFor = "Vanilla"`, so a
consumer can compare that against the client it is running on and say so in its own words.

### New -- Forever gets gear scoring, on Classic's weights, labelled as not Forever-tuned

`ItemDB_Camelot.toc` now loads `Scoring/Vanilla.lua` and ships
`Data/Forever/_core/BiSWeights.lua` (37 specs, 9 classes), so `DB:HasScoring()` is true on
Forever and `GetItemScore` returns a number instead of nil.

Forever shares Vanilla's scoring RULES because it is the same game underneath, and that was
measured rather than assumed: both clients' talent trees carry **367 talents across the same 27
trees, every one at an identical tier, column and maxRank**, and Forever's items use the same
flat-percentage keys (`HIT_PCT`, `CRIT_PCT`) rather than a rating system. A 335-line copy of
that file was the obvious alternative and was rejected -- it would say the same thing twice and
start rotting immediately. `Scoring/Vanilla.lua`'s header now carries the reasoning and a named
trigger for splitting the two, and `Tests/toc_spec.lua` asserts the sharing so nobody repoints
it by accident.

WHERE THIS IS KNOWN TO BE APPROXIMATE, said here rather than left to be discovered: neither
HawsJon nor WoWSims publishes a Forever scale (wowsims/forever computes its weights at runtime
in `sim/core/statweight.go`, so there is no table to read), so these are Classic's numbers.
**35 of those 432 talents are renamed in place** (corrected below, from a re-measurement over
every position) -- Warrior's Axe, Mace and Sword Specialization all display as "Weaponmaster" --
so the per-weapon-skill valuations are unverified for Forever. Shipped anyway because an
approximate ranking beats none and
`LoadBiSWeights` lets a player layer their own, but the generated file's header says plainly
that it is not Forever-tuned.

### Changed -- Forever's pipeline resolution: the PRODUCT decides the version, not the build major

`itemdb_common.PRODUCT_LABEL` is consulted before `MAJOR_LABEL`. Forever's build major is **1**,
which `MAJOR_LABEL` already maps to Vanilla, so keying off the major alone would have filed a
Forever client's data into `Data/Vanilla/` and overwritten Classic Era's. `PRODUCT_FLAVOR` gains
`wow_classic_beta -> _classic_beta_` so `togtools_sv()` finds a Forever walk the day one exists,
and `FROZEN_BUILD` pins `1.60.1.69913` -- pinned because Forever is a beta that moved three times
in three days, not because its era is frozen.

### Fixed -- five builders read an `ItemEffect` column Forever does not have, and failed SILENTLY

Forever runs the modern DB2 schema, where `ItemEffect` carries no `ParentItemID` and the
item-to-effect link lives in a separate `ItemXItemEffect` join table (12,566 rows). Five builders
-- `build-effects`, `build-equip-stats`, `build-mounts`, `build-spell-schools` and
`build-use-effects` -- each read that column and **skip** rows they cannot resolve, so a Forever
run would have written five data files with nothing in them and exited 0. There is now one
`wago_item_effects()` helper that detects the schema from the CSV header and **raises** rather
than returning an empty mapping. The fifth caller was missed by the first search of the tree and
found only by re-searching for the column name itself.

### Changed -- Forever's stats come from WoWSims, because the client stores allocations not values

Measured rather than assumed: Forever's `ItemSparse` stores `StatPercentEditor_N` as an
allocation in basis points, and across the 5,287 stat slots it shares with Classic Era **zero**
are identical (item 1077 is 4 and 3 in Era against 8000 and 6000 in Forever -- the same ratio).
Solving for the per-item budget against Era as ground truth failed: 111 of 136 (itemLevel,
quality) groups disagreed internally, because Forever re-tunes vanilla gear, so Era is not ground
truth for it. A reconstruction would have shipped stat numbers nothing on this box could check,
straight into consumers' gear ranking.

So `tools/build-core-wowsims.py` takes structure (quality, itemLevel, class/subclass, equipLoc)
from wago -- verified against the Vanilla walk at 17,604 of 17,604, with the
`InventoryType -> INVTYPE_*` table cross-tabulated from the same data across 28 values with zero
conflicts -- and stats from `wowsims/forever` (MIT), built against the same client build. The
five primaries and `StatArmor -> RESISTANCE0_NAME` are confirmed against the Vanilla walk;
the remaining keys are mapped from WoWSims' own `Stat` enum and carry no local ground truth,
which the module header says plainly.

Base armor is computed from the client's `ItemArmorTotal` x `ItemArmorQuality` x `ArmorLocation`
curves. `build-core-wowsims.py Vanilla --verify` checks that formula against Classic Era's
captured armor and refuses to pass if it ever exceeds the client's own figure: 6,715 of 6,727
pieces reproduce **exactly**, 0 over-report, and the 12 low ones carry flat bonus armor no curve
models. That run found two real defects -- robes (`InventoryType` 20) have no `ArmorLocation`
row and were scoring 0 armor, and the builder was using bonus armor _instead of_ base rather
than on top of it.

New tool `tools/derive-core-maps.py` is the provenance of those mapping tables: it cross-tabulates
DB2 columns against a walk-sourced core rather than having anyone write the tables from memory,
and can re-derive them when a build changes shape.

### Fixed -- peer-review finding 28: seven shipped files carried no provenance for a moving-branch input

Surfaced by the same board import as v0.10.0's three findings, but one step later: the first
import had **closed** this one by mis-pairing it with the addon's own self-audit row 28 (the
coverage finding) in the Status table -- the board carried two numbering series, the reviewer's
26-30 beside the addon's 27-34, and a bare-number table close cannot tell them apart. Writ's
`####` fix (contract `a0fe2f5c9620`) prompted a re-import, whose preview showed reviewer-28
arriving open, and reading the tools confirmed it: `source_fingerprint` was called by
`build-sets`, `build-use-effects`, `build-vendor-prices` and `build-droprates`, and by none of the
builders the finding names.

- **`build-gems.py`, `build-bis-weights.py`, `build-bis.py`, `build-consumable-groups.py`,
  `build-sources.py` (two headers) and `build-item-sources.py`** now pass
  `sources=[source_fingerprint(<cache>, <label>)]` to `header()`, so `Gems.lua`, `BiSWeights.lua`,
  `BiS.lua`, `ConsumableGroups.lua`, `Sources.lua`, `SourceNames.lua` and `ItemLocations.lua`
  each carry a `-- source <label> sha256:<12 hex>` line naming the bytes they were built from.
  The fetch helpers (`fetch`, `source_lua`, `wowsims_tarball`, `atlas_sources`) return their
  cache path beside the text so the site that writes the header can hash what was read; the one
  outside caller, `build-droprates.py`'s `atlas_alt_npcs`, takes the extra tuple member.
  `build-consumable-groups` also fingerprints the CMaNGOS `spell_elixir` sqlite when it reads it.
  Why it matters (the finding's own scenario): every one of these caches is written once and
  never refreshed, and every upstream is a `main`/`master` branch, so two developers rebuilding
  the same version could ship different `Sources.lua` files that nothing could tell apart.
- **Verified by rebuilding:** `build-sources.py Vanilla` against the cached AtlasLoot files --
  `git diff --numstat` shows `Sources.lua` and `SourceNames.lua` changed by exactly one header
  line each (`-- source AtlasLootClassic data.lua (master) sha256:ab12de3f6426`), nothing else.
  The other five files gain their line on their next rebuild; their data is untouched here.
- Ruff findings on the files touched, fixed in passing: `re.S`/`re.M` aliases, two `%` formats,
  a single-element slice, a `tarfile.open` outside a context manager (`build-bis`), import
  sorting.

### New -- an instance says whether it is a RAID (MINOR 33, Dibs' DIBSREQ-IDB-009)

`GetInstances()` rows gain **`kind`** (`"raid"` / `"dungeon"` / `nil`) and there is a per-key
`lib:GetInstanceKind(instanceKey)` beside it, mirroring `GetAuraGroup`.

**Raised out of a live consumer defect, and the defect is the argument for shipping it.** Dibs
keeps a hardcoded `RAID_KEYS` set of _our_ Vanilla and TBC instance slugs to decide which sources
earn a "best per raid" BiS badge, under a comment reading "Classic Era is frozen, so this set is
complete and permanent". That was true of Era and not of the key VOCABULARY: on WoW Forever the
instance keys are numeric **zone ids**, so nothing matches, no instance classifies as a raid, and
the badge never appears at all. It fails closed and **silently** -- a Forever player reads the
absence as the feature not existing. Every consumer separating raid loot from dungeon loot was
keeping its own copy of this list, and every copy breaks the same way.

**It is derived, not curated, and that was the condition Dibs put on the request** -- they asked
us to decline rather than hand-maintain a raid list on their behalf, since a curated list in the
library is their fragility relocated rather than fixed. Both sources carry it:

- **Vanilla and TBC, from AtlasLoot's own `ContentType`.** Every instance block has exactly one
  (33 of 33 in `data.lua`, 26 of 26 in `data-tbc.lua`), valued `DUNGEON_CONTENT` or
  `RAID10/20/25/40_CONTENT`. Coverage after the rebuild is **33/33** on Vanilla (25 dungeon, 8
  raid) and **59/59** on TBC (41 dungeon, 18 raid).
- **Forever, from the CLIENT, because wowsims does not carry it.** Both wowsims drop datasets
  describe a zone as exactly `{ id, name, expansion }` -- there is no type in them at all. The
  client has one: `Map.InstanceType` (0 none / 1 party / 2 raid / 3 battleground / 4 arena), and
  on 1.60.1.69913 it reports 13 raid maps including five Forever does not share with Era (The
  Tainted Scar, Storm Cliffs, The Crystal Vale, Nightmare Grove, Scarlet Enclave). **Two joins
  are needed and neither is complete alone**, which was measured rather than assumed: our keys
  are `AreaTable` ids, `Map.AreaTableID` links some of them and `AreaTable.ContinentID` the rest.
  Preferring the direct link and falling back to the other resolves **24 of 24** (17 dungeon, 7
  raid). `InstanceType 0` is treated as "the table has no opinion" rather than as dungeon, so the
  other join gets its turn.

**`nil` means UNKNOWN and is never defaulted**, the same contract as `dropRate` and a weight
scale's `authoredFor`. Mists ships no kinds -- its `Sources.lua` predates the current builder
(numeric keys, no source fingerprint) and `ATLAS_FILES` has no entry for it, so the builder exits
rather than regenerating. Both builders now REPORT their coverage and name any instance they
could not classify, because an unclassified instance is otherwise invisible.

**Size is flattened away on purpose and the library takes no view on which raids count.** Our
Vanilla data calls `UpperBlackrockSpire` a `"dungeon"`, which is AtlasLoot's classification;
Dibs' `RAID_KEYS` counts it a raid. Both are defensible, the library reports the fact, and the
judgement stays with the consumer -- exactly the boundary Dibs asked for.

The 5th `LoadSources` argument is trailing and optional like the 4th, so a data file written
against the older shape loads unchanged; only `"raid"` and `"dungeon"` are stored, so a builder
change cannot leak a third spelling to a consumer that has no branch for it.

**A trap this creates for consumers, found by Dibs while adopting and documented in the README
because the next one will hit it too.** `WorldBosses` and `WorldBossesBC` are `"raid"` upstream --
both keys on TBC and Mists, the first alone on Vanilla. They are AtlasLoot's synthetic groupings
for Azuregos, Kazzak and Doomwalker rather than places. A consumer that gives world bosses a
category of their own and tests for it BELOW the raid test will find that category becomes
unreachable the moment it adopts `kind`, with nothing to notice: Dibs caught it while writing the
spec for their adoption, not by running the code. We are not reclassifying it -- the honest
statement is that AtlasLoot files the block as raid content, and overriding that would break the
consumer who wants world bosses counted as raid content, who is no less reasonable than the one
who does not. The README now names both this and the `UpperBlackrockSpire` case.

### New -- an extractor now reports N of M and refuses at zero, and it found something on its first run

Peer Review's ruling on the imbue regex (inbox `d415861ec6cd`), which they called the third
instance of one shape across the fleet in a day. That regex matched none of sixteen weapon imbues
for months, and **it did not merely lose data -- it produced a false statement to a consumer**, who
had no way to check it: Dibs was told "wowsims does not type imbues". Their remedy is a mechanism
rather than a resolution to be careful: **an extractor that pulls N of M should report both
numbers and refuse at zero.** Matching none of a non-zero population is a broken reader, never a
source with nothing to say.

`build-consumable-groups.py` now prints `matched N of M ITEM-KEYED ConsumableInputConfig
declaration(s)` and exits if M is non-zero and N is zero. **Two things went wrong building it, and
both are the check earning its keep before it had even shipped:**

- **The first denominator counted declarations the numerator was never meant to match**, and fired
  immediately on wowsims/tbc-new -- which carries two configs this path never reads, because TBC's
  slots come from CMaNGOS's `spell_elixir`. A denominator out of scope with its numerator is not a
  check, it is a nuisance that gets deleted the second time it cries wolf. Narrowed to item-keyed
  declarations: loose in shape, since a shape assumption is what the original regex got wrong, but
  identical in scope.
- **Then it reported a permanent "94 of 100".** The six were the Greater Protection Potions, which
  wowsims ships **commented out** behind a TODO reading "not yet implemented in the back-end" --
  so no data was being lost, the regex was right, and the denominator was counting dead source.
  Whole-line `//` comments are now stripped before both counts, so a commented-out config is
  absent from the numerator and the denominator alike. It reads **94 of 94**. A ratio that is
  permanently unequal for a legitimate reason teaches a reader to ignore the one signal it exists
  to raise.

### New -- the first test a BUILDER has ever had, and a filter that now fails instead of reporting

Two rulings from peer review on the MINOR 29 audit (inbox `bb50021ffb88`), both acted on.

**`Tests/split_seasonal_check.py` pins `_drop_breakdown`, whose safety cases were designed for
and then never executed.** The audit had recorded it as untestable "because the repo carries no
Python test suite for any builder". Peer Review's ruling: that blocker is oversized for a pure
string function with two inputs and two expected outputs -- **what you would be waiting for is a
framework, and what this finding needs is an assertion.** They were right, and the uncomfortable
part is that this workspace had been driving Python through the desk's `run_check` all day while
that sentence sat in an audit. Nothing was blocked; it had been categorised as blocked.

Four asserts, covering the two cases that make the rule non-obvious and both from real shipped
headers: `build-hidden`'s `(5 by name, 17 by RequiredLevel > 60)` must sum to 22 and not 82,
because only the number OPENING a clause is a part -- counting every number would delete a
correct breakdown; and `build-factions`' `(348 A / 338 H)` has no comma, sums to 348 rather than
the total, and must be left exactly as written. **Red-checked** by inverting the factions
expectation: the run exits non-zero and names the case with got/want. It is not wired into the Lua
suite and the file says so -- a checklist item like `verify-manifest`, because a Python check
nobody knows to run is the same silence in a different place.

**The Forever drop filter now fails on an unexpected refusal instead of printing one.** It refuses
drops in zones the client does not have, which is right for the cross-expansion leaks it was
written for -- but it is also the shape that would make a legitimate Forever boss's drops vanish
in silence if its zone were ever missing from `AreaTable`. Peer Review: _a report nobody diffs is
not a check._ The known leaks are now pinned **by zone id** -- `EXPECTED_LEAK_ZONES`, Trial of the
Crusader 4722 and The Shattered Halls 3714 -- and refusing anything outside that set halts the
build naming the zone. A count would not distinguish "the same two leaks" from "two different
zones", which is exactly the change worth hearing about. Red-checked the same way: dropping 3714
from the set makes the build exit naming The Shattered Halls.

**Also measured, and it closes a question rather than documenting it.** Peer Review asked whether
`wowsims_proc_rates`' `by_spell` map matches anything on any flavour, since a map that is empty
everywhere is code with no production _effect_ -- harder to see than code with no caller. It is
not empty: wowsims/forever returns 38 `by_item` and 25 `by_spell` entries, while wowsims/classic
returns zero of both, which costs nothing because Vanilla and TBC take their rates from CMaNGOS
and never needed this tier. The 25 are ITEM-effect buff ids and are disjoint from Forever's
set-bonus proc spells, so `build-sets.py` finding nothing is a **missing source rather than a
missed join** -- two different things to go looking for. Both per-repo figures are now a paragraph
at the function, so the next reader does not re-derive them.

### Changed -- peer review closes out the Forever audit: a licence read, a rounding question counted, and a header that said the opposite of the truth

Peer Review's reply on the MINOR 28 self-audit (inbox `ecc7fe5466f2`). Three of its findings were
already fixed by the time it arrived -- the rating system, the school summing and the `StatArmor`
ambiguity -- so what follows is the remainder, plus the method point that is worth more than any
of them.

**The licence is read now, and it checks out.** `Data/Forever` ships with "MIT,
github.com/wowsims" credited in the generated headers of five builders, and that was asserted on
the strength of the org's usual licence rather than a file anyone had opened -- a distribution
claim about somebody else's work, in files that ship to CurseForge. The tarball was already on disk.
`forever-master/LICENSE` reads **"MIT License, Copyright (c) 2022 wowsims team"**, so the credit
was correct and is now sourced.

**The rounding question does NOT close with zero, and the number matters.** The MINOR 28 audit
justified `round()` on "31 of 31 wowsims-resolved effects match" -- but every one of those was an
integer, so rounding was never asked to break a tie, which makes the agreement weaker evidence
than it reads as. Counted over Forever's whole `SpellEffect` table at 1.60.1.69913: **42,449 rows
carry `EffectBasePointsF`, 747 are non-integer, and 13 have a fractional part of exactly 0.5** --
an exact tie being the only case where Python's round-half-to-even differs from half-up. **None of
those 13 spell ids appears anywhere in `Data/Forever/_core`**, so no shipped value was produced by
breaking a tie and the rounding mode cannot move the package today. It stays `round()`, now with
the count and the latency written beside it in `itemdb_common.py` rather than a claim that every
value is integral.

**`Scoring/Vanilla.lua`'s header asserted the opposite of the truth, in its most load-bearing
sentence.** It read "Forever's items carry the same flat-percentage stat keys rather than a rating
system" -- which is exactly backwards, and it was the stated justification for Forever loading this
file at all. Peer Review settled it from a source nobody had thought to use: the client's own UI is
on this box, and `wow-ui-source-forever`'s Camelot `PaperDollFrame.lua` declares the full combat
rating index while `PaperDollFrameStats.lua:486` computes melee hit as
`GetCombatRatingBonus(CR_HIT_MELEE) + GetHitModifier()` -- the client itself adding the
rating-derived percent to the flat percent because they are different quantities.

The header now says so, and states the thing that actually makes sharing sound: **the conversion
happens in the pipeline, not in the rules.** What reaches `Scoring/Vanilla.lua` is already a flat
percentage because `build-core-wowsims.py` divided it. Sharing is correct _because of_ that
conversion rather than because the two games agree, and removing it would silently make every rule
in the file wrong instead of making it error.

**Its split trigger was stale in the same way `Scoring/TBC.lua`'s socket comment was.** It called
the talent divergence "only a hint" on the grounds that "the EFFECTS behind those spells have not
been compared". They have been, and they differ -- 30 of 32 renamed talents, and 265 of the 383
whose name is _unchanged_, 147 structurally. The trigger now names the measurement, says
per-weapon-skill valuations on Forever are known wrong, and explains why the file is still shared
anyway: the divergence is in the data these rules price, not yet in the rules, so splitting today
would produce two identical copies. The split happens when a Forever-tuned scale exists to put in
one.

**The method point, which is the one to keep.** The audit said the question was unanswerable
because no Forever client is installed. Peer Review's reading: the limitation was about a _client_
and the conclusion drawn from it was about _verifiability_, and those come apart, because the
client's source is a separate artefact that was sitting on the same drive. A stated impossibility
is a claim like any other -- and this one sent a HIGH finding out labelled "unverified" when it was
a confirmed defect.

**Kept, as Peer Review advised:** the Vanilla `BiSWeights.lua` change that rode along with the
Forever work. Reverting it would leave the shipped file disagreeing with its own generator, which
is a worse state than an additive change that was declared.

**A second round on the same thread found that the rating fix itself FAILED OPEN, into exactly
the defect it had just closed.** `rating_divisors` dropped any constant it could not resolve, and
the emitter's `(val / d) if d else val` then shipped that stat as a **raw rating under a
percentage key** -- `HIT_PCT` back at ten times its real value, with no error, no changed row
count, and a run report saying the conversion ran. WoWSims renaming one constant, restructuring
`base_stats_auto_gen.go`, or changing a declaration's formatting past the regex was all it would
have taken.

The discriminator was already inside the function: **if anything resolved above 1, the repo IS a
rating game**, so a `RATING_CONST` entry that then fails to resolve is a broken read rather than a
game without ratings. It now refuses, naming every constant it could not find. Driven in all three
directions rather than assumed: wowsims/forever resolves all nine and returns the identical map
(so no data file moves), wowsims/classic returns `{}` with no error because every constant there
is 1, and pointing one entry at a name WoWSims does not have produces the refusal. This is the
third fail-closed of the same shape this week, after `_ARMOR_TOTAL` and `KNOWN_STAT`.

**And the divisor's LEVEL is now stated rather than assumed.** A rating-to-percent conversion is a
per-level quantity in the client, and this pipeline applies one number to every item -- so what is
shipped means "percent at some level", and nothing recorded which. Reading the generated file
answers it: all nine constants are plain scalars (`const PhysicalHitRatingPerHitPercent =
10.000000`), and WoWSims plainly does model level-dependence where it exists and names it -- the
very next declaration is `var CritPerAgiMaxLevel = map[proto.Class]float64{...}`, both a map and
carrying `MaxLevel` in its name. So within WoWSims' model the divisor is level-independent and
applying one number is what the sim itself does. The docstring says that, and says its limit: it
is a fact about WoWSims' model rather than a measurement of the client, and if anything ever
prices a low-level character's item the question is live again.

### Fixed -- Mists was shipping VANILLA's 33 instances as its whole drop graph, and the builder refused the version rather than saying so

Found while answering the contract above, by asking why Mists would carry no instance kinds. It
was not a gap in the classification -- it was that `Data/Mists/_core/Sources.lua` had not been
regenerated since before the **read-every-file fix**, whose reasoning is written in
`build-sources.py` itself: AtlasLoot's files are cumulative, old content does not disappear, and
reading only `data.lua` "shipped the vanilla instance list as TBC's drop graph with no Outland
content at all". TBC was fixed at the time. **Mists was not, and could not be**: `ATLAS_FILES`
carried no entry for it, so `build-sources.py Mists` hit an unconditional exit, and a version the
builder refuses is a version nobody notices is stale. The shipped file was Blackfathom Deeps,
Blackrock Depths, Molten Core, Naxxramas, Scarlet Monastery -- Vanilla's 33 and nothing else --
on a client whose players raid Karazhan, Ulduar and Icecrown.

**Mists now reads all three files, as TBC reads two: 5,501 items across 80 instances** (was 2,248
across 33), with 80/80 carrying a raid/dungeon kind (57 dungeon, 23 raid). Every Outland and
Northrend instance that a Mists client can still walk into now answers `GetSources`.

**What it still does NOT have, stated rather than left to be discovered: its own expansions.**
AtlasLootClassic publishes `data.lua`, `data-tbc.lua`, `data-wrath.lua` and nothing later --
verified by listing the upstream directory through the GitHub API, which returns exactly those
three data files beside matching `.toc` files for Vanilla, TBC and Wrath. So Cataclysm and Mists
content is absent from this source permanently, not temporarily, and `HasSources(id)` answering
false there means UNKNOWN as it always has. `Cata` gains the same three-file entry for when that
flavour has data of its own.

The lesson is the builder's shape rather than the data: **a builder that exits on an unknown
version silently freezes whatever that version last shipped.** The refusal is still correct for a
version with no upstream at all, but it is not a substitute for the version being listed.

### Fixed -- two specs that were passing on ambient harness state rather than on what they claimed

Both found by moving the test-harness pin to `98634af`, and both were pinning the harness instead
of the library. Neither was a library defect; both were specs that asserted a precondition they
never established, which is the shape that keeps a green suite green while the thing under test
stops being exercised.

- **`RaceUsable` "fails OPEN when the race is unknown"** asserted that the env's `UnitRace` simply
  had no third return. That was true when written and stopped being true on 2026-09-18, when the
  harness gave `UnitRace` a `raceID` looked up from `wow.races`. The example went red -- correctly.
  It now makes the race genuinely unresolvable by giving the player a race file token the lookup
  does not carry, which is the real "a new playable race against an older lookup" case. A
  companion example pins the other half (an Orc player, race 2, admitted by the Horde mask and
  refused by the Alliance one), so the fail-open branch cannot pass vacuously.
- **`GetSeason` "defaults to no season when neither seasonal API exists"** relied on the env not
  having `C_Seasons`. The harness supplies it offline -- something this repo adopted at the
  `dc95cca` pin and recorded in this changelog at the time -- so the fall-through the example
  exists to prove had stopped executing while the assertion still passed. **The coverage gate is
  what caught it**, as an uncovered `return 0`; the suite was green throughout. Both namespaces
  are now cleared explicitly and restored.

### Harness pin -- `dc95cca` -> `98634af`, and `finally` now does what its name says

Adopted the harness's fix for **IDBREQ-HARNESS-002**, which was ours to report: `finally` was
defined as `function finally(fn) fn() end` -- it ran the cleanup **immediately** rather than after
the example, so the standard save-and-restore restored before the value had been changed and the
change then leaked for the rest of the run. One of ours had already leaked a nil
`LibItemDB_PriceDB` into every later example. The harness took deferral over a rename (reverse
order, runs whether the body passed or failed, list reset per example) on the reasoning that its
runner deliberately installs the busted DSL and a consumer copying a busted idiom should get
busted's behaviour. Our three sites were rewritten as explicit restores before the fix landed and
needed no further change; the new specs here use `finally` as intended. `finally` is also added to
`.luarc.json` -- the harness declares it and this addon did not, which is precisely why the
language-server warning that found the defect could only ever have appeared from out here.

**Also adopted from the same pin: `cfhtml.lua`, a checker for `docs/Curseforge_Description.html`**
-- well-formedness, the character ceiling and offsite links. It matters more than a lint step
here, because that page was the one shipped artefact in this repo that **nothing could validate**,
and it is duly the file that had drifted into advertising a bridge we deleted (above). It found
two real things on its first run, both pre-existing and both now fixed without losing anything:
these projects allow **Discord links only**, and the page carried an `<a href>` to the GitHub
repository and another to `tbcwowaddons.weebly.com` in the HawsJon attribution. Both are now plain
text -- the repository name and the URL are still stated, so a reader loses no information and the
credit is unchanged. The page reports 66,103 characters, 23,897 under the 90,000 ceiling.

### Documentation -- a "not to be confused with" note, because another addon now answers to `ItemDB`

Questbook reported (inbox `fe6b6b05ad59`) that Questie 12 splits its database into a separate
addon, **QuestieDB**, whose published API documents `LibQuestieDB.Item` as "aliased as `ItemDB`" --
the same word as this addon's folder. They checked our tree before telling us and found no
collision; so did we, independently: `ItemDB.lua` creates only locals (the VersionCheck host table
is a local, and the project name reaches it as a string return from `host:GetName()`), and a search
for `ItemDB =`, `_G.ItemDB` and `_G["ItemDB"]` across every `.lua` in the package returns nothing.
Nothing of ours contends with theirs whichever loads second, because we register only
`LibItemDB-1.0` through LibStub.

What is left is a player seeing two things called ItemDB, which is a documentation problem and is
fixed as one: `README.md` now carries the note directly under the folder/project-name line, saying
what QuestieDB is, that the two do not contend, and which folder is ours. Nothing in the library
changed.

**Caught while in the same files: the CurseForge page still advertised the SmexyMats bridge**, in
two places describing the library as it is now rather than as it was -- the tooltip fan-out bullet
listing "AllTheThings, Recipe Master, Leatrix Plus, TradeSkillMaster, Auctionator and SmexyMats",
and the "nothing else is required" bullet saying its lines are carried through. The provider was
removed earlier in this same version (`Integrations.lua:243`), so both sentences named a bridge
that no longer exists on a page a player reads before installing. Both now list only the five
addons that are actually bridged. The `README.md` tables were already correct, which is why this
survived: the removal updated the developer-facing tables and missed the player-facing prose.
**The v0.6.0 block in the page's own "Recent Updates" still names SmexyMats and is deliberately
left alone** -- it is that release's notes and it was true of that release; the same reason this
changelog never edits a released entry.

**And that aside came back as a finding, which found two more of the same shape here.** Questbook
went looking for the pattern in their own tree, found three, and named the mechanism (inbox
`43577af0bbb8`): the developer-facing docs get updated because you are _in_ them while you change
the code, and the player-facing prose gets updated only for the thing you just changed -- the
release note -- while the standing feature description nobody is looking at goes quietly out of
date. Release notes are append-only and self-correcting; feature descriptions are the opposite, and
nothing fails when they rot. Their sharpest case is the one that also applies here: a page that
_understates_ is worse than one that overstates, because a player who reads "not in yet" never
looks for the feature and never reports it missing. Sweeping our own page on that basis:

- **"Not every feature is available on every version yet" listed Forever as if it had almost
  nothing.** It has nearly everything: comparing `Data/Forever/_core` against `Data/Vanilla/_core`
  file by file, the only two Vanilla ships that Forever does not are `DropRates.lua` and `BiS.lua`.
  The paragraph now says so -- Forever has all of it bar per-boss drop rates (no source publishes
  them for that game) and ready-made BiS lists, with gear scoring itself working on Classic's
  weights -- and the release note eight paragraphs above had said as much for a day. Race
  restrictions were missing from that sentence's list for every version, too.
- **The reagent -> professions feature was in the release notes and in no feature bullet at all.**
  It shipped at MINOR 32 earlier in this version, and a player reading "What it can do" -- the list
  that decides whether they install -- would not have learnt that the library answers what a stack
  of cloth is for, or that it puts the line on the tooltip. It now has its own bullet.

---

## [v0.10.0] (2026-09-18) - Per-boss DROP RATES ship as data; class PROFICIENCY (`CanUse`); TBC ammo scores; CMaNGOS licence corrected

Four inbox threads, worked oldest first across two days and two sessions, plus the three
peer-review findings that importing the retired boards into the writ inbox turned out to have left
open. **Library `MINOR` 26 -> 27.**
Feature-gate on `if DB.GetDropRate then` for the rates and `if DB.CanUse then` for proficiency.

### New Features -- per-boss drop rates (Dibs' `DIBSREQ-IDB-005`)

The operator, on Dibs: _"why are you using atlas loots number? don't we have that data in itemdb?
if not, we should open a contract with it to get it."_ Dibs' `Modules/SourceDetail.lua` was reading
`AtlasLoot.Data.Droprate:GetData(npcID, itemID)` live, behind a pcall, so the same Planner row
showed a percentage for a player with AtlasLootClassic installed and nothing for the next -- an
item DATA fact living outside the item database. The number now ships here.

- **`tools/build-droprates.py <Version>`** computes the rates from the **CMaNGOS world
  database** this pipeline already downloads for proc rates and locations
  (`creature_loot_template` + `reference_loot_template`), by porting the server's own roll
  rules from mangos `LootMgr.cpp`: group-0 entries roll independently; a group picks ONE entry,
  explicit chances tried cumulatively before an even split of the remainder among the
  zero-chance entries; a reference (`mincountOrRef < 0`) rolls its own chance once and then
  processes the referenced template `maxcount` times, recursively; conditions are ignored (the
  rate is the chance when the condition is met); P(at least once) over every path is
  `1 - prod(1 - p)`. The creature-to-loot join is `creature_template.LootId`; a boss is widened
  to every npcID its AtlasLoot block names (Attumen + Midnight, combined as independent kills --
  the AtlasLoot files are read for that one fact and nothing else) and, on TBC, to its
  `HeroicEntry`, whose loot merges by MAX per item since heroic is an alternative kill.
  **Quest-gated drops (negative chance) are not emitted**: Essence of the Firelord is 100% for
  a raid holding the quest and 4.6% in AtlasLoot's observed count because most raids are not,
  and neither number is "the rate", so such a pair answers nil. Pairs are kept when the item
  exists in `Data/<Version>/_core`. Rates are rounded to 2 dp; the header carries the SQLite's
  content fingerprint (`source_fingerprint`), since `cmangos/<x>-db` publishes only a moving
  `latest` asset.
- **The first cut, earlier the same day, read AtlasLootClassic's `droprate.lua` instead** --
  one file, 295 Vanilla bosses, 1,696 items / 2,135 pairs, no Outland at all, and whole loot
  classes missing (Lucifron's block has no recipe drops). The operator: _"Atlas isn't complete
  and i'd rather we added complete data."_ Replaced before it shipped; the tool's `--compare`
  flag keeps that file as a cross-check on the port, never an input.
- **Chest loot.** Some bosses drop nothing themselves: the emulator puts their loot on a
  gameobject (Majordomo's Cache of the Firelord, the Four Horsemen chest, Knot Thimblejack's
  cache) and the creature has `LootId 0`. No table links a creature to its chest, so for an
  encounter with no creature loot the builder takes the `gameobject_loot_template` entry whose
  reachable items overlap the boss's own `Sources.lua` item list the most, at three or more
  matches (`CHEST_MIN_OVERLAP`). Five Vanilla encounters and six TBC ones resolve this way,
  each printed per run as `encounter -> loot entry`.
- **`Data/Vanilla/_core/DropRates.lua`: 4,963 items, 26,307 item/boss pairs, 304 of the graph's
  306 encounters. `Data/TBC/_core/DropRates.lua`: 6,670 items, 30,211 pairs, 424 of 428
  encounters, 71 widened to several creatures, 58 with heroic loot merged.** The encounters
  left with nothing are AtlasLoot ids that are not creatures in the DB (`36296`, `8696`,
  `22856`, `18672`); the builder prints them per run. Mists is not built: CMaNGOS has no MoP
  database, and its `Sources.lua` encounter keys are not known to be npcIDs.
- **What the AtlasLoot cross-check says is still missing, classified pair by pair (a scratchpad
  probe, Vanilla):** 9 items are in no CMaNGOS loot table at all (Ossirian's 21457, Fankriss'
  21639, Gandling's 13950 among them -- a gap in classic-db, not in the port), ~20 sit in a
  reference table the boss's chain never reaches, 10 are quest-gated by design. Those pairs
  answer nil.
- **Where the two sources overlap (`--compare`, Vanilla, 2,087 pairs): median relative
  difference 22.4%; 554 pairs within 10%, 566 within 25%, 444 within 50%, 359 within 100%,
  164 beyond.** The chain was read for the worst of the tail and every one is
  table-versus-observation, not a port defect: Pattern: Big Bag of Enchantment is 15% in the
  table and 0.4% observed; Runeblade of Baron Rivendare 1% vs 0.05%; the Scholomance set pieces
  sit in one equal-chanced reference at 3.7% each where the observed figure is 0.1-0.4%. Where
  the table and the observation agree on structure they agree on number (Lucifron: Felheart
  Gloves 33% vs 30.18 observed; the equal-chanced epics 3.4% vs 2.96-3.37). CMaNGOS encodes
  1.12-era tables; AtlasLoot's figures are a hand-pasted snapshot of classic.wowhead.com's
  crowd-uploaded loot counts (its CHANGELOG v1.2.2, 2019-10-02: _"Add much more drop rate data
  from classic.wowhead.com"_), last refreshed 2020-09-05 per its git history, with no generator
  in the repo. This ships the table and says so in the README.
- **`lib:LoadDropRates(t)`** -- a SEPARATE loader, as the contract asked, so the three-argument
  `LoadSources` every older data file calls and its `"encID,encID"` packing are untouched
  (`Tests/libitemdb_spec.lua` "accepts a three-argument LoadSources" still pins it). Merges.
- **`lib:GetDropRate(itemID, encounterID)` -> percent | nil.** `nil` is _unknown_, never
  _never_ (a quest-gated drop, or an encounter the data does not cover). Nil-safe on either
  argument; the encounter may be the number or its string, because a consumer holds both (a
  link field is a string, a `GetSources` row a number).
- **`GetSources` boss rows gain `rate`** when a rate is known for that boss; the field is
  absent otherwise, so Dibs prints nothing rather than "0%". The five existing fields are
  unchanged. A location row never carries one.
- `itemdb_common.core_ids` lists `DropRates.lua` as a non-item file, so the id scan does not
  read the new file as item rows.
- README: `GetSources` / `GetDropRate` rows, the build-tool list, the drop-sources paragraph
  (with the roll rules in one sentence), the CMaNGOS credit, and a line telling consumers not
  to read AtlasLoot live for this. CF page: the API list and the credit.

### New Features -- proficiency: `ClassProficient` / `CanUse` (Questbook's contract, 2026-09-18)

The operator, on Questbook's "For me" filter: _"then open a contract with ItemDB to fix it."_
`ClassUsable` answers the item's class TAG; nothing answered the class's TRAINING -- a hunter and a
mace, a level-39 hunter and mail, a mage and a shield -- so **three addons carried the same Vanilla
tables as copies** (Dibs `Data/ItemSources.lua`, TOGBankClassic `Modules/Usable.lua`, Questbook
`Modules/RewardsIndex.lua`) with nothing asserting they agreed. The tables now live here, once.

- **`DB:ClassProficient(classID, itemClassID, subClassID, equipLoc, level)` -> boolean.** Pure.
  Armour (class 4): shields (subclass 6) for Warrior / Paladin / Shaman only; body slots (head,
  shoulder, chest, robe, wrist, hand, waist, legs, feet) capped by material -- Cloth 1 for Priest /
  Mage / Warlock, Leather 2 for Rogue / Druid, Mail 3 for Hunter / Shaman, Plate 4 for Warrior /
  Paladin -- and **level-aware**: Mail and Plate are trained at 40, so below it the cap is one
  tier down (`nil` level = the trained cap). Cloak / neck / finger / trinket / held / relic pass
  for everyone. Weapons (class 2): the allowed subclass set per class, verbatim from the fleet's
  tables. Fails **open** -- a `nil` class, a class off the table (Wrath's Death Knight), a
  non-armour/weapon item, a `nil` subclass -- and subclass `0` is a real value (1H axe; generic
  armour), never "unknown". Ids as numbers or numeric strings.
- **`DB:CanUse(itemID, classID?, level?)`** = `ClassUsable` AND `ClassProficient` on the item's
  own class / subclass / equipLoc. Defaults: the player's class, the player's level (new
  `DB:GetPlayerLevel()`, `UnitLevel` captured at load like `UnitClass`). NOT the required level
  and NOT faction, as the contract asked and TOGBank's `Usable.lua:20-27` reasons. An unknown
  item answers `true`.
- **`DB:GetArmorCap(classID, level)`** and **`DB.PROFICIENCY`** (the five tables as readable
  data) so a consumer can build a "which weapons can my class use" list without a copy.
- **Verification of the ids, not the tables:** every subclass id was checked against the Classic
  Era client's `ItemConstantsDocumentation.lua` (`ItemArmorSubclass` 1-4 Cloth-Plate, 6 Shield;
  `ItemWeaponSubclass` 0-19, fist = 13 "Unarmed"). The table MEMBERSHIP is the fleet's pinned
  answer (TOGBank's `Tests/usable_spec.lua`, whose examples are ported verbatim into
  `Tests/libitemdb_spec.lua`), not read from the client -- proficiency is a learned spell there,
  not item data -- and the header says so.
- **A second ItemDB session, reviewing the docs against this code, caught an asymmetry before it
  shipped:** `CLASS_SHIELD` is a positive list, so a class off the table (Death Knight) answered
  `false` for a shield while the material and weapon branches answered `true` -- the exact
  asymmetry TOGBank's reference carries. The shield branch now guards on `CLASS_ARMOR[classID]`
  first, so "unknown class fails open" holds in every branch; specs pin class 6 and class 99 with a
  shield, and class 99 in plate at level 10.
- Same `MINOR` 27 as the drop rates above (shipped together); feature-detect on `DB.CanUse`.

### Fixed -- TBC hunters' ammo scored 0 (Dibs' `DIBSREQ-IDB-003`)

`Scoring/TBC.lua` registered no ammo scorer, on a comment that said `AMMO_DAMAGE` "is not captured
in the TBC walk" -- and `docs/TBC-Parity.md` carried the same claim ("Vanilla has 38 items, TBC 0").
Both were wrong about where the stat comes from: it never came from the walk. `build-equip-stats.py`
reads it from wago `ItemSparse` for every version, and `Data/TBC/_core/EquipStats.lua` has carried
**63** `AMMO_DAMAGE` rows the whole time, so the data was there and the rule was missing.

- **`lib.StatScorers.ammo`** in the core is the scorer (`AMMO_DAMAGE x DPS_RANGED`, hunters only),
  moved out of `Scoring/Vanilla.lua` where it was a local. The arithmetic prices a stat key the
  core's own pipeline emits identically for every flavour, so it is shared; the RULE -- whether
  the expansion has ammo -- still lives in each `Scoring/<Version>.lua`, which opts in through
  `statScorers`. Vanilla and TBC both register it. Wrath will; Cata, which removed ammo, will not.
- Spec: "prices ammo through the ranged-DPS weight, exactly as Vanilla does" under the TBC rules
  block, 16.5 x 2 = 33, and 0 for a class with no ranged-DPS weight.
- `docs/TBC-Parity.md`'s AMMO_DAMAGE item is ticked with the correction.

### Fixed -- README credited the CMaNGOS database as GPL-2.0 (Questbook's finding)

Found while Questbook copied the credit line. The databases this pipeline reads
(`cmangos/classic-db`, `cmangos/tbc-db`, fetched by `build-proc-rates.py`) are **GPL-3.0** --
verified against GitHub's licence API for both repos today (`LICENSE.md`, SPDX `GPL-3.0`). GPL-2.0 is
the licence of `cmangos/mangos-classic`, the server core, which nothing here reads. README's Credits
and the header of `build-proc-rates.py` now name the database repos and GPL-3.0. Released changelog
entries that say GPL-2.0 are history and stay as written. AtlasLootClassic's GPL-2.0 credit is
correct and unchanged.

### Fixed -- three peer-review findings, two open since 2026-08-22 (inbox `2bbead0a`, `b0947a64`) and one never filed

- **Finding 29 (HIGH): `tools/split-seasonal.py` silently reverted to the pre-ATT
  threshold-only split when AllTheThings was absent.** It sat at `docs/AUDIT.md:5249` under an
  H4 heading the board importer does not read, so no todo or fix ever existed until
  2026-09-18. `att_era_ids` returns an EMPTY set when ATT is not installed or no Lua
  interpreter is found, printing only a stderr note; `main()` then carried on with `era = {}`,
  so every id at or above the threshold moved back into the overlay -- Chronoboon Displacer
  and the other Era additions v0.5.0 restored among them -- and vanished on Era realms again.
  Now the tool **refuses** on an empty set (the one value that cannot occur with ATT present
  and always occurs without it; a small count is normal, ATT coverage being partial), naming
  what was missing and what to install, in the style of `build-item-sources.py`'s DB refusal.
  `--without-att` runs the threshold-only split on purpose.
- **Finding 27: `tools/build-locales.py` exited 0 after refusing locales.** Every failure path
  in its loop was a bare `continue` and `main()` ended with the loop, so the Mists run that
  wrote six locales and refused five exited exactly as a clean run did, with the skips on
  stderr and the successes on stdout. Now every refusal and skip (names refused over the
  fallback limit, names skipped on a failed fetch, RandomProps skipped) is collected and the
  run ends with `sys.exit` naming them: _"3 of 11 locale step(s) did not build -- deDE names
  refused (57.6% fallback); ..."_. A clean run prints `all N locales built`. The files on disk
  for a refused locale are the previous ones, and the message says so.
- **Finding 26: nothing checked that a builder rerun had not reverted the seasonal split.**
  Any `build-*.py` rerun writes the whole unsplit table back into `_core`, and
  `split-seasonal.py` had to be re-run by hand; `verify-manifest` cannot see it (both halves
  are on disk and named), and correcting the header counts (finding 32) made an unsplit file
  internally consistent and wrong. New `Tests/seasonal_split_spec.lua`: for every
  `Data\Vanilla\_seasonal\...` file the TOC names, its id set and the base file's id set must
  be **disjoint** -- 31 pairs (18 core tables, 13 locale name files), read from the shipped
  tree, no DB2, no network. Goes red on the first reverted split with the id that proves it
  and the command to fix it. The base may legitimately be empty (every Class 18 item is
  seasonal), so the precondition is "the base calls a loader", not "the base has rows".

### Documentation -- README and the CurseForge page brought up to the library's current state

A full pass of both files against the real API surface (every `function lib:` in the library,
`Integrations.lua`, `Price/*.lua`), at the operator's instruction, after the two features above
had each added their own rows. Item counts were re-measured from the shipped `Data/` files rather
than trusted: Vanilla 24,127 (17,604 base + 6,523 seasonal), TBC 30,032, Mists 88,259 -- all three
match what both files already said.

- **README "Scope by expansion" contradicted the README's own TBC section.** It still said fixed
  BiS lists, aura buffs, talents and talent effects were Vanilla-only; `Data/TBC/_core/` has
  carried `BiS.lua`, `AuraBuffs.lua`, `Talents.lua` and `TalentEffects.lua` since v0.5.0, and the
  "Running on TBC" section two screens down said so. Rewritten to the real per-flavour scope,
  including that Mists carries the 33 original instances' drop graph (no rates) and that the
  price ladder and proficiency rules are code, so every flavour has them.
- **README "Testing" still said `LibItemDB-1.0.lua` was at ~57% coverage** and the "standing
  gap"; it has been at 100% since v0.7.0, as are the Scoring and Price files. The coverage command
  now lists every shipped Lua file and the section states the 100% bar.
- **README "Standing files" described a board protocol that was retired on 2026-09-10** (raise a
  request in your own `docs/LIBRARY_CONTRACTS.md`, ItemDB mirrors it back). Retitled "Historical
  record": the writ inbox is the channel between fleet addons; an outside consumer opens a GitHub
  issue or asks on Discord. `docs/TBC-Parity.md` is the one standing document.
- **The four boards are IMPORTED into the writ inbox and REMOVED**, at the operator's instruction
  (_"have the audit, contracts and harness documents all been imported into the bank/desk/todo in
  writ?"_ -- they had not -- and _"if you've migrated it, the audit.md board should be retired as
  well"_). `docs/AUDIT.md` (33 items; 29 closed, strays re-checked against the Status table and the
  code), `docs/LIBRARY_CONTRACTS.md` (7), `docs/DEPENDENCY_CONTRACTS.md` (8), `Tests/HARNESS_CONTRACT.md`
  (1) -- every thread marked, then `git rm` on all four; history keeps every line. The importer's
  open/closed split was checked against the board's own Status table and the code rather than
  trusted: it over-reported findings 9 and 10 (Fixed on the board) and under-reported 27. Three
  findings were genuinely open and are fixed in this release -- see "Fixed -- three peer-review
  findings" above. One of them, **finding 29 (HIGH), no import could see**: it sat at a `####`
  heading, one level deeper than writ's board importer reads, so in 24 days it had reached no todo
  and no fix. Found by listing every heading on the board against the import's list; the `####`
  shape is sent to writ as contract `a0fe2f5c9620`. `CLAUDE.md`'s "Read these before working"
  table now points at the inbox instead.
- README: the intro names what the library answers beyond identity (origin + rate, who can use it,
  EP, price); the example shows `GetSources` rows with `rate`, `GetDropRate` and `CanUse`; the
  data-layout block lists `DropRates.lua`, the other side-tables and the `_seasonal/` overlay;
  `ClearScanResults` (public since MINOR 25, never documented) is on the `CancelScan` row.
- **CF page:** a v0.10.0 block under Recent Updates (New / Fixed); "What it can do" gains the
  drop-chance and "can this character use it" bullets; the example shows `rate`, `GetDropRate`,
  `CanUse` and `ClassProficient`; two overlapping "who can use it" method bullets merged into one
  that also names `GetArmorCap`, `GetPlayerLevel` and `PROFICIENCY`; the "Data coverage" paragraph
  no longer says BiS lists are Vanilla-only and now lists what each flavour ships. The worked
  figure is a real pair from the data (Felheart Gloves from Lucifron, 33%; `[16805]="12118:33"`),
  not an illustrative one.

### Harness pin

`Tests/wowapi` `82eb99e` -> `dc95cca`. Adoption entries since the last pin: `C_Seasons` and
`C_Spell.GetSpellName` now exist offline (the season specs already stub `C_Seasons` explicitly,
so nothing changed); `Settings.GetCategory` takes an ID (nothing here calls it); the
`LibAceGUIWidgets-Resize` load and an `env_spec` lint disable (nothing to adopt). Suite green at
the new pin before any change in this entry was made.

### Housekeeping

- `tools/itemdb_common.py`: `re.S` -> `re.DOTALL`; explicit `check=False` on the `att_extract`
  subprocess call. `tools/build-proc-rates.py`: unused `os` import removed, one `%` format
  rewritten as an f-string. All three were ruff findings on files this entry touched.
- **Archived v0.6.0 into `CHANGELOG_ARCHIVE.md`.** This entry took the live file to 116,926
  characters, 3,074 under the 120,000 working ceiling for the GitHub release body; the v0.6.0
  section (19,346 bytes) moved across unchanged, newest-first, and the pointer line now reads
  "v0.6.0 and earlier".

## [v0.9.0] (2026-09-15) - A FED price source: a consumer's own price list rides the ladder

**TOGBankClassic's `LIBREQ-PRICE-011`** (their `docs/LIBRARY_CONTRACTS.md` 7.14; the request
mis-numbered itself 009 and corrected in-thread). The operator: _"for the donations, we need a way
to determine what the value is so any banker applies the same value. need some way for me with TSM
to sync my TSM values with other folks that don't sync up."_ TOGBank publishes one officer's price
list to the guild; a banker without TSM would otherwise value a donated stack at their own scan or
the vendor floor, the officer's client would say something else, and the donation ledger is
permanent. TOGBank shipped a consult-the-list-first shim in front of its own `GetPrice` calls; with
this, that shim goes and every consumer of the ladder (TOGPM's crafting costs, PersonalShopper)
sees the guild's figure through the API it already calls. **Library `MINOR` 25 -> 26.**
Feature-gate on `if DB.StoreExternalPrices then`.

### New Features -- `Price/Sources.lua`: fed sources

- **`DB:StoreExternalPrices(sourceID, sourceName, entries)` -> `count | nil, reason`.**
  `entries = { [itemID] = { minBuyout|market|historical = copper, at = epoch } }`, the same three
  statistic names as everywhere else. **Replaces** the source's whole table for the current realm +
  faction (a feed is the list, not a delta), kept in `LibItemDB_PriceDB.realms[scope].external`
  so it survives a reload and a list fed on one realm never answers on another. Junk is refused
  per statistic exactly as `StoreScannedPrice` refuses it -- a non-number, a zero, a negative --
  and an entry with nothing left is not stored. An entry without `at` is dated by the newest `at`
  in the list, else by the feed. A built-in id (`scan`, `tsm`, ...) or an empty one is refused.
- **`DB:ClearExternalPrices(sourceID)` -> `held`.** Drops the data, keeps the row: the source's
  toggle and precedence live in a per-ACCOUNT registry (`settings.external[id] = { name,
  enabled }`) that outlives a clear, so the next feed of the same id lands where the user put it,
  still on or off as they left it. Between feeds the row shows as not detected.
- **It is a source like the others.** `activeSources` / `GetPriceSources` resolve an id through
  `sourceFor(id)` -- a built-in from `SOURCES`, else a descriptor built from the registry and what
  the current scope holds -- so `try` / `lookup` / `HasPriceData` / `MovePriceSource` are
  untouched and a fed source answers under the ladder's rules: a named statistic only from an entry
  carrying it, `best` walking `minBuyout`, `market`, `historical`, provenance
  `{ source = sourceID, sourceName, statistic, age = now - at, at }`.
- **Default precedence FIRST** the first time an id is fed (`table.insert(order, 1, id)`), because a
  guild list exists precisely to override the client's own view; `normaliseOrder` likewise puts a
  registered fed source a saved order omits at the front, where an omitted built-in is still
  appended. TOGBank's own rule closes the loop: it never feeds on the authority's client, whose
  sources ARE the list, so a fed copy ranked first cannot hand the next build yesterday's figures.
- **`GetPriceSources` rows gain `external`, `age`, `count`.** `age` / `count` are set only for
  sources whose data the library holds and can date -- the own scan (last full scan, priced items;
  `scanInfo`, which `GetScannedItemCount` now reads too) and a fed source (newest `at`, entries).
  A third party does not say, so both are `nil` there.
- **`DB:IsPriceSourceEnabled(id)` / `DB:SetPriceSourceEnabled(id, on)`** -- one switch for any
  source. A built-in routes to its settings key (each `SOURCES` entry now names it as `toggle`),
  so `LibItemDB_PriceSettingsChanged` still carries `useAuctionator` and the fallback cascade still
  runs; a fed source flips its registry toggle and fires `("external", sourceID)`.
- **`LibItemDB_PriceSettingsChanged("external", sourceID)`** fires on every feed, clear and toggle.

### Changed -- `Price/Window.lua`

- **The window's own `TOGGLE_KEY` table is gone.** It was the same id -> settings-key fact
  `SOURCES` already held, kept in two places -- and it could never have known a fed id. Both the
  row's check action and the menu's "Enabled" item go through `SetPriceSourceEnabled`.
- **A "Data age" column** (64 px; Statistics narrowed 200 -> 170 to make room): the own scan's
  last full scan, a fed source's newest figure, `"never"` before either -- and an empty cell for a
  third party, which cannot be dated and where `"never"` would be a claim. The help text says what
  a fed source is.

### Tests

- `Tests/price_spec.lua`: a `fed sources` block of 15 examples -- store shape and count, precedence
  first then user-movable, provenance and per-entry statistic gating, junk refusal per entry, dating
  fallbacks, replace-not-merge, refused ids, realm + faction scoping, the `GetPriceSources` row,
  the toggle through both switches, the callback on feed and clear, registry surviving a clear, the
  SavedVariables round trip with a saved order that omits the source, a saved table of the wrong
  shape ignored (`externalHeld` checks `items` / `stats` / `at` before trusting it), the bulk form,
  two fed sources kept apart. `Tests/pricewindow_spec.lua`: the age cell on built-in rows, a fed source's row, and
  the live window repainting on a feed, toggling it through the row action and the menu.
- 537 examples green (515 before); `Price/Sources.lua`, `Price/Window.lua`, `Price/Scanner.lua`
  at 100.00% line coverage.

### Documentation

- `README.md`: a "Fed sources" section under Item prices -- the call shape, every rule above
  stated for an outside dev, and the one rule the library cannot enforce (never feed on the
  authority's own client); the method table gains the four new methods and the new
  `GetPriceSources` fields; the callback list says what `("external", sourceID)` means.
- `docs/Curseforge_Description.html`: the feed in the "what it can do" price bullet and the API
  example, the four methods in the key-methods list, and the v0.9.0 Recent Updates block.

## [v0.8.0] (2026-09-14) - Item VALUE: the price ladder, the Auction House scanner and the third-party price integrations move here from TOGProfessionMaster, with their own window

**One body of work, at the operator's direction (2026-09-14, relayed by TOGBankClassic's
`LIBREQ-PRICE-001..010`):** _"we need to move those 3rd party integrations into itemDB now and
build a UI in IDB for those integrations like we do currently in TOGPM. we'll want to move that
all into it's own window, we can use VersionCheck as a reference."_ TOGProfessionMaster carried the
only Auction House scanner in the fleet plus a duplicate of the Auctionator / TSM adapters this
library already published in `Integrations.lua` -- and TOGBankClassic's storefront needed the same
capability. Two copies of a third-party integration is `LIBREQ-ACQ-001` again, so it is one copy,
here, consumed by both. **Library `MINOR` 24 -> 25.** Feature-gate on `if DB.GetPrice then`.

The boundary, stated once so it is not re-argued: **the library answers "what is this item
worth"; it never answers "what do we charge for it".** Guild discounts, officer overrides,
donation rates and rank tiers stay in the consumers. TOGPM's crafting-cost maths (`CraftCost`,
`CraftCostForReagents`, `GetReagentCost` -- a vendor-sold reagent costed at the vendor price even
when someone lists it) stay in TOGPM; they are profession policy, not market.

### New Features -- `Price/Sources.lua`: the ladder, its store, its settings

- **`DB:GetPrice(itemID, statistic)` -> `copper, provenance`.** Keyed by item id, never name or
  link; copper as an integer; `nil` for no data and never a zero (an unpriced item silently
  priced at 0 is given away for free -- TOGBankClassic's `LIBREQ-PRICE-003`). **A named statistic
  is answered only by a source that carries it**: `"minBuyout"`, `"market"`, `"historical"`;
  asking for market never quietly hands back a minimum buyout under another label. `"best"` walks
  each source's statistics in that source's own preference before moving to the next source --
  `minBuyout`, `market`, `historical` for Auctionator, Auctioneer and the own scan, which is
  exactly the ladder TOGPM's `Price.Get` ran (Auctionator live then historical, Auctioneer market
  then cached, own scan); `market`, `minBuyout`, `historical` for TSM, whose market figure is the
  region-wide one (see the TSM source below). Provenance carries `source`, `sourceName`, the REAL
  `statistic` (never `"best"`), `age` in seconds and the matching `at` epoch -- the own scan is
  exact, Auctionator reports whole days (`GetAuctionAgeByItemID`), Auctioneer and TSM do not say
  and report `nil`.
- **`DB:GetPrices(itemIDs, statistic)` -> `results, count`**, the bulk form: an array of ids or a
  set `{ [id] = ... }` (a bank inventory's shape), the source list resolved **once** per batch.
  Pinned by a spec that counts the detection probes.
- **`DB:GetPriceSources()`** -- every source in the user's precedence with `detected`, `enabled`,
  `precedence` and the `statistics` it can answer; **`DB:HasPriceData()`** -- whether ANY enabled
  source could answer on this machine, so a UI can tell "this item has no price" from "you have
  no price data at all" (`LIBREQ-PRICE-006`).
- **`DB:GetVendorBuyPrice(itemID)`** -- what a vendor charges, best source first: Auctionator's
  vendor cache when that source is enabled, a price this account saw at a merchant (captured on
  `MERCHANT_SHOW`, per single item, unlimited-stock wares only -- the only source that knows the
  player's reputation discount), then the shipped base price. TOGPM's `Price.GetVendorBuy`, moved.
- **Four sources, one registry** (`SOURCES`), each with `detect` / `enabled` / `stats`:
  - **Auctionator** -- `minBuyout` from `GetAuctionPriceByItemID`; `historical` from
    `Auctionator.Database:GetMeanPrice(id, 14)`, gated by `useAuctionatorHistorical`. **TOGPM's
    adapter reached for a `GetHistoricalPriceByItemID` that Auctionator's API v1 does not have**
    (read: `Source/API/v1/*` carries no such function) and silently fell back to the live price,
    so its "historical" was never historical. A v1 function of that name is still preferred if
    one ever ships; the mean is what answers today.
  - **Auctioneer** (Auc-Advanced) -- `market` from `GetMarketValue`, `historical` from the cached
    stat engines (`GetAlgorithmValue` across the known engine names and call shapes, then the Stat
    modules' `GetPriceArray`, most observations wins), gated by `useAuctioneerCached`. The item is
    offered as the real link when cached, then `item:%d:0:0:0:0:0:0:0`, then `item:%d` -- built by
    appending, because a nil first element stops `ipairs` before the synthetic forms that exist
    for the uncached case. The one adapter this library did not already have.
  - **TradeSkillMaster -- REGION figures first.** The operator, after the first in-game pass
    (`/itemdb price` answered _"No price for item 8952"_ with TSM enabled and first): _"you need
    to use tsm app helper to populate the TSM regional data, that is correct ALL THE TIME FULL AH
    data -- not piecemeal data from the AH we're getting now -- the piecemeal stuff is for suckers
    WITHOUT TSM"_. TSM holds two pictures of the house. The **realm** figures (`DBMinBuyout`,
    `DBMarket`, `DBRecent`, `DBHistorical`; App Helper's `AUCTIONDB_NON_COMMODITY_*`) are only as
    fresh as the Desktop App's last publish for THAT realm -- Old Blanchy's carried a
    `downloadTime` of 2024-11-19, 664 days old, with most items (8952 among them) absent, and
    TSM serves that snapshot with no age on it. The **region** figures (`DBRegionMarketAvg`,
    `DBRegionHistorical`, `DBRegionSaleAvg`; App Helper's `AUCTIONDB_REGION_*` for
    `Classic-US`) are every realm in the region, aggregated and refreshed by the app -- 8952 is
    there at 20s. So: `market` = `DBRegionMarketAvg` then `DBMarket` / `DBRecent`; `historical` =
    `DBRegionHistorical` / `DBRegionSaleAvg` then `DBHistorical`; `minBuyout` = `DBMinBuyout`
    (a minimum buyout is a listing, not an aggregate; there is no region one). `useTSMAppHelper`
    gates the region half, **defaults ON**, and no longer enables the source by itself -- it is
    TSM's primary half, not a fallback, so it is NOT cascaded off with `useTSM` either (a source
    toggled off and on must come back on region data). Read through `TSM_API` rather than by
    capturing `TSM_APPHELPER_LOAD_DATA`: TSM already resolves the client's region dataset
    (Classic / HC / SoD / Fresh x US / EU), decodes the app's base-32 packing, and
    `TradeSkillMaster_AppHelper` cannot load without TSM (`## Dependency`), so there is nothing
    underneath it to reach and a load-order trap in trying. Both item-string spellings and both
    argument orders are still tried, as TOGPM did, because builds differ.
  - **ItemDB scan** -- `minBuyout` from the store, with an exact age.
- **Settings, per account**, with TOGPM's defaults except two: own scan on, auto-scan off, delay 0
  (client default), every third-party parent toggle off, every sub-toggle on so enabling a parent
  gets its whole ladder (TOGPM shipped `useTSMAppHelper` off; see the TSM source above for why it
  is on), order Auctionator / Auctioneer / TSM / scan -- and **default statistic `best`, not
  TOGPM's `minBuyout`**: a minimum buyout is a listing figure that Auctioneer never carries and
  TSM's region data never carries, so a caller naming nothing skipped both, which is what the
  first in-game `/itemdb price` showed. `best` lands on the same minimum buyout wherever that is
  all a source has. The settings table carries a `version` stamp (1): a table with none was
  written by the pre-release build that materialised the old two defaults into it, and those two
  values (`defaultStatistic`, `useTSMAppHelper`) are reset to the new defaults once, on load --
  a saved default cannot otherwise be told from a chosen one. `GetPriceSetting` /
  `SetPriceSetting` (validated: booleans coerced,
  `scanDelay` clamped 0.5-10 with 0 = default, `useAuctionator` / `useAuctioneer` going off take
  their fallback with them), `GetPriceSourceOrder` /
  `SetPriceSourceOrder` / `MovePriceSource` (unknown ids dropped, omitted ids appended, so a saved
  order from an older build gains a new source rather than losing it). Every write fires
  `LibItemDB_PriceSettingsChanged`.
- **The store is scoped by realm + faction** (`"Realm - Faction"`, `DB:GetPriceScope()`), as
  TOGPM's `Ace.db.factionrealm` was: Vanilla and TBC keep one auction house per faction, so a
  Horde scan never answers an Alliance lookup (specced by swapping the faction mid-example).
  Derived per-item statistics only -- `{ p = copper, at = epoch, n = listings }` -- never raw
  rows (`LIBREQ-PRICE-008`).
- **SavedVariables: `LibItemDB_PriceDB`**, declared in all five TOCs, the first thing this library
  has ever persisted. A write made before `ADDON_LOADED` (a consumer pricing during its own load)
  lands in a pending table that is **promoted** to the saved global when the client hands us none,
  and discarded when it hands us a saved table -- so an early write survives and a saved table is
  never clobbered. `Tests/toc_spec.lua` asserts the directive against the name in the source.
- **Callbacks through CallbackHandler-1.0** (`DB.RegisterCallback(owner, event, fn)`):
  `LibItemDB_ScanComplete(kind, reason, results)`, `LibItemDB_ScanProgress(kind, scanned, total,
  item)`, `LibItemDB_AuctionHouse(isOpen)`, `LibItemDB_PriceSettingsChanged(key, value)`.
- `DB:FormatMoney(copper)` (TOGPM's `Price.Money`), `DB:FormatPriceAge(seconds)`,
  `DB:GetPriceStatistics()` / `GetPriceStatisticLabel`, `DB:StoreScannedPrice` /
  `StoreVendorPrice` (public so PersonalShopper's scanner can feed the same store later),
  `DB:GetScannedItemCount()`, `DB:GetLastScan()`.

### New Features -- `Price/Scanner.lua`: the Auction House scanner, moved

TOGPM's `Modules/AHScanner.lua`, ported whole: the **full scan** (legacy `QueryAuctionItems(...,
getAll=true)` on Era / TBC / Wrath, honouring `CanSendAuctionQuery`'s second return and silencing
every other `AUCTION_ITEM_LIST_UPDATE` listener for the payload -- Auctionator's pattern;
`C_AuctionHouse.ReplicateItems` on Cata / MoP with a 15-minute self-throttle; 500 rows per frame
either way), the **targeted scan** (`StartTargetedScan(items, opts)`, one browse query per name
with the configured delay, `CanSendAuctionQuery` retry on the legacy path, an uncached-item retry
and a silent-server timeout on the modern one), `GetScanListings`, `CancelScan`, the **ItemDB
Scan** button on the Auction House frame, `IsAuctionHouseOpen`, and `AuctionHouseSearch(name)`
(TOGPM's `AH.SearchFor`, so its `[AH]` buttons keep a home). `GetScanState()` is the
`LIBREQ-PRICE-005` surface: running / kind / progress / last scan / house open. Ace timers became
`C_Timer.After`; `addon:Print` became a `LibItemDB:` chat line; the modern-vs-legacy decision is
still taken once at load from `C_AuctionHouse`.

The arithmetic that matters is unchanged and re-pinned: **per-UNIT price is `ceil(buyout /
count)`** and the cheapest listing is not the cheapest item. A targeted scan's lowest buyouts now
also land in the store, so the next `GetPrice` answers from them.

### Bug Fixes

- **A timer left armed by a cancelled targeted scan could advance the NEXT scan.** `C_Timer.After`
  cannot be cancelled, so a scan cancelled between items (the AH closing does exactly that) left
  its "next item" timer armed; the player reopens the house and starts a new scan inside that
  delay, the stale timer fires `_scanNext`, and it pops the new scan's next item while the first
  query is still in flight -- or, with a one-item scan, finishes it as "0 of 0 items" before the
  result arrives. TOGPM's scanner had the same hole through AceTimer's `ScheduleTimer`, never
  cancelled. Found by this library's own suite: one example's leftover timer drained the next
  example's queue. Every targeted-scan timer now carries a **generation** number; `StartTargetedScan`
  and `_finishScan` bump it, and a timer from an older generation is inert. Pinned by "a timer
  left armed by a cancelled scan cannot advance the next one".
- **`/itemdb price <link>` split the argument on spaces**, so a pasted link whose item name has a
  space in it ("Copper Ore") was refused as usage. The id is taken out of the link and the
  statistic from after its closing `|r`. Found by the spec before it shipped.
- **The usage line printed as `[minBuyout|marketistorical|best]`** -- the chat frame reads `|h`
  as a hyperlink escape and swallowed it. Seen in game. Separators are now `/`, and the spec
  asserts no pipe past the coloured prefix in either help line.
- **`/itemdb price` refused an item NAME** -- from the library whose reason to exist is resolving
  names. The last word is the statistic when it names one; the rest is an id or a name, resolved
  through `ResolveName` (case-insensitive; a suffixed name prices its base item); an unknown name
  says so rather than printing usage.
- **The Scan tab's refusal message was overwritten by its own repaint** ("Could not start a scan:
  ah-closed" written, then the status repaint blanked it). Repaint first, then the refusal. Found
  by the window spec.
- **The Sources list rendered EMPTY on the first in-game open -- no rows, no header -- while
  every offline assertion passed.** Found by the operator, from a screenshot. The cause: the
  TabGroup was given the "List" layout (the Scan tab's stacked controls need it), and an AceGUI
  TabGroup re-sizes ITSELF to its children after every layout (`LayoutFinished` ->
  `SetHeight(children + 23 + borderoffset)`). The Sources tab has no AceGUI children -- the
  RowList is a raw frame on the content -- so the group shrank to 53 px, its content frame to
  an explicit height of 0, and RowList, which sizes its visible rows from `parent:GetHeight()`,
  showed nothing. VersionCheck never meets this because its tab layout is "Fill". Fixed with the
  widget's own opt-out, `tabs.noAutoHeight = true`. Two things changed with it: the list now sits
  DIRECTLY on the tab content exactly as VersionCheck's does (the intermediate pane is gone) and
  the default-statistic picker moved to the window's bottom bar, left of the info "i", where
  VersionCheck parks its buttons; and a `C_Timer.After(0)` refresh runs after the window shows,
  because an anchored frame's height reads 0 until the client's next layout pass. **Why the suite
  missed it:** the spec asserted the list's DATA (`#win.list.data == 4`) and never its geometry.
  It now asserts the content height, the visible row count, that rows 1-4 are shown and row 5 is
  not, and the picker's rect against the info button's -- and the content-height assertion fails
  against the old code. Same lesson as the harness's own rule: an assertion that a widget was
  _given_ data proves nothing about where it is drawn.

### New Features -- `Price/Window.lua`: the configuration window

`/itemdb` (and `/libitemdb`): a LibAceGUIWidgets **ClearFrame** -- the suite's chrome, status bar
naming the version and the realm scope, the info "i" -- with a **TabGroup** branded by
`W:BrandTabGroup`, modelled on VersionCheck-1.0's roster window. **Sources**: a `RowList` with one
row per source (Source / Detected / Enabled / Statistics / Order), a check icon that toggles the
source, up/down icons that move it (hidden at the ends), a right-click menu carrying each source's
extra toggles (Auctionator's historical fallback, Auctioneer's cached fallback, TSM's "Region
data from the TSM Desktop App first"),
and the default-statistic picker on the window's bottom bar. **Scan**: house open/closed, last full scan
with age and count, live progress, **Scan now** (refusals reported in place), auto-scan on open,
and the delay -- a "use this client's default" box over a 0.5-10s slider. Geometry persists in
`LibItemDB_PriceDB.window` through `W:PersistWindow`. The window owns no data: rows come from
`GetPriceSources`, every control writes through the settings API, and it repaints on the library's
own callbacks, so a change made through the API shows without reopening. Built on first open and
never before. `/itemdb scan` starts a full scan; `/itemdb price <id, link or name> [statistic]`
prints what the ladder answers, with provenance.

### Changed

- **All five TOCs, in lockstep:** `## Dependencies: Ace3, VersionCheck-1.0, LibAceGUIWidgets`
  (the window needs it, the same reason VersionCheck-1.0 declares it), `## OptionalDeps` gains
  `TradeSkillMaster_AppHelper` and `Auc-Advanced` so the client loads them first when present,
  `## SavedVariables: LibItemDB_PriceDB`, and the three `Price\*.lua` files after
  `Integrations.lua`. `.pkgmeta` `required-dependencies` gains `libaceguiwidgets`.
  `Tests/toc_spec.lua` now asserts the dependency line, the SavedVariables name (read from the
  source, so they cannot drift) and that `Dependencies` / `OptionalDeps` are identical across
  flavours.
- `.luacheckrc` / `.luarc.json`: the auction-house, merchant and slash globals the price files
  read; `ITEM_QUALITY_COLORS` and the `SLASH_*` names as written globals; `redundant-parameter`
  disabled in the language server, whose arity for `QueryAuctionItems` and friends was being
  inferred from the specs' own stand-ins.

### Testing

- **Three new spec files, 171 examples, 100% line coverage of all three price files** (473, 438
  and 371 executable lines), run through the harness gate. `Tests/env_price.lua` loads the library
  and the three files once per run and resets the SavedVariables table and the scanner's session
  state per example. `price_spec.lua` pins the ladder, every adapter's feature-detection and
  toggle-gating, the bad-return guards, `nil`-never-zero, provenance, the bulk form, the store's
  realm + faction scoping, the SavedVariables promotion, the merchant capture and the settings
  API. `pricescan_spec.lua` carries TOGPM's `ahfullscan_spec` / `ahscanner_spec` cases across
  (per-unit arithmetic, the zero-indexed modern API, every refusal of both scans) and adds the
  targeted scan driven end to end on both APIs, the stale-timer defect, and the load-time
  modern-API detection (the file is reloaded under a stub `C_AuctionHouse`, which it is written to
  survive). `pricewindow_spec.lua` builds the real window on `env.frames` with the installed Ace3
  and LibAceGUIWidgets -- rows, actions, the right-click menu, the picker, both tabs, the callbacks
  repainting it, geometry persistence -- plus the frame-free halves (`BuildPriceSourceRows`,
  `BuildScanStatus`, `FormatPriceAge`, the slash parser). Suite: **520 passed**, 0 failed.
- **Verified in game by the operator, Classic Era, Old Blanchy-Horde**, read back from
  `LibItemDB_PriceDB` rather than assumed: the window's toggles, reorder and resize persisted
  through `/reload`; a full `getAll` scan priced **524 items** (`lastScanCount`, every row a
  positive per-unit price and count); and `/itemdb price` on Roasted Quail answered
  `20s (TradeSkillMaster, Market value, age unknown)` from the region-first adapter -- the same
  command printed "No price" before it. TOGProfessionMaster consumed this MINOR against those
  results and deleted its copies (its v1.0.11).
- **Harness pin `769c043` -> `82eb99e`** (26 days of adoption entries; nothing in them broke this
  suite, and `GetServerTime` on the driven clock, `wow.flushTimers`, and
  `libs.load("LibAceGUIWidgets-1.0")` are used by the new specs).
- `verify-manifest`: 5 TOCs, 214 `.lua`, every one named by a manifest.

### Documentation

- `README.md`: a new **Item prices** section -- the contract, the four sources and what each
  carries (TSM's region-first order spelled out), the full API table, the callbacks, the window,
  and what is deliberately not here; the intro now names pricing as part of what the library is
  for. Requirements updated for LibAceGUIWidgets, the two new optional deps and the SavedVariables.
- `docs/Curseforge_Description.html`: the price feature (configure once, every consumer uses it;
  region data first) in the feature list, the price API in the example, the dependency list, and
  the v0.8.0 notes grouped New / Changed / Fixed. The "Asking for something" section now points
  at GitHub issues and Discord instead of the frozen `docs/LIBRARY_CONTRACTS.md` / `docs/AUDIT.md`
  boards (frozen 2026-09-10; they stay as the historical record).
- `docs/DEPENDENCY_CONTRACTS.md` §5: a dated note under the "not reading the App Helper blob"
  decision -- the region data IS consumed, through `TSM_API`, and the decision still stands.

### Known Limitations

- **An automatic scan that the server throttles stays silent by design** (TOGPM's behaviour,
  carried over): only a manual Scan now / ItemDB Scan prints "Full scan is on cooldown". A
  player with auto-scan on who opens the house inside the shared 15-minute window sees nothing
  happen. A status line on the Scan tab would close that; not done here.
- TSM reports no age for any figure through `TSM_API`, so `age` is `nil` for every TSM answer --
  including a realm snapshot the app stopped refreshing long ago. Region-first makes that the
  fallback rather than the answer, but a consumer showing "age unknown" for TSM is showing the
  truth.
- The harness's `env/libs.lua` manifest counts `tocOmits = 95` for `LibItemDB-1.0` against
  `ItemDB.toc`; with three more shipped files that is 98 now, and `verify-libs` on the harness side
  will report the drift until the harness bumps it (sent to its inbox with this release).

## [v0.7.1] (2026-08-22) - GetSlotRanking stops re-walking the whole database; two silent data defects caught by measuring instead of trusting

**Two bodies of work.** The first is the release's reason: a `script ran too long` field report,
traced by benchmark rather than by reading the traceback, ending in a 5x faster `GetSlotRanking`.
The second came out of proving that fix inert -- re-running a builder to show it changed nothing
instead uncovered **two shipped data defects that every check in the repo had passed**: required
levels served for seasonal items on non-seasonal realms, and a locale builder that overwrote 41,777
real names with English and exited 0. Both are fixed here, and both are recorded in
`docs/AUDIT.md` (findings 33 and 34) because the way they hid is worth more than the fix.

A field report from a v0.7.0 player: two `script ran too long` errors, both with LibItemDB in the
innermost frame. **Neither named line was the cause**, and the first job here was refusing to
"fix" them. `script ran too long` is the client's per-execution watchdog -- it fires wherever the
interpreter happens to be standing when the budget for the whole click runs out. The two frames it
named were `unpackCore`'s `strsplit` return (`:259`) and `ScoreStats`' `if not w then return nil
end` (`:2308`), reached from a `BuffEP` that makes exactly **one** scoring call. Ten seconds were
already gone before either was entered.

So the work was to find what actually spends a frame budget, by measuring it. Benchmarked against
the shipped Vanilla data (17,604 items) on desktop Lua 5.1 -- the client's interpreter is slower
again, so these are a floor, not an estimate of what the player saw:

| Call | Before | After |
| --- | --- | --- |
| `GetStats(id)` | 5.5 us | 3.8 us |
| `GetItemScore(id, ...)` | 8.8 us | 7.8 us |
| `GetSlotRanking` (no `pool`) | **44.1 ms** | **8.4 ms** |
| a 17-slot Planner draw | **0.75 s** | **0.14 s** |

### Bug Fixes

- **`GetSlotRanking` with no `pool` walked and re-scored the ENTIRE database, once per slot.** It
  built an array of every id in `self.core` and handed all 17,604 of them to `RankItems`, which
  `unpackCore`'d each one only to discard the ~95% not in the requested slot -- and then did the
  whole thing again for the next slot. A consumer drawing one item picker per equipment slot (the
  documented use, and what Dibs' Planner does) therefore paid seventeen full-database walks for
  one screen: 0.75 s on desktop Lua, and enough on its own to trip the client's watchdog mid-draw.
  `slotIndex` now buckets core by `equipLoc` **once**, lazily, and each ranking scans only the
  items that can possibly match. `LoadCore` invalidates it, which is the part that could go wrong
  silently -- a `_seasonal` overlay or a second addon's `LoadCore` landing after a consumer had
  already ranked something would otherwise be invisible to every later ranking -- so that is
  specced directly, with an assertion first proving the index really was warm. **A `nil` slot
  ("rank everything") still walks core**, since no per-slot bucket can serve it. Public API,
  signature and results are unchanged, so there is no `MINOR` bump and nothing to feature-gate.
  Location: `LibItemDB-1.0.lua` (`slotIndex`, `lib:GetSlotRanking`, `lib:LoadCore`).

- **Ranked items that score EQUAL came back in a different order on every call.** The pool was
  built by walking `pairs(self.core)`, whose order is arbitrary, so `table.sort` broke ties
  differently each time and a UI redrawing the same ranking could reshuffle rows that had not
  changed. Building the index once fixes it as a side effect: within a session the order is now
  stable. Found while writing the fix above, not reported.

### Performance

- **`GetStats` allocated three tables per call to merge two extras.** It walked
  `ipairs { self.equipStats[id] or "", self.effects[id] or "" }` -- an array literal per call --
  and ran each blob through `decodeStats` into a throwaway table just to `pairs()` it across. It
  is the hottest getter in the library (a consumer scoring a loot browser calls it tens of
  thousands of times per refresh), so the new `mergeStats` layers a blob straight into the table
  that is being built: 5.5 us -> 3.8 us, and no array. The `or ""` on each extra was **load-
  bearing** in the old shape rather than defensive -- a nil FIRST element ends `ipairs`
  immediately, which had once silently dropped the effects blob for every consumable -- so the
  trap goes with the array, and the reason is recorded at the call site rather than deleted with
  the code. `Search` carried a second copy of the same loop, sentinel and all, and now shares the
  helper; that duplication is why the consumable bug had to be fixed twice.
  Location: `LibItemDB-1.0.lua` (`mergeStats`, `lib:GetStats`, `lib:Search`).

### Data

- **`build-locales.py` let a partial wago export overwrite 41,777 shipped Traditional Chinese
  names with English, and exited 0** (`docs/AUDIT.md` finding 34). The `try/except` around the
  name fetch only catches a **throw**; an export that returns successfully but half-empty is not
  an exception, so the missing ids take the documented English-fallback path and are written over
  real localized strings. Measured on the Mists `5.5.4.68806` rebuild: healthy locales fell back
  on ~22 of 88,260 names (0.02%), while zhTW came back 37,465 localized against **50,794
  fallbacks (57.6%)**. Its diff was 41,777 insertions / 41,777 deletions and its log line looked
  like every other locale's. Reverted; guard added -- a locale exceeding `--max-fallback-pct`
  (default 5%, two orders of magnitude above healthy and one below the observed failure) is
  **refused** and its existing file left alone. The guard immediately caught three more on the
  next run: esMX 72.9%, frFR 69.3%, zhTW 57.6%.
  **The shape is the harness's own 2026-08-19 rule in a new place** -- the builder diagnosed
  "this name is not localized" from an **absence**, and the absence was a broken fetch, not a
  fact about the data.
- **The same run silently skipped five locales outright while still exiting 0**, so one green exit
  code covered a data loss and five no-ops. That is why the Mists result below is reported as a
  fraction rather than as done.
- **Locale build stamps: TBC complete, Mists 6 of 11** (finding 16). TBC's 23 locale files
  rebuilt with every diff header-only and 30,032 names byte-identical across 11 locales. Mists
  rebuilt all 12 `RandomProps.lua` and six `Names.lua` (enGB, itIT, koKR, ptBR, ruRU, zhCN -- the
  last also picking up three genuine corrections); **deDE, esES, esMX, frFR and zhTW were refused
  and left untouched**, keeping their real names and their old unstamped headers. A missing stamp
  is cosmetic; an overwritten name is not. The fetch is flaky rather than broken -- three of those
  locales threw on one run and returned partial data on the next -- so the retry needs no code
  change, only a healthy export.
- **`_core` needed no rebuild on either flavour, which is what measuring first established**: all
  14 TBC wago files already carry the pin `2.5.6.68941` and both Mists wago files `5.5.4.68806`.
  The 16 TBC / 17 Mists files stamped `20505` / `50503` are walk-sourced interface stamps and
  correctly outside the mosaic -- they are not to be "fixed". `enUS/Names.lua` carries no stamp on
  any version and that is also correct: it is the walk locale, written by `build-core.py` and
  deliberately skipped by `build-locales.py`.

- **`Data/Vanilla/_core/ReqLevels.lua` shipped UNSPLIT while `_seasonal/ReqLevels.lua` also
  existed, so 5,108 seasonal ids were defined twice** (`docs/AUDIT.md` finding 33). Every other
  split dataset partitions base and overlay between them; this one carried the full 15,652 rows in
  the base _and_ its 5,108 seasonal rows again in the overlay, so `GetRequiredLevel` answered for
  seasonal items on a **non**-seasonal realm -- the one thing the `lib:IsSeasonalRealm()` gate
  exists to prevent. The split now holds: 10,544 + 5,108 = 15,652, each file stating its own real
  count.
- **How it was found, because the method matters more than the fix.** Re-running
  `build-vendor-prices.py Vanilla` to prove an unrelated change was inert regenerated
  `SellPrices.lua` **unsplit** (13,771 -> 18,140 rows) -- which is the standing hazard that any
  builder rerun reverts the partition and `split-seasonal.py` must follow it. Re-running the split
  restored SellPrices byte-identically and moved ReqLevels' 5,108 rows to the overlay they should
  always have been in. Nothing had caught it: the suite was green, `verify-manifest` passed, and
  the header matched the row count -- because v0.7.0's finding 32 had corrected that header to
  15,652, which made the unsplit file look _consistent_ rather than wrong. A header that agrees
  with its own file says nothing about whether the file is the right half.

### Documentation

- **New `docs/LIBRARY_CONTRACTS.md` -- the board for the addons that CONSUME this library.**
  `DEPENDENCY_CONTRACTS.md` points outward and up (what ItemDB needs from what it depends on) and
  had no room for traffic pointing the other way, so a finding about a consumer landed in it and
  was moved out the same day; §8 there is now a stub saying where it went. Dibs has its own
  `docs/LIBRARY_CONTRACTS.md` for asking libraries for things, and the obvious move was to reply
  in it -- but **other repos are read-only from here**, which is the rule the whole contract
  system rests on. The user settled it: _"you can use yours and i'll tell dibs to read it."_
  Format, markers (`[VERIFIED]` / `[READ]` / `[SURVEYED]` / `[IDB-CLAIM]` / `[NEED]`) and the
  reply-in-a-blockquote convention are taken from Dibs' file, which took them from
  TOGBankClassic's, so every repo in the suite sees one document shape. It is also the file the
  session watcher has been aimed at since before it existed.
- **`IDBREQ-DIBS-001` records the half of the report ItemDB cannot fix.** Dibs
  rebuilds its `attackOpts` equipped-weapon context (two `GetInfo` + two `GetStats`) and
  `Loadout:EquippedEP` (a full `GetItemScore` on your worn gear) **per item row**, when both are
  constant for a whole refresh. The entry states what was measured, what ItemDB already fixed, and
  the three changes Dibs still needs -- written up rather than applied, per this file's read-only
  rule about other repos.
- **Dibs answered within the hour, and corrected two things ItemDB wrote. Both accepted, mirrored
  into `LIBRARY_CONTRACTS.md` 1.1 rather than quietly amended.** Items 1 and 2 are done on their
  side (unreleased v0.4.3), item 3 declined for a stated reason -- capping what a browser shows is
  the user's call, not something to decide inside a performance fix. They did not promote the
  benchmark table, which is correct: their spec counts CALLS, not microseconds.
  - **`PLAYER_ENTERING_WORLD` was missing from the invalidator ItemDB specified.**
    `GetInventoryItemID` answers nil for **slot empty** AND for **inventory not loaded yet**, and a
    consumer cannot tell them apart -- so a first score taken before the inventory lands caches 0
    for every slot, and no equipment event fires merely from logging in, leaving it wrong all
    session. A consumer following the original wording literally inherits that bug.
  - **The claim "the ONE honest level-linked effect" was an over-claim, and the real one was
    bigger.** `Items:PlayerClassSpec` cached its talent scan only when points were spent -- so every
    character below level 10 re-walked all three talent trees through the deprecated
    `Specialization` shim, once per item, via `Weights:Source`. That is the level-2 case in its
    purest form and has nothing to do with a thrown weapon. It was named from **two of the four**
    tracebacks that report carried, on a repo that was read rather than run. The finding was right;
    the completeness claim stacked on top of it was not, and that kind reads as authoritative and
    stops the other side looking. Nothing about ItemDB's own fix changes.
- **The consumer board's reply rule was wrong on the day it was written, and Dibs could not follow
  it.** It said "consumers read and respond here" -- but an outside session may write only the
  shared conversation files in another repo, so that invited a write their repo law refuses. Two
  rules disagreeing, and ItemDB's was the wrong one. Replaced with a loop that works: ItemDB raises
  here, the consumer replies in **their own** board, and **an ItemDB session mirrors it back** --
  an obligation, not a courtesy, since until it happens the ticket reads as unanswered to anyone
  reading only this file. Dibs had to flag the first one for a human.
- **`IDBREQ-DIBS-002`: an ItemDB `[VERIFIED]` claim on Dibs' board had gone stale, and correcting
  it caught ItemDB repeating an unverified inference one paragraph after warning about them.**
  Their section 1.4 still closes with ItemDB's 2026-08-03 _"Settled: ItemDB ships `ItemDB_BCC.toc`
  only. `ItemDB_TBC.toc` is deleted."_ ItemDB reversed that since; the repo ships `ItemDB_TBC.toc`
  and no `_BCC`, pinned by `Tests/toc_spec.lua`. A `[VERIFIED]` claim by a library about its own
  shipping filenames, under a heading marked settled, is the least likely thing anyone re-checks --
  and the consumer cannot catch it, because the claim is the library's.
  - **The first draft of that correction then repeated the error it was correcting.** It accepted
    Dibs' reasoning that _"eleven working addons would not be silently falling back to their
    Vanilla tocs, so both suffixes load"_ and published it as fact. Wrong: per the harness's own
    `docs/TOC.md`, the separator is part of the name -- modern suffixes take an underscore, the two
    legacy ones (`-BCC`, `-WOTLKC`) a hyphen, and `-BCC` was dropped in Patch 2.5.5 -- so the
    underscored `_BCC.toc` was never a recognised special name on any client and falls through to
    the unsuffixed TOC. The reductio is the actual situation: that harness doc's 2026-08-07 fleet
    sweep found six addons in exactly that state, and lists ItemDB as clean. The wrong text is left
    standing in the board with the correction appended under it, which is what the append-only law
    is for -- and which is a better record than a silent swap would have been.
  - **Two enforced laws collided while fixing it.** Append-only refuses any edit that does not
    preserve existing text, including a one-character `*` -> `_` swap; MD049 demands one emphasis
    style per file, set by whoever wrote first. In an append-only file no later appender could ever
    normalise it. MD049 is now disabled in `LIBRARY_CONTRACTS.md` with that reasoning written in
    the file; MD050 stays on, since it still catches something.
- **`Tests/HARNESS_CONTRACT.md`: the harness's `env/wow.lua` flavour-alias comment names ItemDB as
  shipping `_BCC.toc`.** It does not, and the comment also presents that spelling as a live
  alternative, which the harness's own `docs/TOC.md` contradicts. Raised as a comment correction
  only -- the `bcc = 5` alias should stay, several addons still carry the filename, and nothing in
  ItemDB is blocked.
- **Archived v0.5.0 and v0.4.7 into `CHANGELOG_ARCHIVE.md`.** This entry took the live file to
  116,065 characters -- 3,935 short of the 120,000 working ceiling, under GitHub's hard 125,000
  limit on a release body -- and the packager publishes `CHANGELOG.md` verbatim as that body, so
  the next entry would have been the one that failed the release. Moved at version boundaries,
  nothing edited, newest-first order preserved; the live file is back to 77,438 characters with
  42,562 to spare. v0.7.1, v0.7.0 and v0.6.0 remain live.
- **The session watcher now covers `Dibs/docs/LIBRARY_CONTRACTS.md`.** ItemDB learned of that reply
  because the user relayed it. The standing rule is that an addon watches the conversations it is a
  party to and not the fleet's; a board section that answers an ItemDB ticket is exactly such a
  conversation, and leaving it out made the reply arrive by hand. Stored in the watcher spec so the
  next session arms it without re-deriving the path.
- **The level-2 character in the report is evidence, not a mechanism, and the entry says so.**
  The traceback's locals carry a quality-1 item-level-3 `INVTYPE_THROWN` weapon -- starter kit in
  the ranged slot, which is how we know the reporter was on a fresh character. **ItemDB has no
  level-dependent code path**: nothing in the library branches on player level and no scoring path
  reads `GetRequiredLevel`. **That half stands; what was published alongside it did not.** A link
  was named on the Dibs side -- something in the ranged slot makes
  `weaponContext(equippedRangedID())` do real work per row instead of returning `nil` at once -- and
  it is real, but calling it _the_ link was wrong: the bigger one was their talent-scan cache, which
  Dibs found the same day (see the correction bullet above). The lasting point is the one that
  survived being wrong: **saying "ItemDB has no level-dependent path" was verified and cost
  nothing to be sure of; saying which single mechanism did it, about a repo that was read rather
  than run and from half the tracebacks, was neither.**

---

## [v0.7.0] (2026-08-20) - Both directions of a vendor transaction; correct proc trigger rates; school-gated spell-damage EP; a reviewed Vanilla rebuild

Two bodies of work ship together here. The vendor-price half was written 2026-08-07 and its
sections are unchanged below; the proc / scoring / rebuild half is 2026-08-20. Nothing in this
entry has been released before.

### New Features -- proc trigger scopes and school gating

- **`GetItemScore` now honours `opts.schools` (LibItemDB-1.0 MINOR 24).** A consumer could
  already pass the magic schools a spec actually casts, and this library silently ignored it --
  so a holy priest banked full EP for shadow-specific spell damage, and a frost mage for a
  +Fire off-hand. The data had shipped for months (`SpellSchools.lua`, `lib:GetItemSchools`);
  only the scorer never consulted it. Now an item whose spell damage is school-restricted earns
  that EP only when the caller's set and the item's **intersect** -- one match is enough, so a
  fire/frost spec keeps full value on a +Fire piece. **Only the school-conditional key is
  dropped:** the item's other stats still score, and its set bonus, on-use and proc are
  untouched because none of them carries a school of its own. An item with no school tag is
  generic +spell damage and always counts. **Omit the option and every score is bit-identical
  to MINOR 23**, which is what makes this safe to ship into live consumers. The gated key is
  declared by the expansion (`schoolGated` in `Scoring/Vanilla.lua` and `Scoring/TBC.lua`), not
  hardcoded in the core, and it is matched POST-alias so `ITEM_MOD_SPELL_POWER` and
  `ITEM_MOD_SPELL_DAMAGE_DONE` are both covered by one entry. `GetItemScoreBreakdown` gates
  identically through the same shared helper, and a gated stat is **omitted** from `parts`
  rather than emitted as a zero row. Seven specs, five of them negative controls; mutation-
  checked by reverting the gate, which reddens exactly the two gating assertions and leaves the
  five "unchanged" controls green. Routed from the Dibs board (`docs/AUDIT.md` finding 20).
  Location: `LibItemDB-1.0.lua`, `Scoring/Vanilla.lua`, `Scoring/TBC.lua`.

### Bug Fixes

- **`Factions.lua` silently lost 155 items whenever it was rebuilt on a current client.**
  wago renamed the `Faction` table's race-mask columns at build 1.15.9.68808: what was
  `ReputationRaceMask_0..3` is now `ReputationRaceMasks0_0`, `ReputationRaceMasks0_1` and so on.
  `race_mask()` knew two spellings and neither matched, so it returned `nil` for **every**
  faction, the `factionID -> side` map came back **empty**, and every item whose side comes only
  from `MinFactionID` dropped out -- the 155 Arathi Basin and Alterac Valley reputation rewards
  (factions 509 League of Arathor, 510 The Defilers, 729 Frostwolf, 730 Stormpike). No error,
  no warning, and a header that read plausibly: 531 items where the shipped file has 686. This
  is the identical failure the function's own docstring already recorded for TBC, arriving a
  third time. Fixed by teaching `race_mask()` the array spelling, **and** by making the silence
  impossible: the builder now exits with a message naming the columns it did find if the
  `Faction` table yields no sides at all, or if `ItemSparse` yields no race mask for any core
  item. There is no build in which nobody picks a side, so an empty map is always a schema
  change and never a fact about the data. Rebuilt output is 686 items (348 A / 338 H) -- exactly
  the shipped counts, now at build 1.15.9.69109. Location: `tools/build-factions.py`.

- **The same defect was still live in the shipped TBC data, and the rebuild recovered 151 items.**
  Fixing `race_mask()` fixed the _builder_; TBC's `Factions.lua` had never been regenerated since,
  so it kept shipping the broken reader's output while its header read `2.5.6.68941` and looked
  current. That is the trap this class of bug keeps setting: a stale artefact is indistinguishable
  from a fresh one, because the stamp records the DB2 it was built against and not the code that
  built it. TBC now reports **284 restricted items (137 A / 147 H)**, up from 133 (68 A / 65 H).
  What came back identifies itself: they are the **racial mounts** -- `Horn of the Black Wolf` and
  `Horn of the Red Wolf` as Horde, `Black Stallion Bridle`, `Pinto Bridle` and
  `Chestnut Mare Bridle` as Alliance -- which are precisely the items whose side comes from a race
  mask and nothing else. Until now `FactionUsable` returned **true** for every one of them on TBC,
  so a ranking would happily recommend an Orc a horse. Location: `Data/TBC/_core/Factions.lua`.

- **`Data/Vanilla/_core/ReqLevels.lua` shipped 10,544 rows while its header claimed 15,652.**
  So **5,108 Vanilla items carried no required level at all** while the file asserted they did:
  `GetRequiredLevel` answered `0` -- which is the real domain value meaning _"no requirement"_, not
  a miss -- for every one of them, and `GetInfo`'s 7th return was wrong for roughly a fifth of the
  database. A consumer sorting a bag by required level, or gating "can I equip this yet", got a
  confident wrong answer with nothing to indicate it. Found by arithmetic rather than by eye: a
  `--stat` diff reported +5,110 lines on a file whose header count had not moved, which is a
  contradiction; `--numstat` gave 5,109 insertions against **1** deletion, and a pure-addition diff
  means every previous row survived, so the old file held 15,652 - 5,108 = 10,544. The rebuilt file
  measures consistent -- 15,652 rows against a header of 15,652. This is finding 22's shape (a
  header true of neither side) and it had shipped, which is why the remedy is the rule rather than
  the row count: **a stat-diff that disagrees with a file's own self-reported count is a defect
  signal, not noise.** Location: `Data/Vanilla/_core/ReqLevels.lua`.

- **`split-seasonal.py` could leave BOTH halves of a file stating a row count true of neither.**
  Its header correction tried two candidates -- the pre-split total and the other half's count --
  and refused (correctly, by design) when neither matched. But `pre_total` is the count of the
  **union** of the base file and the existing overlay, while a freshly built file states only its
  **own** rows; those diverge the moment a rebuild at a newer client build drops ids the overlay
  still carries. Measured: the 11 non-enUS Vanilla `Names.lua` were emitted with 23,448 names,
  the overlay held 679 ids that build no longer has, so `pre_total` was 24,127, neither candidate
  matched, and all 22 files shipped a header claiming **23,448** against real counts of 17,604
  and 6,523. `enUS` escaped only because `build-locales.py` does not write it. Fixed by adding
  the base file's own arrival count as the first candidate. The exactly-once rule is unchanged,
  so this cannot make an ambiguous header guessable -- it only lets an unambiguous one that no
  candidate happened to name be corrected. All 24 Vanilla `Names.lua` now match their headers.
  Location: `tools/split-seasonal.py`.

### Improvements

- **The Vanilla dataset is now one build, and every generated file carries its stamp.** All 78
  Vanilla data files were regenerated pinned to `1.15.9.69109`, collapsing the three-stamp mosaic
  (`docs/AUDIT.md` findings 16-19) to a single build. `Hidden.lua` carries a build stamp for the
  first time on any version -- it had none, so its drift was undetectable by reading the repo --
  along with the ATT removed-with-patch cutoff it also never recorded, and `RepLoot.lua`,
  `ItemLocations.lua` and all 24 `Names.lua` gained theirs. **Verified rather than asserted:
  every one of the 78 files diffs as header lines only** (1-2 lines each), and the row counts are
  unchanged across the whole tree, so no shipped score moved. The two exceptions in the diff
  (`Sets.lua`, `UseEffects.lua`) are the earlier `pm=` change set, not this rebuild.
  Location: `Data/Vanilla/`.

- **`ItemDB.toc` now lists `Data\Vanilla\_seasonal\ItemLocations.lua`.** The rebuild's seasonal
  split created that file for the first time and the TOC lists the `_seasonal` files **by hand**,
  so it shipped named by no manifest and would have loaded on nobody -- item locations silently
  missing for every seasonal item. Caught by `verify-manifest.lua`, which is exactly the hazard
  that check exists for and which a green suite cannot see. Location: `ItemDB.toc`.

- **`header()`'s docstring no longer claims a migration that is finished.** It said "NOT YET
  MIGRATED: the 13 builders that already hand-write the stamp still do", which stopped being true
  when the finding-19 remainder landed -- no builder hand-writes the line any more.
  Location: `tools/itemdb_common.py`.

- **The proc trigger-scope classifier is a real bit test now, in ONE place (finding 15, tier 3).**
  `sc` came from `mask >= 0x10000` -- a magnitude compare on a bitfield -- written out twice, as a
  function in `build-use-effects.py` and re-implemented inline in `build-sets.py`. Three sessions
  recorded the bit meanings as "not established anywhere on this box" and treated that as a
  blocker. **It was not one: they are public emulator source**, and CMaNGOS **mangos-classic**
  (the Vanilla tree this addon targets) and TrinityCore 3.3.5 agree bit for bit, which is what
  makes a Wrath-era table safe to apply to Vanilla data. The old rule was wrong in **both**
  directions: `0x4000` (`DEAL_HELPFUL_SPELL`, a heal cast) is _below_ the threshold and read
  `"any"`, while `0x40000` (`DEAL_HARMFUL_PERIODIC`, a DoT tick) and `0x100000`
  (`TAKE_ANY_DAMAGE`) read `"spell"`. `itemdb_common.proc_scope` now tests bits and answers
  `spell` / `any` / **`periodic`** / **`taken`**; a mask carrying both cast and swing bits
  resolves to `any` deliberately, because the effect does fire on melee and the swing rate is the
  one a paperdoll can actually measure. Verified against the three masks measured from
  `wago_cache` plus both old-failure directions: 7/7 correct, 4 of the 7 changed by the fix.
  The data IS regenerated on both flavours, and every shipped proc row's `sc` was checked against
  the classifier afterwards: **504 rows, 0 disagreements.** Final distribution: `any` 438,
  `spell` 34, `taken` 29, `periodic` 3. Location: `tools/itemdb_common.py`,
  `tools/build-use-effects.py`, `tools/build-sets.py`, `Data/*/_core/Sets.lua`,
  `Data/*/_core/UseEffects.lua`.

- **All four proc trigger rates now ship, derived rather than curated.** `castsPerSec` had been
  declared by no module since MINOR 23, and the two new scopes would have joined it -- three
  named holes all falling back to the swing rate. They are filled, and each number says where it
  came from:
  - **`hitsTakenPerSec` = 0.5, MEASURED** from CMaNGOS `creature_template.MeleeBaseAttackTime`
    over the raid-boss population: the mode is **2000 ms in both eras** (102 of 147 Vanilla
    bosses, 150 of 175 TBC), and the means agree at 2069 ms and 1983 ms. Assumption stated in the
    builder: exactly one boss on you.
  - **`ticksPerSec` = maintained DoTs / 3 s, MEASURED** from `SpellEffect.EffectAuraPeriod`:
    3000 ms is the plurality in both eras (38.9% of 1,282 periodic auras at 1.15.9.69109; 44.0%
    of 1,600 at 2.5.6.68941) and is the exact period of every canonical DoT read individually --
    Corruption, Shadow Word: Pain, Immolate, Renew, Rejuvenation. The assumption is how many DoTs
    a spec keeps up, which no table records, so it is written per class with the reasoning.
  - **`castsPerSec` = 0.4 for casters**, adopted from a number this repo already shipped rather
    than re-derived: `HITS_PER_SEC` assigns 0.4 to Priest/Mage/Warlock precisely because
    "casters trigger off ... casts". The GCD caps any caster at 0.667/s. The melee values are the
    judgement half and are labelled as such.
  Location: `tools/build-score-model.py`, `Data/Vanilla/_core/ScoreModel.lua`,
  `Data/TBC/_core/ScoreModel.lua`.

- **Verified on real items through the real shipped data, not only on fixtures.** Scoring a
  warrior/protection loadout: **Skullflame Shield 47.94 EP with no paperdoll and 47.94 with a
  5-swings-per-second one** -- identical, which is the whole point. Freezing Band 0.78, Girdle of
  Reprisal 7.99, Grand Marshal's Aegis 87.62, all likewise unmoved by weapon speed. Before this
  change every one of them scaled with how fast the wearer attacked.

- **~26 "chance when struck" items were priced off how fast the WEARER attacks.** Found by
  listing the rows the new classifier changes instead of trusting that three sample masks covered
  the space -- which they did not. Reading only `TAKE_ANY_DAMAGE` (`0x100000`) misses every
  effect that names the SPECIFIC incoming types instead of the generic one, and almost all of
  them do: `pm=0x28` and `pm=0x2A8` are `TAKE_MELEE_SWING|TAKE_MELEE_ABILITY`(`|TAKE_RANGED_*`)
  with `0x100000` clear. That is **Skullflame Shield, Freezing Band, Girdle of Reprisal, Vile
  Protector, Truesilver Breastplate, Thermaplugg's Central Core, Grand Marshal's Aegis, High
  Warlord's Shield Wall, Battlegear of Wrath and Darkmoon Card: Vengeance** -- every one a
  canonical when-struck item, every one classified `sc="any"` and therefore rated by the wearer's
  own swing rate. `PROC_ON_TAKEN` now covers the whole `TAKE_*` half of the enum.
  Location: `tools/itemdb_common.py`.

- **The proc rate rule is now one sentence, and it covers all four scopes.** `hitsPerSec` is the
  only rate `opts.attack` can override, so it is the only rate a **swing**-triggered proc may
  read; every other scope resolves off the MODEL, because nothing in a character sheet knows how
  often you cast, how often your DoTs tick, or how often you get hit. `scoreProcEffects` gains
  `ticksPerSec` (DoT/HoT ticks; falls back to `castsPerSec`, since a tick implies you cast the
  DoT) and `hitsTakenPerSec` (incoming attacks, a tanking number; falls back to the model's
  `hitsPerSec`). Both OPTIONAL and both defaulting to a rate that is already correct, so no
  shipped module declaring neither can see a score move -- the same staging finding 9 used, and
  the reason these are two separately-named holes rather than one constant doing four jobs.
  **Without this the rebuild would have REVERSED finding 9's fix**: `periodic` and `taken` would
  have fallen to the `else` branch and started reading the paperdoll, so Timbal's Focusing
  Crystal would have gone from a cast rate to a swing rate. Mutation-checked by restoring the
  two-way branch: the paperdoll assertions fail at 1750 against an expected 175, a 10x inflation,
  while the "no rate declared" control stays green. Location: `LibItemDB-1.0.lua`.

### New Features -- vendor prices (written 2026-08-07)

- **`lib:GetVendorSellPrice(itemID)` — what a vendor PAYS YOU, in copper.** `LibItemDB-1.0`
  **MINOR 22**. With `GetVendorBasePrice` below, the library now answers **both** directions of a
  vendor transaction offline. Location: `LibItemDB-1.0.lua` (`lib.sellPrice`,
  `lib:LoadSellPrices`, `lib:GetVendorSellPrice`), `tools/build-vendor-prices.py`,
  `Data/{Vanilla,TBC}/_core/SellPrices.lua`. **18,140** Vanilla / **21,720** TBC items.

  **Why ship it when `GetItemInfo` already returns it — the reason is the cold cache.**
  `GetItemInfo`'s 11th return is the same number, but only for an item the client has **cached**;
  on a cold cache it returns `nil` for every field and forces a `GET_ITEM_INFO_RECEIVED` retry
  loop. That is the exact rationale `GetRequiredLevel` already ships on, and it is the founding
  reason this library exists. A consumer reading the live value will look correct in every test
  run on items just inspected, and render nothing on a recipe the player has never seen.

  **No vendor gate, and the asymmetry is deliberate.** Any vendor buys anything, so "what will I
  be paid" is answerable for every item with a sell value; "what does it cost" is only meaningful
  where a vendor actually stocks it, which is what `GetVendorBasePrice`'s `npc_vendor`
  intersection is for. Consequence: `nil` from `GetVendorSellPrice` is a **clean** statement (the
  item has no sell value), unlike `nil` from `GetVendorBasePrice`, which conflates four
  conditions.

  **No reputation discount is applied, and the spec pins that as an assumption rather than a
  fact.** Faction discounts are believed buy-side only — the sources define a faction discount in
  terms of buying and say nothing about selling — but this is **not verified**, and no client
  source can settle it: searching all four flavour trees in the Blizzard UI source, the only
  `discount` references are the in-game store, transmog and item upgrade. The mechanic is
  entirely server-side. `Tests/libitemdb_spec.lua` carries a test whose stated job is to **fail**
  if that ever changes.

### New Features (buy price)

- **`lib:GetVendorBasePrice(itemID)` — what a vendor CHARGES you, in copper, or `nil`.**
  `LibItemDB-1.0` **MINOR 21**. Requested by TOGProfessionMaster
  (`docs/DEPENDENCY_CONTRACTS.md` §7) for the last-resort tier of its cost-to-craft chain,
  which has to price reagents no live source can — thread, vials, dye, flux.

  **This is not `sellPrice`, and the distinction is the whole feature.** `GetItemInfo`
  returns what a vendor pays _you_; the client has that natively. It has no buy price at
  all — checked rather than assumed, there is no `buyPrice` field anywhere in
  `ItemDocumentation.lua`, and the only client route is `GetMerchantItemInfo(index)`, which
  needs an open merchant window and answers for the item in that slot. "What would this
  cost" is unanswerable online, which is why it ships as data.

  Location: `LibItemDB-1.0.lua` (`lib.vendorPrice`, `lib:LoadVendorPrices`,
  `lib:GetVendorBasePrice`), `tools/build-vendor-prices.py`,
  `Data/{Vanilla,TBC}/_core/VendorPrices.lua`.

- **The gate is two sources intersected, and the second is not optional.** wago
  `ItemSparse.BuyPrice` supplies the price; emulator `npc_vendor` supplies whether a vendor
  sells it **at all**. `BuyPrice` is roughly `sellPrice * 4` and is populated on nearly every
  item in the game, drop materials included — it is a _price_, never a vendor-availability
  signal, so shipping it alone would tag Thorium Ore with a price no vendor will honour.
  Vendor inventories are server-side and appear in no client DB2. The gate is
  `maxcount == 0 AND ExtendedCost == 0` (unlimited stock, bought with gold), which is the
  same reasoning Auctionator uses when it caches only `numAvailable == -1`.

  Verified on the built data: Coarse Thread 10c, Fine Thread 1s, Silken Thread 5s, Rune
  Thread 50s, Strong Flux 20s, Red/Blue Dye 50c, Salt 50c — and Thorium Ore, Copper Ore and
  Coarse Stone correctly absent.

### Improvements -- vendor prices

- **Cross-checked against TOGProfessionMaster's independent extraction: 59 of 59 overlapping
  values agree, zero disagreements.** Its shipped `Data/VendorPrices.lua` holds 93 rows built
  by a different script in a different repo; every id it shares with ours carries the same
  copper value, and the one Vanilla-file absentee (`23572`) is a TBC item correctly excluded
  from the Vanilla dataset and present in the TBC one. Two independent extractions agreeing
  is the check that found real bugs in the §1 recipe-scroll migration, so it was run here
  before claiming the data was right.

- **Audit finding 1 fired on this very change, which is the strongest argument for fixing it.**
  Generating `SellPrices.lua` made `split-seasonal.py` partition 4,369 Vanilla rows into
  `Data/Vanilla/_seasonal/SellPrices.lua` — a file no TOC listed, because the seasonal manifest
  block is hand-maintained. Caught only because the finding had just been filed and the builder's
  output was read. Unnoticed, 4,369 seasonal items would have had no sell price on
  SoD/Anniversary realms, silently, with a green suite. The TOC line is added; the missing guard
  (assert every data file on disk is named by some manifest) remains open as finding 1.

- **`shipped_ids()` moved into `itemdb_common.py`.** `build-req-levels.py` had the only copy;
  `build-vendor-prices.py` needed the same gate, and a second copy of a rule about which ids
  a version ships is exactly the kind of pair that drifts silently. One definition, two
  callers. Location: `tools/itemdb_common.py`, `tools/build-req-levels.py`.

- **The emulator dumps are read from a sibling ProfessionDB install, not duplicated.** New
  `itemdb_common.npc_vendor_files()`, the same reach-across-to-a-sibling-addon shape as the
  existing `att_categories_dir()`. It prefers a local `tools/emulator_data/` if one exists.
  The relevant input is **2.7 MB across two `*_npc_vendor.sql` files**, not the ~459 MB the
  whole `emulator_data` directory weighs — that figure is almost entirely one full
  TrinityCore world dump this gate never opens.

- **The builder fails loudly when the dumps are missing**, rather than emitting an empty
  table. A shipped-but-empty `VendorPrices.lua` is indistinguishable at runtime from "no
  vendor sells anything": the library would answer `nil` for every item and nothing would
  report a problem.

### Bug Fixes -- EP scoring, all found by peer review (`docs/AUDIT.md` rounds 6-13)

Nine findings, every fix mutation-checked. **Scores change** for affected items: these were all
silent zeroes, and a zero was invisible rather than wrong-looking because `scoreProcEffects`,
`GetSetBonusEP` and `GetItemScoreBreakdown` each drop a row whose EP is 0 -- so a consumer saw **no
row at all**, indistinguishable from an item that has no such effect.

- **Every heal proc in both flavours scored exactly zero** (finding 7). `Scoring/Vanilla.lua` and
  `Scoring/TBC.lua` shipped `epPerHPS = 0`, so the heal bucket
  (`c = (e.m * rate) * model.epPerHPS * hw`) was identically zero for every class and spec. It was
  an unfilled constant, not a policy. Now **3.5**, derived rather than tuned: `epPerHPS` is healing
  power per 1 HPS, and Classic's direct-spell coefficient is `castTime / 3.5`, so `+H` healing power
  yields `H / 3.5` HPS and 1 HPS costs 3.5 healing power. Worst case fixed: Bonescythe Armor's
  entire set value is one heal proc, so the Rogue tier set contributed **nothing**.
- **Every `b="damage"` proc scored exactly zero for every caster spec** (finding 11). The damage
  bucket priced procs only through a weapon-DPS weight, and no caster scale carries one: priest,
  mage and warlock all price `ITEM_MOD_SPELL_DAMAGE_DONE` with neither `DPS_MAINHAND` nor
  `DPS_RANGED`, while shaman `enhancement` has `DPS_MAINHAND=3`, which is what shows the split is
  real rather than a gap in the data. A caster route now converts bonus DPS to a
  spell-damage-equivalent. **It is a fallback, not a replacement** -- a class with a weapon weight
  is untouched.
- **`epPerRawDPS` was shipped, documented, per-class overridable and read by nothing** (finding 8).
  It was **orphaned, not dead**: the missing half of the conversion the caster route needed. Now
  `3.5` by the same coefficient rule (direct _damage_ is also `castTime / 3.5`) and wired to that
  route. Deleting it would have been the tidy wrong answer.
- **`sc` (trigger scope) was carried in the data with two real values and read nowhere**
  (finding 9, route half). It now selects the route: an `sc="spell"` proc takes the caster route
  even on a class that swings. This matters for hybrids carrying both weights -- paladin
  protection/retribution and shaman enhancement -- where a spell-triggered proc was priced by how
  often the class _swings_, overvaluing it by roughly 3x. Requiring a spell-damage weight before
  switching is load-bearing: a pure melee scale must keep the weapon route rather than falling
  through to zero.
- **A paperdoll could drive a proc that fires on a CAST** (finding 9, rate half). `LibItemDB-1.0`
  **MINOR 23**. `hitsPerSec` was one number doing three jobs -- `Scoring/Vanilla.lua` calls it a
  "default proc trigger rate", the library calls it "triggering hits/sec", and `GetItemScore` takes
  it from `opts.attack`, which is a paperdoll and can only report weapon _swings_. So the moment a
  consumer wired the paperdoll (the documented intent) every `sc="spell"` proc would start moving
  with the speed of whatever weapon the player held -- Vestments of Faith's 8-piece triggers on a
  priest's spells and would have tracked their mace. A spell-scoped row is now priced off
  `model.castsPerSec` where the flavour declares one, and off the **model's** `hitsPerSec` -- never
  the paperdoll's -- where it does not. Location: `LibItemDB-1.0.lua` (`scoreProcEffects`).

  **No cast rate is invented and no shipped score moves.** No rules module declares `castsPerSec`,
  so the fallback is exactly what the callers already resolved when no paperdoll is wired: every
  current number is bit-identical, which the specs assert directly. What changed is that
  `opts.attack` can no longer reach a spell-scoped row. **Choosing the actual value is still open**
  and is a design question rather than a defect -- there is no cast-rate field in the data and no
  paperdoll wired in, so picking a number here would be the invented-constant failure this repo
  names. Recorded in `docs/AUDIT.md` rather than guessed at.
- **A proc's trigger scope `sc` is decided by a MAGNITUDE test on a BITFIELD** (finding 15).
  `proc_scope` reads as "does this mask have the spell bit"; `mask >= 0x10000` does not test that
  bit or any bit, so every high bit collapses to one answer. Measured from the DB2 cache, three
  rows the data all labels `sc="spell"` share **no common bit**: Shiffar's Nexus-Horn `0x14000`
  (genuinely on-cast), Timbal's Focusing Crystal `0x240000` (a **DoT-tick** proc) and Battlegear of
  Might's 5-piece `0x100000` -- the **warrior** tier set, currently scored as a mana restore on
  spell cast at a warrior's swing rate.

  **Not fixed, and deliberately not guessed at:** no constant turns a magnitude compare into a bit
  test, and the bit semantics are established nowhere on this box -- absent from the Blizzard client
  tree, and CMaNGOS's `spell_proc_event.procFlags` is `0` for these spells, meaning the emulator
  **defers to the very field we already read**. **What shipped instead is the raw mask**, as `pm`
  beside `sc`, in `Sets.lua` and `UseEffects.lua` on both flavours (`LibItemDB-1.0` **MINOR 23**).
  That cannot lose information -- the mask is the canonical datum even the emulator falls back to --
  so a correct reading can be recomputed later with no data rebuild. `sc` is unchanged everywhere,
  so **no score moves**; every rebuild was pinned to the build already stamped in the file and each
  diff verified to contain the new field and nothing else. Location: `tools/build-sets.py`,
  `tools/build-use-effects.py`, `LibItemDB-1.0.lua`.
- **The pipeline has three input tiers and only one of them could be recorded** (finding 16). A
  generated dataset can only be audited by re-running the thing that made it, and two of the three
  inputs left no trace of which state they were in:

  1. **wago DB2 -- already addressable.** The fetch URL is `?build=<b>`, so the `client build` stamp
     is not a fingerprint, it **is the recipe**: pin the stamp and a bare clone re-fetches that exact
     build. This tier needed documenting, not fixing.
  2. **CMaNGOS -- not addressable, and now hashed.** The download URL ends
     `releases/download/latest/`, a moving tag with **no version in it**, so there is no release id
     to ask for or to record. New `source_fingerprint()` emits
     `-- source <file> sha256:<12 hex>` for these, wired into `build-use-effects` (proc rates),
     `build-sets` (the sqlite) and `build-vendor-prices` (the `npc_vendor` dumps, one line each,
     since the gate is their union). **This is the tier that actually bit us:** item 20905 lost its
     proc rate between two runs and nothing in the repo could show it.
  3. **The TOG Tools walk -- not reproducible at all, so it states a policy instead.** It is the
     output of an in-game item walk on one machine; no hash helps. `build-core`'s files now say so
     outright, including that a bulk refresh **must skip them** rather than emit an empty one.

  A source that is absent is **dropped, not written as missing** -- a builder legitimately degrades
  without its optional CMaNGOS cache, and a header claiming a source it never read would be worse
  than one that is silent. Verified without touching `Data/`: fingerprints are stable across calls,
  an absent input emits no line at all, and a `header()` call with no `sources=` is byte-identical
  to before. Location: `tools/itemdb_common.py`, `tools/build-{use-effects,sets,vendor-prices,core}.py`.
- **The build stamp was a convention with no implementation, and ~78 generated files had none**
  (findings 18/19). Every generated data file is supposed to record the wago build it came from --
  that property is what makes a regenerated dataset auditable at all -- but nothing implemented it:
  `header()` took no build, so thirteen builders hand-wrote the line (three of them bypassing the
  helper) and the rest simply did not. The unstamped set was the **majority** of generated files:
  all **72** locale `Names.lua` / `RandomProps.lua`, plus `ItemLocations.lua`, `Hidden.lua` and
  `RepLoot.lua`. `Names.lua` did not even name which builder wrote it -- it could not, because no
  builder does; both callers go through `itemdb_common.write_names`, which sits 56 lines above
  `header()` in the module that owns the convention.

  `header()` now takes `build=` / `detail=` / `note=`, and **every call site passes it** -- the six
  that omitted the stamp entirely, and all fifteen that hand-wrote it, including the three which
  bypassed the helper altogether (`build-req-levels` and both halves of `build-vendor-prices` wrote
  their whole header with raw `f.write`, which is how the convention spread without ever becoming a
  mechanism). **The stamp is now emitted in exactly one place**, so omitting it takes deleting an
  argument rather than merely not thinking of one. Byte-identity was verified by **running**
  builders rather than reading them: `build-sets` (a `header()` migration) reproduced its file
  unchanged at +22/-22, and `build-req-levels` (a raw-`f.write` conversion) reproduced its six
  header lines character for character.
  **`client build None` is never written** -- `build-rep-loot` legitimately has no build when its
  wago enrichment is skipped, and says so, because absent is honestly unknown while `None` reads as
  a recorded fact. `build-hidden.py` was routed through the shared helper instead of gaining a
  fourteenth hand-written line, and it now also stamps the **ATT removed-with-patch cutoff**, a
  second unrecorded input the build alone does not determine. **No shipped data changed in this
  commit** -- the stamps appear on the next regeneration, which is deliberately a separate,
  reviewed change. Verified: `header()` unit-checked on all five paths, and re-running an
  un-migrated builder reproduced its file byte-identically. Location: `tools/itemdb_common.py`,
  `tools/build-{hidden,rep-loot,item-sources,locales,core}.py`.
- **Both halves of a split data file inherited a row count describing neither** (finding 19).
  A builder emits one file and its header states that file's count; `split-seasonal.py` then divides
  the rows and copies the header **verbatim** into both halves. So Vanilla's `ReqLevels.lua` ships
  10,544 rows in `_core` and 5,108 in `_seasonal`, and **both headers say 15,652**. The build stamp
  inherits correctly -- both halves really did come from that build -- and only the count is wrong,
  which is why the fix belongs in the splitter rather than in `header()`: the splitter is the only
  component that can tell the two fields apart, because it is the only one that knows the post-split
  totals. `header()` runs inside the builder, before either file exists.

  `_recount` corrects the count and never touches the stamp. It is deliberately conservative:
  it rewrites only when the pre-split total appears **exactly once** as a standalone number across
  the header, and only in `--` comment lines, so a header that repeats the number or whose total
  collides with another figure (`N of 24127 shipped items`) is left alone rather than guessed at.
  Unit-checked on six cases including both refusals and the `156520`-vs-`15652` substring boundary.
  **No shipped file is corrected yet** -- that lands on the next deliberate split.
  Location: `tools/split-seasonal.py`.

  **It matches the OTHER HALF's count as well as the pre-split total, and that is what makes it
  idempotent.** `rebuild` sources both halves' structure from the **base** file, so on a second run
  the overlay inherits the base's already-corrected number; a pre-total-only match would find
  nothing, refuse, and leave the overlay stating the base's row count. Caught by running the
  correction twice rather than once -- with the single-candidate rule, run 2 rewrote Vanilla's
  seasonal `ReqLevels` header from `5108` to `10544`. Mutation-checked both ways.

  **`Sets.lua` is the one file that refuses, and the reason is worth recording:** its `_core` half
  holds 172 sets and its overlay holds **287**, because SoD sets exist only in the overlay -- the Era
  DB2 cannot produce them, which is why the splitter unions rather than recomputes. So the header's
  `172` is the base count and the pre-split total (459) appears nowhere in it. Refusing is correct;
  the overlay keeps a wrong `172 sets` until a labelled-count fix, which is not attempted here.
- **Eight builders could not reach `FROZEN_BUILD` at all** (finding 17, step 1). They resolved the
  wago build through `client_for_version` directly -- so the pin was not merely shadowed by a live
  client, it was **never consulted**, and a version whose client has moved on (the Anniversary client
  progresses 2.x -> 3.x -> ...) **exited** rather than falling back to it. `build-classes`,
  `build-core`, `build-effects`, `build-equip-stats`, `build-factions`, `build-item-sources`,
  `build-sets` and `build-use-effects` now resolve through `wago_build_for_version`, matching the
  other nine.

  Two consequences. It is what lets the pin ever become the default -- that change would otherwise
  have been invisible to exactly the builders that produce `Sets.lua` and `UseEffects.lua`. And
  **seven of the eight become runnable on a machine without the era's client**; `build-core` is the
  exception, because it also needs the TOG Tools walk SavedVariables, which no pin can substitute
  for. Verified: `build-sets.py Wrath` now reports _"no installed client and no FROZEN_BUILD entry"_
  instead of _"no installed client"_, and a pinned Vanilla rebuild is byte-identical (+22/-22,
  unchanged). Location: the eight `tools/build-*.py` above.
- **Four builders could not be pinned to a build at all** (finding 18). `build-req-levels`,
  `build-vendor-prices`, `build-hidden` and `build-rep-loot` accepted no `--wago-build`, so they
  always took whatever the default resolved to -- and that default is the **live client's build**,
  which moves. That is why the shipped dataset's odd files were odd: `ReqLevels` / `SellPrices` /
  `VendorPrices` are the outputs of exactly these builders, so they carry whatever build was current
  the day they ran while their pinnable neighbours do not. **The outliers were outliers by
  capability, not by date.** All four now take `--wago-build`, consulted first, matching the other
  twenty-one. Location: `tools/build-{req-levels,vendor-prices,hidden,rep-loot}.py`.

  This matters most in `build-hidden`, where the build feeds both the level-cap sweep and (via
  `_client_patch`) the ATT removed-with-patch cutoff -- so an unintended build changes **which items
  the library refuses to serve**. Its `or DEFAULT_BUILD` tail is deliberately left in place for now:
  removing it is a separate change, and it had to wait for the `AttributeError` fix below.
- **`_client_patch` guarded the wrong exception, and the hazard next to it was holding it shut**
  (finding 19). `except (ValueError, TypeError)` handles a malformed build _string_; the likelier
  input is a _missing_ build, and `None.split(".")` raises `AttributeError`, which was not caught.
  It could not fire only because `build-hidden.py:148`'s `or DEFAULT_BUILD` tail guarantees a value
  -- so the silent wrong-era fallback already filed as a hazard was the thing preventing an uncaught
  exception in the same function, and removing it first would have converted a quiet wrong build
  into a crash inside the builder that decides what `RankItems` will serve. `AttributeError` added,
  with the ordering constraint written where the next person will hit it. **The `999999` fallback is
  left alone deliberately and documented as what it is:** not a "don't know" sentinel but the
  **maximum** cutoff, so an unparseable build would silently hide every removed-from-game item for
  every era. Changing which items are hidden is a data decision, not a bug fix.
- **Five weight-scale keys were hardcoded in the core** (finding 10), reaching past `RULES` while
  every other per-expansion vocabulary difference already arrived through it. Each flavour now
  declares `procKeys`. Latent rather than live today, and the scenario is Wrath: it merged healing
  into spell power, so a `Scoring/Wrath.lua` keyed on `ITEM_MOD_SPELL_POWER` would have zeroed both
  the heal _and_ the caster-damage routes for a second, independent reason.
- **`Data/Mists/_core/Hidden.lua` was on disk and named by no TOC** (finding 5), so on a Mists
  client `lib.hidden` stayed empty and `RankItems` / search silently stopped filtering, over
  **13,066** items. One line in `ItemDB_Mists.toc`.

### Testing

- **`Tests/manifest_spec.lua` (new)** asserts every shipped `.lua` is named by some manifest: the
  direction `toc_spec.lua` cannot check, and the one that actually fails in practice. It
  **invokes** the shared `verify-manifest.lua` rather than reimplementing its walk, so the walk
  stays single-sourced. It deliberately does **not** test `pipe:close()`'s result -- Lua 5.1 gives
  `file:close()` no return contract, so a spec built on it would pass no matter what the tool said.
- **Around 24 specs added** across the scoring surface, lifting `LibItemDB-1.0.lua` line coverage
  from a measured **60.09%** to **70.62%**. Every fix above was mutation-checked; the `procKeys` one
  two-sided, because a refactor whose indirection resolves to the same literals is invisible to the
  existing suite.
- **`GetItemScoreBreakdown`'s "guaranteed by construction" equality with `GetItemScore` is now
  pinned by spec** (finding 4). It was two hand-matched orchestrations, and the only spec touching
  it used a flask with a single stat, so the duplicated blocks had zero coverage.
- **Line coverage reached 100.00% on every shipped file** -- `LibItemDB-1.0.lua` 1308/1308,
  `ItemDB.lua`, `Integrations.lua`, `Scoring/Vanilla.lua` and `Scoring/TBC.lua`. It was 79.02% on
  the library at the start of this pass (60.09% earlier in the entry); the suite is 346 specs.
  What the last 21% turned out to be is the point: **`GetSources`, the whole loot browser
  (`GetLootModules` / `GetLootCategories` / `GetLootSections`), `GetItemSet` / `GetSet`,
  `GetSetBonusEP`, every BiS reader, `LoadBiS`, `LoadScoreModel`, `Search`'s result assembly,
  `GetClasses` / `GetSubClasses`, `GetRandomProperties` and `lib:LoadClasses`** -- all of them
  public read APIs a consumer calls directly, none of them executed once by the suite. Two live
  defects fell straight out of writing the specs (below). Fixture traps worth knowing are written
  into the spec file at each site: the harness plays a **Horde** character; `LoadSources`'s
  `items` map uses a **comma** and its `instances` map a **colon**, and swapping them loads
  nothing and raises nothing; and a `Search` result is an array **with a `capped` field on it**,
  so an empty result is `{ capped = false }` and never `{}`.

### Bug Fixes -- stale lazy indexes

- **Two of the library's four lazy indexes were never invalidated, so a data file loading after
  anything had read one served stale answers for the rest of the session.** `LoadSources` cleared
  `_srcInstItems` (instance -> items) but not `_srcEncItems` (boss -> items), which is built from
  the very same `srcItems` table; `LoadRepLoot` cleared nothing at all, leaving `_repLootSrc`
  (item -> reward sources) frozen at whatever the first `GetSources` call built. The visible
  effect: a boss's loot list missing every item added by a later file, and reputation/battleground
  rewards absent from `GetSources` entirely. **Latent rather than live on a real client** -- a TOC
  loads every `_core` file before a consumer can query anything -- but it is live for any
  consumer doing a runtime top-up, which `LoadSources` is documented to support, and it was live
  in the test suite, which is one shared Lua state. Both now clear their index, matching what
  `LoadBiS` already did for `_bisIndex`. Mutation-checked: restoring either omission reddens
  exactly the one spec written for it and nothing else. Location: `LibItemDB-1.0.lua`
  (`LoadSources`, `LoadRepLoot`).

### Testing -- harness pin

- **`Tests/wowapi` moved from `ff379c2` (2026-08-16) to `769c043` (2026-08-19).** Every adoption
  entry in that range reads "Adopt: nothing" for a consumer in our position, with one exception:
  `verify-libs.lua` had been **reporting a false green**, counting every `SKIP` as a success and
  printing `8/8 libraries verified` having loaded nothing, and the entry says to re-run it. Run
  correctly from the **addon** root (not the harness root, which is what the superseded
  instruction said) all three verify tools are genuinely clean here: 8/8 libraries with real
  method counts, 27/27 AceGUI widgets constructed and driven, and every env reset restoring every
  global it owns. Suite green at both pins.

### Bug Fixes -- vendor prices

- **`nil` from `GetVendorBasePrice` was documented as proof that no vendor sells an item. It is
  not, and the claim contradicted the era caveat shipped alongside it.** Caught by peer review
  (`docs/AUDIT.md` round 4, finding 3). Absence conflates four conditions and only the first is
  "no vendor sells it": the gate is a Wrath/Cata `npc_vendor` dump, so an item sold **only** by a
  Vanilla- or TBC-era vendor is absent while a vendor really does sell it; absence also covers a
  `BuyPrice` of 0 and an id the version doesn't ship. A consumer building a "not sold by vendors"
  label on `nil` would have been wrong for an unknown number of Classic items, silently.

  The wording is now **"no vendor record"** everywhere. It had propagated to **five** sites, found
  by grepping the phrase rather than trusting memory: the getter's summary line and docstring, the
  `lib.vendorPrice` state comment, the README API row, the CurseForge example, and the spec's own
  **test name** — which asserted the false contract in its title, the version most likely to be
  taken as settled by the next reader. Documentation only; no behaviour changed. Location:
  `LibItemDB-1.0.lua`, `README.md`, `docs/Curseforge_Description.html`, `Tests/libitemdb_spec.lua`.

- **Why `nil` covers both "no record" and "unknown item", stated properly.** It was justified by
  caller convenience; the real reason is that `0` is unreachable by construction at two independent
  layers — `build-vendor-prices.py` requires `BuyPrice > 0`, and `LoadVendorPrices` rejects `0`,
  negatives and non-numerics — so there is no third state to represent. `GetRequiredLevel` differs
  only because its `0` is a real domain value ("no requirement"). The asymmetry is principled.

### Known Limitations

- **The shipped number is the BASE price — what a NEUTRAL player pays.** Reputation discounts
  are applied server-side at purchase. Verified rather than reasoned about: Classic Era's
  `MerchantFrame.lua:200` takes `price` straight from `GetMerchantItemInfo` and there is no
  discount arithmetic anywhere in the UI, so the client only ever receives an
  already-discounted figure and only while a merchant is open. There is no client-side table
  of discount tiers. The API is named `GetVendorBasePrice` rather than `GetVendorPrice`
  precisely so a caller notices — the failure mode is a plausible wrong number, not an error.

- **The `npc_vendor` dumps are Wrath (AzerothCore) and Cata (TrinityCore) era.** No Vanilla or
  TBC emulator dump is available, so a Vanilla build is gated on Wrath-era vendor
  inventories. Intersecting with the ids each version ships keeps out items that don't exist
  in the era, but existence is not availability: an item a Wrath vendor stocks may not have
  been vendor-sold in 1.12, and an item vendor-sold only in Vanilla is missing entirely.
  Stated here because nothing in the pipeline can detect it.

- **Coverage is 862 items (Vanilla) and 1,708 (TBC), not the 3,023 the request predicted.**
  That figure counted vendor-sold items with a `BuyPrice` across every expansion's merged
  DB2; ours additionally intersects with the ids each version actually ships, and most of the
  remainder are Wrath/Cata items a Classic client has no core row for. Serving a price for an
  item `GetInfo` returns `nil` for would be the worse outcome.

---

## [v0.6.0] (2026-08-06) - A third-party tooltip bridge (ATT / TSM / Auctionator / SmexyMats); recipe-scroll data built here and handed to LibProfessionDB

### New Features

- **`Integrations.lua` — a bridge, not a re-implementation.** One place for reading what another
  addon already knows so a consumer's own tooltip carries the same lines the player sees elsewhere:
  their wording, their formatting, their icons, passed through unmodified. A registry rather than a
  pile of functions, because the list is expected to grow — adding the next addon is a table entry.

  The rules are enforced, not aspirational: **never a hard dependency** (several of these load
  _after_ this library, so detection is at call time, never a load-time capture); **never raise**
  (these are semi-public surfaces on code nobody here controls, so every call is wrapped and a
  provider that has moved drops out while the rest still answer); **never read their data into
  ItemDB's own tables** (if a fact is worth shipping it comes from DBC like everything else); and
  **nothing is called automatically** — the consumer owns its tooltip.

  `lib:GetAvailableIntegrations()` says which are usable right now.

- **`lib:ApplyExternalTooltipHooks(tooltip, scriptType)` — the universal bridge.** Replays every
  installed addon's tooltip handlers against **your** tooltip, so it works for an addon whether or
  not it exposes any API. That is the only way to reach RecipeMaster (whole namespace is the
  addon-private vararg, with zero `_G` writes) and Leatrix Plus (no public API).

  `HookScript` composes — the frame's script becomes a function calling the previous handler then
  the new one — and `GetScript` hands that whole chain back. Every handler takes the tooltip as its
  argument and writes to that argument, so invoking the chain with a different tooltip routes all of
  them onto it. The setter (`SetItemByID` / `SetSpellByID`) is what fires the script; it fires on
  _your_ frame, which has none of their hooks because they hooked `GameTooltip`.

  **`GameTooltip` is never read, written, shown, hidden or re-owned** — a parallel fan-out rather
  than a scratchpad, so nothing flickers and there is nothing to save and restore. A spec puts a
  metatable trap on it and asserts nothing beyond `GetScript` is ever even looked up.

  Two hard requirements, both refused up front rather than left to fail inside someone else's addon:
  the tooltip must be a **named** frame inheriting `GameTooltipTemplate` (RecipeMaster's dedup reads
  `_G[tooltip:GetName().."TextLeft"..i]`), and it must be **populated before** the call.

  Verified from source rather than assumed: Blizzard sets **no** Lua `OnTooltipSetItem` /
  `OnTooltipSetSpell` handler on Classic Era — its population happens in C during the setter — so
  the replayed chain is purely addon handlers and cannot duplicate Blizzard's own lines.
  **Not yet verified in a running client**, which no offline spec can do.

- **`lib:AttachExternalRecipeInfo(tooltip, spellID)`** — attaches AllTheThings' own lines to any
  tooltip, keyed by **spell**, so it works for a recipe with no teaching item at all. Built from
  ATT's _Classic_ path (`src/Modules/Tooltip.lua:1214`, `SearchForField`) rather than its retail one
  (`:831`, `SearchForObject`) — the two hand over different search functions and only the first is
  what a Classic client runs. `AllTheThings` is `## OptionalDeps` in all five TOCs and never a hard
  dependency; every hop is feature-detected, the call is wrapped, and it returns false in every
  failure mode without raising.

  `AttachTooltipSearchResults` returns nothing (`Tooltip.lua:789-812`), so "did anything attach" is
  measured as a `NumLines` delta — `true` means lines actually landed, which is what a caller needs
  to decide whether to add its own "no data" line. The spell-keyed lookup is sound by construction:
  `src/Cache.lua:895-898` shows `fieldConverters.recipeID` also calls `cacheSpellID`, so every ATT
  recipe row is dual-indexed under `spellID`.

  ItemDB reads **no data** from ATT and must not start. If ATT has a fact this suite needs, it gets
  sourced from DBC like everything else.

- **`Integrations.lua` — one place for third-party addon bridges**, as a registry rather than a pile
  of functions, since the list is expected to grow. `lib:GetAvailableIntegrations()` says which are
  usable right now (resolved at call time — several of these load after this library);
  `lib:GetExternalPrices(itemLink)` returns each price addon's own numbers, in copper, unmodified,
  so a consumer's tooltip can show the figure the player already sees elsewhere.

  **TradeSkillMaster** and **Auctionator** (Auction / Vendor / Disenchant) are **value-fetch only** —
  neither can draw into a tooltip, so the consumer renders them. Both raise on bad arguments in real
  use, so every call is wrapped; a missing, misconfigured or moved provider drops out and the others
  still answer.

- **TSM prices are enumerated, not hard-coded.** An earlier cut asked TSM for three sources it had
  been told about by name. It now asks `TSM_API.GetPriceSourceKeys()` what this install actually
  registers, and pairs each key with TSM's own localized label from `GetPriceSourceDescription`, so
  a line reads as it does in TSM's own tooltip and in the player's language. A source the player has
  from a TSM module we have never heard of, or one TSM adds in a later build, appears with no change
  here.

  Counted against the installed client rather than estimated: **41** sources across `RegisterSource`
  calls — AuctionDB 9, Accounting 9, External 8, Item 7, Operations 5, Crafting 3.

  **Whether a number is money is an allow-list, not a guess.** `DBRegionSaleRate` (`0.038`) and
  `DBRegionSoldPerDay` (`0.076`) are not copper, and money-formatting them renders `0c` — silently
  wrong, in exactly the place a player would trust it. So would `ItemLevel`, `MaxStack`,
  `NumInventory`, `ItemQuality`, `RequiredLevel`, `NumExpires` and `SaleRate`. Those nine are the
  complete non-money set; the other **32** get `TSM_API.FormatMoneyString` and everything else is
  handed back raw with `isMoney` nil. The split was verified exhaustive against this TSM build —
  32 + 9 = 41, no key unaccounted for.

  It also fails **safe** in the direction that matters: an unrecognised key — a TSM module added
  later — renders as its plain value rather than as fabricated gold.

  Recorded as a closed finding rather than a request, because **we do not own TSM and cannot change
  it**: TSM does hook `GameTooltip`, but its handler returns immediately unless the tooltip is in its
  own `private.tooltipRegistry` (`Tooltip/TooltipWrapper.lua:113`). That is correct of them, and it
  means TSM is the one bridge here whose _rendering_ cannot be replayed — only its values.

- **`lib:GetExternalMaterialInfo(itemID, itemLink)` — SmexyMats' reagent data.** Which professions
  _use_ a material (`SmexyMats.Reagents`) and where it _comes from_ (`Sources` + `Vendor`), plus the
  expansion. A separate call from prices because it answers a different question.

  **The strings pass through unmodified, markup included** — SmexyMats embeds profession icons as
  `|T…|t` when the user has icons enabled and plain names when they do not, read from its own
  `SmexyMatsDB.profile`. Reproducing what that player already sees is the entire point, so nothing
  here strips or re-cases them. An item that is not a material returns nil rather than empty
  strings, so a consumer has one check instead of two.

- **Deliberately NOT bridged: RecipeMaster** — and it does not need to be. It hooks `GameTooltip`'s
  `OnTooltipSetItem` _and_ `OnTooltipSetSpell`, plus `ItemRefTooltip`
  (`Source/Handlers/TooltipHandler.lua:165,176,187`), so a consumer using `GameTooltip` with
  `SetItemByID` / `SetSpellByID` gets it automatically in its own styling — and the
  `OnTooltipSetSpell` hook is what covers a trainer-taught recipe with no scroll item at all.

  **What decides bridgeability is the namespace, not the tooltip**, which is worth recording because
  getting that backwards cost a wrong call here first: SmexyMats is
  `LibStub("AceAddon-3.0"):NewAddon("SmexyMats", …)`, a real global, so its data functions are
  reachable; RecipeMaster is `local addonName, rm = ...` with **zero `_G` writes anywhere in its
  source**, so nothing is. Same tooltip mechanism, opposite reachability.

  Two assumptions checked and corrected while investigating: TSM's tooltip does **not** come from
  `TradeSkillMaster_AppHelper` (28 lines, no tooltip code — it is the app's auction data), and
  vendor price needs **no** addon, since `GetItemInfo` returns `sellPrice` natively.

### Architecture — recipe-scroll data went to LibProfessionDB before release

The recipe→teaching-item work raised by TOGProfessionMaster was **developed in ItemDB and moved to
`LibProfessionDB-1.0` (its MINOR 8) before either shipped**, so no released version of ItemDB ever
carried it and no consumer had to migrate. It is keyed by craft spell id, which is how that library
already keys recipes, and a recipe tooltip is recipe-shaped rather than item-shaped: recipes
reference items, items never reference recipes, so `ProfessionDB → ItemDB` is the safe direction.

`LibItemDB-1.0` is at **MINOR 20**; `GetLink` / `GetName` are unchanged and are what a consumer
calls on the id ProfessionDB returns.

The findings are recorded here because they outlive the code that moved:

- **The mapping is a DBC join, not a name match.** `ItemEffect` alone does not answer it — most
  scrolls teach via a generic intermediary "Learning" spell, so the missing hop is
  `SpellEffect[SpellID, Effect = 36].EffectTriggerSpell`. Measured against the English-prefix
  matcher it replaced: the matcher found **zero** links the join misses, the join found **35** the
  matcher missed, and the join is locale-independent where the prefix list was English-only.
  TOGProfessionMaster has since retired that matcher at source.
- **`ItemSparse.Description` is the wrong field for a scroll's `Use:` line** — populated for 60 of
  1,073 real Vanilla scrolls, against the teaching spell's `Spell.Description_lang` at 1,022.
- **TBC has no per-recipe teaching spell at all**, so no `Use:` sentence exists to derive there:
  `ItemEffect` carries the generic spell 483 "Learning" (empty description) plus the craft spell.
- **`requiredSkill` was wrong and is now dropped, not fixed.** It read
  `SkillLineAbility.MinSkillLineRank`, a floor that defaults to 1, so _Smelt Truesilver_ rendered as
  "Requires Mining (1)" against a real requirement of 230 — found in game rather than offline.
  ProfessionDB carries the correct value on the recipe itself, so a second copy could only drift.
- **Deleting the source needs the destination verified first.** ProfessionDB's hand-over listed
  `AttachExternalRecipeInfo` as moved and it had not been — no such function, no `AllTheThings`
  reference, no `OptionalDeps` anywhere in that repo. It stays here until that library actually has
  it. ItemDB's copies were untracked in git, so a delete-on-trust would have had no history to
  recover from.

### Testing

- **TOC sweep across all five manifests, and `ItemDB_BCC.toc` is now `ItemDB_TBC.toc`.** The Title
  already read "TBC"; only the filename disagreed.

  **Settled from Blizzard's own source rather than from popularity**, which is how it should have
  been settled the first time: `F:\Blizzard API Docs` ships four flavour trees, and Blizzard's own
  addons use **`_TBC.toc`** in all of them — 11-12 of them per Classic tree — with **not a single
  `_BCC.toc` anywhere in any tree**. `_BCC` is an addon-community convention (from "Burning Crusade
  Classic") that the client also accepts, which is exactly why it spreads. Renamed with `git mv` so
  history follows; `Tests/libitemdb_spec.lua`, `Scoring/TBC.lua`, `CLAUDE.md` and the replication
  script's comment moved with it. References inside released CHANGELOG entries, `docs/TBC-Parity.md`
  and `docs/DEPENDENCY_CONTRACTS.md` were deliberately left alone — they are historical or
  append-only, and record what the file was called at the time.

  `CLAUDE.md` also carried three **stale Interface numbers** (11508/20505/50503 against the real
  11509/20506/50504), which is worse than a wrong filename: it is the reference a future session
  trusts when bumping a TOC.

- **New `Tests/toc_spec.lua` — the manifests had no coverage of any kind.** Nothing else in the
  suite reads a TOC, so a file missing from one, or one naming a file that no longer exists, tested
  perfectly green until a client loaded it. Twelve assertions: every listed file exists on disk; no
  Mainline manifest exists (deliberate — the captures do not cover Retail); the core block loads
  `LibStub` → library → `Integrations.lua` in that order in **every** flavour, because
  `Integrations.lua` resolves the library at file scope and returns early if it is not registered
  yet, which would silently take every bridge with it; exactly one `Scoring/` file per flavour and
  only where rules exist; the four bridged addons declared `OptionalDeps` and **never** as hard
  dependencies; Interface numbers per flavour; `Notes`/`Author`/`Category`/project-id identical
  across manifests; `ItemDB-v1.1.4` never hardcoded; and no empty directive.

  Writing it caught a real structural fact I had wrong twice: `ItemDB.lua` loads **before** the
  data files, not last, and that is correct — the bootstrap only wires a `PLAYER_LOGIN` handler and
  never reads the database at load. The invariant that matters is that the core is a contiguous
  prefix ahead of all `Data\` files, since every data file calls into the library as it loads. Wrath
  and Cata ship **no data at all** and are now flagged `placeholder` explicitly, so a flavour that
  ever _loses_ its data fails loudly instead of quietly reading as "not captured yet".

- **Release docs corrected and completed.** `docs/Curseforge_Description.html` listed the bridge as
  AllTheThings / TSM / Auctionator / SmexyMats and **omitted Recipe Master and Leatrix Plus** — the
  two the universal fan-out exists for, since neither exposes anything to call. That contradicted
  `README.md`, which had them right. Verified before syncing rather than trusting either doc:
  Leatrix Plus does `GameTooltip:HookScript("OnTooltipSetItem", ShowSellPrice)`
  (`Leatrix_Plus.lua:8502`), so the fan-out genuinely reaches it. Both the feature list and the
  v0.6.0 entry now name all six and explain the replay-what-they-already-do model in player terms.

  `README.md` gained a **Testing** section — how to run the suite, the no-`busted`/no-CI rules, how
  to read the coverage number (including that a guard counts as covered once its condition is
  evaluated, so 100% is a floor rather than proof), and the three standing append-only files.
  Both READMEs now also record that the four bridged addons are `## OptionalDeps` in every TOC,
  present only so the client loads them first, never as a requirement.

- **`ItemDB.lua` had never been loaded offline — 0 of 13 lines.** `Tests/itemdb_spec.lua` is new and
  takes it to **13/13 (100%)**. It is only a bootstrap, but it decides the identity this addon
  reports to the guild and it feature-tests a client API, which is the shape that fails silently
  rather than loudly. Twelve tests pin: the version is read through **`C_AddOns.GetAddOnMetadata`**
  with the bare global staged **absent** (verified in the Classic Era tree — 0 bare call sites
  against 5 namespaced, declared in `AddOnsDocumentation.lua`), so reaching for the deprecated name
  fails the suite rather than passing quietly; metadata is looked up under the folder name
  `ItemDB` while the reported identity is deliberately `LibItemDB`, which is the pair most likely
  to be "corrected" into a bug later; the `"dev"` fallback for an unpackaged working copy where
  `ItemDB-v1.1.4` was never substituted; `UnregisterAllEvents` being the _only_ thing that stops
  a second run; the silent flag on the `LibStub` lookup; and no raise when VersionCheck is missing,
  present-without-`Enable`, or when LibStub itself is absent.

  The lookup happening at **login** rather than file scope is pinned too — that is what lets
  VersionCheck load after this addon without the check going dark.

Suite **141 passed, 0 failed**, with `Integrations.lua` at **158/158 executable lines (100%)** —
measured with `Tests/wowapi/coverage.lua`, not asserted. **40 of the 129 cover the bridge**: 8 on
`AttachExternalRecipeInfo`, 14 on the price providers, 8 on the universal fan-out, 8 on
`GetExternalMaterialInfo`, plus the TOC and `GameTooltip`-safety guards.

The failure modes are what they are built around, since every one of these calls a surface nobody
here controls: the provider is absent, the provider has moved, the provider **raises** (TSM and
Auctionator both validate arguments by throwing), the provider returns 0 or a negative, and — for
the fan-out — a handler raising midway must not discard the lines an earlier one already added. One
spec puts a metatable trap on `GameTooltip` and asserts nothing beyond `GetScript` is ever looked up.

**What these tests cannot do is confirm any of it works in game.** They drive our own stubs of the
five addons, shaped by reading their source, so a misreading is ratified rather than caught — and
this session misread both SmexyMats and TSM before correcting. Live verification is
`docs/DEPENDENCY_CONTRACTS.md` §9, still open with TOGProfessionMaster.

Adopted **`docs/AUDIT.md`**, the harness's peer-review protocol — the inverse of a contract: a
contract is raised here and answered by the harness, an audit finding is raised by a review session
and answered by us. The first cut was built against the older docs and got two rules wrong,
corrected on the harness's own notice: it had a `## Fixed` section, which means a resolved finding
gets **moved** — a slower form of deleting it, when the value is the failure scenario sitting next to
the code it describes. Findings now stay in place and state lives only in the **Status table**.

Earlier in this cycle the `Tests/wowapi` pin moved from `4161af8` (2026-07-19) to `3206e75` (and now
`f2b0114`), which surfaced three real gaps in the shared env — all raised and fixed upstream:

- **`strsplit` dropped a trailing empty field.** Empty _middle_ fields were already correct, which
  is why it survived inspection. In a packed `field<US>field<US>…` record a dropped trailing empty
  changes the field _count_ without changing anything visible. This spec file's local copy was
  hiding it; deleting the copy proved our decode never depended on it.
- **`GetItemQualityColor` / `GetItemClassInfo` / `GetItemSubClassInfo` did not exist in the env.**
  The library captures all three into file-scope locals at load, so a consumer not staging its own
  took nil copies permanently. Our spec had been staging its own — which is exactly what stopped the
  gap being noticed.
- One assertion changed as a result: plate head armour now checks `GetItemType` against the real
  subclass name `"Plate"` rather than the `"Sub4.4"` a local stub had fabricated.

---

## [v0.5.0] (2026-08-03) - TBC scoring modules, Outland loot + the Classic raids, Era item availability, required level, enchants & gems

### Architecture

- **Scoring is now per-expansion: one core + `Scoring/<Version>.lua` rules modules.** The library was a
  single 2,257-line file with **no version branching whatsoever** — one engine that encoded Vanilla's
  mechanics because Vanilla was all that existed. Enriching TBC would have meant editing that shared
  engine, and the two expansions genuinely disagree about what a stat _is_: surveyed from the shipped
  `_core` data, Vanilla carries `CRIT_PCT` / `HIT_PCT` / `DODGE_PCT` / `DEFENSE` / `WEAPON_SKILL_*` and
  **no** ratings; TBC carries **14 `ITEM_MOD_*_RATING` keys across 6,000+ items**, 2,687 items with
  `EMPTY_SOCKET_*`, and **no** flat percentages or weapon skill. Adding TBC's keys to the shared
  `WEIGHT_STATS` would have given every _Vanilla_ weight editor haste / expertise / resilience sliders
  that can never do anything.
  The split is governed by one policeable rule: **the core contains no game mechanics, only mechanism.**
  The stat walk, weight lookup, `parts` accumulation, set/use/proc plumbing and the whole public API stay
  in `LibItemDB-1.0.lua` (fixed once, every expansion benefits); key aliasing, `weightStats`, labels, the
  per-hand DPS map, derived-stat conversions, AP max-pairing, extra scorers and model tuning move to
  `Scoring/Vanilla.lua` and `Scoring/TBC.lua`. Each TOC loads exactly one, so a Vanilla client never has
  TBC's rules in memory and **enriching one expansion cannot regress another**. New API:
  `lib:RegisterScoring(rules)` (called by the module), `lib:GetScoringVersion()`, `lib:HasScoring()`.
  A flavour with no module yet (Wrath / Cata) registers nothing and every scoring API returns `nil` —
  the existing documented degradation. Adding an expansion is adding a file, never branching the core.
  The Vanilla extraction was done as a **pure refactor**: all 57 pre-existing specs passed unchanged,
  including the exact EP values, before any TBC work began. Location: `LibItemDB-1.0.lua` (rules
  contract + `RULES` seam), `Scoring/Vanilla.lua`, `Scoring/TBC.lua`, both TOCs.

- **`Scoring/TBC.lua`** — combat ratings (a TBC scale is priced per rating point, so gear ratings need no
  conversion); the flat percentages that still reach us from on-equip spell auras fold onto the matching
  rating via `derived` (1% crit = 22.076923 crit rating, etc.); attack-type-specific crit/hit/haste
  ratings fold onto the generic keys (without which the 393 items carrying `ITEM_MOD_CRIT_MELEE_RATING`
  and 393 carrying `ITEM_MOD_CRIT_RANGED_RATING` would each score 0); flat HP/mana pools as in Vanilla;
  **no** weapon-skill or ammo scorer, because an expansion not having a mechanic is expressed by
  registering no scorer for it. Every conversion constant is **sourced, not recalled** — WoWSims TBC
  (MIT) `sim/core/base_stats_auto_gen.go`, which is generated from game data, plus
  `ResilienceRatingPerCritReductionChance = 39.4231` from `sim/core/constants.go`; they are level-70
  values, quoted in the file.

### New Features

- **TBC drop sources are real Outland content.** 1,606 items across **26 instances** / 120 bosses:
  Karazhan (15 bosses, 175 items), Black Temple, Sunwell Plateau, Serpentshrine Cavern, Tempest Keep,
  Zul'Aman, Hyjal Summit, Gruul's Lair, Magtheridon's Lair, all 15 Outland 5-mans and World Bosses BC.
- **Seven new TBC data tables**, all from the version-parameterized DB2 builders: `EquipStats` (1,172),
  `Classes` (3,644 class-restricted), `Factions` (133), `Sets` (309 sets / 712 bonus thresholds / 34
  scored procs), `UseEffects` (61 on-use, 221 proc), `SpellSchools` (270), `Mounts` (230).
- **`GetWeightStats()` is now per-expansion** — TBC returns the 14 rating keys with no weapon-skill or
  flat-percentage entries; Vanilla is unchanged. A consumer must build a weight editor from this call,
  never from a hardcoded list.

- **TBC EP stat weights — gear scoring, item ranking and per-raid BiS now work on TBC.** 37 specs across
  9 classes (`Data/TBC/_core/BiSWeights.lua`), plus the per-class scoring model
  (`Data/TBC/_core/ScoreModel.lua`). The source turned out to be the one the builder already downloaded:
  HawsJon's Pawn scale serves **Classic and Burning Crusade from a single branch**, and its own comment
  says the weights "were originally designed for Burning Crusade" — Classic Era is the special case,
  where each rating weight is pre-multiplied into per-1% units (`HitRatingPer = 9.37931`, …) because that
  client has no rating system. On TBC every multiplier is 1 and the weights stay per **rating point**,
  which is exactly what TBC items carry. `build-bis-weights.py` now picks both the multipliers and the
  stat map by version: `STAT_MAP_VANILLA` targets the flat-percentage keys, `STAT_MAP_TBC` the
  `ITEM_MOD_*_RATING` keys plus expertise / haste / resilience (no Vanilla equivalent) and direct
  `Health` / `Mana` weights. Getting either half wrong fails **silently** — Classic's multipliers would
  inflate every TBC rating weight ~9×, and Classic's keys would give a scale with zero overlap against
  TBC items, scoring everything 0 — so the version drives both. Cross-checked on warrior/fury: the
  Vanilla/TBC ratio is 9.37895 for hit (vs `HitRatingPer` 9.37931) and exactly 8.5 for crit (vs
  `CritRatingPer` 8.5), while non-rating stats are identical. Vanilla's output re-verified byte-identical.
  Location: `tools/build-bis-weights.py`, `Data/TBC/_core/{BiSWeights,ScoreModel}.lua`, `ItemDB_BCC.toc`.

- **`lib:HasBiSWeights()`** — EP weights and fixed BiS gear lists are **separate datasets**, and TBC now
  has the first without the second. `HasBiS()` only ever tested the fixed lists, so a consumer gating EP
  on it (as the first consumer does) would show **no scores at all on TBC** while the weights sat loaded
  — a silent failure caught by scoring a real TBC item end to end. `HasBiSWeights()` is the gate for
  `GetItemScore` / `ScoreStats` / `RankItems` / `GetSlotRanking` / `GetRaidBiS`; `HasBiS()` remains
  correct for `GetBiS` / `IsBiS` / `GetBiSPhases`. Location: `LibItemDB-1.0.lua`, `README.md`.

- **Fixed BiS gear lists, talents, talent effects, aura buffs and reputation loot for TBC.**
  91 BiS sets across 8 classes; 579 talents / 9 classes with 62 carrying stat effects; 140 buff
  auras; 534 reputation reward items across 20 factions. Talents and aura buffs needed no work at
  all — both builders are wago DB2-driven and version-parameterized, and had been listed as
  Vanilla-only on the assumption their sources were Vanilla-specific. `build-rep-loot.py` was
  reading whichever AtlasLoot copy happened to be **installed** (always the vanilla tables) and
  now fetches the per-expansion file, the same fix as `build-sources.py`; Vanilla still prefers an
  installed copy so its output stays bit-identical offline.
  `build-bis.py` needed three fixes, each resolved from the source rather than assumed:
  the tbc-new path nests one level deeper (`ui/<class>/<spec>/gear_sets/`); its spec folders
  (`dps`, `feralcat`, `feralbear`) don't match HawsJon's tokens, so spec resolution now goes
  folder map → filename (`p1_arms` / `p1_fury` / `p2Arcane` / `destro_fire_t4` disambiguate more
  than expected) → fan-out across the class's DPS specs, with **healer/tank roles derived from
  the shipped weights** rather than hardcoded (healing weight dominating spell damage = healer;
  avoidance well above the ~0.05 baseline = tank), so `priest/dps` lands on `shadow` alone and
  `rogue/dps` on its three DPS specs; and warlock names its sets by content tier (`t4`/`t5`/`t6`/
  `za`/`swp`) so `parse_phase` found no number and dropped all of them — phases now fall back to
  the progression order `presets.ts` declares, which is the source's own ordering rather than an
  outside claim about which TBC tier is which phase. Hunter has no `gear_sets` in tbc-new at all,
  so it has no TBC BiS lists — a source gap, not a build failure. Location:
  `tools/build-bis.py`, `tools/build-rep-loot.py`, `Data/TBC/_core/{BiS,Talents,TalentEffects,
  AuraBuffs,RepLoot}.lua`, `ItemDB_BCC.toc`.

- **TBC gem sockets are now scored, and TBC PvP rewards are in.** An empty socket is priced at the
  **best gem that fits it under the weights the item is being scored with** — spec-dependent by
  construction, so computed at score time rather than baked into data. New `tools/build-gems.py`
  extracts the gem facts from Pawn's `GemsBurningCrusade.lua` (CC BY-NC, credited) into
  `Data/TBC/_core/Gems.lua` (132 gems; colours R/Y/B, M for meta), and `Scoring/TBC.lua` does the
  pricing with a per-weight-table cache so ranking thousands of items doesn't rescan the gem list.
  A meta socket takes only meta gems; a prismatic takes any colour. Socket BONUSES are
  deliberately not modelled — chasing one means choosing off-colour gems, a gearing decision
  rather than an item fact — so socket value is an upper bound, stated rather than hidden. New
  API: `lib:LoadGems`, `lib:GetGem`, `lib:GetGems`.
  PvP rewards: 584 items across 7 sources (Honor, Arena Seasons 1–4, Outland zones). Location:
  `tools/build-gems.py`, `LibItemDB-1.0.lua`, `Scoring/TBC.lua`, `Data/TBC/_core/Gems.lua`.

- **TBC item locations (13,226) and consumable exclusion groups (105) — the last two gaps.** Both
  had been written off as "blocked on external provisioning". They weren't: the pipeline already
  had a downloader, it was just hardcoded to the classic DB. `build-proc-rates.py` pulls
  `cmangos/classic-db`'s `latest` release asset, and `cmangos/tbc-db` publishes the same asset
  shape (`tbc-sqlite-db.zip`, 100 MB → a 298 MB SQLite). It is version-aware now (`CMANGOS`), and
  `build-item-sources.py` reads the matching DB. TBC locations: crafted 2,531 / drop 4,369 /
  pvp 303 / quest 3,262 / reputation 707 / vendor 3,430 — more than Vanilla's 8,593.
  **Consumable groups** needed a different answer again: the battle/guardian elixir split is in
  neither the client DB2 nor `spell_template` (Elixir of Major Agility and Elixir of Major
  Fortitude have byte-identical spell rows). CMaNGOS keeps it in its own **`spell_elixir`** table,
  with the masks `SpellMgr.h` defines — `0x01` battle, `0x02` guardian, `0x03` flask, `0x10`
  well-fed. Cross-checked against wowsims' preset consumes: **9 of 9 agree, 0 mismatches.**
  105 groups (battle-elixir 37, guardian-elixir 41, flask 27). Location:
  `tools/build-proc-rates.py`, `tools/build-item-sources.py`, `tools/build-consumable-groups.py`,
  `Data/TBC/_core/{ItemLocations,ConsumableGroups}.lua`, `ItemDB_BCC.toc`.

- **Each instance now says which expansion its content belongs to (MINOR 16).** `GetInstances()`
  entries gained `expansion` (`"Vanilla"` / `"TBC"` / …) — the expansion the **content** belongs to,
  not the client serving it, so a TBC client returns Karazhan `"TBC"` and Molten Core `"Vanilla"`
  side by side. Requested as Dibs' `DIBSREQ-IDB-001`: it groups a planner's source filter with the
  current expansion's raids at the top level and older still-runnable content nested under
  "Classic Raids" / "Classic Dungeons", and could not derive the split — the instance keys and item
  ids look identical either way. Strictly the data half of the cumulative-sources fix below: that
  put the level-60 raids back on TBC, and without a tag they just list flat.
  `LoadSources(source, items, instances, expansions)` takes the map as a **trailing optional 4th**
  argument, so an older library ignores it and a three-argument data file still loads (both pinned
  by specs). `expansion` is `nil` where the shipped data predates the tag, and a consumer should
  read absent as "current expansion" — which is the flat behaviour it had before, so this degrades
  rather than breaking. The builder gets the tag for free now that the AtlasLoot files are read
  cumulatively: the file an instance came from _is_ its expansion, first file winning so an
  instance extended later still belongs to the one that introduced it. TBC tags 26 TBC + 33
  Vanilla across its 59 instances; Vanilla tags all 33 Vanilla.
  Location: `LibItemDB-1.0.lua` (`LoadSources`, `GetInstances`, `srcInstExp`),
  `tools/build-sources.py` (`FILE_EXPANSION`).

- **Rebuilt item strings can carry an enchant, and TBC's four gems (MINOR 15).** `itemString()`
  hardcoded fields 2–6 empty (`"item:%d::::::%d"`), so a rebuilt link kept the item and its random
  suffix and **silently dropped the enchant** — an addon that stores a full link and reconstructs it
  later rendered the item unenchanted, with nothing to notice. Raised as TOGBankClassic's
  `LIBREQ-IDB-003`, where it would have been a straight regression against what that addon stores
  today. `LIBREQ-IDB-004` (gems, fields 3–6) is the same function and is now worth doing, since
  v0.5.0 ships the TBC data set — so both are closed together.
  `BuildItemString` and `GetSuffixLink` take `(itemID, propID, enchantID, gem1, gem2, gem3, gem4)`;
  everything past `propID` is optional and **trailing**, so existing two-argument calls are
  byte-identical (pinned by a spec). `0` and `nil` both mean absent, and an id with nothing else
  still collapses to the bare `"item:<id>"`. Layout after the id is
  `enchant:gem1:gem2:gem3:gem4:suffix` — `BuildItemString(10132, 863, 2504)` →
  `"item:10132:2504:::::863"`, TOGBank's stated acceptance case, which is asserted verbatim.
  Location: `LibItemDB-1.0.lua` (`itemString`, `buildSuffixLink`, `BuildItemString`, `GetSuffixLink`).

- **Required player level — `lib:GetRequiredLevel(id)`, and `GetInfo`'s 7th return (MINOR 14).**
  The DB carried item level but not **required** level, so a consumer sorting a bank or bag by
  "level" — which almost always means the level you must be to equip the thing, not its item level — had
  to fall back to `GetItemInfo` and keep cold-cache retry loops. The two genuinely differ:
  Thunderfury is item level 80, required level 60. Requested as TOGBankClassic's `LIBREQ-IDB-002`,
  where sorting on item level by mistake was the original bug.
  **Contract:** `0` for an item with no requirement, `nil` for an id the DB doesn't have — so "no
  requirement" and "no data" stay distinguishable, per the return-`nil`-never-a-wrong-value rule.
  `GetInfo` gained `requiredLevel` as a **trailing** 7th return and `ResolveSuffix` a
  `requiredLevel` field; both are additive, so existing callers are untouched.
  Shipped as its own item-keyed table (`_core/ReqLevels.lua`, `lib:LoadRequiredLevels`) rather than
  a 7th field on the core row — the core is generated from a client walk, and regenerating 17k stat
  rows to add one wago-sourced column would risk silently re-deriving every stat from whatever walk
  is on disk. Same shape as Factions / Mounts / SpellSchools. Only items that _have_ a requirement
  are emitted: Vanilla 15,652 of 24,127, TBC 18,279 of 30,032.
  Location: `tools/build-req-levels.py`, `LibItemDB-1.0.lua`, `ItemDB.toc`, `ItemDB_BCC.toc`.

### Bug Fixes

- **The dev replication watcher was copying the whole repo into live installs (dev tooling, not
  shipped).** `wow-version-replication.ps1` mirrors the source tree into the other installed WoW
  flavours and is supposed to reproduce what the BigWigs packager puts in the zip. A dry run showed
  **972 files copying and 7 skipped**: `docs/`, `tools/`, `Tests/`, `.github/`, `.vscode/` and five
  dotfiles were all being replicated. Two defects, both in how it mirrors `.pkgmeta`:
  1. **A bare folder name matched nothing.** `release.sh`'s `parse_ignore()` rewrites a directory
     entry to `<dir>/*`, but the glob-to-regex step compiled `docs` to `^docs$` — which matches only
     a _file_ literally named `docs`. The folder was listed in `.pkgmeta`, reported as loaded at
     startup, and copied anyway. Bare wildcard-free entries now resolve against the repo and a
     directory becomes a prefix match.
  2. **Dotfiles were enumerated instead of pruned as a class.** The packager prunes them
     unconditionally (`copy_directory_tree`: `-name ".*" -prune`), so a dot entry in `.pkgmeta` is a
     no-op and they are deliberately absent from it — meaning the script cannot learn them from
     there and must mirror the prune itself. It listed `.git`/`.gitignore`/`.gitattributes`/
     `.gitmodules` individually and missed every other one. Now a single rule covers any path
     component beginning with a dot.
  Now **414 copy / 286 skip**, zero folder leaks, zero dotfiles. Caught by `-DryRun` before the
  watcher ran; the same two defects are likely present in other addons' copies of this script.
  Location: `wow-version-replication.ps1`.

- **TBC's drop graph had no level-60 content at all — every Classic raid and dungeon was missing.**
  `Data/TBC/_core/Sources.lua` shipped only the 26 Outland instances, so on a TBC client nothing
  from the base game had a source: Molten Core, Blackwing Lair, AQ40/AQ20, Onyxia, Zul'Gurub and
  Naxxramas 40 were absent from `GetInstances()` entirely, and their items reported no drop source.
  Those raids still exist and are still runnable in 2.5.x — outclassed at 70, but farmed for mounts,
  transmog and old-content clears — so their gear belongs in the TBC graph.
  **This is a defect I introduced while fixing the opposite one, and it has now been wrong in both
  directions.** `build-sources.py` originally read AtlasLoot's vanilla `data.lua` for _every_
  version, which shipped the Classic instance list as TBC's drop graph with no Outland content at
  all (2,240 vanilla drops survived the core filter, so the output looked populated). Correcting
  that by reading _only_ `data-tbc.lua` for TBC removed every level-60 raid instead. Both
  single-file answers are wrong: the files are **cumulative**, because old content does not
  disappear.
  `ATLAS_FILE` (one file) is now `ATLAS_FILES` (a list per version, oldest first) — Vanilla reads
  `data.lua`, TBC reads `data.lua` + `data-tbc.lua`, Wrath adds `data-wrath.lua` — and instance
  keys repeated across files accumulate their encounters instead of the later file replacing the
  earlier. Safe by construction: the existing per-item guard keeps only ids present in
  `Data/<Version>/_core`, so a version can never carry drops for items its client doesn't ship.
  TBC goes from **26 instances / 428 items** to **59 instances, 3,846 items, 428 bosses**; Vanilla
  output is byte-identical (verified — 0 files changed). Location: `tools/build-sources.py`,
  `Data/TBC/_core/{Sources,SourceNames}.lua`.

- **Era-available items above the seasonal threshold were unreachable on Era.** The `_seasonal`
  split partitioned on item ID alone (`>= 25000` → overlay, guarded by `lib:IsSeasonalRealm()`),
  which conflates _"high item ID"_ with _"seasonal realm"_. Items added to Classic **Era** itself sit
  above that line too, so they were shipped into the SoD/Anniversary overlay and never loaded on Era:
  **Chronoboon Displacer (184937)** and its Supercharged form, the Love-is-in-the-Air / Midsummer
  event items (190179–190309), and Tabard of Mastery (191481) — 11 items in all. Reported against
  TOGBankClassic's `LIBREQ-IDB-001`, where Chronoboon is a constant guild-bank resident.
  The client DB2 carries no flag separating an Era addition from a SoD one, so the split now takes
  that fact from **AllTheThings**, which curates `db/Vanilla` and `db/VanillaSOD` as separate trees —
  the same source `build-hidden.py` already uses for never-implemented / removed-with-patch.
  `att_extract.lua` gained an `era <itemID>` output (item constructors **plus** `providers`/`cost`
  references, since 8 of the 11 appear only as a quest's provider and never get an item node);
  `itemdb_common.att_era_ids()` wraps it; `split-seasonal.py` keeps an at/above-threshold item in
  base when ATT places it in the era's tree. ATT coverage is partial by design (71.9% of the base
  set), so membership only ever **keeps** an item — never pushes one into the overlay — and an
  absent ATT install degrades to the previous threshold-only behaviour. Validated against the whole
  6,481-item SoD block: **zero** false positives. Era now holds 17,604 items (was 17,593), and the
  duplicate-reissue bug the split exists to prevent is untouched (`228291` still absent on Era).
  Location: `tools/att_extract.lua`, `tools/itemdb_common.py`, `tools/split-seasonal.py`.

- **`split-seasonal.py` could not undo itself, and would have corrupted three files.** Three defects,
  all found while fixing the above and all latent for any future re-run:
  1. **One-way.** It read only the base file and wrote both sides, so once an item was in the overlay
     no rule change could bring it back short of regenerating from wago. It now re-partitions the
     **union** of base + overlay and is idempotent (a second run reports zero and writes nothing).
  2. **Spell-keyed files were being split by item ID.** `AuraBuffs.lua` is keyed by **spellID**, and
     Vanilla buff ranks live at 25289–27841 — above the threshold. A re-run would have moved 8 raid/
     world buffs into the SoD overlay, deleting them from Era. `Talents`/`TalentEffects`/`ScoreModel`
     (`[classID]`) and `RepLoot` (`[sourceName]`) have the same hazard. All are now skipped, verified
     against each file's `lib:Load*` signature rather than assumed.
  3. **Multi-table files collapsed.** `Effects.lua` holds `LoadEffects` **and** `LoadConsumableTypes`
     keyed by the same ids (`UseEffects.lua` has three tables); a file-wide `{id: line}` map kept only
     the last, halving the file — and an id-set check cannot see it because the ids are identical.
     Partitioning is now per table **block**, matched across the two sides by the opening `lib:Load*`
     call rather than by position, since `Effects.lua` gained its second table after its overlay was
     generated. This also fixed 92 seasonal consumable-type rows that had drifted into base and were
     being served on Era. The rebuild aborts without writing if a partition would lose an entry or if
     the overlay carries a table the base lacks.
  Location: `tools/split-seasonal.py`.

- **TBC data was built with VANILLA proc rates.** `build-use-effects.py` and `build-sets.py` both
  hardcoded the vanilla proc-rate file / sqlite, so every TBC trinket and set proc built earlier
  in this release was priced with vanilla tuning — a quiet wrong-era result, only visible once the
  TBC world DB existed to compare against. Both are version-scoped now and TBC was rebuilt: 305
  TBC proc rates (vs the 232 vanilla ones it had been using), giving 235 scored procs instead of
  221, and 60 set-proc rates instead of 42. Vanilla output verified unchanged. Location:
  `tools/build-use-effects.py`, `tools/build-sets.py`.

- **TBC PvP rewards parsed to ZERO and the whole `pvp` loot module was missing.** TBC PvP isn't
  organised by reputation standing at all — it groups by Honor / Arena season / open-world zone,
  with sub-blocks named "Sets", "Weapons", …, and the class-set rows carry **ItemSet IDs**
  (`TableType = SET_ITTYPE`) rather than item IDs. The parser required a standing label before it
  would accept any row, so every TBC PvP row was discarded. It now recognises that shape and
  expands set IDs via the DB2 `ItemSet` table. Critically the shape is chosen **once per file**
  (on whether the file contains any standing label at all) rather than as a per-row fallback:
  as a per-row fallback the new paths also fired on Vanilla and silently added 105 items to its
  PvP rewards. Per-file, every Vanilla file stays bit-identical. Location:
  `tools/build-rep-loot.py`.

- **`build-item-sources.py` would have read the CLASSIC world DB for any expansion.** The CMaNGOS
  SQLite path was hardcoded, so building TBC item locations would have emitted vanilla
  quest/vendor/drop locations for TBC items — the same wrong-era failure as the drop-graph bug
  below, and just as quiet. The DB is now selected by version (`DB_FILE`) and a missing one is an
  actionable error naming the exact file wanted (`tools/cmangos_cache/tbcmangos.sqlite`).
  Provisioning it is a manual step, so TBC item locations remain unbuilt — but they can no longer
  be built _wrongly_. Location: `tools/build-item-sources.py`.

- **A BiS gear set whose filename carried no phase number was silently dropped — on Vanilla too.**
  The tier-named-set fix above also recovered a warlock phase-2 set on **Vanilla** (42 → 43 sets).
  This is the one Vanilla data change in this release and it is an addition only: no existing set
  moved. Kept rather than suppressed because it is a builder defect, not TBC enrichment — leaving
  it would mean knowingly shipping a known drop. Location: `tools/build-bis.py`,
  `Data/Vanilla/_core/BiS.lua`.

- **TBC shipped the VANILLA instance list as its drop graph.** `Data/TBC/_core/SourceNames.lua` declared
  "33 instances" — Molten Core, BWL, AQ40, Naxxramas… — with **zero** Outland content, while
  `HasSourceData()` returned `true`, so a consumer's instance UI lit up fully and showed a Karazhan
  raider a list of vanilla raids. Worse than missing data, because feature-detection passed. Root cause:
  `tools/build-sources.py` always fetched AtlasLoot's `data.lua`, which is the **vanilla** module;
  AtlasLoot keeps one data file per expansion (`data.lua` / `data-tbc.lua` / `data-wrath.lua`). The
  builder now selects by version **and caches per file** — a single shared cache name was part of how the
  vanilla tables got reused. Wrath is wired for free. Vanilla's regenerated output verified
  byte-identical. Location: `tools/build-sources.py`, `Data/TBC/_core/{Sources,SourceNames}.lua`.
- **`Data/TBC/_core/Hidden.lua` was built but never loaded** — absent from `ItemDB_BCC.toc`, so
  `IsHidden()` returned false for everything on TBC and 4,593 test / placeholder / never-implemented
  items appeared in every consumer picker and ranking. Location: `ItemDB_BCC.toc`.
- **`build-factions.py` produced ZERO faction-restricted TBC items** — a silently empty file, two
  independent defects. (1) **The DB2 schema differs by client**: Vanilla (1.15.x) exports one
  `AllowableRace` column, TBC (2.5.x) splits the 64-bit mask into `AllowableRace_0` / `AllowableRace_1`;
  the builder read the old name and got `None` for all 30,128 rows. (2) **The race bitmasks were
  Vanilla-only** — 8 races, missing TBC's Blood Elf and Draenei. The two new bits were verified from the
  2.5.x data rather than assumed: Black Stallion Bridle (Alliance mount) = `1101` = `1024|64|8|4|1` →
  Draenei is 1024; Horn of the Black Wolf (Horde) = `690` = `512|128|32|16|2` → Blood Elf is 512,
  consistent with `1 << (raceID-1)`. Confirmed the mask change is a **no-op on Vanilla** by scoring the
  1.15.9 dataset both ways: 0 rows disagree. Now 133 TBC items (68 Alliance / 65 Horde). Location:
  `tools/build-factions.py` (`race_mask`, `ALLIANCE`, `HORDE`).

### Notes

- **Known gap — TBC gem sockets score 0.** 2,687 TBC items carry `EMPTY_SOCKET_*`. A socket is worth
  whatever you put in it, which needs a gem model the library doesn't ship, so socketed gear is
  under-valued rather than guessed at. `Scoring/TBC.lua` lists the keys in `skipPrefix` with the reason;
  closing it means adding a socket scorer **in that module**, with no risk to any other expansion.
- **Still Vanilla-only: BiS / EP weights, talents, aura-buffs, consumable groups.** `build-bis-weights.py`
  sources HawsJon's Pawn scale, which is Classic-only — the Pawn repo has no TBC scale file. On TBC
  `HasBiS()` is false and every EP/BiS/ranking API returns `nil`.
  **The latent trap in that builder is now closed.** Its `STAT_MAP` maps `HitRating → HIT_PCT` /
  `CritRating → CRIT_PCT` — correct for Vanilla, but **wrong for TBC**, whose items carry
  `ITEM_MOD_HIT_RATING`: running it unchanged would have emitted a scale with zero key overlap against
  the items it scores, every item silently worth 0 with no error anywhere. It now **refuses any version
  but Vanilla** with an error naming both missing halves (a weight source for that expansion, and a
  per-version `STAT_MAP`), rather than producing a plausible-looking wrong file. Vanilla's output
  verified unchanged. Candidates and the rest of the remaining work are tracked in `docs/TBC-Parity.md`.
  Location: `tools/build-bis-weights.py`.
- **Tests.** `Tests/libitemdb_spec.lua` extended to **67 passing** (from 57). The new
  `scoring rules modules` block is the guard on the whole architecture, because its failure mode is
  silent — a wrong-expansion rule returns a plausible number, never an error. It pins that the same core
  and the same stat table produce each expansion's own answer (`{CRIT_PCT=1}` scores 7 under Vanilla and
  22.076923 × the crit-rating weight under TBC), that TBC folds the attack-type-specific rating keys,
  that sockets and weapon skill score 0 on TBC, that each expansion offers only the weight stats it can
  populate, and — the regression this architecture exists to prevent — that **Vanilla's answers are
  byte-for-byte restored** once its rules are back. Verified separately by loading the entire
  `ItemDB_BCC.toc` `_core` set through the offline harness: 26 files, 30,032 items, 26 instances.
- Data files touched are TBC-only. A Vanilla `Factions.lua` refresh (client build 1.15.8 → 1.15.9, 155
  items) was generated during this work and **deliberately reverted** — it is an unrelated upstream data
  change and does not belong in a TBC commit.

---

## [v0.4.7] (2026-08-02) - Consumable mutual-exclusion groups ("one active per slot")

### New Features

- **Every consumable buff now carries its mutual-exclusion GROUP (`GetConsumableGroup` / the new
  `exclGroup` field on `GetConsumableBuffs`).** WoW enforces "one active per kind" for consumable buffs —
  one agility elixir, one strength source, one flask, one food, one attack-power buff, one weapon oil, and
  so on — but, exactly like the vanilla single-subclass problem we already worked around, it never encodes
  the grouping in the client DB2 (`SpellCategory` is 0 for these). A buffs planner therefore can't derive
  "these two can't both be up" from the game. So we ship the grouping as derived/opinion data, sourced —
  **not guessed** — from the same MIT WoWSims data behind BiS: its Classic consumable inputs are typed by
  the exclusion slot (`ConsumableInputConfig<AgilityElixir>`, `<Flask>`, `<Food>`, …), one field per slot
  in its `Consumes` proto, i.e. precisely the "one per group" rule. `tools/build-consumable-groups.py`
  fetches `wowsims/classic`, parses those typed inputs, intersects with the version `_core`, and emits
  `Data/Vanilla/_core/ConsumableGroups.lua` (`lib:LoadConsumableGroups`) — **78 consumables across 19
  slots** (`agility-elixir`, `strength-buff`, `attack-power-buff`, `armor-elixir`, `health-elixir`,
  `spell-power-buff`, `fire-power-buff`, `frost-power-buff`, `shadow-power-buff`, `mana-regen-elixir`,
  `flask`, `food`, `alcohol`, `hit-consumable`, `zanza-buff`, `potions`, `conjured`, `explosive`,
  `sapper-explosive`). Two items sharing a token are mutually exclusive; a consumer enforces one selection
  per token. This is finer and more correct than the TBC battle/guardian split (which doesn't exist in
  Vanilla): e.g. **Mageblood Potion (20007) is a `mana-regen-elixir`**, so it coexists with an
  agility/strength elixir rather than colliding. `exclGroup` is `nil` for consumables outside any slot.
  Location: `LibItemDB-1.0.lua` (`lib.consumableGroup`, `LoadConsumableGroups`, `GetConsumableGroup`,
  `exclGroup` in `GetConsumableBuffs`), `tools/build-consumable-groups.py`,
  `Data/Vanilla/_core/ConsumableGroups.lua`, `ItemDB.toc`. MINOR bumped 12 → 13.

- **`lib:ScoreStats(stats, classID, spec, opts)` — score an ARBITRARY stat table exactly like an item's.**
  The scorer behind `GetItemScore` was reachable only with an item id, so a consumer wanting the EP of a
  _buff_, _consumable_, _enchant_ or _talent_ had to re-implement `Σ stat × weight` itself — and that
  silently produces the wrong number, because the two datasets use **disjoint key spellings**:
  `Data/Vanilla/_core/Effects.lua` emits `ITEM_MOD_MANA_REGENERATION` (42 rows) and `ITEM_MOD_SPELL_POWER`
  (32 rows), while `BiSWeights.lua` only ever weights `ITEM_MOD_POWER_REGEN0_SHORT` (29) and
  `ITEM_MOD_SPELL_DAMAGE_DONE` (16) — **zero overlap**. The bridge is the file-local `BIS_ALIAS` fold, so
  a hand-rolled sum scores every mp5 and spell-power consumable at exactly **0**, with nothing to notice.
  Making the scorer public is the fix; duplicating the alias table in each consumer is not. The wrapper
  runs the full `scoreStats` path (alias folding, melee-vs-ranged AP max-pairing, per-hand `DPS_*` by
  `opts.equipLoc`) plus `scoreWeaponSkill` (`opts.attack`) and `scoreAmmo`, so a stat table scores
  identically whether it came off an item or a flask. Set / on-use / proc effects are **item-keyed** and
  therefore out of scope — use `GetItemScore` for a real item. `nil` when the class/spec has no weights.
  `opts = { source, equipLoc, attack }` is a table, deliberately mirroring `GetItemScore`'s
  `(id, classID, spec, opts)` rather than taking positionals — a positional `source` read through a
  string's metatable yields `nil` instead of erroring, which would silently score under the default
  weight scale. Consumers feature-detect with `if DB.ScoreStats then`. Location: `LibItemDB-1.0.lua`
  (`lib:ScoreStats`, next to `GetItemScore`), `README.md`, `Tests/libitemdb_spec.lua`. Shipped under
  MINOR 13 (unreleased at the time of writing, so no second bump).

- **Flat `HEALTH` / `MANA` pools now score, priced through the stat that delivers them.** No weight scale
  carries a raw-pool weight (HawsJon has no `HEALTH`/`MANA` key), so **Flask of the Titans** (+1200 HP)
  and **Flask of Distilled Wisdom** (+2000 mana) scored 0 — on gear _and_ through `ScoreStats`. They're
  now valued as the primary stat that buys the pool, at the game's fixed conversion: **10 HP per Stamina**
  and **15 mana per Intellect**, both sourced rather than recalled — WoWSims (MIT)
  `sim/core/character.go` `AddStatDependency(stats.Stamina, stats.Health, 10)` and `sim/core/mana.go`
  `AddStatDependency(stats.Intellect, stats.Mana, 15*modifier)`. So a +1200 HP flask is worth exactly the
  120 Stamina it is, under whatever scale is active. Applied inside `scoreStats`, so gear and consumables
  agree by construction, and itemized in `GetItemScoreBreakdown` as a labelled row whose `factors`
  multiply back to its `ep` (pinned by a spec). `HEALTH`/`MANA` are deliberately **not** added to
  `WEIGHT_STATS` — they're derived rows, not weightable keys, so a weight editor must not offer a slider
  for them; they get `WEIGHT_LABEL` entries only. _Known approximation:_ Intellect also buys spell crit
  for casters, so a caster's Int weight slightly over-credits a raw mana pool; it's exact for physical
  specs. Refining that needs a per-class Int→crit constant which would belong in `ScoreModel` next to
  `hitsPerSec` — not built, because it would currently affect exactly one item. Location:
  `LibItemDB-1.0.lua` (`HP_PER_STAMINA` / `MANA_PER_INT`, the pool branch in `scoreStats`,
  `WEIGHT_LABEL`).

### Bug Fixes

- **Every bandage in the game shipped claiming to grant mana.** `tools/build-effects.py` mapped DB2 aura
  **8 to `MANA`**, with a comment calling it `MOD_INCREASE_ENERGY` — but aura 8 is _periodic heal_, and
  aura **35** is the max-mana one (the table mapped both). Verified against the DB2 rather than the
  comment: `Linen Bandage` and `Heavy Runecloth Bandage` are `aura=8`, `Flask of Distilled Wisdom` is
  `aura=35`, `Flask of the Titans` is `aura=34`. The result was that a heal-over-time TICK was published
  as a max-mana buff — `Linen Bandage` → `MANA=11`, `Heavy Runecloth Bandage` → `MANA=250`, every BG and
  faction bandage variant, plus restore-over-time potions (`Dreamless Sleep Potion` → `MANA=300`, which
  is actually its _health_ restore; its real mana restore, aura 24, was unmapped and dropped). **31 of
  the 36** shipped `HEALTH`/`MANA` rows in Vanilla came from this, and the same bug shipped in TBC (37
  rows) and Mists (58) — **126 bogus rows across the three versions.** Any consumer summing consumable
  stats was crediting bandages with mana they never grant, and it would have been amplified by the pool
  scoring above. Aura 8 is now deliberately unmapped, with a comment recording _why_ so it isn't
  "fixed" back; aura 24 (the genuine restore) stays unmapped for the same reason — **a restore is not a
  stat buff and has no place in a stat table.** Heal/restore consumables therefore carry no effect row
  at all and no longer appear in `GetConsumableBuffs`, which also means the `bandage` category is no
  longer returned by `GetConsumableCategories` (the classifier remains, it just matches nothing). The
  rebuild is a pure removal — diffed to confirm **only** those rows and the header count changed in all
  three versions; no other effect data moved. Location: `tools/build-effects.py` (`SIMPLE_AURA_KEY`,
  `DRINK_KEYS` comment), `Data/{Vanilla,TBC,Mists}/_core/Effects.lua`, `LibItemDB-1.0.lua` (category
  comment), `README.md`, `docs/Curseforge_Description.html`.

### Notes

- **Vanilla only, by source.** Only `wowsims/classic` carries the per-item typed inputs; `tbc-new`/`mop`
  model consumables with the coarser `battleElixirId`/`guardianElixirId` proto fields (the TBC+ system
  Blizzard _does_ tag in the DB2), so the generator finds nothing there and emits nothing — matching
  `AuraBuffs`/`Talents`, which are also Vanilla-only. `GetConsumableGroup` returns `nil` on TBC/Mists.
- **Tests.** `Tests/libitemdb_spec.lua` extended (**57 passing**, up from 44): `exclGroup` surfaces on
  `GetConsumableBuffs` rows, `GetConsumableGroup` resolves string/number ids and returns `nil` when
  ungrouped, and a new `ScoreStats` block pins the contract that actually breaks silently — both alias
  folds (mp5, spell power), AP max-pairing rather than summing, per-hand DPS from `equipLoc`,
  weapon-skill keys never applied as a flat weight, explicit `source` selection, the `nil` cases, and an
  equivalence assertion that `ScoreStats(GetStats(id), …)` equals `GetItemScore(id, …)` for an item with
  no set/use/proc effect — plus the pool conversions (health via Stamina, mana via Intellect, 0 rather
  than a divide error when the scale has no such primary weight) and a breakdown row whose `factors`
  multiply back to its `ep`. Full suite green via `lua Tests/wowapi/run.lua`.

## [v0.4.6] (2026-07-31) - Buffs & talents (trees + effects), buff/consumable enumeration & categorization, offline test suite

### New Features

- **Raid / world / self / totem BUFF stats are now in the DB (`GetAuraBuff` / `GetAuraBuffs`).** Buffs
  (Mark of the Wild, Blessing of Might, Rallying Cry, Aspect of the Hawk, Strength of Earth Totem, …)
  aren't items, so their magnitudes lived nowhere in ItemDB and a consumer had to hardcode them. An aura
  is just a spell with APPLY_AURA stat effects in the SAME vocabulary gear uses, so `tools/build-aura-buffs.py`
  pulls it all from wago DB2 — the **only** curation is the buff NAME list (which buffs matter, not in the
  DB2). Every name is resolved to its player-learnable ranks via **SkillLineAbility** (so boss / NPC /
  seasonal same-named spells are excluded), and stats read from **SpellEffect** (value = base + 1). Emits
  `Data/<Version>/_core/AuraBuffs.lua` (`lib:LoadAuraBuffs`) — **121 ranks across 41 buffs**, EVERY rank,
  so the DB is complete and a consumer serves whichever rank it wants. Readers: `lib:GetAuraBuff(spellID)`
  → `{ cat, name, stats }` for one rank; `lib:GetAuraBuffs(name)` → `{ cat, ranks = { {spellID, stats}, … } }`
  sorted low→high (last = max rank). Coverage handles the awkward shapes: paladin/priest resistance auras
  and Aspect of the Wild (aura 558), Blessing of Wisdom's mp5 (periodic-energize aura 24), Leader of the
  Pack (its learnable spell is a dummy; the crit aura is captured via fallback), and shaman totems
  (Strength of Earth / Grace of Air / resistance totems — the "… Totem" spell is only the SUMMON, so the
  buff is read from the aura the totem pulses). **Percent buffs** (Blessing of Kings, Greater Blessing of
  Kings, Spirit of Zandalar, Mol'dar's Moxie, Sayge's Dark Fortune of Strength / Agility / Stamina /
  Intelligence / Spirit / Armor / Damage) are carried too, in a parallel **`PCT_<STAT>`** vocabulary (`PCT_STRENGTH=10` = +10%
  Strength) that a flat `STAT=v` can't hold — a consumer applies these multiplicatively on top of summed
  flat stats. Sourced data-driven from the percent auras (137 all-/one-stat %, 80 one-stat %, 101 armor %,
  79 damage %; value = base + 1), validated against wago SpellEffect; Sayge's Dark Fortune of Resistance
  correctly stays flat (+25 all-magic, the existing resist path). Only item buffs (scrolls / flasks / food —
  already in `Effects.lua` by itemID) remain a consumer's job. Library MINOR **8 → 9** (the `PCT_` keys ride
  the existing stat codec — no API change). Location: `tools/build-aura-buffs.py`, `LibItemDB-1.0.lua`,
  `Data/Vanilla/_core/AuraBuffs.lua`, `ItemDB.toc`.
- **Every class's talent tree is now in the DB (`GetTalentTree` / `GetTalentClasses`).** A build planner
  seeds its talent tab from the live `GetTalentInfo` API — but that API only exposes the logged-in
  character's class, so you can't plan a build for a class you aren't on. The tree STRUCTURE is static, so
  `tools/build-talents.py` ships it from wago DB2 (`Talent` + `TalentTab` + `SpellName`): all 9 vanilla
  classes × 3 trees, **432 talents**. `lib:GetTalentTree(classID)` returns
  `{ [tab] = { id, name, talents = { [index] = { tier, column, maxRank, name, spellID, prereq } } } }` — the
  SAME _shape_ a consumer already builds from the live API (tab in in-game order; `index` numbers a tab's
  talents by (tier, column), internally consistent so `prereq` is an index in the same tab — a consumer
  overlaying live `GetTalentInfo` data should correlate by tier/column/spellID, as the Classic index order
  isn't a documented guarantee), lifting the "current toon only" limit to every class. `spellID` is the rank-1 spell, so a
  consumer resolves icon / tooltip (and, later, talent effects) from it. `lib:GetTalentClasses()` lists the
  classes with data, for a class picker. Emits `Data/Vanilla/_core/Talents.lua` (`lib:LoadTalents`, one call
  per class). Data-driven — no magnitudes are curated; class/tab/tier/column/rank/prereq all come from the
  DB2. Library MINOR **9 → 10**. Location: `tools/build-talents.py`, `LibItemDB-1.0.lua`,
  `Data/Vanilla/_core/Talents.lua`, `ItemDB.toc`, `Tests/libitemdb_spec.lua`.
- **Talent EFFECTS — the stat modifiers a talent grants, per rank (`GetTalentEffect`).** The tree
  structure lets a planner build any class; this lets it fold that build's bonuses into gear scoring.
  `tools/build-talents.py` now also emits `Data/Vanilla/_core/TalentEffects.lua` (`lib:LoadTalentEffects`)
  with each talent's per-rank stats in the same vocabulary gear/buffs use (crit, hit, %stats, %AP, %armor,
  dodge/parry/block, defense/weapon skill, plus `PCT_<STAT>` percents). `lib:GetTalentEffect(classID, tab,
  index, rank)` → `{ stats, weapons }`. **Weapon-conditional** crit/hit/damage (Axe Spec, Cruelty,
  Precision) carries a `weapons` tag decoded from wago `SpellEquippedItems` — the same short weapon-type
  names `GetItemType` returns, so a consumer applies it only when the wielded weapon matches (a
  general-melee talent tags every melee type; an axe-only one tags just `Axe`). Two correctness guards, both
  validated against wago rather than assumed: only **passive** talents contribute — a talent that grants an
  active or a castable buff (Divine Spirit, Deterrence, Blessing of Kings) is filtered via
  `SPELL_ATTR0_PASSIVE`, so a granted buff's stats can't masquerade as an always-on sheet bonus; and effects
  are keyed off each talent's real rank-spells (not by name), so same-named talents across classes don't
  cross-contaminate. **40 talents** carry sheet effects. NOT here (documented, not silently dropped):
  spell-property modifiers (`ADD_PCT/FLAT_MODIFIER` — most caster DPS talents like Arcane Instability),
  procs, and stat conversions — they modify specific spells, not the character sheet, so no stat blob can
  hold them (that needs spell modelling; WoWSims is the reference). Library MINOR **10 → 11**. Location:
  `tools/build-talents.py`, `LibItemDB-1.0.lua`, `Data/Vanilla/_core/TalentEffects.lua`, `ItemDB.toc`,
  `Tests/libitemdb_spec.lua`.
- **Buff & consumable enumeration (`GetBuffsInCategory` / `GetConsumableBuffs`).** Every buff already
  carries a category, so the library now serves the whole list instead of only answering lookups by
  name/spellID: `GetBuffCategories()` → the categories present (`raid` / `self` / `totem` / `world`);
  `GetBuffsInCategory(cat)` → every buff in it as `{ cat, name, ranks }`, sorted. So a consumer's buff
  picker is driven by the DB — add a buff (e.g. the Sayge's Intelligence fix below) and it appears
  automatically, instead of drifting from a hand-kept list. Same for consumables:
  `GetConsumableBuffs(category)` enumerates every use-effect item from `Effects.lua` as
  `{ id, name, type, stats }` grouped by the consumable **category we assign** (detailed below), and
  `GetConsumableCategories()` lists those categories (lazy index, rebuilt when the data changes).
  `GetAuraBuffs` now also returns `name`. Also fixed a data hole: **Sayge's Dark Fortune of Intelligence** (spell 23766,
  `PCT_INTELLECT=10`) was missing because the curation list searched wago for "…of Intellect" — the real
  name is "…of Intelligence" — so the world-buff set is now complete at **8** Sayge's. And widened
  consumable use-effect capture (`build-effects.py`) to **avoidance (dodge / parry / block) and melee-haste**
  auras, which were dropped before — so the Dire Maul Jujus are complete (Juju Flurry `MELEE_HASTE_PCT=3`,
  Juju Escape `DODGE_PCT=5` were previously missing). And taught `build-effects.py` the **temporary
  weapon-enchant** chain (`ItemEffect → SpellEffect ENCHANT_ITEM_TEMPORARY → SpellItemEnchantment`), so
  **sharpening stones / weightstones / oils** are captured for the buff picker — a flat `WEAPON_DAMAGE` key
  for the stones (Rough +2 … Dense +8), while the oils' and Elemental Sharpening Stone's equip-spell auras
  (spell power / mp5 / healing / crit) reuse the existing aura decoder. Plus two audited gaps: **Flask of
  Distilled Wisdom** (aura 35 max-mana → `MANA`) and the **Protection Potions** (Fire / Frost / Nature /
  Shadow / Holy / Arcane + Greater — aura 69 `SCHOOL_ABSORB` → a school-tagged `ABSORBn` key, `n` = the same
  school index as `RESISTANCEn`). **326** use-effect consumables now. And because vanilla files every
  consumable under ONE subclass (the Potion/Elixir/Flask split didn't arrive until later expansions),
  `build-effects.py` now **classifies** each into a category — `flask` / `elixir` / `potion` / `scroll` /
  `food` / `weapon` (stones & oils) / `bandage` / `other` — from the effect path (a weapon-enchant, or a
  Well-Fed periodic trigger) plus an English-name heuristic (plain mana/health restores — drinks — fold
  into `food`), shipped as `lib:LoadConsumableTypes`.
  `GetConsumableBuffs` / `GetConsumableCategories` now group by it, so a buffs picker gets flask-vs-potion
  straight from the DB instead of parsing names. The decoder also **dedups duplicate effect rows per spell**
  (matching `build-aura-buffs.py`), fixing a latent double-count — Bubbly Beverage read +20 stamina, now the
  correct +10 (regenerated for Vanilla, TBC and Mists). The enumeration **skips hidden items** (test /
  deprecated / never-obtainable), so a flagged item like `ALEX BUG TEST ITEM` stays out of the picker,
  matching how `Search` / `GetSlotRanking` already behave.
  Library MINOR **11 → 12**. Location: `LibItemDB-1.0.lua`, `tools/build-aura-buffs.py`,
  `tools/build-effects.py`, `Data/Vanilla/_core/AuraBuffs.lua`, `Data/Vanilla/_core/Effects.lua`,
  `Tests/libitemdb_spec.lua`.

### Improvements

- **Offline unit-test suite (`Tests/`, WoWAPITesting harness).** ItemDB carries the shared offline test
  harness (`Tests/wowapi` git submodule) with a busted-style spec, `Tests/libitemdb_spec.lua`, that pins
  the fragile parts — the packed-string codec and every read API built on it: `GetInfo`, `GetStats` merge
  precedence, links / suffix links, name & suffix resolution, spell schools, season detection, and now
  `GetItemType` (weapon subtype / slot / mount override / subclass fallback), the aura-buff readers
  (`GetAuraBuff` / `GetAuraBuffs` rank sorting, `PCT_<STAT>` decode), the talent readers (`GetTalentTree` /
  `GetTalentEffect`, incl. weapon-conditional tags), and the buff / consumable enumeration (category
  listing + hidden-item exclusion). Added the `.luacheckrc` the layout requires (a `files["Tests"]` block
  using `std = "lua51+busted"`, `ignore = { "143/assert" }`); `Tests` is excluded from the packaged build
  in `.pkgmeta`, so it never reaches players. Runs in milliseconds on a bare Lua 5.1 interpreter
  (`lua Tests/wowapi/run.lua`) — no game client, no LuaRocks. **44 specs, all green.** Location:
  `Tests/libitemdb_spec.lua`, `.luacheckrc`.

---

## [v0.4.5] (2026-07-30) - Uniform loot-browser API, two-front weapon-skill scoring, and school-specific spell-damage tags

### New Features

- **Uniform grouped-loot browser API (`GetLootModules` / `GetLootCategories` / `GetLootSections`).**
  A consumer's loot browser can render every source through ONE code path instead of a bespoke path
  per source. Three readers expose a `module → categories → sections → items` tree: `GetLootModules()`
  lists the source modules this client can populate (`instances`, `factions`, `pvp`, `collections` —
  only the non-empty ones, so a consumer ships incrementally); `GetLootCategories(moduleKey)` the
  subcategories (each instance / faction / battleground, or "Class Sets"); `GetLootSections(moduleKey,
  categoryKey)` the loot grouped into `{ header, items = {id,…} }` sections in display order —
  instances → one section per boss in **kill order**, pvp/factions → one section per reputation
  **tier** (Friendly→Exalted), collections → one section per set. The existing instance/boss readers
  (`GetInstances` / `GetInstanceEncounters`) fold in as the
  `instances` module, so there's one path, not five. Backed by Sources (instances), the new RepLoot
  data (pvp/faction reward tiers, below) and Sets (collections); the reverse-indexes are lazy. Crafting
  (professions) is deferred to ProfessionDB, so that module isn't advertised. Location: `LibItemDB-1.0.lua`.

- **Battleground & reputation reward gear is now sourced (fixes "Other" on AV/WSG/AB rewards).**
  Reward gear bought from a battleground / faction quartermaster with marks + reputation (Don Julio's
  Band, The Unstoppable Force, the AV tomes, …) was **unsourced**: CMaNGOS's `npc_vendor` data carries
  no extended-cost / reputation info, so our pipeline never saw it — `GetSources` returned nothing
  ("Other" in a planner), and the loot browser's `pvp` module showed the reagents AV vendors happen to
  sell instead. `tools/build-rep-loot.py` reads the **installed** `AtlasLootClassic_PvP` /
  `AtlasLootClassic_Factions` `data.lua` (facts extracted + credited, GPL-2.0) and emits
  `Data/<Version>/_core/RepLoot.lua` — reward gear by source and reputation **tier** (`lib:LoadRepLoot`).
  It feeds **`GetSources`** (a `{ instance = "Alterac Valley", source = "pvp" }` badge) **and** the loot
  browser's `pvp` / `factions` modules (real Friendly→Exalted tier sections). AV Exalted now matches
  AtlasLoot exactly (13 items incl. both faction mounts), and reputation rewards are sourced too
  (`GetSources(18182)` → Argent Dawn / reputation). **3 battlegrounds + 9 reputation factions, 470
  reward items.** The two AtlasLoot modules use different tier markers (PvP `_G[FACTION_STANDING_LABEL]`
  vs Factions `ALIL["Exalted"]`) and Factions has multi-item rows (faction-variant insignia) — both
  handled. Each BG tier is also split into `[ALLIANCE_DIFF]` / `[HORDE_DIFF]` reward blocks, so gear
  only one side can buy (Stormpike vs Frostwolf weapons, the two mounts) is **faction-tagged into
  `itemFaction`** (259 items) — a consumer's A/H filter then hides the other side's rewards while
  shared gear (rings, quivers) stays visible for both. Location: `tools/build-rep-loot.py`,
  `LibItemDB-1.0.lua`, `Data/Vanilla/_core/RepLoot.lua`, `ItemDB.toc`.

- **`GetItemType(id)` — a short, always-populated display type for every item**, so a consumer's
  "Type" column is never blank and never leaks a raw slot code. Slot-defined items use the slot
  (Ring / Neck / Trinket / Cloak / Off-Hand / Shield), weapons a short weapon-type (Sword / Axe /
  Staff / Dagger / Gun / Bow / Crossbow / Wand / Polearm / Mace / Fist Weapon / Thrown), and
  everything else the game's localized subclass name (Cloth / Leather / Mail / Plate; Potion / Food &
  Drink / Elixir / Bandage / Scroll; Arrow / Bullet; Quiver; Bag; …). The subclass name is used only
  where it reads well — jewelry and held items report "Miscellaneous" in the client, so those fall
  back to the equip slot. **Mounts** are a special case: Classic keeps the vanilla classification where
  mount items are Miscellaneous / subclass 0 (the client's subclass name is literally "Junk"), so
  `tools/build-mounts.py` flags the items whose on-use spell applies `SPELL_AURA_MOUNTED` (aura 78) into
  `Data/<Version>/_core/Mounts.lua` (`lib:LoadMounts`), and `GetItemType` types those as **Mount** (124
  Vanilla mount items) — the best mount in the game no longer reads "Junk". Location: `LibItemDB-1.0.lua`,
  `tools/build-mounts.py`, `Data/Vanilla/_core/Mounts.lua`, `ItemDB.toc`.

- **Items expose the spell SCHOOL their spell-damage bonus is restricted to (`GetItemSchools`).**
  The walk's GetItemStats reports school-specific spell damage ("+20 Fire damage") as **generic**
  `ITEM_MOD_SPELL_DAMAGE_DONE`, dropping the school — so a frost mage scored a Fire off-hand and an
  arcane mage scored Nature boots at full value, identically to the specs those items actually help.
  `tools/build-spell-schools.py` recovers the school from the DB2 aura-13 (`MOD_DAMAGE_DONE`)
  `EffectMiscValue_0` school mask (2 Holy / 4 Fire / 8 Nature / 16 Frost / 32 Shadow / 64 Arcane) and
  emits `Data/<Version>/_core/SpellSchools.lua` (`lib:LoadSpellSchools({[13701]="fire",
  [20536]="shadow", ...})`). Only school-**specific** items are tagged; generic `+spell damage`
  (all-magic mask 126) stays untagged so it still helps everyone, the physical bit (attack power) is
  ignored, and any generic component leaves an item untagged so a filter can never wrongly exclude it.
  New reader `lib:GetItemSchools(id)` → `{ fire=true, ... }` or nil lets a consumer gate the
  spell-damage EP to the matching spec. **188 Vanilla items** (TBC 270; Mists 0 — later expansions
  consolidated spell power, so nothing is school-specific there). Library MINOR **7 → 8**. Location:
  `tools/build-spell-schools.py`, `LibItemDB-1.0.lua`, `Data/Vanilla/_core/SpellSchools.lua`, `ItemDB.toc`.

### Bug Fixes

- **Weapon skill scored only ONE weapon type at a time, silently zeroing the other.** `scoreWeaponSkill`
  took a single `attack.weaponType`, so a player's melee weapon skill and their ranged weapon skill
  could never both count — whichever type the caller passed, the item's `WEAPON_SKILL_*` for the other
  scored 0. Two faces of the same bug: a hunter's stat-stick +Bow/Gun/Crossbow scored 0 while the melee
  type was passed; and once the caller passed the ranged type, **Maladath's +4 Swords scored 0** (the
  scorer looked up `WEAPON_SKILL_BOW` on a sword). Fixed: `scoreWeaponSkill` now takes BOTH a melee
  context (`weaponType`/`weaponDPS`) and a ranged context (`rangedType`/`rangedDPS`) and emits a row for
  each `WEAPON_SKILL_<type>` the item carries for a type the player wields. Maladath's +4 Swords now
  scores (hunter ~3.2 via the 0.75 melee weight, warrior ~22.8 via 5.31); a +Bow/Gun/Crossbow stat-stick
  scores via the ranged path — neither zeroes the other. Location: `LibItemDB-1.0.lua`.

- **Ranged weapon skill was undervalued ~8×.** It was priced as `frac × weaponDPS × DPS_RANGED` — only
  the bow's white auto-shot damage — so +4 Bow skill scored ~0.9 EP. But its miss reduction (~0.8% vs a
  level-63 boss) helps a hunter's **entire** shot rotation (auto + Aimed/Multi/Steady), not just
  auto-shot, so it is now priced as ranged **hit%** through the `HIT_PCT` weight: +4 Bow ≈ 0.8% × 9.379
  ≈ **7.5 EP**. Melee keeps the white-DPS model (miss + dodge + glancing), so warrior weapon-skill
  numbers are unchanged. Location: `LibItemDB-1.0.lua`.

### Notes

- The new `attack` fields (`rangedType` / `rangedDPS` / `rangedSkill`) are optional and additive — a
  caller that sets only `weaponType` keeps the previous single-front behavior. Each weapon-skill row
  carries `factors` (product = `ep`), so a consumer renders its full derivation like any other row.
- `SpellSchools.lua` is a Vanilla `_core` file, matching the Vanilla-only scoring layer; the generator
  is era-general and emits TBC/Mists automatically once those eras gain a scoring layer.

---

## [v0.4.4] (2026-07-29) - Set-bonus EP (flat-stat, self-buff & proc bonuses), ranged-weapon scoring, EP-breakdown "why", and ATT unavailable-item filtering

A broad enrichment pass across several fronts:

- **Set bonuses are now fully valued.** Flat-stat auras that used to ship empty (avoidance,
  block, weapon / defense skill) are decoded, curated self-buff scalers resolve (Dragonstalker
  3pc "Improved Aspect of the Hawk"), and chance-on-hit proc bonuses score (rated from tested
  CMaNGOS data) — each priced per stage and amortized per piece, including the hunter
  Dragonstalker 8-piece Expose Weakness.
- **The ranged side gets its due.** Ammo (arrows / bullets) is scored as ranged DPS, quivers
  and ammo pouches for their ranged attack speed, and ranged weapon speed is exposed.
- **Every EP-breakdown row now shows its derivation** — `magnitude × uptime × weight = ep` —
  so a consumer can display exactly why an item scores what it does.
- **Items that exist in the files but were never actually obtainable (or were removed in a
  past patch) are filtered out automatically** from AllTheThings, retiring the hand-curated
  list. Plus ammo / battleground source-attribution fixes.

### New Features

- **Never-implemented / removed items are now flagged from AllTheThings — no more hand-curation.**
  Items with perfectly normal client data (real name, sane required level, real stats) that were
  never actually obtainable — never implemented, or removed from the game in a past patch — can't
  be caught by any client-derivable heuristic, so they were being hidden one at a time by hand
  (`curated_hidden.py`). `tools/att_extract.lua` now reads the installed **AllTheThings** addon
  (`github.com/ATTWoWAddon/AllTheThings`, MIT — facts extracted + credited) by _evaluating_ its
  data with stubbed helpers, and pulls ATT's curated **Never Implemented** list plus every item
  flagged **removed with patch** (`rwp`). `build-hidden.py` merges them, filtering removed items
  to those already gone by the current client patch — so a vanilla item removed in a later
  expansion (e.g. Earthstrike, removed 4.0.3) stays served. **925 Vanilla items now flagged this
  way** (Speedy Racer Goggles, Wormhide Protector, Wormscale Stompers, …), verified not to hide
  anything obtainable. It's era-general (ATT ships `db/Vanilla`…`db/Mists`), so it lights up for
  each expansion as that era's hidden-item filtering ships; skipped gracefully if ATT isn't
  installed, with `curated_hidden.py` kept as a backstop. Location: `tools/att_extract.lua`,
  `tools/build-hidden.py`.

- **The EP breakdown now explains HOW every row got its number.** A stat row always showed
  its math (`14 × 0.90 = 12.6`), but effect rows (on-use, proc, weapon skill, set bonus) gave
  only a final number with no derivation — an on-use trinket read "= 33.4" with no hint that
  it's +280 AP averaged over its cooldown. Every part from `GetItemScoreBreakdown` now carries
  a **`factors`** list — ordered multiplicands `{label, value, pct?}` whose product equals the
  row's `ep` — so a consumer can render the full derivation for _any_ row: an on-use is
  `280 AP × 17% uptime × 1.3 premium × 0.55 weight = 33.4`; a proc is `magnitude × rate ×
  weight`; a set row is `full ÷ pieces`. `pct = true` marks 0–1 fractions to show as a percent.
  Location: `LibItemDB-1.0.lua`.

- **Ammo (arrows / bullets) are now captured and scored as ranged DPS.** Projectiles were in
  the DB (slot `INVTYPE_AMMO`) but their added damage was uncaptured — the walk's `GetItemStats`
  returns nothing for ammo. Ammo adds a **fixed amount to your ranged DPS**: the client stores
  it (`ItemSparse.MinDamage_0/MaxDamage_0`) and shows it as "Adds X damage per second" — a
  _per-second_ figure, not per-shot, that doesn't scale with bow speed (verified: Ice Threaded
  Bullet's `min/max` avg 16.5 == its "16.5 damage per second" tooltip). `build-equip-stats.py`
  emits it as **`AMMO_DAMAGE`**, and `GetItemScore` values it exactly like ranged weapon DPS —
  `AMMO_DAMAGE × DPS_RANGED` — nonzero only for hunters (0 for melee). Its breakdown row carries
  `factors` like every other. 38 Vanilla ammo items (Ice Threaded Bullet → ~43 EP for a
  marksmanship hunter, 16.5 × 2.6). Also exposes **`WEAPON_SPEED`** (seconds,
  `ItemSparse.ItemDelay/1000`) on ranged weapons (406 bows / guns / crossbows / thrown) for a
  consumer to derive shot / proc rates for a _planned_ weapon — informational, not used for
  ammo (ammo DPS is already bow-independent). Location: `tools/build-equip-stats.py`,
  `LibItemDB-1.0.lua`, `Data/Vanilla/_core/EquipStats.lua`.

- **Quivers and ammo pouches are now valued for hunters (ranged attack speed).** The
  ranged-haste stat these carry was already captured (on-equip aura 557 →
  `RANGED_HASTE_PCT`, `build-equip-stats.py`) but had no EP weight, so a quiver scored 0.
  `build-bis-weights.py` now maps HawsJon's `HasteRating` → `RANGED_HASTE_PCT`; the
  `HasteRatingPer` conversion lands it in per-1 % units (MM hunter 8.03 × 0.4 ≈ **3.2 EP per
  1 % ranged haste**, so a +14 % quiver ≈ **45 EP**). It's **gated to hunters** — the only
  specs HawsJon gives a `RangedDps` weight — because a melee class's `HasteRating` is _melee_
  haste and would otherwise value a quiver's ranged haste through the wrong stat. Verified:
  hunter BM/MM/SV score a 14 % quiver 45–56 EP; warriors score it 0. Location:
  `tools/build-bis-weights.py`, `Data/Vanilla/_core/BiSWeights.lua`.

- **Flat-stat set-bonus auras are now decoded.** `build-sets.py`'s `decode()` previously
  handled only the primary-stat / AP / spell-power / resistance auras, so the avoidance,
  block and weapon/defense-skill bonuses (which the Vanilla client stores as their own
  aura types) shipped empty. It now also decodes dodge (aura 49), parry (47), block chance
  (51), block value (564) and `MOD_SKILL` (30 → `DEFENSE` line 95 or `WEAPON_SKILL_<type>`).
  ~35 previously-empty Vanilla bonuses now populate — e.g. _The Darksoul_ 3pc `DEFENSE=20`,
  _Deathbone Guardian_ 2pc `DEFENSE` / 5pc `PARRY_PCT`, _Battlegear of Might_ 3pc
  `BLOCK_VALUE=30`, _Overlord's Resolution_ `DODGE_PCT`, _Defias Leather_ 4pc
  `WEAPON_SKILL_DAGGER`. Notably fills in real **tank** set bonuses (pairs with the native
  HawsJon tank weights from v0.4.3). Location: `tools/build-sets.py`.

- **Curated self-buff scaler resolves the "Improved &lt;buff&gt;" tier bonuses.** A bonus
  like Dragonstalker's 3-piece is an `ADD_PCT_MODIFIER` (aura 108) pointing at another
  spell — "increase the effect of Aspect of the Hawk by 20%" — not a direct stat, so the
  decoder emitted `""`. New `tools/curated_setbonus.py` hand-resolves the handful that
  scale a _self-buff whose effect is a flat stat_ (modifier % × the buff's max-rank value),
  keyed by bonus spell ID. **Dragonstalker Armor 3pc "Improved Aspect of the Hawk"** now
  scores `ITEM_MOD_RANGED_ATTACK_POWER=24` (+20% of Aspect of the Hawk rank 7's 120 ranged
  AP). _Enhanced Battle Shout_ (Battlegear of Wrath) and _Improved Blessings_ (Freethinker's)
  are deliberately deferred — ambiguous current-Era max-rank value / party-raid utility
  rather than a personal stat — with the reasoning documented in the module. Damage/heal/CC
  spell modifiers (Improved Frost Shock / Lightning Bolt / Serpent Sting / …) are out of
  scope: they scale a spell's damage, not a flat stat. Location: `tools/curated_setbonus.py`,
  `tools/build-sets.py`.

- **Proc set bonuses are now valued, rated from the same source as item procs.**
  `build-sets.py` follows a set-bonus proc (`ItemSetSpell` spell with aura 42
  `PROC_TRIGGER_SPELL`) to its triggered effect and, when that resolves to a scoreable bucket
  (`buff` = stat × uptime, `damage` / `heal` / `mana` = amount × rate) **and** we have an
  authoritative rate, emits it in a new `p` table per set — the same `{b,k,m,d,ppm|ch,icd,st,
  sc}` row shape as item procs (`build-use-effects.py`). The rate is the **CMaNGOS tested PPM**
  (`spell_proc_event.ppmRate`) where available, else a real wago per-hit chance (1–99 %). This
  matters because the client stores a `ProcChance` of 100/101 for many set procs as a
  _sentinel_, not a literal every-hit rate — the real rate (e.g. Expose Weakness 2 PPM,
  Bloodfang 2, Crusader's Wrath 3) lives in the emulator data, exactly as the item proc
  pipeline already resolves it. **23 Vanilla set procs now score** (e.g. _Lightforge/Judgement_
  6pc +95 spell power, _Bloodfang_ 8pc lightning damage, _Stormcaller's_ 3pc +50 spell power,
  the tier heal/mana restores). Location: `tools/build-sets.py`, `Data/Vanilla/_core/Sets.lua`.

- **The library scores and amortizes set procs (LibItemDB MINOR 6 → 7).** `LoadSets` parses
  the new `p` field into `set.procs`; `GetItemScore` / `GetItemScoreBreakdown` price them via
  the existing `scoreProcEffects` (new `sumSetProcs` helper), summed over every threshold ≤
  the set's max and **amortized across the set's pieces** exactly like the flat set-bonus
  stats. `maxT` now also considers proc-only thresholds, and set procs respect
  `opts.useEffects = false`. Verified against a Lua harness (amortization, the
  breakdown total == `GetItemScore` invariant, `useEffects` gating). Location:
  `LibItemDB-1.0.lua`.

- **Expose Weakness (Dragonstalker 8-piece) — its self share is scored.** The bonus is a
  raid-wide _target debuff_ that raises the **ranged** attack power of every attacker on the
  target (aura 127, the same aura as Hunter's Mark — calibrated exactly: Hunter's Mark rank 5
  is `base 109 → +110 ranged AP`, so Expose Weakness's `base 449 → +450 ranged AP`). The
  wearer is one of those attackers, so its value to the hunter is the **+450 ranged AP** they
  gain (aura 127 added to the proc stat map) — we score only that self share, not the
  raid-wide total. Its real rate is **2 PPM** (CMaNGOS; the client's `ProcChance 100` is a
  sentinel), which with a 7 s buff is ~23 % uptime — so ~+105 effective ranged AP, **~7
  EP/piece** for a marksmanship hunter across the 8-set. (An earlier pass mis-read the
  `ProcChance 100` as a literal every-hit rate and over-valued it ~4×; the CMaNGOS PPM is the
  fix.)

### Bug Fixes

- **Internal NPC-equipment items ("Monster - …") were leaking into the served DB.** Blizzard's
  `Monster - X` items (swords, shields, bows, guns, and ammo like `Monster - Fire Arrow`, id
  19082) are worn by mobs for attack visuals and are never player-obtainable, but ATT doesn't
  enumerate that whole family in its Never-Implemented list, so one slipped through as a
  selectable arrow. `build-hidden.py` now hides the entire family by name, anchored to the
  literal `"Monster - "` prefix so the real food "Monster Omelet" is untouched (~509 items
  across Vanilla). Location: `tools/build-hidden.py`, `Data/*/_core/Hidden.lua`.

- **TBC hidden-item generation silently ran against Era data.** `build-hidden.py` derives a
  version's wago build from the installed clients, but there's no TBC DB2 cache tied to a
  current client on this box, so `wago_build_for_version("TBC")` returned nil and fell back to
  `DEFAULT_BUILD` — an _Era_ (1.15.x) build. TBC's ATT removed-with-patch cutoff and level-cap
  pass were therefore reading Vanilla data (patch **11508** instead of the live TBC **20506**).
  Fixed: a pinned `FROZEN_BUILD` map supplies the canonical DB2 build for a frozen era (TBC =
  the cached `2.5.5.67511`), and a `FROZEN_CLIENT_PATCH` map supplies that era's _live_ client
  patch (TBC live = **20506** / 2.5.6) for the removed-with-patch cutoff — so item data comes
  from the cached era build while removals track the live patch. Every TBC (and future
  Wrath/Cata) build script now resolves its own era's data instead of Era's. TBC removed-item
  hides went 19 → 53. Location: `tools/itemdb_common.py`, `tools/build-hidden.py`.

- **`.pkgmeta` ignore patterns were malformed, so `docs/` and `tools/` were shipping in the
  release zip.** `docs/`/`tools/` carried trailing slashes (the packager builds `docs//*`,
  which matches nothing) and the script globs used unsupported `**/` prefixes. Rewritten to the
  packager's actual syntax — bare folder names, single-star repo-relative globs — and the
  no-op dotfile entries dropped. The build scripts and docs no longer ship to players.
  Location: `.pkgmeta`.

- **`ItemDB_Mists.toc` interface was a patch behind.** Bumped `50503` → `50504` to match the
  live 5.5.4 Classic client. Location: `ItemDB_Mists.toc`.

- **Proc set bonuses had no per-stage EP (so Dibs showed nothing for them).** The proc
  _scoring_ was done, but `GetSetBonusEP` — the per-threshold lookup a consumer uses to show
  each set stage's value — priced only the flat-stat stages and silently skipped the proc
  stages. So every chance-on-hit set bonus (Dragonstalker 8pc Expose Weakness, Bloodfang 8pc,
  Vestments of Faith 8pc, …) read blank in a per-stage display, across all sets — not just the
  one item that surfaced it. Fixed: `GetSetBonusEP` now prices proc stages too, through the
  same rate × value math item procs use (Dragonstalker for a hunter: 3pc = 13 EP, 8pc = 58 EP;
  90 proc stages across sets × specs now return a value). Takes an optional `attack`
  ({ hitsPerSec }) for paperdoll proc-rate context. Stages that are genuinely unvaluable — pet
  buffs, crowd-control, enemy debuffs, procs with no known rate — correctly stay omitted.
  Location: `LibItemDB-1.0.lua`.

- **Ammo and BG-quiver sources were wrong.** My source resolver let a vendor's _location_
  decide an item's source, so common arrows/bullets a vendor happened to sell **inside a
  battleground** got stamped "Alterac Valley" (Accurate Slugs, Jagged Arrow, Razor Arrow, Solid
  Shot), while the genuine AV reputation-reward ammo — rep-gated and absent from the CMaNGOS
  vendor data — fell through to "Other" (Ice Threaded Arrow / Bullet). Fixed: buyable ammo
  (classID 6) is now always **Vendor** regardless of where the vendor stands, and a battleground
  quartermaster also selling common ammo no longer tags it as a BG reward. The real BG-reward
  ammo and the two Alterac Valley ranged-haste quivers (Harpy Hide Quiver, Gnoll Skin Bandolier
  — rep-gated, gold-bought, not in the vendor data) are curated to their battleground. BG
  _gear_ is unaffected. Location: `tools/build-item-sources.py`, `Data/Vanilla/_core/ItemLocations.lua`.

### Improvements

- **Single source of truth for the flat "secondary" aura → stat vocabulary.** The dodge/
  parry/block/block-value aura map, the `MOD_SKILL` skill-line map (`SKILL_LINE`) and the
  `value = EffectBasePoints + 1` convention now live once in `itemdb_common.py`
  (`AVOIDANCE_AURA`, `SKILL_LINE`, `MOD_SKILL_AURA`), imported by both `build-equip-stats.py`
  (on-equip auras) and `build-sets.py` (set-bonus auras) so the two can't drift.
  `build-equip-stats.py` was refactored onto the shared maps; its `EquipStats.lua` output is
  byte-identical, confirming the move changed nothing. Location: `tools/itemdb_common.py`,
  `tools/build-equip-stats.py`.

### Notes

- Set procs whose `ProcChance` is a 100/101 sentinel with **no** rate in either wago or
  CMaNGOS, extra-attack procs (no single weapon to fold against for a set), and pure enemy
  debuffs / crowd-control (roots, fears) with no computable self value are left unscored,
  not guessed — same policy as the item proc pipeline. 22 Vanilla set procs stay unscored.

---

## [v0.4.3] (2026-07-19) - EP-correctness pass, uniform battleground sources, native tank weights

### Bug Fixes

- **Weapon-skill EP was mis-valued for hunters and for ranged weapons.** The v0.4.2 model
  applied miss + dodge + glance uniformly and through the melee/ranged-agnostic AP weight, which
  (a) gave _ranged_ weapon skill a dodge + glance term it can't have — ranged attacks in Classic
  never glance and can't be dodged (`OutcomeRangedHitAndCrit`), and (b) let a hunter's _melee_
  weapon skill score absurdly high (~105 EP, above a warrior's), because HawsJon rates a hunter's
  melee AP the same as ranged (`Ap = Rap = 0.55`). `scoreWeaponSkill` now (i) makes ranged types
  (bow/gun/crossbow/thrown) **miss-only**, and (ii) values the effect through the class's
  **weapon-DPS weight** (`DPS_MAINHAND` for melee, `DPS_RANGED` for ranged) instead of AP — which
  self-calibrates the melee-vs-ranged split (HawsJon rates a hunter's melee weapon DPS ~0.75 vs
  ranged ~2.6). Result: hunter melee weapon skill now scores low (weaving, ~9 EP) while a warrior's
  stays high (~66), and ranged weapon skill is no longer inflated by a phantom glance term.
  Mechanics confirmed against WoWSims' `sim/core` attack table (`OutcomeMeleeWhite` vs
  `OutcomeMeleeSpecial` vs `OutcomeRangedHitAndCrit`). The `opts.attack` contract is unchanged.
  Location: `LibItemDB-1.0.lua`.

- **Damage procs had the identical AP-weight bug.** `scoreProcEffects`' damage bucket priced a
  proc's bonus DPS as `DPS × 14 × max(melee AP, ranged AP)` — the same melee/ranged-agnostic path
  weapon skill had — so Thunderfury's melee lightning proc read ~231 EP for a _hunter_ who never
  swings it. It now prices through the per-hand weapon-DPS weight (`equipLoc` threaded into
  `scoreProcEffects`): Thunderfury's proc = **warrior 157 / rogue 90 / hunter 22** EP, self-
  calibrating like base weapon DPS and weapon skill. Location: `LibItemDB-1.0.lua`.

- **HawsJon's avoidance weights were being dropped.** `build-bis-weights.py` silently discarded
  `DefenseRating / DodgeRating / ParryRating / BlockRating / BlockValue`, so defense/dodge/parry/
  block scored 0 for _every_ spec — even though HawsJon assigns them (small for DPS, large for
  protection). They're now imported in the right units (per-1% for dodge/parry/block via the
  `RatingPer` conversions; per-defense-skill for defense). A hunter's dodge is now worth ~0.47 EP/%
  instead of 0; a protection warrior gets dodge 6.6 / parry 5.5 / defense 1.2 / block 4.1.
  Location: `tools/build-bis-weights.py`.

### Changes

- **The curated "tank" weight scale is removed** (superseded). It only existed because we were
  dropping HawsJon's tank weights (fixed above); now those import correctly, so HawsJon's
  `protection` (warrior/paladin) and `feral_tank` (druid) specs rank tank gear natively and better
  (sim-derived, not an approximation). Score tank gear with the normal
  `GetItemScore(id, classID, "protection")` — the separate `{source = "tank"}` scale,
  `tools/build-tank-weights.py`, and `_core/TankWeights.lua` are gone. Location: `ItemDB.toc`.

- **Battleground gear now reads the battleground, uniformly.** Instead of "Vendor" (honor gear) or a
  reputation faction ("The League of Arathor"), every BG item now shows **Warsong Gulch / Alterac
  Valley / Arathi Basin** — via a battleground-faction map (rep gear → the BG, not the faction) plus
  the curated BG reward-vendor NPCs (honor / mark gear carries no faction, so its vendor points at
  the BG). ~290 items relabelled. Location: `tools/build-item-sources.py`.

### Improvements

- **Two more items hand-flagged as unobtainable** — **Wormscale Stompers (21612)** (an ATT "never
  available to players" / Crieve's Never-Implemented item) and **Andonisus, Reaper of Souls (22736)**
  (a temporary disarm-only weapon from the Atiesh questline — the boss dual-wields them, you can't
  keep or farm it). Both added to the curated never-obtainable list so they're no longer served in
  rankings or search. Location: `tools/curated_hidden.py`.

---

## [v0.4.2] (2026-07-18) - Item sources, tank gear, weapon skill & more on-equip stats

### New Features

- **Item source locations** — every item now resolves to a real origin instead of a
  consumer falling back to "Other". `GetSources` previously knew only AtlasLoot boss
  drops; quest rewards, vendor items, crafted items, world drops, and PvP / reputation
  gear all read "Other". `tools/build-item-sources.py` reads the **CMaNGOS** vanilla
  server DB (the same SQLite the proc rates come from) plus wago `Map` / `AreaTable` /
  `Faction` names and derives, keyed by item ID:
  - **quest** — reward item ← `quest_template` ← `creature_(questrelation|involvedrelation)`
    NPC → the NPC's spawn map (an instance name), else the quest's `ZoneOrSort` zone. So
    Striker's Diadem (21366) resolves to **Ahn'Qiraj Temple**, not "Other".
  - **vendor** — `npc_vendor` → the NPC's instance, else generic _Vendor_.
  - **crafted** — a create-item spell (`spell_template` Effect == 24) → its product → _Crafted_.
  - **drop** — `creature_loot_template` → the creature's instance map, else _World Drop_.
  - **pvp** — wago `ItemSparse.RequiredPVPRank > 0` → **PvP**, overriding other origins
    (the rank _is_ the source, so High Warlord's / Grand Marshal's read _PvP_).
  - **reputation** — wago `ItemSparse.MinFactionID > 0` → the faction name (_Argent Dawn_,
    _Cenarion Circle_, _The Defilers_, …), added alongside the vendor zone.
  Continent maps (0/1/530/571) are skipped so an instance map always wins; battleground maps
  resolve by name (AV → _Alterac Valley_, WSG → _Warsong Gulch_, AB → _Arathi Basin_). Instance
  names are normalized to the AtlasLoot `SourceNames` spelling (`NAME_ALIAS`: wago's _Ahn'Qiraj
  Temple_→_Temple of Ahn'Qiraj_, _Ahn'Qiraj_→_Ruins of Ahn'Qiraj_, _Deadmines_→_The Deadmines_,
  _Stormwind Stockade_→_The Stockade_) so the location and boss-drop graphs agree — a consumer
  needs no aliases and `GetSources` can dedup. Emitted to `_core/ItemLocations.lua` (`lib:LoadItemLocations`, `{ [id] = {{loc, kind}, …} }`) — 8588
  items on Vanilla: crafted 1669, drop 3470, quest 1987, vendor 1652, pvp 461, reputation 260.
  Source facts are from **CMaNGOS** (GPL-2.0), credited. Location: `tools/build-item-sources.py`.

- **`GetSources` enriched** — merges the CMaNGOS locations under the AtlasLoot boss graph.
  Boss drops keep their full `{ instanceKey, instance, boss, encounterID, source = "atlasloot" }`
  detail; each location adds `{ instance = <place>, source = <kind> }` (no boss) for kinds
  `quest` / `vendor` / `crafted` / `pvp` / `reputation` / `drop`. Each **place shows once**: a
  location whose instance is already shown — by the boss graph, or by an earlier location (e.g. a
  ZG item that both drops and is a reputation reward _in_ ZG) — is collapsed, while the boss
  graph's legitimate multiple-bosses-per-instance rows stand. `HasSources` is true when either
  source exists. New loader
  `lib:LoadItemLocations`, storage `lib.itemLoc`; wired into `ItemDB.toc` and `core_ids`'
  non-item skip list. Location: `LibItemDB-1.0.lua`, `tools/itemdb_common.py`.

- **Hand-curated "do not serve" list** — some items have perfectly normal client data (a
  real name, a sane required level, real stats) yet were never made obtainable in Classic,
  so no `build-hidden.py` heuristic catches them and they'd rank as unreachable top-tier
  BiS. `tools/curated_hidden.py` (`MANUAL_HIDDEN = { id: reason }`) is the hand table for
  these; `build-hidden.py` merges it into each version's `Hidden.lua` on top of the
  automated name/level flags, so the items stay fully queryable for automation
  (`GetInfo`/`GetLink`/`GetStats`) and only ranking/search skip them — reusing the existing
  `IsHidden` / `opts.includeHidden` path, no lib or TOC change. First entries: **Ashbringer**
  (13262 — the original, never-released; Corrupted Ashbringer 22691 stays served) and **Shard
  of the Defiler** (17142). Only Vanilla currently loads a `Hidden.lua` (the ranking /
  search features are Vanilla-only), so that's where the flags take effect. Location:
  `tools/curated_hidden.py`, `tools/build-hidden.py`.

- **Life-steal & haste proc EP** — two more proc effect types now score, extending the
  v0.4.1 proc pass. A **life-steal** proc ("Chance on hit: Steals 185 life",
  `SPELL_EFFECT_HEALTH_LEECH`) is enemy damage plus an equal self-heal, so it folds into
  the `damage` + `heal` buckets; a **melee-haste** proc (+X% attack speed for D s,
  `MOD_MELEE_RANGED_HASTE`) folds into `damage` as X% more white damage over the buff.
  Both use the weapon's own damage/speed and score through the existing DPS→AP path — no
  new lib buckets. Corrupted Ashbringer's leech now adds ~126 EP for a fury warrior
  instead of reading nothing. `build-use-effects.py` now also captures `Delay` (weapon
  speed) for the haste math. Of the procs still unscored, ~284 are genuinely un-scoreable
  (enemy debuffs / stuns / utility with no proc rate) and stay flagged for the BiS
  backstop. Location: `tools/build-use-effects.py`.

- **On-equip stats the walk missed now captured — tank avoidance, weapon skill, spell
  penetration, ranged haste.** Vanilla delivers a whole class of stats as on-equip _spell
  auras_, not `ItemSparse` stat fields, so `GetItemStats` (and the walk) never saw them — every
  tank item was missing its defining stats, and famous items like Edgemaster's Handguards showed
  nothing. `build-equip-stats.py` now recovers them from the same on-equip aura chain it already
  used for hit/crit:
  - **defense / dodge / parry / block** — aura 30 (`MOD_SKILL`, misc 95) → `DEFENSE`, aura 49 →
    `DODGE_PCT`, 47 → `PARRY_PCT`, 51 → `BLOCK_PCT`.
  - **weapon skill** (endgame: +weapon skill vs a level-63 boss cuts miss/dodge/glancing and adds
    crit) — aura 30 with the 15 combat skill lines → `WEAPON_SKILL_SWORD` / `_AXE` / `_DAGGER` /
    `_MACE` / `_2H_*` / `_POLEARM` / `_STAFF` / `_FIST` / `_UNARMED` / `_BOW` / `_GUN` /
    `_CROSSBOW` / `_THROWN`. Profession lines (fishing/mining/…) are excluded.
  - **spell penetration** — aura 123 (stored negative) → `ITEM_MOD_SPELL_PENETRATION` (a key
    HawsJon already weights, so it scores for casters immediately — it was just never captured).
  - **ranged haste** — aura 557 (quivers / ammo pouches) → `RANGED_HASTE_PCT`.

  **+309 items** now carry these (EquipStats 760 → 1069), verified against Elementium Reinforced
  Bulwark (+7 defense), Dreadnaught Legplates (+13 defense / +1% dodge), Stronghold Gauntlets (+1%
  parry), Edgemaster's Handguards (+7 sword/axe/dagger), Trueaim Gauntlets (+8 bow/gun/crossbow),
  Enigma Robes (+20 spell pen). All merge into `GetStats` / `Search` and join `WEIGHT_STATS`
  (`GetWeightStats`, now 40 keys). The auras `GetItemStats` already surfaces (AP / spell power /
  mp5 / healing / resistance) stay excluded to avoid double-counting; non-stat auras (procs,
  movement, "+X vs Undead", damage shields) are skipped. Weapon skill is per-type and only helps
  the weapon you wield (a paperdoll applies the equipped line); HawsJon ships no weapon-skill
  weight, so it reads 0 until a scale provides one. Location: `tools/build-equip-stats.py`,
  `LibItemDB-1.0.lua`.

- **Weapon-skill EP scoring (formula-based).** Capturing weapon skill isn't enough to _rank_
  it, and no data source ships a per-point weight — the value is non-linear and target-dependent
  (checked HawsJon, WoWSims presets, CMaNGOS, wago: none has one). So `GetItemScore` values it by
  porting the Classic attack-table math the way WoWSims implements it (`sim/core/target.go`): an
  item's `+N` skill for the weapon you wield converts to fewer misses (`0.05 + skillDiff×0.002`
  above the 10-skill gap, else `×0.001`), fewer dodges (`×0.001`), and stronger glancing blows
  (the `1.3 − 0.05×skillDiff` / `1.2 − 0.03×skillDiff` glance multipliers, whose clamp _is_ the
  ~308 soft cap) — summed over current→current+N skill as a white-DPS gain, then DPS → AP → weight.
  It's **context-aware** via `opts.attack = { weaponType, weaponSkill (current, default 300),
  weaponDPS (default 90), targetDefense (default 315 = a level-63 boss) }`, and only counts the
  equipped weapon's type. Verified: Edgemaster's Handguards (+7) scores **~96 EP** for a sword or
  dagger user at 300 skill, tapering to ~37 at 305 and ~9 at the 308 cap, and **0** for a mace
  user — a pure weapon-skill item that used to score ~1 EP now ranks like the BiS-tier item it is.
  Weapon-skill keys are formula-scored, so `scoreStats` skips them (no flat double-count); they
  stay in `WEIGHT_STATS` only for display/breakdown labels. Location: `LibItemDB-1.0.lua`
  (`scoreWeaponSkill`). Formula credited to **WoWSims** (MIT).

- **Block value captured; tank gear can now be EP-ranked.** Added block _value_ (aura 564 —
  Aegis of the Blood God +30, Drillborer Disk +23, the Dreadnaught set), completing the tank stat
  set (defense / dodge / parry / block% / block-value; 21 items). And since the shipped HawsJon
  scale is DPS/healer-only and weights none of those, tank gear couldn't be ranked at all — so a
  new **curated "tank" weight scale** (`tools/build-tank-weights.py` → `_core/TankWeights.lua`,
  `LoadBiSWeights("tank", …)`) makes it rankable via `GetItemScore(id, class, spec, {source="tank"})`:
  warrior/paladin protection + druid feral-tank, survival-focused (Stamina-referenced). Verified:
  Elementium Reinforced Bulwark 80.9 (HawsJon) → 156.8 (tank). **These weights are an APPROXIMATE
  curated default, not sim-derived — no source ships static tank weights — so tune them via
  `LoadBiSWeights`.** Location: `tools/build-equip-stats.py`, `tools/build-tank-weights.py`.

- **Curated legendary sources** — Thunderfury and Sulfuras (assembled from multiple pieces, so
  CMaNGOS's quest/loot graph can't place them) now resolve to **Molten Core** instead of "Other",
  via a `CURATED_SOURCES` override in `build-item-sources.py`. Extend it as more surface.

- **More test/placeholder items hidden** — `build-hidden.py`'s name filter now catches
  "test"/"Test"/"TEST" as a whole word _anywhere_ (case-insensitive), not just all-caps
  or at the start, so generated junk like "2200 Test sword 80 purple", "Fast Test
  Polearm" and "Level 60 Test Gear …" (~190 more on Vanilla) no longer ranks or searches.
  Excludes the one real "High Test Eternium Fishing Line" (high-test = a genuine
  fishing-line term). Location: `tools/build-hidden.py`.

### Notes

- ~53% of core items now carry a location (up from boss drops alone). The rest is almost
  entirely low-level starter / vendor-trash gear (Worn Shortsword, Recruit's set) and
  hidden / unobtainable items — none of which surface in ranking or planning.
- Vanilla only (CMaNGOS is a Vanilla server DB); TBC / Mists keep the AtlasLoot boss graph.
- **Feral attack power** is now captured too. It's tooltip-only in the client (not a DB2 aura — an
  aura-99 scan finds nothing, which is why WoWSims scrapes it), and it's just 5 items in the whole
  game (Atiesh +420, The End of Dreams +305, Blessed Qiraji War Hammer +280, Hammer of Bestial Fury
  +154, Mace of Unending Life +140). Their values are lifted from WoWSims' parsed `db.json` (facts,
  credited) into `FERAL_ATTACK_POWER`, and — since a feral druid is always in form — aliased to
  `ITEM_MOD_ATTACK_POWER_SHORT` so it scores exactly like melee AP (verified: Blessed Qiraji War
  Hammer's +280 folds into the Attack Power row for a feral druid). Location: `tools/build-equip-stats.py`,
  `LibItemDB-1.0.lua`.
- One stat stays uncaptured, as an honest follow-up: **"+X damage vs creature type"** (aura 102/131 —
  the captured value doesn't reconcile with the item tooltips, and 102 pairs with 131, so shipping it
  risks wrong/double-counted data).
- Cleaned two `unbalanced-assignments` lint hints in `scoreStats` / `scoreUseEffects` by
  splitting the AP-accumulator declarations onto their own line (no behaviour change).

---

## [v0.4.1] (2026-07-15) - On-use + proc EP scoring, EP breakdown & set-bonus API

### New Features

- **On-use effect EP** — a trinket's "Use: +280 Attack Power for 20s (2 min cd)" is
  a cast spell, not item stats, so a static-stat EP scored it ~0 even when it's the
  best trinket in the game (Earthstrike sorted to the bottom and got hidden by
  "upgrades only"). `tools/build-use-effects.py` extracts on-use effects from the DB2
  chain (`ItemEffect` TriggerType 0 → `SpellEffect` direct stat auras →
  `SpellMisc.DurationIndex` / `SpellDuration` for length + `ItemEffect.CoolDownMSec`)
  → `_core/UseEffects.lua` (`lib:LoadUseEffects`, `{k, m, d, cd}` per item — 17 scored
  on Vanilla). `GetItemScore` folds in an **uptime-averaged** term,
  `Σ magnitude × min(1, d/cd) × premium × weight` (opts `useEffects` default on,
  `usePremium` default 1.3 for the controllable-burst bump). New reads:
  `lib:GetUseEffect(id)` (drives a "Use: +280 AP (20s / 2m)" display) and
  `lib:HasUnscoredProc(id)`. Location: `tools/build-use-effects.py`,
  `LibItemDB-1.0.lua`.

- **Chance-on-hit & extra-attack proc EP** — procs now score too. The missing piece —
  the proc _rate_ — isn't in the client (`ProcChance` is a `100`/`101` sentinel), so it
  comes from the **CMaNGOS** vanilla server DB. `tools/build-proc-rates.py` reads
  CMaNGOS's SQLite world DB and resolves each item's rate the way the server does:
  `item_template.spellppmRate` (tuned PPM — Thunderfury 6, Ironfoe 0.8), else a real
  `spell_template.ProcChance`, else `GetWeaponProcChance`'s default of **1.08 PPM** for
  un-tuned "chance on hit" weapons (they all normalize to one constant PPM). Joined by
  item ID onto the effect read from the client → `_core/UseEffects.lua`
  (`lib:LoadProcEffects` / `lib:GetProcEffect`). `GetItemScore` prices each proc by
  bucket: **buff** (stat × uptime), **damage** (DPS → attack power at 14 AP = 1 DPS →
  weight; **extra-attack** procs like Ironfoe/Flurry Axe fold in as `extraSwings × avg
  weapon damage`), **heal** (HPS → healing weight), **mana** (→ mp5); rate is `ppm/60`
  (weapon-speed-independent) or `chance × hitsPerSec`. **181 procs + 17 on-use score**
  on Vanilla. Proc rates are facts from **CMaNGOS** (GPL-2.0), credited. Location:
  `tools/build-proc-rates.py`, `build-use-effects.py`, `LibItemDB-1.0.lua`.

- **`GetSetBonusEP`** — `lib:GetSetBonusEP(setID, classID, spec)` → `{ [threshold] = ep }`,
  the EP of each set-bonus _stage_ (only the flat-stat ones — proc bonuses score 0 and are
  omitted). A consumer that knows how many pieces are equipped sums the stages it's crossed,
  which is the _real_ set contribution — vs. the flat per-piece amortization
  `GetItemScore(opts.setBonus)` uses as a rough ranking proxy. Location: `LibItemDB-1.0.lua`.

- **`GetItemScoreBreakdown`** — the itemized version of `GetItemScore` for a "why this
  EP" tooltip: `{ total, parts = { {kind, key, label, value, weight, ep}, … } }`. Each
  contributing stat is its own row (`value × weight = ep`); set bonus, and every on-use
  and proc effect, are their own rows too. Guaranteed **by construction** — it calls the
  same scorers with the same `opts` — so `total == GetItemScore(…)` and `Σ parts.ep ==
  total`. Generic Attack Power is one row (the winning melee/ranged, never both). The hot
  path (`GetItemScore`/ranking) is untouched — the scorers only allocate rows when a
  collector is passed. Location: `LibItemDB-1.0.lua`.

- **Scoring-model table** — a separate `_core/ScoreModel.lua`
  (`lib:LoadScoreModel` / `lib:GetScoreModel`, `tools/build-score-model.py`) holds
  **our** MIT modeling constants — the on-use burst premium (moved out of hardcode),
  the per-class proc trigger rate (`hitsPerSec`; a paperdoll overrides at score time),
  and `epPerHPS` (heal-per-second → healing power) — kept **separate** from the licensed,
  immutable HawsJon weights in `BiSWeights.lua` so their data is never touched. Per-class
  overrides merge over a baked `DEFAULT_MODEL`. (Damage procs need no constant — DPS is
  priced as attack power via the fixed 14 AP = 1 DPS.)

### Bug Fixes

- **Attack Power double-counted on generic-AP effects** — a generic "+X Attack Power"
  is stored in DB2 as **two** auras (99 melee + 124 ranged), because in-game generic
  AP raises both attack types. Emitting both keys and summing scored the boost twice
  for any class whose melee and ranged AP weights are equal (a hunter), so Earthstrike
  read 52 instead of its true 26 and wrongly outranked always-on trinkets like Drake
  Fang Talisman. `scoreStats` / `scoreUseEffects` now take `max(meleeAP, rangedAP)`
  instead of summing — it auto-picks the attack type each class actually uses (ranged
  for a hunter, melee for a warrior). Passive `GetItemStats` reports generic AP once,
  so the walk path was never affected (0 `_core` items carry both keys). Location:
  `LibItemDB-1.0.lua`.

### Known Gaps

- **Some procs stay flagged, by design** — enemy debuffs (an armor/stat reduction _on
  the target_), pure-utility procs (stun, snare, dispel), and the rare proc with no rate
  in any CMaNGOS tier aren't scored; they're flagged (`lib:HasUnscoredProc`) so a
  consumer can caveat them and never hide a known-BiS item on a low score.
- **Extra-attack EP is a floor** — it counts the weapon's _base_ swing damage; a real
  extra swing also gets AP/crit scaling and can chain-proc, so the true value is higher.
- **Caster flat-damage procs** price via attack power (14 AP = 1 DPS), not spell power —
  fine for physical classes, an approximation for casters. A follow-up.

---

## [v0.4.0] (2026-07-05) - Drop sources, Best-in-Slot / EP, class & faction filtering

### New Features

- **Drop sources** — each item now carries the instance + boss that drops it,
  built offline from **AtlasLootClassic** and re-expressed in LibItemDB's own
  schema. The Classic client ships no Dungeon Journal, and the obvious client-DB2
  fallback (the _Retail_ Journal, read from wago.tools) was audited against
  AtlasLoot and found **~40% incomplete** for Classic — missing whole
  Cata-revamped/restructured instances (Scholomance, Upper Blackrock Spire,
  Scarlet Monastery, Ragefire Chasm) and 10–25% of drops even on the un-revamped
  raids (Molten Core 77%, Blackwing Lair 91%) — and flat wrong-era for Onyxia /
  Zul'Gurub / Naxxramas. So AtlasLoot is the authoritative source.
  `tools/build-sources.py` parses `AtlasLootClassic_DungeonsAndRaids/data.lua`
  (`data["Key"].items[].npcID` + `{slot, itemID}` rows), intersects each itemID
  with the version's built `_core` (so a version only carries drops for content
  whose items it ships), and emits `_core/Sources.lua` (item→boss graph,
  boss→instance) + `_core/SourceNames.lua` (instance + boss display names).
  Coverage per version: **33 instances** — every raid and dungeon plus a
  synthetic **World Bosses** instance (Kazzak, Azuregos, the four Emerald
  dragons): Vanilla 2,227 items / 306 bosses, TBC 2,240 / 308, Mists 2,248 / 307.

  We do **not** ship AtlasLoot's file — which-item-drops-from-which-boss is fact,
  not copyrightable expression, so only the facts are extracted; AtlasLootClassic
  (GPL-2.0, github.com/Hoizame/AtlasLootClassic) is credited in every generated
  header and in the README. Instance key is AtlasLoot's stable data key (a string,
  e.g. `"MoltenCore"`); encounter key is the boss npcID. `core_ids()` skips
  `Sources*` files (they key instances by `["Name"]=`, not item IDs).

- **LibItemDB API** — loaders `lib:LoadSources(source, items, instances)` and
  `lib:LoadSourceNames({ inst=, enc= })` (instance keys may be strings); readers
  `lib:GetSources(itemID)` → `{ { instanceKey, instance, boss, encounterID,
  source }, … }`, `lib:GetInstanceItems(instanceKey)`, `lib:GetInstances()`,
  `lib:GetInstanceEncounters(instanceKey)`, plus `lib:HasSources(id)` /
  `lib:HasSourceData()`. An item that drops off several bosses/instances lists
  them all. Library MINOR bumped 5 → 6 (additive). Location: `LibItemDB-1.0.lua`.

- **Source audit tool** — `tools/audit-sources.py` cross-checks the shipped
  AtlasLoot data against the wago Retail Journal (an independent second opinion,
  not shipped) and reports where they disagree — candidate omissions to review.
  This is how the ~40% Journal-incompleteness above was measured.

- **Best-in-Slot (provider model)** — the fixed BiS gear set per class/spec/phase,
  built from **WoWSims** (MIT, github.com/wowsims) `ui/<spec>/gear_sets/*.gear.json`
  by `tools/build-sources.py`'s sibling `tools/build-bis.py` (positional 17-slot
  `items` array → slot key; phase from filename). Shipped as the `"wowsims"`
  provider; `lib:LoadBiS(source, data)` lets any addon or the user register/replace
  a list under another source name and pick it with `lib:SetDefaultBiSSource`. API:
  `lib:GetBiS(classID, spec, phase)`, `GetBiSItem`, `GetBiSSpecs`, `GetBiSPhases`,
  `IsBiS(itemID)` (reverse). Vanilla: 42 sets across 8 classes. `_core/BiS.lua`.

- **EP ranking + per-raid BiS** — the payoff of combining drops + weights + stats.
  `tools/build-bis-weights.py` extracts **HawsJon's Classic stat weights** (the
  community-standard set Pawn auto-installs on Classic) from `ClassicHawsJon.lua`
  (github.com/VgerMods/Pawn) — resolving each `<Rating>Per` level-60 conversion to a
  per-1% weight and mapping HawsJon's stat names to our keys → **37 specs / 9 classes**
  in `_core/BiSWeights.lua` (`lib:LoadBiSWeights`, provider model). Values are used
  **unchanged** (immutable read-only `"hawsjon"` scale; players layer their own via
  `LoadBiSWeights`); HawsJon / Pawn / Vger credited (CC BY-NC-ND). _(WoWSims'
  hardcoded `epWeights` were dropped — they're miscalibrated for Classic, e.g. Hunter
  Agility 0.64 vs Ranged AP 1.0 inverted, which sank agility gear like Ossirian's
  Binding to ~#30; with HawsJon it correctly ranks #2 of 701 belts.)_ EP weights now
  carry their **own default** (`"hawsjon"`), separate from the fixed-set default
  (`"wowsims"`); `Get/SetDefaultBiSSource`, `GetBiSSources`, `GetBiSSpecs` are
  weight-scale-scoped (what a player's in-game weight editor picks). Runtime scores
  `Σ(stat × weight)` over `GetStats`:
  `lib:GetItemScore(itemID, classID, spec, opts)`, `lib:RankItems(ids, …)`,
  **`lib:GetRaidBiS(instanceKey, classID, spec)`** (an instance's drops ranked —
  "what to want from this raid", `opts.perSlot` groups by slot), and
  `lib:GetSlotRanking(classID, spec, slot)` ("top N helms, in order"). Weapon DPS
  is weighted per hand (`DPS_MAINHAND/OFFHAND/RANGED`) resolved by equip slot;
  fragmented AP/mp5 keys are aliased. Verified: Warrior MC ranking leads with
  Bonereaver's Edge; Mage MC ranking is entirely different and correct.

- **On-equip stat enrichment** — vanilla implements hit/crit/spell-hit/spell-crit
  as on-equip **spell effects**, not `ItemSparse` stat fields, so `GetItemStats`
  (and the walk) never reported them — leaving ranking blind to the stats that
  matter most. `tools/build-equip-stats.py` recovers them from the same DB2 chain
  `build-effects.py` uses (`ItemEffect` TriggerType 1 → `SpellEffect` auras 52 crit
  / 54 hit / 55 spell-hit / 552 spell-crit, value = base+1), emits `_core/
  EquipStats.lua`, merged into `GetStats`/`Search` via `lib:LoadEquipStats`.
  Vanilla: 2,660 items (Lionheart Helm → CRIT_PCT=2, HIT_PCT=2, etc.).

- **Set bonuses** — what naive scorers miss. `tools/build-sets.py` reads DB2
  `ItemSet` (membership) + `ItemSetSpell` (threshold → spell) → `SpellEffect`,
  decoding flat-stat bonuses into our vocabulary (proc bonuses kept but empty) →
  `_core/Sets.lua`. API `lib:GetItemSet(itemID)`, `lib:GetSet(setID)`,
  `lib:GetSetBonusStats(setID, pieces)`; `GetItemScore(..., {setBonus=true})` adds
  a set piece's amortized bonus EP. Vanilla: 481 sets, 1,251 bonus thresholds
  (Devilsaur 2pc → +2% hit, Arcanist 3pc → +18 spell power, etc.).

- **Realm-aware data (Era vs SoD / Anniversary)** — the 1.15 client's DB2 is a
  superset: original vanilla items (ID < 25000) _plus_ the SoD / Fresh-Anniversary
  reissues and new items (ID >= 25000, mostly 200000+). Loading all of it mixed the
  two, so on an Era realm consumers saw duplicate / sourceless seasonal rows (e.g.
  "Crown of Destruction" as both 18817 and its reissue 228291). `tools/split-
  seasonal.py` now partitions each version's item-keyed data — base stays in place,
  the >= 25000 items move to `Data/<Version>/_seasonal/` — and the overlay files
  self-guard on the new `lib:IsSeasonalRealm()` (`C_Seasons.GetActiveSeason` /
  `C_SeasonInfo.GetCurrentDisplaySeasonID`; seasons 2 SoD / 11 Fresh / 12
  FreshHardcore). Era / Hardcore load original-Classic only; SoD / Fresh also load
  the overlay — automatically, so consumers need no season logic. No data is
  discarded. Vanilla: 17,595 base + 6,535 seasonal items. Also adds `lib:GetSeason()`.

- **Faction filtering (Alliance / Horde)** — faction-restricted gear isn't flagged by
  a race mask (`AllowableRace` is -1 for both "Highlander's" Alliance and "Defiler's"
  Horde items). `tools/build-factions.py` derives the side from **three** signals →
  `_core/Factions.lua` (`lib:LoadFactions`, restricted items only, neutral omitted):
  (1) `ItemSparse.AllowableRace` race mask (Alliance 77 / Horde 178); (2) a required
  reputation only one side can earn (`MinFactionID` → `Faction.ReputationRaceMask_0`);
  (3) **PvP rank rewards** — "Grand Marshal's ..." (Alliance) and "High Warlord's ..."
  (Horde) have _identical_ DB2 rows (no faction field at all), so for items carrying a
  `RequiredPVPRank` the side is read from the faction-specific rank-title prefix (the
  two rank ladders are disjoint bar the shared rank-3 "Sergeant", left neutral) plus an
  explicit "Alliance"/"Horde" name word. **This is faction-only — it never filters on
  the player's rank**; a Horde player still sees every High Warlord's weapon whether or
  not they've earned it, only the Alliance ones drop out. 686 restricted items on
  Vanilla (was 240; +446 PvP rank rewards). The ranking APIs (`GetRaidBiS` /
  `GetSlotRanking` / `RankItems`) hide the **other faction's** items by default via
  `UnitFactionGroup` (opt out with `opts.allFactions`); `lib:GetItemFaction(id)` and
  `lib:GetPlayerFaction()` expose it. Also fixed `core_ids()` to skip the
  non-item-keyed `_core` files (Sources/SourceNames/BiS/BiSWeights/Sets/Factions).

- **Class filtering (a Rogue helm won't show for a Hunter)** — class-restricted gear
  is flagged by `ItemSparse.AllowableClass`, **but the dungeon sets (D1/D2), the AQ40
  tier-2.5 sets, the Naxx T3 sets and Atiesh are mis-flagged as all-class** — every
  Bonescythe (Rogue T3) piece and Atiesh come back usable by everyone (and T3 flags
  are even inconsistent _within_ a set). `tools/build-classes.py` trusts `AllowableClass`
  where it's real (~1815 items) and **corrects the mis-flagged sets via set membership**
  (Bonescythe → Rogue, Cryptstalker → Hunter, …; 271 items across 36 curated sets) plus
  a 4-item map for Atiesh (marked usable by the caster classes) → `_core/Classes.lua`
  (`lib:LoadClassRestrictions`, mask bit = `1 << (classID-1)`; **2,090** restricted items
  on Vanilla). The ranking APIs hide gear the ranked class can't use by default (opt out
  `opts.allClasses`); `lib:GetItemClasses(id)` / `lib:ClassUsable(id, classID)` expose it.
  This is **obtainability, not stats** — a hunter can't do the rogue/caster quest, so the
  item never appears; the hunter's own Cryptstalker/Beaststalker/Giantstalker/Lok'delar
  still rank.

- **Same-name dedup in rankings** — several item IDs can share one name and slot (the
  four class versions of **Atiesh**, a base item and its deprecated twin). Best-first
  rankings now keep only the highest-scoring one per (name, slot), which also auto-picks
  the class-appropriate variant (the caster Atiesh wins for a caster). Opt out with
  `opts.keepDuplicates`. Location: `RankItems` in `LibItemDB-1.0.lua`.

- **Hidden (test / placeholder / above-cap) items** — the client DB2 carries items
  no player of the version can obtain or use: never-implemented junk ("90 Epic Rogue
  Belt", "[PH]" placeholders, "Test …", "Deprecated …") **and** unimplemented /
  future-expansion gear with a normal name but a required level above the cap (e.g.
  **The Twin Blades of Azzinoth** and the **Warglaive of Azzinoth** pair, RequiredLevel
  70 in a level-60 game). These are **kept** in the DB for completeness but no longer
  **served**: `tools/build-hidden.py` flags them by two client-derivable signals —
  name pattern **and RequiredLevel > the version's level cap** (60/70/80/85/90, from
  wago `ItemSparse`) → `_core/Hidden.lua` (`lib:LoadHidden`, **927** on Vanilla: 910 by
  name + 17 by level, zero false positives — Atiesh/Thunderfury/Ashbringer stay).
  `GetInfo`/`GetLink`/`GetStats`/`GetSources` still resolve them, but `RankItems`/
  `GetRaidBiS`/`GetSlotRanking`/`Search` skip them by default (`opts.includeHidden` to
  include); `lib:IsHidden(id)` exposes the flag. (The "This was never available to
  players" tooltip line is the **ATT** addon's curated list — not a Blizzard string
  nor in client data — so we use the client-derivable signals instead; ATT's full
  never-implemented list could layer on later for below-cap cases.)

### Known Gaps

- **Wrath / Cata / Retail** — no drop sources: those versions have no `_core`
  item data yet (Wrath/Cata are unshipped placeholders; Retail isn't shipped by
  this library). Sources build on top of `_core`, so they follow once those
  clients are walked and `build-core` / `build-locales` run.
- **Localization** — instance and boss names are English-only for now (AtlasLoot's
  enUS keys), shipped locale-independent in `_core/SourceNames.lua`. Per-locale
  source names are a follow-up.
- **BiS / EP is Vanilla-only** — drops cover Vanilla/TBC/Mists, but BiS sets,
  weights, equip-stat enrichment and set bonuses ship for **Vanilla** only so far;
  TBC/Mists are a `build-bis*.py` / `build-equip-stats.py` / `build-sets.py` run
  away (WoWSims has `tbc-new` / `mop` repos) once validated.
- **EP is approximate** — a linear score (one opinion), not a full sim: stats we
  don't capture (**haste, expertise, defense, dodge, parry, block, weapon speed,
  school-specific spell power**) are unscored, so HawsJon weights for those stats are
  dropped and ordering can be off where they dominate. HawsJon covers all 9 classes ×
  their specs (37 scales); WoWSims still supplies the fixed **gear sets** and leaves
  several healer/tank/paladin sets blank, so `GetBiS` is thinner there than the DPS
  specs (the EP ranking still works for them). No class weapon/armor-proficiency
  filter yet, so an off-class weapon can rank for a spec. Equip auras for defense/
  dodge/parry (30/49/51) aren't decoded yet.
- **Seasonal overlay is coarse** — the `_seasonal` split separates original-Classic
  from everything >= 25000, but doesn't yet distinguish **SoD from Anniversary**
  within that range (no clean DB2 flag was found — they share the 200000+ block), so
  a SoD or Fresh realm loads the whole overlay. And the seasonal items carry
  stats/names/sets but **no sources or BiS** yet (AtlasLoot-classic / WoWSims-`classic`
  don't cover them; WoWSims has a separate `sod` repo). Both are follow-ups.

---

## [v0.3.0] (2026-06-01) - Consumable use-effect stats

### New Features

- **Consumable use-effects** — use-effect consumables (food, elixirs, flasks,
  potions, scrolls, jujus, …) now carry the stat buff they grant on use, which
  `GetItemStats` can't report. New offline pipeline `tools/build-effects.py`
  reads the static wago.tools DB2 chain: `Item → ItemEffect (ParentItemID,
  on-use TriggerType) → SpellID → SpellEffect (Effect 6 = APPLY_AURA)`, following
  the `EffectAura 23` periodic-trigger hop to the **Well Fed** spell for food.
  Auras are decoded to the SAME `KEY=val` vocabulary as gear stat blobs:
  `MOD_STAT` (29) → `ITEM_MOD_<STAT>_SHORT` (misc 0–4 = Str/Agi/Sta/Int/Spi,
  −1 = all), `MOD_RESISTANCE` (22, misc is a **school bitmask**) →
  `RESISTANCE<n>_NAME`, spell power / attack power / mp5 / healing → their
  `ITEM_MOD_*`, plus use-only keys `CRIT_PCT` / `SPELL_CRIT_PCT` / `HEALTH` /
  `MANA`. Value = `EffectBasePoints + 1` (the Classic fixed-effect convention,
  verified against Elixir of the Mongoose +25 Agi/+2% crit, Flask of the Titans
  +1200 health, Tender Wolf Steak +12 Sta/+12 Spi). Inclusion is gated on
  `InventoryType == 0` (non-equippable) so jujus (item class 12) are captured
  and gear/trinket on-use procs are excluded. Emitted locale-independent to
  `Data/<Version>/_core/Effects.lua`. Coverage: Vanilla 277, TBC 339, Mists 651
  consumables. Location: `tools/build-effects.py`, `Data/*/_core/Effects.lua`,
  the three flavour `.toc` files.

- **LibItemDB API** — `lib:LoadEffects(t)`, `lib:GetEffects(id)` (just the
  use-effect buff stats), `lib:HasEffects(id)`. The effect stats are merged into
  `GetStats` and `Search` (the stat filter and result `stats`), so a consumable
  is queryable by the stat it grants, alongside gear. Library MINOR bumped 4 → 5
  (additive). Location: `LibItemDB-1.0.lua`.

### Known Gaps

- **Mists combat ratings** — MoP rating buffs (crit / haste / mastery, via
  `EffectAura 189`, a combat-rating bitmask) aren't decoded yet, so rating-only
  consumables on Mists are under-captured; Vanilla/TBC are flat-stat and fully
  covered. `build-effects.py` logs unmapped auras. Adding `MOD_RATING`
  (CR bit → `ITEM_MOD_*_RATING`) is the follow-up.

---

## [v0.2.0] (2026-05-30) - TBC & Mists data + version-aware pipeline

### New Features

- **TBC and Mists coverage** — `Data/TBC/` (30,032 items, captured on the
  Anniversary client build `2.5.5.67511`) and `Data/Mists/` (88,259 items,
  Classic progression build `5.5.3.67509`), each in all 12 client languages
  with its random-suffix table. Joins the existing Vanilla data. Wrath and Cata
  have no live client yet (the Anniversary realms reach those phases later), so
  their `.toc` files stay empty placeholders until a client exists.

### Improvements

- **Version-aware pipeline** — `build-core.py` and `build-locales.py` now take
  just the Version (e.g. `build-core.py TBC`) and resolve the rest from the
  installed clients: they read `<WoW>/.build.info`, map each client by its build
  MAJOR to a Version (1→Vanilla, 2→TBC, 3→Wrath, 4→Cata, 5→Mists), auto-locate
  that client's walk SavedVariables, and fetch classID + localized names +
  suffixes from the matching wago build. This tracks the Anniversary realm's
  progression automatically — when it advances to 3.4.x, `build-core.py Wrath`
  resolves to it with no code change. `itemdb_common.py` gained
  `installed_clients` / `client_for_version` / `wago_build_for_version` /
  `togtools_sv`; `--sv` / `--wago-build` remain as overrides.

---

## [v0.1.0] (2026-05-30) - Stats, random suffixes, 12 languages, core/names split

### New Features

- **Enriched data: item level + full stats** — every item now carries its item
  level and the client's fully-aggregated stat set (the walk's `GetItemStats`,
  which includes spell power, mp5, spell healing/damage, resistances and armor —
  stats the raw wago stat columns omit). New API: `GetStats`, `GetItemLevel`, and
  stat-filtered `Search` (`stat`, `minValue`, `minLevel`, `maxLevel`), so e.g.
  "plate with strength" is answerable offline.
- **Random suffixes ("of the Bear")** — modern Era encodes a random suffix as a
  positive `ItemRandomProperties` ID in field 8 of the item link
  (`item:15218::::::1196`). The DB ships those (name + exact stat lines per tier,
  from wago `ItemRandomProperties` + `SpellItemEnchantment`). New API:
  `GetRandomProperty`, `GetRandomProperties`, `HasRandomProperty`,
  `BuildItemString`, `GetSuffixLink`, `ResolveSuffix`, and suffix-aware
  `ResolveName`. `BuildItemString(itemID, propID)` reconstructs a link the game
  renders the full, correctly-scaled tooltip from — no stats are computed or
  stored for the scaling; the client does it.
- **All 12 client locales for Vanilla** — `deDE, enGB, enUS, esES, esMX, frFR,
  itIT, koKR, ptBR, ruRU, zhCN, zhTW`. Names a locale hasn't translated fall back
  to English, so every language is complete (24,127 items, 2,033 suffix tiers).

### Improvements

- **core/names storage split (LibStub MINOR → 4)** — locale-independent data
  (quality, subclass, equip slot, item level, stats) now ships once in
  `Data/<Version>/_core/<Class>.lua`; only localized names ship per language in
  `Data/<Version>/<locale>/Names.lua`. New `lib:LoadCore` / `lib:LoadNames`
  (and `lib:SetBuild`); the old `lib:LoadClasses` is kept as a back-compat shim.
  This avoids duplicating the bulky numeric data across all 12 languages.
- **Pipeline rewrite** — replaced `tools/build-data.sh` with
  `tools/build-core.py` (walk SavedVariables → `_core/`, classID joined from
  wago's `Item` table since the walk's serialization drops it) and
  `tools/build-locales.py` (wago `ItemSparse.Display_lang` → per-locale names
  with English fallback; suffix tables via the now locale-aware
  `build-suffixes.py`), sharing `tools/itemdb_common.py`. Stats come from the
  walk; classID + translated names come from wago.
- **`Data/classic/` → `Data/Vanilla/`** to match the ProfessionDB layout; the
  Vanilla `.toc` lists the `_core` files (loaded once) plus every locale's
  self-guarded `Names.lua` + `RandomProps.lua`.

---

## [v0.0.1] (2026-05-30) - Initial library

### New Features

- **LibItemDB-1.0** — Standalone offline item database exposed as a LibStub
  library. Resolves item name ↔ id ↔ link and filters by type / subtype with no
  client cache required. API: `IsReady`, `Count`, `GetMeta`, `GetName`,
  `GetInfo`, `GetQuality`, `GetLink`, `HasItem`, `GetID`, `GetClasses`,
  `GetSubClasses`, `Search`, `Iterate`. Data is loaded via `LoadClasses` from
  shipped, pre-built data files (no end-user scan).
- **Classic (Era) enUS data** — `Data/classic/enUS.lua`, 24,069 items captured
  from client build 11508 via the TOG Tools Item DB builder. Bucketed by item
  class; each entry packs `name · quality · subClassID · equipLoc`.
- **Ships for every flavour except Retail** — per-flavour TOCs for Vanilla/Era
  (11508), TBC (20505), Wrath (30405), Cataclysm (40402), and Mists (50503). A
  flavour TOC lists its `Data/<version>/<locale>.lua` line only once that
  capture exists; until then it loads the library with an empty database.
- **Guild version-check** — `ItemDB.lua` registers a `{ GetName = "LibItemDB",
  Version }` host with VersionCheck-1.0 at `PLAYER_LOGIN`, so the library shows
  up in guild version checks like the rest of the TOG suite. Hard dependencies
  on **Ace3** and **VersionCheck-1.0** are declared in every `.toc` and in
  `.pkgmeta` (`required-dependencies`).
