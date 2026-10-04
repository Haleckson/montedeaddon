# Changelog

## [v1.8.0] (2026-09-25) - WoW Forever gets its own data tree, top-ups merge, peer review moves to the writ inbox, and every Classic tree is re-stamped

**Library MINOR 11 -> 12.** Three public behaviours changed, so a same-MINOR copy
must not be allowed to shadow this one. **`Data/` WAS regenerated**: every
Classic `_core` tree one flavour at a time (Vanilla, TBC, Wrath, Cata, Mists),
each diffed before the next, plus a new `Data/Forever` tree.

### Data

- **Classic `_core` trees regenerated.** Outside 12 Alchemy recipes the diff is
  header-only: each file now credits `tools/build_authoritative_data.py` and
  carries a `-- build <id>` stamp. Every per-file recipe count is unchanged.
- **The 12 TBC transmutes/flasks (28580-28591) now require 375**, not 385/390,
  in TBC, Wrath, Cata and Mists. Their tiers follow: TBC transmutes 28580-28585
  375/385/392/400 (was 385/388/392/400), TBC flasks 28586-28591 375/390/397/405
  (was 390/393/397/405); Wrath/Cata/Mists 375/376/377/380 (was a flat
  385/385/385/385, the TBC-only override clamped above those trees' own
  TrivialHigh of 380). Derived by the existing pattern-recipe tier rule.
- **Vanilla and TBC `AcquireMethods.lua` regenerated at the current pins**
  (peer review finding 12). Only the stamp line changed: the data had been
  right and the stamps stale.
- **New `Data/Forever` tree** from Forever's own DBC (1.60.1.69977): 2,511
  recipes across 10 professions, 12 locales, RecipeItems (1,859 of 2,664
  recipes have a teaching item) and AcquireMethods. No HiddenRecipes, Sources
  or trainer-derived `requiredSkill`: none of those sources carry Forever data.
- **MoP pin bumped 5.5.3.67509 -> 5.5.4.69934** (`tools/pdb_common.py`), the
  first 5.5.4 build `check-build-pins.py --locales MoP` reports complete for
  every locale. `Data/Mists` regenerated through all three builders (core +
  names, RecipeItems, AcquireMethods), each diffed: stamp lines only. Recipe
  counts (5,302 core, every locale), teaching items (3,026 of 5,456) and
  acquisition flags (62) are unchanged; `RecipeScrollPrefixes.lua` byte-identical.
- **Vanilla pin bumped 1.15.9.69109 -> 1.15.9.69722**, alone and after MoP,
  once `check-build-pins.py --locales Vanilla` reported it complete for every
  locale. Same three builders, same result: stamp lines only. 1,565 recipes
  (core and every locale), 1,074 of 1,645 with a teaching item, 28 acquisition
  flags, prefixes byte-identical.
- **TBC pin bumped 2.5.6.69110 -> 2.5.6.69795**, alone and after Vanilla
  validated, once `check-build-pins.py --locales TBC` reported it complete for
  every locale. Stamp lines only: 2,170 recipes (core and every locale), 1,453
  of 2,267 with a teaching item, 35 acquisition flags, prefixes byte-identical.
  Wrath and Cata were reported current by the 2026-09-23 pin check and were
  not re-swept here.

### Tools

- **New `tools/profcapture.py`: reads a TOGTools Profession Capture** and
  reports it against a shipped tree (default Forever). Forever has no emulator
  or AllTheThings data, so which recipes a player can obtain, and what trainers
  ask for them, can only come from a live client. At the operator's direction
  (2026-09-24) that capture is TOGTools' job (contract `e2868011`, TOGTools
  v0.9.0, schema 1); a walker visits trainers and recipe vendors and the
  SavedVariables come back here. Per shipped recipe the report lists trainer /
  vendor / drop / known evidence, recipes with none, spells the capture saw
  that the tree lacks, and trainer skill ranks that disagree with
  `requiredSkill`. It writes nothing under `Data/`. It carries its own strict
  Lua-literal reader, because `port_pm_data.py`'s regex comment strip is unsafe
  on SavedVariables full of names. It also reads TOGTools' NPC-free
  recipe-source walk (`profCapture.walk`, Forever/Retail only), which asks the
  client for the source text the Professions window shows under an unlearned
  recipe. That text is client-built and localized, so it is split into
  `Label: value` lines with colour codes removed, and the labels are reported
  verbatim instead of being given meanings here. A walked, unlearned recipe
  with no source text at all is reported separately as the strongest
  never-obtainable signal. `--selftest` passes 19 of 19. Its readers
  agree with `core_recipe_ids` on Forever (2,510 recipes, 1,859 teaching items)
  and Vanilla. **Not yet run on a real capture**: none exists yet.
- **Tested and ruled out: TOGTools' Item DB walk as evidence of
  obtainability.** In both Era walks, the teaching items of all 27
  AllTheThings never-implemented Vanilla recipes resolve on the server exactly
  as real ones do.

### Changed (library)

- **`LoadCore` / `LoadNames` MERGE instead of replace.** Only the fields a call
  supplies are written, driven by one `CORE_FIELDS` list that `LoadRecipes` also
  loops. The header always promised that other addons could "contribute /
  top-up" recipes; the old code blanked every field a top-up omitted and left a
  present-but-hollow recipe. Peer review finding 13, plus a follow-up that
  removed a second hand-written copy of the field list.
- **`GetGameVersion` can answer `"Forever"` or `"Unknown"`.** Interface 16001
  exactly is `"Forever"`, tested *before* the Vanilla branch; any other
  16000-19999 client, and anything at 60000+ (Mists is now bounded), is
  `"Unknown"` and loads no data (`IsReady()` false) instead of Era's or Mists'
  recipes as its own. Peer review finding 16 and thread 3900ffe9.
- **`LoadSources` counts true totals across a merge and copies instead of
  adopting.** An untruncated contribution was dropped from `.total` (3 + {2,
  n=100} reported 100, not 103), and the first caller's array was appended into
  by later merges. Peer review findings 14 and 15.

### New

- **`ProfessionDB_Camelot.toc` (WoW Forever, Interface 16001)** loads the
  library and the `Data/Forever` tree, so an addon that hard-depends on
  ProfessionDB is no longer refused on Forever (Dibs was) and gets real data.
- **A spec compiles every data file every TOC lists.** Only Vanilla/TBC files
  were ever executed by the suite; the first Forever build shipped a koKR
  Enchanting file with a raw newline inside a name string (spell 8694), which
  this caught. `lua_value` now escapes `\n` and `\r`. Every Classic file
  compiled, so no released data was affected.

### Changed (pipeline, `tools/`)

- **WoW Forever is a branch flavour** (`pdb_common.BRANCH_BUILDS`, pin
  `1.60.1.69977`, wago branch `wow_classic_beta`), kept off the Classic
  expansion axis: no emulator trainer tier, no emulator Sources, not part of
  `merge_expansions`. Those ship as visible gaps rather than borrowed Classic
  data.
- **Both DB2 schemas are read.** `pdb_common.item_effect_pairs` joins Forever's
  `ItemXItemEffect` where Classic has `ItemEffect.ParentItemID`, and
  `spell_effect_base_die` translates Forever's `EffectBasePointsF`. On Vanilla's
  cache both return exactly what the old reads did (16,944 pairs; 0 of 40,250
  SpellEffect rows differ).
- **12 TBC Alchemy overrides 385/390 -> 375** (28580-28591). The old values
  were the DBC trivial column, above TBC's 375 cap; Wrath, Cata and Mists all
  carry 375 in that column, and warcraft.wiki.gg reads 375 for all twelve.
  `manual_skill_overrides.json` now documents every source label in use.
- **`SHORT_ROW_RATIO` 0.80 -> 0.95, measured.** 201 legitimate same-expansion
  pairs bottom out at 99.3%; known short exports sit at 19-56%.
- **The builder now stamps every `_core` file with its build**, and
  `check-build-pins.py --stamps` checks every stamped file, not just
  `RecipeItems.lua` (peer review findings 11 and 12). It never prints an
  all-clear while files went unchecked, and a branch flavour with no tree is
  reported rather than failing the run (peer review thread 3de6a4bd).
- **`--builds <one flavour>` no longer overwrites `recipe_items_map.json`**,
  which the sources builder reads for every expansion; it is written only when
  the whole Classic axis was built.
- **`build-recipe-items.py`'s "gathering lines have no scrolls" check is
  Classic-only.** Forever teaches housing blueprints on Herbalism and Skinning
  ("Blueprint: Greenhouse", "Blueprint: Field Guide"), so the join is right.

### Changed (process)

- **Peer review, harness contracts and dependency contracts moved to the writ
  inbox.** `docs/AUDIT.md`, `Tests/HARNESS_CONTRACT.md` and
  `docs/DEPENDENCY_CONTRACTS.md` were imported and removed; git history keeps
  every committed line. The audit board's rounds 24-25 were never committed and
  survive as inbox threads only.
- **Suite 169 -> 184 specs**, 0 failed. The unanchored-tiers rule and the
  compile-every-listed-file spec both walk six trees now, `ProfessionDB_Camelot.toc`
  included.

### Documentation

- **README and CurseForge page brought up to the v1.8.0 tree.** Forever added
  wherever the flavours are listed, with what it lacks (sources, never-implemented
  list, trainer `requiredSkill`) stated beside it; the build-pin table and the
  CurseForge build list now read Vanilla `1.15.9.69722`, TBC `2.5.6.69795`,
  Mists `5.5.4.69934`; the "Mists is deliberately behind" paragraph is rewritten
  as history; the build-stamp paragraph no longer claims only `RecipeItems.lua`
  is stamped. Measured off the Forever tree for the unanchored-tiers table: 614
  unanchored, 14 absent-but-anchored, 26 with `requiredSkill` exactly 1 (totals
  now 61 and 218). Forever scroll coverage 1,859 / 2,664 (69.8%), 3 rank books,
  from its `RecipeItems.lua` header.
- **CurseForge v1.8.0 notes grouped under New / Changed / Fixed**, with the
  `fix:` prefixes dropped, and the Vanilla/TBC/Mists build moves added.

## [v1.7.0] (2026-08-20) - Trainer requirements are scoped per expansion, scroll prefixes ship their sample count, and Vanilla stops borrowing a later expansion's numbers

**This entry started as tooling-only and did not stay that way.** An earlier
draft of this paragraph said *"nothing in this entry changes a single byte that
reaches a player"*, which was true when it held only the harness pin and the
replication script. It is now false, and the correction is the headline:
**`Data/` is rewritten across all five expansions and the library gains a public
API return.**

**MINOR, not PATCH, and the deciding facts rather than the feeling:**
`GetRecipeScrollPrefix` returns a **second value** and `LibProfessionDB-1.0` is
at **MINOR 11**, which this project bumps only when the public API changes; a new
loader, `LoadRecipeScrollPrefixSamples`, ships **new data in all 60 locale
files** (12 locales x 5 games); and a new TBC trainer source was added to the
pipeline. All of it is backwards-compatible -- `GetRecipeScrollPrefix`'s first
return is unchanged, so no existing call site moves -- but additive is not
corrective.

**Read `Changed (shipped data)` before upgrading if you consume this library.**
Vanilla `requiredSkill` coverage drops about 25% on purpose, and
`docs/DEPENDENCY_CONTRACTS.md` section 6 carries the consumer rule that goes
with it.

### Fixed

- **`wow-version-replication.ps1` was replicating `Tests/`, `docs/` and
  `tools/` into the `_classic_` and `_anniversary_` installs on every sync,
  while reporting those exclusions as loaded.** `Convert-GlobToRegex` compiled a
  folder entry to `^Tests$`, which matches a FILE literally named `Tests` and
  nothing else. It could never have worked: `$isDir` was set from a trailing
  backslash, and a trailing slash is exactly what the BigWigs packager forbids
  (`release.sh`'s `parse_ignore()` trims a trailing `/*`, not a bare `/`, so
  `Tests/` would compile to `Tests//*` and match nothing), so a correct
  `.pkgmeta` can never set that flag. Fixed by promoting `$isDir` when a
  wildcard-free entry resolves to a real directory under `$Source`, the idiom
  already in `AceCommQueue-1.0:125-130`. The wildcard exclusion is load-bearing:
  `Test-Path` would glob a pattern and could promote an unrelated directory.

  This stopped being cosmetic when `Tests/wowapi` grew `mcp/` (a Python tree)
  and `conformance/` (a loadable addon with its own `.toc`), because a sync then
  installed a **second addon** into the other flavour installs. Raised as
  `docs/AUDIT.md` finding 2 and answered there. The `.pkgmeta` itself was
  already correct, so the released zip was never affected.

- **The same script replicated every dotfile it had not been told about by
  name.** The always-skip list was five explicit patterns covering `.git`,
  `.gitignore`, `.gitattributes` and `.gitmodules` -- i.e. exactly the dotfiles
  somebody had enumerated. `-DryRun` showed `.busted`, `.luacheckrc`,
  `.luarc.json`, `.markdownlint.json`, `.markdownlintignore`,
  `.github\workflows\release.yml` and `.vscode\tasks.json` all copying. This one
  cannot be delegated to `.pkgmeta`: the packager prunes dotfiles
  unconditionally in `copy_directory_tree()` (`-name ".*" -prune`), so a dot
  entry in an `ignore:` list is a no-op there and nobody writes one -- which
  makes this script the only place the rule can live. Replaced the enumeration
  with the general component rule `'(^|\\)\.'`. It is load-bearing rather than
  tidy: `.git` in these repos is a one-line gitdir pointer file (the real git
  dir lives outside the WoW tree), so replicating it aimed the copy at the wrong
  repository.

  Found by the `-DryRun` run that was verifying the fix above, not by reading.
  It is the third instance of one species in this repo, after finding 1 (a guard
  that could not fail the way the incident failed) and finding 2 (an exclusion
  that could not match the thing it named): **a mechanism that reports success
  while doing nothing**, made invisible by a startup banner that prints a count
  of rules parsed and reads as coverage.

### Changed

- **`Tests/wowapi` pin moved `59c4280` -> `27e8850`, 86 commits.** Suite
  **103 passed, 0 failed, 0 pending** before and after; `verify-addons` 150/150
  files, `verify-widgets` 27/27, `verify-libs` 8/8 with `LibProfessionDB-1.0`
  reporting 51 methods. **Nothing in those 86 commits reached this library**,
  and that is recorded rather than left as silence: the Adoption log carries
  several entries warning a consumer's suite may go red (`UnitName`/`UnitClass`
  answering per token, `SetCVar` firing `CVAR_UPDATE`, `ColorPickerFrame`
  copying its info, `GetTexCoord` returning eight values,
  `UIDropDownMenu_Initialize` running its initialiser, `Settings` category `ID`
  becoming a number, the drag/resize model), and none of them touched us because
  `LibProfessionDB-1.0` reads `GetBuildInfo` and `GetLocale` at load and no
  client API after. A green suite here really is a no-op.

### Documentation

- **`AttachExternalRecipeInfo` was documented in `README.md` and on the
  CurseForge page for three releases and HAS NEVER EXISTED IN THIS LIBRARY.
  Both references are removed.** A consumer following the documentation gets
  `attempt to call a nil value (method 'AttachExternalRecipeInfo')`, which is the
  worst grade of documentation defect -- not vague, not out of date, just
  describing a method that is not there.

  **How it happened, because the mechanism is reusable:** when the recipe-scroll
  API moved here from `LibItemDB-1.0` in v1.5.0, the delivery note in
  `docs/DEPENDENCY_CONTRACTS.md` listed this method as having *"came with the
  rest, on your reasoning -- it is keyed by spell and draws a recipe tooltip, and
  reads no item data at all."* The reasoning was sound and the method was never
  written. **The README was updated from the migration PLAN rather than from the
  migrated CODE**, and every later edit inherited the row without re-checking it.
  Verified now with `git log -S AttachExternalRecipeInfo -- LibProfessionDB-1.0.lua`,
  which returns **no commit at all**.

  **`ItemDB` and `TOGProfessionMaster` are told**, in an appended note in
  `docs/DEPENDENCY_CONTRACTS.md` under the original delivery. If either is
  feature-detecting with `if DB.AttachExternalRecipeInfo then` it has been
  silently taking the false branch since v1.5.0 and needs nothing; a direct call
  has been erroring.

- **`LoadRecipeScrollPrefixSamples` is documented.** v1.7.0 added a third loader
  reading `<locale>/RecipeScrollPrefixes.lua`, and the README's ingestion table
  listed only two. The same section warns that *"a parse anchored to the file
  rather than the loader will sweep unrelated tables together -- the mistake two
  independent scripts have already made here"*, and the count in that warning was
  itself now wrong. Both the table and the count are corrected.

- **Four stale figures corrected, each re-measured against the tree rather than
  carried forward.** These are the sort of number that goes wrong silently,
  because nothing recomputes a sentence:

  | Claim | Was | Is | Where it was checked |
  | --- | ---: | ---: | --- |
  | Vanilla scroll coverage | 1,073 (65.2%) | **1,074 (65.3%)** | `Data/Vanilla/_core/RecipeItems.lua:8` |
  | Vanilla synthetic descriptors | 572 | **571** | same header |
  | Vanilla never-implemented, shipped | 21 | **25** | `Data/Vanilla/_core/HiddenRecipes.lua:8` |
  | `Data/*/itIT/` files | 63 | **62** | counted off disk |

  The first two moved **in this release** -- the `is_obsolete` fix gave one more
  recipe a real teaching item, so it left the synthetic set. The third has been
  wrong since v1.6.0, when the extractor fix raised it from 21 to 25 and the
  README was not followed through. **The generators write their own counts into
  each data file's header**, which is why three of the four were checkable in one
  read: prefer the header to the prose.

- **The esES/esMX scroll-prefix note was internally contradictory and is now
  measured.** It read *"esES ships only 2 of 9 ... esMX has all 8"* -- nine and
  eight in one sentence. Measured on Vanilla: enUS derives **9**, esMX **8**,
  esES **2**. esMX is missing **Mining (`186`)**, which is the same profession
  whose enUS prefix rests on a single scroll -- so the locale gap and the
  sample-count feature are the same underlying thinness, and the README now says
  so.

- **The CurseForge page no longer lists Italian as a supported language.** It sat
  in a flat list of locales *"-- every official WoW locale"*, which reads as a
  promise to an Italian player. Italian is a **Retail** locale, cannot load on any
  flavour this library ships, and the text inside those files is English. It now
  has its own entry saying exactly that, rather than being quietly counted.

- **The CurseForge HTML is now PARSED rather than read.** Every review of that
  file to date checked it by eye or by grep, and a pre-release review nearly filed
  a false finding when its own output escaping manufactured a malformed
  `<\code>` tag that was not in the file. It parses clean: every tag balanced,
  every entity defined.

- **`docs/AUDIT.md`**: finding 2 answered FIXED in place, with the dry-run
  evidence both before and after. Its Status row could not be updated -- the
  enforced append-only law refuses both a rewrite and the documented
  strike-in-place shape when the target is a table cell -- so state is carried
  in an appended `## Status update` section instead, per the harness's own
  2026-08-14 instruction.
- **`Tests/HARNESS_CONTRACT.md`**: records the new pin (the `Pin:` line in the
  header is append-only and stale), and opens one contract on the contradiction
  above, where two protocol documents tell ~20 consumers to do something the law
  refuses.
- Both files gained a `charset-ok` declaration. They are developer threads that
  ship no text to the client, they are append-only in both directions, and each
  side quotes the other verbatim -- so neither side may normalise the other's
  punctuation, and without the declaration the charset law blocks every future
  response that has to quote an existing line.

- **`Get-PkgmetaIgnores` silently repaired input the packager breaks on, so the
  dry run could not fail on the one `.pkgmeta` defect that ships an empty zip.**
  `wow-version-replication.ps1:140-166`. The parser stripped trailing comments
  before reading a list item; the BigWigs packager does not. On
  `- "*.ps1"  # glob`, `release.sh`'s `yaml_listitem()` removes the opening quote
  and finds no closing one, the stray quote breaks the `eval` in
  `copy_directory_tree`, the destination lands empty, **every file is copied
  nowhere**, and the packager still exits 0 and uploads a ~108-byte archive.
  Because `-DryRun` is now the acceptance test for the two exclusion fixes above,
  the one check that most needed to fail on that file could not: a green dry run
  would have been produced by the exact `.pkgmeta` that ships an empty release.

  Now it **warns instead of repairing** -- the script's job is to agree with the
  packager, not to be kinder than it -- and the inline strip is anchored to a
  whitespace-preceded `#`, since `#` is a legal filename character.

  **Closing it introduced a regression in the same function, which is also
  fixed.** Anchoring the strip meant a column-zero whole-line comment inside the
  `ignore:` block no longer blanked; it survived as `# ...` and the next test
  read it as a new top-level YAML key, **terminating the block and discarding
  every entry after it**. So a fix aimed at one report-success-while-doing-nothing
  mechanism briefly installed another one, three lines away. Comment lines are
  now skipped outright before anything else looks at them. Our `.pkgmeta` keeps
  its comments above `ignore:` and would not have hit it.

  Verified: the parser still loads the same eight globs, no warning fires on the
  real file, and `WOULD` for `Tests|docs|tools` and for any dot component are
  both still 0. The guard itself is proven at the predicate level over seven
  cases, including `- "weird#name.lua"` surviving intact. It was **not** driven
  end to end from a genuinely broken `.pkgmeta`: a repo law refuses to write one,
  detecting the same empty-zip shape. Raised as `docs/AUDIT.md` finding 3.

### Fixed (data pipeline)

- **Trainer skill requirements were held in ONE flat map across every emulator
  source, so whichever source sat last in the list silently rewrote every other
  expansion's shipped data.** `extract_all_skill_ranks` in
  `tools/extract_emulator_trainers.py` returned a single `{spellId: rank}` dict
  built across all four world DBs, licensed by a comment at
  `build_authoritative_data.py:187-189` reading *"the data is build-agnostic
  (trainers are server-side, not per-client-build)"*. **That premise is false,
  and the sources themselves are the disproof:** `cmangos_classic` teaches Smelt
  Silver at 65 and `cmangos_tbc` at 75. "Not derived from a client build" does
  not imply "the same in every expansion". A flat map physically cannot hold two
  answers, so every build read whichever one was written last -- the
  cross-expansion merge that `build_authoritative_data.py:1528` states in as many
  words does not happen: *"Not merged across expansions -- each game folder is
  that build's point-in-time set."* **Two comments in one file asserting opposite
  things about whether expansion matters.**

  A second precedence rule was broken by the same mechanism, and nothing
  asserted it: the function's own docstring said *"SOURCES is ordered oldest ->
  newest ... so a straight overwrite as we iterate gives the right
  precedence"*, and `cmangos_tbc` had been appended to the **end** of `SOURCES`.
  The oldest non-vanilla source was overwriting the two newest. **A precedence
  policy expressed as list order is a policy an append can void.**

  Fixed by keying the map by expansion: `extract_all_skill_ranks` now returns
  `{expansion: {spellId: rank}}`, and `skill_ranks_for_expansion()` flattens it
  for one target build under one written rule -- **a build takes trainer values
  from its own expansion or any older one, never a newer one; within that set
  the newest wins.** `EXPANSION_ORDER` is the single place the axis is written
  down, so `SOURCES` order is now decorative and cannot express a precedence.
  `extract_recipes_for_build` resolves its `EXPANSION_BUILDS` label once at the
  top (it had been resolving it 200 lines later for `BUILD_EXCLUDED_SPELLS`) and
  passes it down. The false comment is replaced by its disproof, and the stale
  *"AzerothCore Wrath + TrinityCore Cata"* note in the `requiredSkill` priority
  chain now names all four sources.

  **Duplicate rows for one spell within a single source now take the LOWEST
  rank and every disagreement is printed**, replacing a dict assignment that
  made the shipped value depend on row order. `requiredSkill` answers "what
  skill do I need to learn this", so if any trainer teaches it at 310 the answer
  is 310. There are seven, all in `cmangos_tbc`, and six were unknown: spells
  10548 (230/235), 10619 (225/255), 19047 (230/250), 19058 (230/250), 26926
  (5/20), 29557 (310/315), 34983 (350/360).

  **This closes an open item that had two wrong hypotheses attached to it.**
  Four `Data/Mists/_core/` files -- Blacksmithing, Engineering, Jewelcrafting,
  Mining -- had been diverging from their committed state at an *unchanged* DBC
  pin, and had been blamed first on the `is_obsolete` fix changing a
  teaching-item tie-break and then on a stale builder. Both were wrong. It was
  the flat map, and scoping it reverted all four to byte-identical without
  anything else being touched. Raised and answered as `docs/AUDIT.md` rounds 7
  and 8.

- **The fix above shipped with the flat map still live for one expansion,
  because two lists had to agree and nothing checked that they did.**
  `skill_ranks_for_expansion` fell back to *"use every source"* for a label it
  did not recognise -- **which is the flat merged map, restored** -- and
  `EXPANSION_ORDER` ended in `"mists"` while `pdb_common.EXPANSION_BUILDS` calls
  that expansion **`MoP`** (only its Data folder is named `Mists`). So the MoP
  tree never recognised its own label and took the fallback for the whole of the
  change that was meant to remove it. **A fix for "a rule living in the
  incidental agreement of two things", carrying a rule living in the incidental
  agreement of two things.**

  **Data consequence: zero, and structurally rather than by luck.** With the
  label corrected the tree regenerates byte-identical. Scoped, MoP takes
  `vanilla -> tbc -> wrath -> cata`, there being no MoP trainer source; unscoped
  it took those same four plus a `"mists"` key nothing ever wrote to. **The
  newest expansion is precisely where "everything" and "everything not newer
  than me" coincide**, so the defect could not show itself in the output of the
  only tree it reached. Measured after the fix rather than predicted before it.

  Closed three ways, all of which were needed: `EXPANSION_ORDER` now spells the
  label `"mop"` under a comment saying so is load-bearing;
  `skill_ranks_for_expansion` **raises** on an unrecognised label instead of
  merging; and `build_authoritative_data.py` **asserts at import** that every
  `EXPANSION_BUILDS` label lowercases into `EXPANSION_ORDER`. **That assertion
  is what found this** -- it failed on its first run with `['MoP']`. Raised as
  `docs/AUDIT.md` round 10 finding 2.

- **Five pipeline guards were written in a construct Python is allowed to
  delete.** `python -O` and `PYTHONOPTIMIZE=1` strip `assert` statements
  outright, so each of these stopped existing on an environment variable with no
  code change: the ascending-major ordering check in
  `extract_emulator_trainers.py`, the `EXPANSION_ORDER` derivation guard in
  `build_authoritative_data.py`, and **the three partition guards in
  `build-recipe-items.py`** that assert no spell is in both the real and
  synthetic scroll tables, none is in neither, and no skill-rank book is given a
  synthetic scroll.

  The last three are the serious half: **they protect shipped data integrity and
  fail quietly.** All five are now `if not <cond>: raise ValueError(...)`, which
  no interpreter flag removes. **Lua `assert` in `Tests/` is untouched and
  correct** -- the busted runner has no `-O` and Lua's `assert` is an ordinary
  function call.

  **Measured rather than accepted from the language spec:** under `-O`,
  `assert [5,4,3,2,1] == sorted(...)` passes silently; the replacement raises
  under both plain `python` and `python -O` when fed a reversed
  `EXPANSION_BUILDS`. That red-test also closes a guard that had been reported
  twice as undriven -- **converting it is what produced a failure path worth
  driving.** `docs/AUDIT.md` round 14 finding 5.

- **`extract_recipes_for_build` no longer defaults an unknown build to its own
  build-id string.** The label lookup ended `, build)`, and a build-id can never
  be an expansion label -- so any build absent from `EXPANSION_BUILDS` would have
  carried that string into the trainer lookup and taken an unscoped map for its
  whole tree, as well as silently missing `BUILD_EXCLUDED_SPELLS`. There is no
  correct answer for a build with no pin, so it raises.

- **The trainer-extraction failure message promised a fallback the code
  refuses.** It said *"trainer-taught requiredSkill will fall back to SLA
  heuristic"*. It does not: the priority chain is `manual or scroll or trainer`,
  so with no trainer data the value is `None` and the field is **omitted** --
  and the chain rejects the SLA fallback precisely because it masks the gap.
  Post-388 that was actively misleading: an operator expecting heuristic values
  would get omissions plus placeholder difficulty tiers. It now says what
  happens, calls the result a bad build that must not ship, and points at
  `docs/DEPENDENCY_CONTRACTS.md` §6. `docs/AUDIT.md` round 10 finding 3.

- **The obsolete-item filter matched the ordinary English word "Old", so a real
  recipe scroll was thrown away and replaced with a fabricated one.**
  `tools/build-recipe-items.py` skipped any item whose name matched
  `(^|\W)(ZZOLD|OLD|TEST|DEPRECATED|\[PH\]|PH\b|UNUSED)` before the
  teaching-item join ran. `OLD` had no right anchor, so item **234255 "Recipe:
  Flask of the Old Gods"** was discarded as a Blizzard dev leftover. With no
  item left teaching craft **1213548**, the builder fell through to the
  synthetic path and shipped a made-up scroll for a recipe whose real scroll
  exists -- breaking the invariant that a recipe answers `GetRecipeItem` **or**
  `GetSyntheticRecipeScroll` and never the wrong one.

  Traced end to end on the cached build `1.15.8.67156` rather than inferred:
  `SkillLineAbility` puts craft 1213548 on skill line 171, `ItemEffect` gives
  item 234255 the spell 1213550, `SpellEffect` gives 1213550 an Effect 36
  granting 1213548, and `ItemSparse` names 234255. Every input the join needs
  was present; the filter ran first.

  **The interesting half is that the correct rule already existed in the same
  folder.** `tools/build_authoritative_data.py` anchored it as `\bOLD$` --
  trailing marker only -- under a comment reading *"Conservative on purpose:
  matches must be word-boundary or unique-bracket forms so the filter never eats
  a legitimate item."* Two implementations of one rule, drifted, one wrong. The
  bad copy's own comment claimed *"Same intent as the obsolete filter in the
  other build-\*.py scripts"*, which was false and read as a reason not to check.

  Fixed by removing the duplicate rather than patching it: the predicate is now
  `is_obsolete_item_name` / `OBSOLETE_NAME_PATTERNS` in `tools/pdb_common.py`,
  carrying the careful version verbatim, and both builders import it. Verified
  by running it: `"Recipe: Flask of the Old Gods"` is no longer obsolete while
  `"Pattern: Double-stitched Leather Gloves OLD"`, `"ZZOLD Design: ..."` and
  `"59 TEST ..."` still are. Measured blast radius on Vanilla is exactly two
  matching scroll names, one of each kind, so the live cost was one recipe --
  but the pattern was a standing trap for any future item named with "Old",
  "Test" or "Unused" as an ordinary word.

  Found by ItemDB, who declined to accept "build drift" for a row that looked
  missing and asked for it to be checked. Answered in full in
  `docs/DEPENDENCY_CONTRACTS.md`.

  **Regenerated, and the whole five-expansion diff is two lines in one file:**

  ```diff
  +[1213548]=234255            (into LoadRecipeItems)
  -[1213548]={171,233965}      (out of LoadSyntheticRecipes)
  ```

  Vanilla real count 1073 -> 1074, synthetic 572 -> 571, partition assertion
  still passing at 1645 of 1645. TBC, Wrath, Cata and Mists regenerated
  **byte-identical**. That is better evidence than the fix itself: it shows the
  corrected filter changed exactly the one thing it was meant to.

- **The stale DBC build pins are bumped, ONE AT A TIME with the diff read
  between each.** Vanilla `1.15.8.67156` -> `1.15.9.69109`, TBC `2.5.5.67511` ->
  `2.5.6.69110`, MoP `5.5.3.67509` -> `5.5.4.69383`. Wrath and Cata were already
  current. Each bump re-fetches that expansion's DBC CSVs and regenerates it
  through **both** builders -- `build_authoritative_data.py` for the cores and 12
  locales of names, then `build-recipe-items.py`.

  **`--builds <label>` is safe to use for one expansion at a time**, and that was
  checked rather than assumed: the spec-lock map at
  `build_authoritative_data.py:1497` iterates `EXPANSION_BUILDS` in full
  regardless of the filter, so restricting the emit does not shrink the union it
  is built from.

  **CORRECTED BEFORE RELEASE -- the paragraph that stood here was wrong.** It
  presented a table of changed skill values as "the drift between the two
  builds" and called them Blizzard tuning passes. **They are not build drift at
  all.** Every one of those values comes from the **TBC emulator trainer source
  added in this same release** (see below); measured afterwards,
  `cmangos_tbc_npc_trainer_template.sql` contains all of them and
  `cmangos_classic_*` contains none:

  | recipe | shipped | regenerates | in the new TBC trainer source |
  | --- | ---: | ---: | ---: |
  | Smelt Silver (2658) | 65 | 75 | **75** |
  | Smelt Bronze (2659) | 50 | 65 | **65** |
  | Smelt Tin (3304) | 50 | 65 | **65** |
  | Engineering (12895) | 205 | 200 | **200** |
  | Jewelcrafting (31048/31049) | 305 | 310 | **310** |

  **The reasoning that produced the wrong answer is worth more than the
  correction**, because it looked like evidence: the changes were argued to be
  genuine because `requiredSkill` and `difficulty[1]` moved TOGETHER. That
  coherence is manufactured -- the builder derives the difficulty tiers **from**
  `requiredSkill` at `build_authoritative_data.py:848-856`. Two fields moving
  together says nothing whatever about where the value came from, and it was
  used as the main argument.

  The pin bumps themselves stand; what was wrong was the claim about which
  changes they caused. Partition assertions unchanged on both (Vanilla
  1074+571=1645, TBC 1453+814=2267), suite green throughout, and the whole
  change set is raised for review in `docs/AUDIT.md` round 7.

  **Vanilla's was a restoration, not a move**: its shipped tree had already been
  generated at `1.15.9.69109` and only the pin had been left behind. It also
  closes the standing "build drift" disagreement with ItemDB, who were on 1.15.9
  while we were pinned to 1.15.8.

- **MoP's bump was attempted, FAILED VALIDATION, and is reverted -- and the
  pipeline now refuses the failure instead of shipping it.** With MoP at
  `5.5.4.69383`, `Data/Mists/zhCN/RecipeScrollPrefixes.lua` silently **lost two
  professions** -- Jewelcrafting and Inscription, 10 down to 8. Every count and
  assertion still passed: partition 3026+2430=5456, 5,302 cores, suite green.
  The file even wrote "8 professions" in its own header, so it read as a
  legitimate locale difference between builds.

  **wago's 5.5.4 zhCN and zhTW `ItemSparse` exports are incomplete at source**,
  and the items that vote for those prefixes were in the missing 80%. Probed
  rather than assumed: the response is `Transfer-Encoding: chunked` with **no
  Content-Length**, ends cleanly on a complete CSV row, and returns **exactly**
  5,981,882 bytes / 17,021 rows on every fetch -- against 88,671 for zhCN on
  5.5.3 and 88,753 for enUS on 5.5.4. Deterministic, so not a timeout and not a
  cut stream. `SkillLineAbility` has 621 Inscription rows on **both** builds, so
  nothing about the game changed, only what arrived.

  MoP is reverted to `5.5.3.67509` and regenerated from its intact caches; zhCN
  is back to 10 professions.

  **`wago_text` now refuses a short export rather than caching it.** The check
  is the row count against the same table and locale on another build of the
  **same expansion** -- and same-expansion is load-bearing, since Vanilla's
  `ItemSparse` is legitimately ~26% of MoP's and a sweep that ignored it
  produced 163 suspects of which 162 were noise. Nothing is written on failure,
  so a re-run retries the fetch rather than reusing a bad file, and a first-ever
  fetch with no sibling to compare against is allowed through rather than
  blocked.

  **The Content-Length check added alongside it is nearly useless here and is
  labelled as such**, because the first version of this entry claimed otherwise:
  wago sends no Content-Length on this endpoint, so it never fires. It is kept
  for other hosts. The row-count guard is what protects this pipeline.

- **`tools/check-build-pins.py`: how far each pinned DBC build has fallen behind
  its live branch, on demand.** Measured 2026-08-20 **before the bumps above** --
  three of five were behind and two current:

  | | pinned | newest live | branch | |
  | --- | --- | --- | --- | --- |
  | Vanilla | 1.15.8.67156 | 1.15.9.69109 | `wow_classic_era` | 3 behind |
  | TBC | 2.5.5.67511 | 2.5.6.69110 | `wow_anniversary` | 9 behind |
  | Wrath | 3.4.5.63697 | 3.4.5.63697 | `wow_classic` | current |
  | Cata | 4.4.2.60895 | 4.4.2.60895 | `wow_classic` | current |
  | MoP | 5.5.3.67509 | 5.5.4.69383 | `wow_classic` | 14 behind |

  **The branch is now pinned per expansion in `pdb_common.WAGO_BRANCH` and must
  never be inferred from the version major.** Finding "the newest build for this
  expansion" by matching on major produced two false positives, one of them
  badly wrong: `wow_classic_titan` **3.80.2** is **Titan Reforged**, a different
  product that answers to "3." and reads as a 14-build-newer Wrath, and
  `wow_classic_era_ptr` additionally carries **10.1 retail** builds, so "newest
  matching major" there is not an answer at all. TBC lives on
  `wow_anniversary`, not on `wow_classic_era`; Wrath, Cata and MoP share
  `wow_classic`, which carries 5.5 / 4.4 / 3.4 / 2.5 / 1.13 side by side and so
  still needs a major filter on top of the branch.

  The tool exits 1 when any pin is behind, 0 when all are current, and **2 when
  wago could not be reached** -- a checker that could not look must not report a
  pass. Read a non-zero exit as a question rather than a verdict: bumping a pin
  regenerates every file for that expansion through **both** builders across 12
  locales and changes what players receive.

- **The pinned Vanilla wago build is OLDER than the build the shipped data was
  last generated from, and the regeneration is what surfaced it.** The header
  stamp went backwards -- `client build 1.15.9.69109` -> `client build
  1.15.8.67156` -- so a previous generation used a newer build than
  `pdb_common.EXPANSION_BUILDS` pins, and the pin was never moved. This is
  exactly the "build drift" ItemDB raised and I twice set aside as not worth
  chasing; they are on 1.15.9 and we are pinned to 1.15.8. **Content cost today
  is zero** -- a full regeneration at 1.15.8 changed one row, so the two builds
  agree on everything else this builder emits. **The pin is deliberately not
  bumped:** doing so regenerates all five expansions against newer DBC for a
  genuinely large diff, which wants its own pass rather than riding along with a
  one-row fix. On the repo todo list.

### Documented (locales)

- **`itIT` cannot load on any Classic client, and is now labelled FORWARD-LOOKING
  instead of being described as correct.** Italian is a **Retail** WoW locale and
  is not offered on any Classic flavour: the original Mists of Pandaria shipped
  fully localised in Italian in 2012 and MoP Classic did not, which separates
  "the content was never localised" from "the Classic pipeline does not ship
  Italian" -- it is the latter. Every data file opens with a `GetLocale()` guard
  and this library ships no Retail flavour, so the **63** `Data/*/itIT/` files
  can never execute for a player.

  They are kept deliberately, not by inertia: Blizzard is being actively
  petitioned for Italian on Classic, the files are already correct and current,
  and re-adding after a delete costs a full regeneration. **The note now carries
  the drop trigger** -- if the package ever needs trimming this is the first
  thing to go, with the exact steps -- because "forward-looking" is otherwise how
  dead weight becomes permanent.

  **Two wrong justifications preceded this and both are recorded in
  `pdb_common.py` above the right one, because the failure is more instructive
  than the answer.** The first inferred what the client holds from an absence in
  a third-party export. The second said it did not matter either way -- sound
  reasoning that **dodged the question instead of answering it**, and that is
  what stopped anyone searching: once a question is moot you no longer need the
  answer, so you stop looking. The answer was one web search away. `docs/AUDIT.md`
  rounds 17-18.

### Changed (build pins)

- **MoP pin bumped `5.5.3.67509` -> `5.5.4.69032`. The builder fetched and
  cached the new build's tables and emitted a Mists tree identical to the old
  one.** That sentence is phrased around the RUN rather than the OUTPUT on
  purpose, and the reason is worth keeping: **on this tree a zero-diff is
  unfalsifiable.** `_core` files carry no build stamp, so a correct rebuild and
  a silently-skipped rebuild produce byte-identical output and **no artefact in
  the repo distinguishes them**. "The files are identical" therefore cannot be
  wrong in any observable way, while "the builder fetched `5.5.4.69032__*` and
  wrote them to the cache" can be -- so that is the claim being made. Raised as
  `docs/AUDIT.md` round 17.

  With that caveat stated: **no shipped byte changed.** Worth saying plainly,
  because "14 builds behind" sounded like a content gap and was not. The bump is
  hygiene -- it puts the pin on the era the client is actually in, so the next
  cross-repo comparison with `LibItemDB` starts from a shared build instead of
  rediscovering the difference.

- **It was pinned to `69032` rather than the newest `69383`, and that is
  deliberate.** wago serves individual `(build, locale)` exports
  **independently**, and a build being newer says nothing about whether it is
  fully served:

  | build | zhCN | zhTW |
  | --- | --- | --- |
  | `5.5.4.69383` (newest) | short, 17,020 recs | short, 50,141 |
  | `5.5.4.69155` | complete | short, 7,360 |
  | `5.5.4.69078` | not tested | short, 4,370 |
  | **`5.5.4.69032`** | **complete** | **complete** |

  **zhTW is the binding constraint and it is not monotonic** -- it is *worse* on
  two older builds than on the newest -- so "wait until wago fixes it" was never
  going to terminate. **A pin is only worth what you can generate from it, so
  the newest FULLY-SERVED build beats the newest build.**

  This corrects the previous note in `pdb_common.py`, which said the exports were
  *"incomplete at source"*. That claimed the gap was in Blizzard's data; it is
  not, and one fetch disproved it. The old comment is left standing in the file
  as the record of what was believed and what overturned it.

- **CORRECTION, and it reverses the two bullets above: `5.5.4.69032` IS NOT
  FULLY SERVED, the bump is REVERTED, and MoP stays on `5.5.3.67509`.** Both
  bullets are left standing because the reasoning in them is the thing that
  failed, and it failed in a way worth being able to read back.

  The regeneration was re-run and `_assert_not_short` refused **the first locale
  it fetched**: `ItemSparse` at `5.5.4.69032` for **`deDE`** returns **26,451
  rows against 88,754** on `69383` -- **30%**. Not zhCN. Not zhTW. A locale
  nobody had looked at.

  **The defect was the method, not the tool.** The table above sweeps exactly two
  locales, on the reasoning that zhTW was the worst case and therefore decisive.
  That reasoning can prove a build serves **zhTW**; it cannot prove a build
  serves **deDE**, and nothing had asked. `check-build-pins.py --locales` already
  scans all eleven non-mirrored locales -- the shortcut was taken by hand,
  outside the tool, because a full sweep is slow. **A completeness claim built
  from a sampled subset is not a completeness claim**, and "the binding
  constraint" was only ever the binding constraint among the locales fetched.

  **What this leaves behind is a MIXED-BUILD TREE, which is why it is a revert
  rather than a note.** `pdb_common` said `5.5.4.69032` while
  `Data/Mists/_core/RecipeItems.lua` was stamped `5.5.3.67509` -- the pin
  described a build the data had never been generated from. This repo's own
  record calls that outcome worse than a consistent old pin. Reverting makes the
  pin true and **changes no shipped byte**: re-running `build-recipe-items.py
  Mists` at `5.5.3.67509` completes and emits `RecipeItems.lua` byte-identical to
  what is committed.

  **It also retires the zero-diff caveat above, in the worst way.** Round 17
  flagged that a zero-diff on this tree is unfalsifiable, because `_core` files
  carry no build stamp and a correct rebuild is indistinguishable from a skipped
  one. `RecipeItems.lua` **does** carry a stamp, and it read `5.5.3.67509` the
  whole time -- so the run described as *"fetched and cached the new build's
  tables"* cannot have reached the emit, because the deDE fetch fails before it.
  **The stamp was sitting in the repo, unread, saying the bump had not happened.**

- **`check-build-pins.py` now asks the mixed-build question too, offline, and it
  runs BEFORE the network call.** The check above was done by hand. Doing it by
  hand is how it went unasked for a day, so it is a tool now:

  ```text
  python tools/check-build-pins.py --stamps   # offline, no network
  python tools/check-build-pins.py            # both checks
  ```

  It compares every pin against the `client build` stamp in that expansion's
  `Data/<game>/_core/RecipeItems.lua` header and reports `MIXED BUILD` when they
  disagree. **The two checks fail in opposite directions**, which is why both
  exist: a stale pin ships *consistent* data describing an older client, which is
  a question; a mixed build ships data from a build the pin does not name, which
  means nothing in the repo describes what players receive.

  **The ordering is load-bearing.** The offline half runs first and its verdict
  is printed even on the `wago unreachable` exit-2 path, because **a failed bump
  and a wago outage arrive together far more often than either arrives alone** --
  that is exactly the situation that produced this defect. A mixed-build result
  also decides the exit code, so a stale-pin `1` cannot mask it.

  **RED-TESTED, not assumed.** Re-pinning MoP to `5.5.4.69032` makes it exit `1`
  naming MoP and both builds; reverting makes it exit `0`. A missing or unreadable
  stamp is a failure rather than a skip, on the same rule that a checker which
  could not look must not report a pass.

- **The full eleven-locale sweep then ran, and MoP stays on `5.5.3.67509`
  because NO 5.5.4 build serves every locale.** This is the measurement the pin
  should have rested on in the first place:

  | build | short locales | count |
  | --- | --- | --- |
  | `5.5.4.69383` (newest) | zhCN, zhTW | 2 |
  | `5.5.4.69155` | ruRU, zhTW | 2 |
  | `5.5.4.69078` | deDE, esES, esMX, frFR, itIT, ruRU, zhTW | 7 |
  | `5.5.4.69032` | deDE, esMX, itIT, koKR | 4 |

  **`69032` does serve zhCN and zhTW in full**, so the two-locale table further
  up is accurate. It is simply the one pair of the eleven that made a build with
  four short locales look like the right answer.

  **Which way to look next, flagged as a hypothesis rather than a finding:** the
  two oldest builds scanned score worst (7 and 4) and the newest scores
  joint-best (2), so wago's exports appear to **fill in over time rather than
  rot**. If that holds, scanning further back is wasted effort and the move is to
  re-run the sweep once wago publishes a build newer than `69383`. Not proven --
  `69155` also scores 2, so the trend is not clean.

  **`_assert_not_short` would refuse any of these anyway**, so a premature bump
  fails the build rather than silently shipping a locale with entries missing.
  That guard is what turned this from a shipped defect into a caught one.

- **`wago.tools` returns intermittent `504`s on large exports** -- two separate
  fetches hit one during this work, and the regeneration failed twice before
  succeeding, once on the very last locale. Retry rather than concluding
  anything from a single failure. Cached tables make a retry cheap: the third
  attempt only had to fetch what the second had not.

### Changed (shipped data)

- **Vanilla `requiredSkill` coverage drops about 25%, and that is the intended
  outcome of the trainer-map fix above rather than a side effect of it.** The
  `Data/Vanilla/_core/` tree goes from roughly 1,551 `requiredSkill` values to
  **1,163** across nine professions. Those ~388 recipes were taking their value
  from **AzerothCore Wrath or TrinityCore Cata** -- exactly the cross-expansion
  merge the fix removes. `cmangos_classic` yields 472 spells against
  AzerothCore's 1,549, so Vanilla has the thinnest same-era trainer source and
  pays the most for scoping.

  **Checked as a design cost and not a parse bug before shipping it:**
  `cmangos_tbc` runs the identical flat parser and yields 791 precisely because
  a TBC world DB legitimately carries both eras' trainer rows, and most Vanilla
  `requiredSkill` values come from the recipe-scroll tier (`ItemSparse`), not
  the trainer tier.

  **The gap is shipped rather than the estimate because this file's own priority
  chain has said so since long before the question came up** (`:825-835`): a
  missing `requiredSkill` ships as **absent** so the gap stays visible, and
  shipping a heuristic *"masks the data gap and produces a false sense of
  accuracy"*. A Wrath trainer row standing in for a Vanilla one is a heuristic.
  **There is no rule that keeps the coverage and also fixes Smelt Silver** --
  `cmangos_classic` has no row for Smelt Silver, Smelt Bronze, Smelt Tin or
  Engineering 12895, so any newer-source fallback reintroduces the defect
  exactly.

  **The consumer note covers the tiers as well as the field, and that second
  half was nearly missed.** Removing a `requiredSkill` does not only blank a
  field -- it moves the recipe into the *unanchored* set, where `difficulty[1]`
  is a DBC placeholder of `1` rather than a real orange threshold. **About 93%
  of the 388 land there** (Vanilla carried ~1,551 `requiredSkill` values across
  1,565 recipes, so at most ~14 were unanchored before; it is 373 now, so at
  least 359 moved). A consumer told only "render `-` instead of `0`" would do
  exactly that and then print `1` as the threshold beside it -- **a made-up
  number, in the release that makes the rule matter most.** Everything written
  was true; the omission was the defect. `docs/AUDIT.md` round 21.

  Full blast radius, measured by regenerating all five `_core` trees rather than
  sampled: **Vanilla** nine professions (values removed); **TBC** Engineering,
  Jewelcrafting, Leatherworking, Mining, RecipeItems; **Wrath** Engineering,
  Inscription, Jewelcrafting, Mining; **Cata** unchanged; **Mists** unchanged,
  with the four diverging files reverted. Consumers notified in
  `docs/DEPENDENCY_CONTRACTS.md` §6 before release, not after.

### Documented (consumer rule)

- **When a recipe's crafting tiers are meaningless, that is now detectable from
  the shipped data alone -- and the obvious one-field version of the rule is
  wrong in both directions.** A recipe's orange tier is a placeholder exactly
  when **`requiredSkill` is ABSENT, AND `difficulty[1] == 1`**. It is the
  conjunction; neither condition alone will do.

  `difficulty[1]` has **two** writers, which is what breaks the single-field
  readings: the placeholder correction at `build_authoritative_data.py:892`,
  and the `[min_rank, ...]` construction 60 lines above it that takes the DBC's
  `MinSkillLineRank` directly. Measured across all five shipped trees rather
  than argued:

  - **`requiredSkill` absent but `difficulty[1] > 1` -- 29 Vanilla, 18 Mists.**
    Anchored by a real `MinSkillLineRank`; perfectly good data. A rule keyed on
    "`requiredSkill` is absent" discards 47 correct thresholds.
  - **`requiredSkill` present and `== 1` with `difficulty[1] == 1` -- 192 across
    all trees**, every one carrying `requiredSkill` exactly 1. Apprentice
    recipes genuinely learnable at skill 1 and genuinely orange from 1. A rule
    keyed on "`difficulty[1] == 1`" condemns 192 correct ones.

  Population of the real unanchored set: Vanilla **373**, TBC **3**, Wrath
  **245**, Cata **284**, Mists **824**. **Wrath, Cata and Mists were already
  carrying theirs before any change this week** -- only Vanilla's is new, and it
  is the same population as the 388 above.

  **Written in two places on purpose**, as a comment at
  `build_authoritative_data.py:892` and in `docs/DEPENDENCY_CONTRACTS.md` §6,
  with the caveat that the rule holds only while those two remain the sole
  writers -- a third anchoring route would silently invalidate it while
  consumers kept applying it. That is the same species as the `SOURCES`-order
  defect fixed above: **a rule living in an incidental property of the data
  rather than in code.**

  **DECIDED: no schema change.** The two candidates were omitting `difficulty`
  when the orange tier is a placeholder, or shipping an explicit unanchored
  flag. **Omitting is wrong** -- only tier 1 is unanchored, while tiers 2-4 come
  from real `TrivialSkillLineRankLow`/`High`, so it discards three good values
  to hide one bad one. **A flag is redundant** -- it would make every consumer
  learn a new field for something the two existing fields already determine.
  The one real argument for a flag was robustness, since a documented rule can
  go stale; that is answered below by enforcement rather than by schema.

- **The unanchored-tiers rule is now ENFORCED against the shipped tree, not just
  documented** -- `Tests/shippeddata_spec.lua`, five specs, suite **164 -> 169**.
  It walks all five game trees through their own TOCs and classifies every
  recipe, then asserts the invariant the contract rests on: **no recipe ever
  ships `difficulty[1] == 1` alongside a `requiredSkill` above 1.** A third
  anchoring route, or a change to the correction's gate, turns the suite red
  instead of turning the contract into a lie.

  **Two of the five specs pin the counter-example classes deliberately**, and
  they are load-bearing rather than decoration: one asserts that recipes exist
  with `requiredSkill` absent and `difficulty[1] > 1`, the other that recipes
  exist with `requiredSkill == 1` and `difficulty[1] == 1`. Each disproves one
  of the two tempting one-field restatements of the rule -- **both of which were
  proposed during review and measured down.** If either class ever empties, the
  conjunction has collapsed into a single condition and the contract should be
  simplified deliberately rather than by drift.

  **Red-tested, not assumed green:** injecting a fabricated `requiredSkill` on
  one spell failed the invariant spec naming the recipe and all five expansions
  it appears in. A corpus assertion (`> 10000` recipes classified) guards the
  whole block against passing vacuously, and the TOC map asserts all five
  flavours were visited. Coverage unchanged at **417/417**.

### Added (API)

- **`GetRecipeScrollPrefix` now returns the SAMPLE COUNT as a second value, at
  `LibProfessionDB-1.0` MINOR 11.**

  ```lua
  local prefix, samples = DB:GetRecipeScrollPrefix(186)   --> "Manual: ", 1
  local prefix          = DB:GetRecipeScrollPrefix(186)   --> "Manual: "  (unchanged)
  ```

  The prefix is a majority vote over real scroll names, and **Mining's whole
  vote is one scroll** -- so "Manual: Smelt Truesilver" is rendered for 22
  synthetic descriptors on the strength of a single sample, while
  Blacksmithing's "Plans: " is derived from 224. That is not wrong, and
  suppressing a low-sample prefix would cost those 22 a usable header. **The
  defect was that a consumer could not tell the two apart**, so it had no basis
  on which to prefer its own heading. A threshold decides that for everyone,
  once, invisibly; a count lets each consumer decide and can be ignored for
  free.

  **First return unchanged and first**, so no existing call site moves. **A nil
  prefix keeps a nil count, never 0** -- "no prefix" and "a prefix from no
  samples" must stay distinguishable, and the second is not a state that can
  exist. The count is also nil for data generated before this shipped, which
  reads correctly as *unknown* rather than as *zero*.

  Shipped as a second loader, `LoadRecipeScrollPrefixSamples`, riding in the
  same per-locale `RecipeScrollPrefixes.lua`: the existing prefix table keeps
  its shape, so an older data file still loads and no consumer branches on a
  union type. Regenerated across five expansions and 24 locales. Ten new specs;
  coverage back to 100% (417/417).

  Requested by ItemDB on 2026-08-06 with *"your call once you own it"*, and
  unanswered until now. Their instinct is what shipped -- the only thing that
  changed is where the number lives: in the data, rather than in a build report
  a human reads once.

- **`Iterate()`'s full walk now guards on the table it is about to index**
  rather than on its sibling key. Same loop, same behaviour, both paths still
  specced -- but guarding `pid` while indexing `slot` left the language server
  unable to narrow the type and reporting a possible nil index forever.

### Added (data pipeline)

- **`tools/check-build-pins.py --locales <expansion>` -- find a build whose
  every locale export is actually complete.** Written because a wrong diagnosis
  produced a wrong recommendation: the MoP pin bump was reported as blocked on
  wago's exports being *"incomplete at source"*, which asserts the gap is in
  Blizzard's data. **It is not.** Measured: `zhCN` is short on `5.5.4.69383` and
  **complete** on `5.5.4.69155`, while `zhTW` is short on both and *worse* on
  the latter. Individual `(build, locale)` exports fail **independently**, so
  the question is not "is wago fixed yet" but "which build is fully served" --
  a bounded search rather than an open-ended wait, and this answers it.

  **It streams with an early exit, and the exit helps the SHORT case rather
  than the complete one** -- a distinction worth stating because getting it
  backwards is what made three scans time out. Ids ascend in the export, so a
  high id only appears near the end (`zhCN` at `5.5.4.69155` reached id 100,011
  at row 82,483 of 88,671, **93% of a 33 MB body**), which means proving a
  locale *complete* costs almost the whole download. What the gate genuinely
  buys is the reverse: a short export is a clean contiguous **prefix** of the id
  space, so it is small and rejected fast. The practical consequence is to check
  the locale most likely to be short **first**.

  **The gate is derived from `enUS` on the same build, never hard-coded** -- a
  literal would silently become wrong for another expansion, which is the exact
  class of defect this file's own header already warns about.

  **HTTP `Range` would make the whole thing trivial and wago does not support
  it.** Since ids ascend, the last row carries the max id, so a tail read would
  answer completeness in one small request. Measured: `Range: bytes=-4096`
  returns **HTTP 200 with the entire 32,875,405-byte body**, not a `206` -- the
  responses are chunked with no `Content-Length`. Recorded so nobody re-derives
  it.

  `--start-at` skips builds already measured, because each one costs a full
  `enUS` download for the reference alone. `enGB` is not fetched at all: it
  mirrors `enUS`, so checking it would measure the same export twice and report
  a locale that is never downloaded.

- **A TBC trainer source, which did not exist.** `tools/emulator_data/` carried
  cmangos-classic (Vanilla), azerothcore (Wrath) and TrinityCore (Cata) and
  **nothing for TBC**, so TBC was the one expansion where trainer-taught recipes
  had no authoritative `requiredSkill` source at all -- which is the structural
  reason hand-curated overrides were reached for there.
  `tools/extract_emulator_trainers.py` gains a `cmangos_tbc` source over
  `cmangos/tbc-db`, and the CMaNGOS prep is now **parameterised by repo rather
  than copied**, on the same reasoning as the `is_obsolete` fix above: a second
  near-identical implementation is how the first pair came to disagree. Run:
  18 MB dump, `npc_trainer` + `npc_trainer_template` extracted, 5,908 trainer
  rows parsed.

  Also fetched `SkillRaceClassInfo` for `2.5.5.67511` (TBC Alchemy is
  `SkillTierID` 41). Recorded so nobody retries it: **`SkillTiers` is not on
  wago.tools at all** -- it 404s on all five pinned builds and wago's own `/db2`
  index lists only `SkillLine`, `SkillLineAbility`, `SkillLineXTraitTree`,
  `SkillRaceClassInfo`, `TradeSkillCategory` and `TradeSkillItem`. The tier's
  max-skill value is not obtainable from that source under any table name.

  **Why this went in now.** I had answered a consumer's question with "cannot be
  measured from this repo" because the cache held no `SkillTiers` -- mistaking
  the absence of a file in a *cache* for the absence of the data. A cache holds
  what was fetched, not what exists. The answer is withdrawn in `docs/AUDIT.md`
  along with what the measurements actually showed: TBC's own `SkillLineAbility`
  gives the twelve disputed Alchemy recipes `TrivialSkillLineRankLow` of exactly
  385 and 390 -- the same numbers as the overrides, and the same column
  `build_authoritative_data.py:825-832` explicitly refuses to use as a
  requirement.

### Added (tests)

- **`Tests/query_spec.lua` and `Tests/bootstrap_spec.lua`: 51 new specs, and
  line coverage goes from 78.68% to 100%.** Suite **154 passed, 0 failed, 0
  pending**; `LibProfessionDB-1.0.lua` 395/395 and `ProfessionDB.lua` 13/13.

  The uncovered block was not an odd corner -- it was the surface consumers
  actually call. `Search`, `Iterate`, `IterateEnchants`, `EnchantsForSlot`, the
  lazy enchant-index build and all ten field getters had never executed under
  test, and `ProfessionDB.lua` was at **0/13**: the bootstrap, its
  `PLAYER_LOGIN` frame and the VersionCheck-1.0 host had never run at all.

  Specced for the properties that fail silently rather than for the line count:
  every getter answering nil for an unknown recipe **and** an unloaded
  profession; the enchant index picking up recipes, enchants and names loaded
  *after* it was first built (driven from outside, so a fifth loader that forgot
  to invalidate fails here rather than passing a code read); `Search` treating
  its query as literal text and not a Lua pattern; `Iterate()` **skipping** an
  empty profession instead of stopping at it, which is reachable because
  `LoadCore(profId, {})` creates the slot; and both sides of every
  feature-detect in the bootstrap, including the bare-global
  `GetAddOnMetadata` branch that no client running this suite would take and the
  three ways VersionCheck can be absent.

  Iterator assertions sort or count rather than indexing a position, since
  `next` order is not stable, and the getter loops assert their own iteration
  count so an empty case table cannot report a pass having checked nothing.

### Known, and not fixed here

- **Line coverage is 78.68% (321/408), not 100%.** `ProfessionDB.lua` is
  **0/13** -- the bootstrap, its `PLAYER_LOGIN` frame and the VersionCheck-1.0
  host have never executed under test -- and `LibProfessionDB-1.0.lua` is
  321/395, with the uncovered block being precisely the surface consumers call:
  `Search`, `Iterate`, `IterateEnchants`, `GetEnchantsForSlot`, the enchant
  index build, and the ten one-line getters at `:646-687`. This corroborates the
  reviewer's own round-1 "Not covered" list rather than contradicting it. On the
  repo todo list; not attempted in this change.

  **Superseded later in this same unreleased entry** -- see "Added (tests)"
  above. Coverage is now **417/417, 100.00%**, across both files. The paragraph
  is left standing rather than rewritten because it records what was true when
  the gap was found.

- **`_core` files carry NO BUILD STAMP, and that is a PROVENANCE gap rather than
  a tidiness one.** "Which DBC build generated this file?" is answerable only
  from `RecipeItems.lua`; every `_core/<Profession>.lua` is silent. **It is what
  makes the MoP zero-diff above unverifiable** -- a correct rebuild and a
  skipped one are indistinguishable in the output. Not fixed here because
  emitting a stamp rewrites every `_core` file across five expansions and this
  release is already 97 paths, but recorded at its real severity: after two days
  spent on build provenance, this is the artefact that would have answered most
  of the questions. `docs/AUDIT.md` round 17.

  Related and smaller: every `_core` header still credits *"the
  TOGProfessionMaster authoritative-data pipeline"*, which moved into this repo
  in v1.6.0. Same reason for deferring, same file set.

- **A recipe with no `requiredSkill` ships `difficulty[1] = 1`, which is a wrong
  number rather than a visible gap -- and the trainer-map fix above gives that
  behaviour 388 more recipes in the Vanilla tree.** The tier correction at
  `build_authoritative_data.py:858` is gated
  `if difficulty[0] <= 1 and required_skill and required_skill > 1`, so with no
  `requiredSkill` the guard fails and `difficulty[0]` keeps the DBC placeholder
  **1**. Concretely, Vanilla Cooking spell 6499 goes from `{50, 90, 110, 130}`
  to `{1, 45, 90, 130}`. **An orange threshold of 1 is not an omitted field a
  consumer can render as "-"; it is a number a player reads and acts on**, so
  the gap-is-visible argument that justifies dropping the 388 does not extend to
  it. The behaviour predates this change -- every recipe with no `requiredSkill`
  was already doing it -- but the larger population is this change's doing.
  **Deliberately not fixed here:** the honest remedy is either to omit
  `difficulty` entirely when `difficulty[0]` is the placeholder, or to ship a
  flag marking the tiers unanchored, and both are shipped-schema decisions with
  consumers on the other end (`TOGProfessionMaster` reads `difficulty`). Raised
  in `docs/AUDIT.md` and flagged to consumers in
  `docs/DEPENDENCY_CONTRACTS.md` §6.

  **Superseded within this entry -- the deferral was wrong and the review said
  so.** Shipping the removal while filing the placeholder as a follow-up trades a
  possibly-wrong `requiredSkill` for a definitely-wrong `difficulty[1]`, 388
  times, using the very argument that rules the trade out: **the change that
  makes a value absent must not arrive before the code that handles absence.**
  The precondition is now met **without** the schema decision, because the
  signal is already in the shipped data -- see "Documented (consumer rule)"
  below. The schema question (omit `difficulty`, or add an explicit flag) stays a
  genuine follow-up rather than a gate.

- ~~**The per-locale `name`/`effect` files were not regenerated with the `_core`
  tree.** The rebuild ran `--core-only`, which is correct for a change that
  touches only locale-independent fields and avoids refetching twelve locales'
  `ItemSparse` -- but it means the `Data/<game>/<locale>/` files have not been
  re-verified against the new `_core`. The suite's shipped-data specs pass
  against the stitched view, which is evidence but not the same as a rebuild.~~

  **CLOSED, by running it rather than reasoning about it.** A full rebuild (no
  `--core-only`) across all five games and twelve locales -- **202,560 name
  entries** -- produced a diff **byte-identical** to the `--core-only` run: not
  one `Data/<game>/<locale>/<Profession>.lua` changed. That is the expected
  result and now a measured one, because the trainer-map fix touches only
  `requiredSkill` and `difficulty`, which are `_core` fields, while `name` and
  `effect` come from `SpellName` and `SpellItemEnchantment`. **`--core-only` was
  the right call and the tree is consistent.**

  The run also cleared the standing worry about the short MoP exports: at the
  current pins (`5.5.3.67509`) `_assert_not_short` did not fire, and
  `Data/Mists/zhCN/` and `Data/Mists/zhTW/RecipeScrollPrefixes.lua` both carry
  all **10** professions including **755** (Jewelcrafting) and **773**
  (Inscription).

## [v1.6.0] (2026-08-08) - Recipe sources move here, recipe scrolls reach all five game versions, the whole build pipeline moves here, and never-implemented recipes

### New Features

- **`GetRecipeSources(spellID)` at MINOR 10 — where a recipe comes from, with
  the npc ids AND their names.** Moved from TOGProfessionMaster, which shipped
  it as twelve files, 380,088 lines and 6.7 MB of a single **all-expansion
  merge** loaded by every client: a Vanilla player carried Cata's drop tables.

  It now ships per version, in **968 KB for all five combined** — and carries
  more than it did before, not less:

  - `DB:GetRecipeSources(spellID)` → `{ trainer = { { id, name }, … }, vendor =
    …, quest = …, container = …, drop = … }`, or nil.
  - `DB:GetRecipeSourceKinds(spellID)` → `{ trainer = true, … }`, the cheap form
    for a caller that only renders labels.
  - `DB:GetSourceName(npcID)` → the English name.

  **Each list carries `.total`, which is NOT always `#list`.** Lists are capped
  at 12 ids because 1,649 recipes drop from 50+ creatures apiece — Rough
  Grinding Stone from 951. Uncapped, the five versions came to 9.5 MB to say
  "drops from everything". Read `.total` for a count; iterate the list for
  examples.

  **Names are English only**, from the emulator world databases'
  `creature_template`, which is not localized — unlike recipe names, which ship
  in 12 languages. New per-version `_core/Sources.lua` + `_core/SourceNames.lua`,
  wired into all five TOCs.

- **The entire data pipeline now lives in this repo.** It was in
  TOGProfessionMaster and wrote *across the repo boundary* into this one, so
  ProfessionDB could not rebuild itself. All eleven tools moved, plus their
  caches. `tools/build_authoritative_data.py` regenerates the whole
  `Data/` tree byte-identically, verified before and after the move.

  New `tools/pdb_common.py` holds the build pins and shared helpers once.
  `tools/build-recipe-items.py` **could not run at all** here (it still imported
  ItemDB's `itemdb_common`) and now does. Two tools carried the same
  `_core`-parsing function under different names, already diverged; there is one
  now.

### Bug Fixes

- **`GetRecipeItem` answered `nil` for EVERY recipe on Wrath, Cata and Mists —
  the recipe-scroll data was only ever shipped for Vanilla and TBC.** When the
  scroll data moved here from `LibItemDB-1.0` at MINOR 8, only
  `Data/Vanilla/_core/RecipeItems.lua` and `Data/TBC/_core/RecipeItems.lua` were
  generated and wired into their TOCs. No such file existed on disk for the
  other three flavours, so on a Wrath, Cata or MoP client `lib.recipeItems`,
  `lib.skillRankBooks` and `lib.syntheticRecipes` all stayed **empty** and
  `GetRecipeItem(spellID)` returned `nil, false` unconditionally — which is
  indistinguishable from the legitimate "this recipe is trainer-taught" answer,
  so nothing surfaced it. Two consequences for a consumer: the real
  teaching-item tooltip never resolved (TOGProfessionMaster falls back to the
  crafted item), and **skill-rank books could not be filtered out**, because
  `isRankBook` is exactly what a consumer uses to exclude them — so *Expert
  Cookbook* (3413), the two First Aid manuals (7924 / 10846) and the Fishing
  books (7732 / 18248) rendered as craftable recipes with a nonsense
  `difficulty` of `{125,125,125,125}`.

  `tools/build-recipe-items.py` has been run for all three, and the outputs plus
  their per-locale `RecipeScrollPrefixes.lua` files wired into
  `ProfessionDB_Wrath.toc`, `ProfessionDB_Cata.toc` and `ProfessionDB_Mists.toc`.
  Coverage lands where the generator's own honesty notes say it should — Mining
  stays ~5%, Herbalism and Skinning 0%, First Aid low:

  - Wrath — 2,026 / 3,710 (54.6%), 10 rank books, 1,684 synthetic
  - Cata — 2,520 / 4,406 (57.2%), 10 rank books, 1,886 synthetic
  - Mists — 3,026 / 5,456 (55.5%), 6 rank books, 2,430 synthetic

  Caught by `Tests/shippeddata_spec.lua`, which fails when a data file on disk is
  in no TOC — it flagged all 36 new locale prefix files before they were wired.

- **Never-implemented recipes were being missed, because AllTheThings records
  the fact TWO ways and the extractor read one.** A node can sit under ATT's
  NeverImplemented tree (**by position**) *or* carry `u = 1` while sitting in the
  ordinary Professions tree (**by flag**). Only the first was handled, and the
  node constructor discarded the opts table entirely, so `u` was never even read.

  Reported against TOGProfessionMaster's Missing Recipes tab: **Darkspear**
  (`16987,{awp=70105,requireSkill=9787,u=1}`, filed under Blacksmithing >
  Weaponsmith) sat in players' lists while ATT's own tooltip said *"This was
  never available to players."*

  A second miss surfaced with it: the flag pass also required a **profession
  ancestor**, so **Steam Tonk Controller** (28327) — filed under a *zone* and a
  *holiday*, `u=1`, `awp=20300` — was skipped too. A `u = 1` recipe qualifies
  wherever ATT happens to have filed it.

- **Difficulty tiers could DESCEND, and ~15% collapsed orange onto yellow.**
  Reported in game as `185 185 205 225`. Two causes in two code paths:

  - `SkillLineAbility.MinSkillLineRank` is a placeholder `1` for scroll and drop
    recipes, so the builder substitutes `requiredSkill` — but then set yellow to
    `TrivialSkillLineRankLow` *or orange itself* when that was not higher.
    Yellow is now interpolated between orange and green instead.
  - The other path had no ordering guard at all, so where `MinSkillLineRank`
    exceeded `TrivialSkillLineRankLow` green landed **below** yellow: Cooking
    2548 shipped `[135, 135, 130, 170]`, Blacksmithing 2665 `[75, 75, 65, 80]`.

  Descending tier sets across all five versions: **37 → 0**. Duplicated
  orange/yellow: **2,651 → 338**. The remaining 338 are deliberate — those
  recipes have `TrivialLow == TrivialHigh`, one threshold and no band, and
  inventing a spread would be fabrication.

- **`IsHiddenRecipe(spellID)` at MINOR 9** — is this a recipe that was never
  obtainable in the live game? Some recipes shipped in the client's spell tables
  and nothing in the world ever taught them: no trainer, no vendor, no drop, no
  quest.

  **No client signal reveals this.** The spell resolves, the crafted item
  resolves, the reagents resolve, and the recipe sits in `SkillLineAbility`
  exactly like a real one — so every generic "is this real on this client" check
  passes it. The only distinguishing fact is historical, which is why it has to
  ship as data.

  - `DB:IsHiddenRecipe(spellID)` → `true` when the recipe was never obtainable.
  - `DB:GetHiddenRecipes()` → the raw `{ [spellID] = true }` map, read-only.

  Feature-detect it (`if DB.IsHiddenRecipe and DB:IsHiddenRecipe(id)`) so the
  call stays inert against an older ProfessionDB.

  **Deliberately narrower than "unobtainable":** it does not cover recipes that
  were once obtainable and later removed, nor holiday-gated ones. An id absent
  from the list is not thereby proven obtainable.

- **`IsAutoTaughtRecipe(spellID)` / `GetAcquireMethod(spellID)`, also MINOR 9** —
  the other half of "why does this recipe say Unknown?". Trainer, vendor, drop and
  quest sources all come from community server databases, and a residue is left
  that none of them mention — 87 of 1,261 Vanilla recipes.

  **26 of that residue is not missing data.** `SkillLineAbility.AcquireMethod = 1`
  means the recipe is granted when the character learns the profession, so nothing
  in the world teaches it: Minor Healing Potion, Rough Sharpening Stone, Linen
  Bandage, Smelt Copper. A browser should say *"Learned with profession"*, not
  *"Unknown"*. Verified to discriminate rather than assumed — those read `1` while
  Bleakwood Hew, a world drop, reads `0`.

  The **raw value** is shipped, not a boolean: TBC and Wrath each carry three
  recipes with `AcquireMethod = 3`, which a boolean would silently discard. `0` is
  omitted, being the default and the large majority. New per-expansion data file
  `Data/<Version>/_core/AcquireMethods.lua` (28 / 35 / 39 / 35 / 62 entries),
  built by `tools/build-acquire-methods.py`, wired into all five TOCs.

- **New data file per expansion, `Data/<Version>/_core/HiddenRecipes.lua`** —
  67 Vanilla / 87 TBC / 129 Wrath / 184 Cata / 231 Mists never-implemented
  recipes. Of those, 25 / 37 / 41 / 58 / 90 are recipes this library actually
  ships; the rest are kept anyway, so adding recipes later cannot silently
  un-hide one. Wired into all five TOCs.

  Counts include the two extraction fixes under Bug Fixes — 11 more shipped
  recipes are correctly hidden than the first pass found.

- **New build tooling, `tools/build-hidden-recipes.py` + `tools/att-nyi-extract.lua`.**
  The extractor **evaluates** AllTheThings' data under a Lua interpreter with
  stubbed constructors rather than parsing it — ATT ships each category file as a
  single minified line, one of them 1.5 MB wide, so text-matching would be
  guesswork. Same technique as LibItemDB's `tools/att_extract.lua`. Only nodes
  under ATT's Professions header (`-44`) and Recipes filter (`200`) are taken, so
  the ~2,800 hidden non-recipe items in the same tree stay LibItemDB's territory.
  The script refuses to write an empty file, which would silently un-hide
  everything.

### Improvements

- **The test suite now catches a data file that no TOC lists — the exact
  regression this addon has already shipped.** Vanilla's 13 Fishing files sat on
  disk, named by no TOC, executed by nothing, with every spec green. The guard
  written after that incident iterates TOC entries, so a file no TOC names
  produces no entry and stays invisible to it: it protects the other direction.

  `Tests/shippeddata_spec.lua` now also walks `Data/` off disk and requires every
  `.lua` under it to appear in at least one of the five TOCs. It matters because
  the generator writes files per flavour × locale × profession while the TOC
  entries are a separate edit, five times over — miss one and that flavour
  silently has no data for that profession, with consumers rendering an empty
  list rather than an error. Raised as `docs/AUDIT.md` finding 1.

### Credits

- The never-implemented list is derived from
  **[AllTheThings](https://github.com/ATTWoWAddon/AllTheThings)** (MIT). Their
  files are **not** redistributed — the extractor reads an installed copy at build
  time and only the resulting spell ids are re-expressed in this library's own
  format. A new Credits section in `README.md` records this alongside
  [wago.tools](https://wago.tools), the source of everything else.

---

## [v1.5.0] (2026-08-06) - Recipe scrolls move here from ItemDB; ids rebuilt from DBC

### New Features

- **Recipe-scroll data now lives here, at `LibProfessionDB-1.0` MINOR 8.** It
  moved from `LibItemDB-1.0` because every part of it is keyed by **craft spell
  id** — exactly as `recipes` already is — so it is recipe data, not item data.
  ItemDB keeps `GetLink` / `GetName`, which answer questions about an *item*, and
  a consumer now asks each library the question it owns.

  - `GetRecipeItem(spellID)` → `itemID, isRankBook` — the scroll that teaches a
    recipe, or **nil**, which is a real answer for roughly a third of recipes:
    they are trainer-taught and no such item exists.
  - `GetSyntheticRecipeScroll(spellID)` → a scroll-shaped descriptor for exactly
    those. Its exact complement — every recipe answers one or the other, never
    both — so a consumer can draw one tooltip shape throughout instead of a seam
    where the real scrolls run out. **It carries no item id and never will:** a
    fabricated id is permanently cache-cold and fails silently in every item API.
  - `GetRecipeScrollPrefix(skillLineID)` → the localized prefix (`"Plans: "`,
    and note frFR is `"Plans : "` with a space before the colon while zhCN uses a
    full-width one). Derived at build time from real scrolls, never transcribed.
  - `AttachExternalRecipeInfo(tooltip, spellID)` → attaches AllTheThings' lines
    to any tooltip. Keyed by spell, so it works for recipes with **no** scroll —
    the case that would otherwise get nothing. Never raises; ATT is optional.

- **`requiredSkill` is deliberately absent from the synthetic descriptor.** ItemDB
  shipped it and it was wrong for ~313 of 572 records: it read
  `SkillLineAbility.MinSkillLineRank`, which is a floor of 1 on eight of twelve
  skill lines rather than the skill needed, and rendered *"Requires Mining (1)"*
  on a recipe requiring 230. This library already carries the correct per-recipe
  value on the recipe, so a second copy could only ever let the two disagree.

### Bug Fixes

- **The TBC TOC was named `ProfessionDB_BCC.toc`, which no WoW client reads.**
  `_BCC` is not a flavour suffix the game recognises, so on a TBC client the file
  was skipped entirely and the game fell back to the base `ProfessionDB.toc` —
  Interface 11509, **Vanilla** recipes, flagged out of date in the AddOns list.
  Nothing errored; TBC users simply had the wrong expansion's data. Renamed to
  `ProfessionDB_TBC.toc`.

  Settled by counting Blizzard's own shipped TOCs rather than from memory:
  `_Vanilla` 40, `_TBC` 37, `_Wrath` 43, `_Cata` 56, `_Mists` 103, `_Mainline`
  156, and `_BCC` **zero**. ItemDB and TOGProfessionMaster were already on
  `_TBC`; this library was the only one out of step. Location: `*.toc`,
  `CLAUDE.md`, `wow-version-replication.ps1`.

- **All 13 Vanilla Fishing data files shipped in the package and were listed by
  no TOC**, so they were installed on every Vanilla client and never executed —
  the same shape as the wrong-library-handle fault above, one layer earlier.
  Every other flavour lists its 13; Vanilla listed none. Now wired in after
  `Firstaid`, matching the alphabetical order the other four use.

  Vanilla Fishing's two entries are both skill-**rank** books rather than recipes
  (spells 7732 and 18248 — *Expert Fishing - The Bass and You* and its Artisan
  counterpart), which is precisely what `GetRecipeItem`'s `isRankBook` second
  return exists to let a consumer filter out. Location: `ProfessionDB.toc`.

- **`itemId` — the recipe-scroll item — was wrong on 42 Vanilla recipes, and
  invented on ~54 more.** It was produced by a *name-match linker* in the
  generator: strip `"Plans: "` / `"Pattern: "` from an item name and match the
  remainder against a spell name. Every one of the 42 was a Season of Discovery
  reissue where the matcher bound the original Vanilla scroll to the seasonal
  spell. The clearest case is item **228118**, whose display name reads *"Plans:
  Stronger-hold Gauntlets"* while the spell it actually teaches is *Stronghold
  Gauntlets* — so a matcher pairs it with the seasonal recipe on its face, and
  the original loses its scroll.

  Replaced with the authoritative DBC join,
  `ItemEffect.SpellID → SpellEffect[Effect=36].EffectTriggerSpell`, which
  resolved **1,877 item→craft links on Vanilla** alone. Also locale-independent,
  where the matcher's prefix list was English-only and could never have worked
  for a `deDE` or `zhCN` pull.

- **A teaching item that does not exist could win the tie-break.** Where several
  items teach one spell the lowest id is kept — but `ItemEffect` can name an id
  with no `ItemSparse` row at all, and those ghosts sort low. Recipe 7443 picked
  6221 (nameless) over 6342 *Formula: Enchant Chest - Minor Mana*, and 25124
  picked 20751 over 20758 *Formula: Minor Wizard Oil*. Candidates must now exist.

### Improvements

- **Cross-checked against a second, independent extraction.** ItemDB derived the
  same mapping separately and the two now agree on **1,071 of 1,071** shared
  recipes, up from 987 of 1,029. Neither bug above was findable by a spec — both
  shipped a plausible number — and only two extractions disagreeing exposed them.

- **Offline test suite, on the shared WoWAPITesting harness.** 40 specs covering
  the flavour gate every data file guards on, the core/names stitch, and the fact
  that the applied-enchant catalogue is a **separate id space** from recipes:
  `2543` is *Westfall Stew* as a craft spell and *"Attack Speed +1%"* as a
  `SpellItemEnchantment`. That last one is pinned because two independent scripts
  mis-parsed it the same way — `Enchanting.lua` calls `LoadCore` at the top and
  `LoadEnchantsCore` 3,700 lines down, and a parse anchored to the file rather
  than the loader sweeps them together. Dev-only; not shipped in the package.

- **`Tests/shippeddata_spec.lua` executes the REAL data files, and it caught a
  release-blocking bug in this very release.** All 26 of the moved files still
  opened with `LibStub("LibItemDB-1.0")` — the handle they were generated with
  before the move — so Vanilla's 1,073 recipe items and 572 synthetic records,
  plus 24 prefix files (12 locales across both flavours), loaded into **ItemDB's**
  tables while this library's stayed empty.
  Every query returned nil and consumers silently fell back; nothing errored
  anywhere. Fixed in the shipped files **and** in the generator, so a rebuild
  cannot reintroduce it.

  The reason it got as far as it did is the part worth keeping: the earlier specs
  called the loaders with **their own fixtures**, which proves a loader works and
  never that a shipped file reaches one, and a whole-TOC load check counted the
  silent `return` as a pass. These run the files off disk in TOC order and assert
  the data arrived. Verified by mutation — restoring the old handle in a single
  file fails four of them.

  It now walks **every TOC discovered on disk**, asserting it finds all five,
  rather than a hard-coded pair. Naming the files was how it broke the moment the
  TBC TOC was renamed, and covering only two of five was how Vanilla's unlisted
  Fishing files went unexamined — nothing loaded them, so nothing checked them.
  The count assertion is deliberate: a bare glob that found nothing would let
  every assertion in the file pass vacuously.

- **Recorded a real data gap found while writing those specs: esES ships only 2
  of 9 scroll prefixes** (Blacksmithing and Enchanting), because the upstream DBC
  strings for the rest are absent in that locale — esMX has all 8. Not a load
  failure, so the locale spec asserts non-empty rather than per-profession
  coverage, and this is noted as its own future fix.

- **Offline harness pinned at `502e31b`**, and the per-flavour interface numbers
  this library ships are now what the harness's own `wow.setBuild(flavour)` is
  built on — it had no authoritative source for them and had declined to guess.
  Corrected `CLAUDE.md`, which still documented Era as 11508, BCC as 20505 and
  Mists as 50503; the TOCs ship 11509, 20506 and 50504. Nothing branched on the
  stale numbers (every 1.15.x is `< 20000`, which is all the flavour gate reads),
  but a wrong number in a doc that another repo builds on is how it becomes a
  real one.

- **`docs/AUDIT.md`** — the standing peer-review conversation, the inverse of a
  harness contract: findings are raised by a review session and answered here.
  Created so a review has somewhere to land, and pointed at from `CLAUDE.md`,
  which is the part that fires unconditionally.

---

## [v1.4.1] (2026-07-28) - TOC interface versions realigned to the live clients

### Improvements

- **Every shipped TOC now declares the Interface version its client actually
  runs.** Three of the five had drifted behind the live builds, which is what
  makes WoW flag the library as out-of-date in the AddOns list (and can hide it
  behind "Load out of date AddOns" for anyone who hasn't ticked that box):
  - **Vanilla / Era** — `11508` → **`11509`** (client 1.15.9)
  - **TBC** — `20505` → **`20506`** (client 2.5.6)
  - **Mists** — `50503` → **`50504`** (client 5.5.4)

  The numbers come from the installed clients themselves (`.build.info`, which
  records each product's exact build — `wow_classic_era` 1.15.9, `wow_anniversary`
  2.5.6, `wow_classic` 5.5.4), not from what other addons happen to target.
- **Wrath (`30405`) and Cata (`40402`) are deliberately untouched.** Neither
  product is installed to verify against, and guessing an Interface number is
  exactly how this drift starts. They keep their last shipped values until there's
  an authoritative source for them.
- **No data and no API change** — recipe data, the enchant catalog, and every
  method are byte-identical to v1.4.0. **LibStub MINOR stays at 7** on purpose:
  it moves only when the public API changes, so consumers already gating on
  `MINOR >= 7` need no update and must not gate anything new on this release.

### Tooling

- **`.pkgmeta` ignore patterns were in the wrong format, so development files
  leaked into the published zip.** Both faults were silent — a malformed entry
  simply matches nothing and the file ships anyway:
  - **`tools/` was never excluded.** The BigWigs packager wants a bare folder
    name (the way `docs` was already written). `parse_ignore()` trims a trailing
    `/*`, not a bare `/`, so `tools/` became the pattern `tools//*` — a double
    slash that matches no path. The whole `tools/` folder was being packaged.
  - **`wow-version-replication.ps1` was being packaged.** The globs were written
    `**/*.ps1` / `**/*.sh` / `**/*.bat`, but matching is done with shell `case`
    globbing, which has no recursive-`**` support. The correct repo-relative form
    is `*.ps1`.
  - Dropped the `.git` / `.github` / `.vscode` / `.luarc.json` /
    `.markdownlint*` entries: everything beginning with a dot is pruned by the
    packager unconditionally, so those lines were no-ops that implied coverage
    they weren't providing. Verified against `release.sh` (`parse_ignore`,
    `match_pattern`, `copy_directory_tree`), not assumed.

---

## [v1.4.0] (2026-07-18) - Enchant catalog: item-applied enchants (arcanums, ZG, kits)

### New Features

- **New enchant catalog covering the permanent gear enchants no profession
  crafts** — Dire Maul arcanums (Lesser Arcanum of Voracity/Rumination/…, Arcanum
  of Rapidity/Focus/Protection), the Zul'Gurub / Zandalar **head, shoulder and leg**
  enchants (Presence of Might, Syncretist's Sigil, Death's Embrace, Falcon's Call,
  Hoodoo Hex, Animist's Caress, …), armor kits, shield spikes, Wolfshead Trophy,
  Mithril Spurs. These are applied by a **consumable item**, so they never appear
  in any profession's recipe list — but a gear planner needs them as slot options.
  Three new methods expose a unified, slot-indexed view over **both** the craftable
  enchants (from recipe data) and these item-applied ones:
  - `DB:EnchantsForSlot(slot)` — every enchant applicable to a slot (`"HEAD"`,
    `"SHOULDER"`, `"WRIST"`, `"WEAPON2H"`, …), craftable and item-applied together.
  - `DB:GetEnchant(enchantId)` — a normalized catalog entry by
    `SpellItemEnchantment` id: `{ id, name, effect, slots (array), stats?, source
    ("craft"/"item"), itemId?, profId?, recipeId? }`.
  - `DB:IterateEnchants()` — iterate the whole catalog.
- **Authoritative, curated sourcing.** The item-applied set is extracted from DBC —
  every `ENCHANT_ITEM` effect whose apply spell is **not** in a profession skill
  line, targets an armor/shield slot (`SpellEquippedItems`), and is granted by a
  **real obtainable item** — so `[PH]` placeholders and QA/dev test enchants drop
  out. Slot + structured stats reuse the v1.3.0 enchant-enrichment extraction.
- **Structured stats now capture crit/hit and the tank/avoidance stats.** The stat
  extraction gained the melee/spell **crit** and **hit** auras plus **defense,
  dodge, block chance, block value, and ranged haste**, emitted under the exact
  stat-weight keys a scorer reads — `CRIT_PCT` / `HIT_PCT` / `SPELL_CRIT_PCT` /
  `SPELL_HIT_PCT` / `DEFENSE` / `DODGE_PCT` / `BLOCK_PCT` / `BLOCK_VALUE` /
  `RANGED_HASTE_PCT`. So an enchant's every stat contributes to a stat-weighted (EP)
  total the same way an item's does. Covers the ZG/AQ head/shoulder/leg enchants
  (Presence of Might → Defense +7 / Stamina +10 / Block Value +15, etc.) and the
  craftable enchant recipes alike.
  Coverage: 80 (Vanilla), 128 (TBC), 140 (Wrath), 169 (Cata), 176 (Mists), in every
  locale. Delivered inside the existing Enchanting data files (no new load order).
- **Kept out of the recipe space on purpose.** Item-applied enchants live in a
  separate catalog keyed by enchant id, so `GetProfessions()` / `GetRecipes()` and
  every recipe-oriented consumer are completely unaffected. **LibStub MINOR → 7.**

### Bug Fixes

- **Enchant stat amounts were off by one for some enchants.** The structured-stat
  extraction (v1.3.0) computed an aura's value as `EffectBasePoints + 1`, which is
  only right when the effect stores its value with a 1-sided die. Enchants that
  store the value directly (die 0) came out **one too high** — e.g. a "Stamina +20 /
  Defense +7 / Block Chance +2%" enchant shipped 21 / 8 / 3. Now computed as
  `EffectBasePoints + EffectDieSides`, which is correct for both encodings; the
  common die-1 enchants are unchanged.
- **Stale localized name files re-synced.** The v1.2.1/v1.2.2 `_core` corrections
  (Basic Campfire dropped from Cooking, Crystal Infused Bandage from Vanilla First
  Aid) were emitted with `--core-only`, so the per-locale **name** files still
  listed those spells. This full regeneration removes them (they were runtime-inert
  — a name with no `_core` entry is skipped — but the files are now correct).

---

## [v1.3.0] (2026-07-12) - Enchant enrichment: id, target slot & structured stats

### New Features

- **Enchant recipes now ship a target slot, a structured stat table, and their
  enchant id — all extracted authoritatively from DBC.** Every recipe whose craft
  applies a permanent enchant (all Enchanting recipes, plus Engineering scopes /
  belt tinkers) now carries three new `_core` fields, and the library exposes them
  via `DB:GetEnchantSlot`, `DB:GetStats`, and `DB:GetEnchantId`:
  - **`enchantSlot`** — the target slot category (`"HANDS"`, `"WRIST"`, `"CHEST"`,
    `"BACK"`, `"SHIELD"`, `"FEET"`, `"WEAPON1H"`, `"WEAPON2H"`, `"WAIST"`,
    `"RANGED"`, …). Sourced from the recipe spell's `SpellEquippedItems`
    equipped-item restriction, so it's language-independent — no recipe-name
    grepping. (Weapon 1H/2H, which the mask doesn't encode, is the only piece
    read off the stable enchant name.)
  - **`stats`** — a structured `{ [key] = amount }` table keyed by the game's own
    `GetItemStats` keys (`ITEM_MOD_AGILITY_SHORT`, `RESISTANCE0_NAME` = armor,
    `RESISTANCE2_NAME` = fire resistance, …), so a consumer sums enchant stats
    straight into item-stat totals instead of re-parsing the `effect` string.
    Extracted from the enchant's DBC effects — chasing the hidden apply-spell's
    `SpellEffect` auras (`MOD_STAT`, `MOD_RESISTANCE` school bitmask, spell power,
    healing, mp5, …) for the common case, direct `SpellItemEnchantment` effects
    for armor/resistance. Absent for procs / on-use effects (Crusader, Fiery
    Weapon) that carry no static stat.
  - **`enchantId`** — the `SpellItemEnchantment` id, i.e. the enchant number in an
    item link's enchant slot. Lets a consumer map an enchant already applied to a
    worn item back to the recipe that produces it — no tooltip scanning.

  Purely additive: the fields live in `_core` only (they're locale-independent),
  no existing field changed, and older consumers ignore them. New DBC pull:
  `SpellEquippedItems`, wired into the existing pipeline. Coverage on Vanilla:
  140 slots, 121 stat tables, 153 enchant ids. **LibStub MINOR → 6.**

---

## [v1.2.2] (2026-07-04) - Complete the spec map for TBC/Wrath (crafted-item gates)

### Bug Fixes

- **`requiredSpec` now covers TBC/Wrath crafted-item-gated recipes.** v1.2.1 derived
  the spec gate solely from the recipe *scroll* (`ItemSparse.RequiredAbility` on the
  `Plans:`/`Pattern:` item), which is how **Vanilla** encodes it. But TBC and Wrath
  moved the gate onto the **crafted item itself** (e.g. Lionheart Blade → item 28428
  → `17039` Master Swordsmith) and leave the scroll ungated — so every post-Vanilla
  spec recipe shipped **without** a `requiredSpec`, and consumers attributing a
  crafter to a spec fell back to "Unspecialized" for the entire TBC/Wrath weapon and
  armor lines. The generator now also matches the produced item against the
  specialization map. Newly tagged: **65 TBC** (Blacksmithing 37, Leatherworking 18,
  Engineering 10), **72 Wrath** (Blacksmithing 42, Leatherworking 18, Engineering
  12), and **2 Vanilla** (Gnomish/Goblin Engineering). Purely additive — no existing
  tag or other `_core` field changed. **LibStub MINOR → 5.** API unchanged.
- **Mooncloth Tailoring recipes now tagged.** The specialization map had `26802`
  ("Detect Amore", a holiday spell) where **Mooncloth Tailoring's real spell id
  `26798`** should have been, so every Mooncloth-gated recipe shipped with no
  `requiredSpec`. Corrected — Mooncloth now tags **3 recipes** per build (TBC/Wrath),
  matching Spellfire and Shadoweave. Spellfire (`26797`) and Shadoweave (`26801`)
  were already correct.

---

## [v1.2.1] (2026-07-02) - Specialization requirements + data corrections

### New Features

- **Recipes now carry their required specialization (`requiredSpec`).** Spec-gated
  recipes — Leatherworking (Dragonscale / Elemental / Tribal), Blacksmithing
  (Armorsmith / Weaponsmith → Swordsmith / Hammersmith / Axesmith), Tailoring
  (Mooncloth / Shadoweave / Spellfire), and Engineering (Gnomish / Goblin) — now
  ship a `requiredSpec` field holding the specialization spell required to learn
  them, sourced from `ItemSparse.RequiredAbility`. It's the same spell id
  `IsSpellKnown` returns for that specialization, so consumers can compare it
  directly (e.g. hide recipes a character's spec can never learn, or attribute a
  crafter to a spec). Covers Vanilla / TBC / Wrath — specializations were removed
  in Cata. The field rides every recipe entry via `LoadCore`; **LibStub MINOR → 4**
  signals its availability. The public query API is otherwise unchanged.

### Bug Fixes

- **Basic Campfire removed from Cooking.** Recipe `818` is the learned campfire
  ability (it produces no item), not a craftable, so it never belonged in the
  recipe set. Dropped from the Cooking data.
- **Crystal Infused Bandage removed from Vanilla First Aid.** Recipe `30021` is a
  TBC First Aid bandage (Netherweave-based, skill 300→360) that the Anniversary
  Classic client ships in its data even though it isn't learnable in Vanilla. It's
  excluded from the **Vanilla** set only — TBC and later still ship it.

### Tooling

- **Dev-sync watcher hardened** (`wow-version-replication.ps1`) — added a per-repo
  single-instance mutex so a second launch (e.g. a VS Code reload re-firing the
  folder-open task) exits cleanly instead of racing the running watcher; wrapped
  `Copy-Item`, the initial sync, and the poll loop in try/catch so a locked target
  (WoW open, AV scan, editor write-replace) or a file that vanishes mid-scan now
  logs a RETRY/WARN and self-heals on the next poll instead of silently killing the
  watcher; the mutex is released on exit. Mirrors the hardening already in the
  sibling addons' copies of this script.
- **`.pkgmeta`** — normalized the `docs` ignore entry (was `docs/`).
- **`.vscode/tasks.json`** — now tracked in the repo so the folder-open dev-sync
  task follows the project to a new machine.

---

## [v1.2.0] (2026-05-30) - Core/names data split

### Improvements

- **De-duplicated locale-independent data (core + names split).** v1.1.0 shipped
  a fully self-contained file per language, so the structural fields
  (`difficulty` / `reagents` / `requiredSkill` / `teaches` / `craftedItemId` /
  `itemId` / `phase`) were byte-identical across all 12 locale folders — and a
  client parsed all 12 copies of the full table on login (the `GetLocale()`
  guard skips *execution*, not *parsing*). Now that data lives **once per game**
  in `Data/<game>/_core/<Prof>.lua` (loaded via `lib:LoadCore`, guarded by
  `IsGameVersion` only), and each `Data/<game>/<locale>/<Prof>.lua` carries only
  the localized `name` + `effect` (via `lib:LoadNames`). The bulky structural
  table is parsed/loaded once instead of 12× — cutting both the download size
  and the once-per-login parse cost. Mirrors how `LibItemDB-1.0` is built.

### API

- **New `lib:LoadCore(profId, core)` and `lib:LoadNames(profId, names)`** (LibStub
  MINOR → 3). Both merge into the same `self.recipes` view, so the public query
  API (`GetRecipe`, `GetReagents`, `GetDifficulty`, `GetEffect`, `Search`,
  `Iterate`, …) returns the same stitched entry shape as before — no consumer
  change. `LoadRecipes` is retained as a back-compat shim that splits a
  self-contained table into a `LoadCore` + `LoadNames` pair.
- Per-flavour TOCs now list the `_core` files first, then all locale name files
  (each still self-guarded on `GetLocale()` + `IsGameVersion`).

---

## [v1.1.0] (2026-05-30) - Full localization

### New Features

- **All official WoW locales** — recipe names and enchant effect text now ship
  in deDE, esES, esMX, frFR, itIT, koKR, ptBR, ruRU, zhCN, and zhTW (plus enGB
  mirroring enUS), alongside enUS. 12 locales total, ~202,140 recipe entries
  across the five game versions, 672 data files. Each data file guards on
  `GetLocale()` so a client loads only its own language, and each per-flavour
  `.toc` lists every locale's files.

### Improvements

- **Locale-stable recipe sets** — only `name` and `effect` are translated; the
  recipe set, difficulty tiers, reagents, required skill, and item IDs are
  byte-identical across every locale. Strings come from localized `SpellName` +
  `SpellItemEnchantment` pulls, re-resolved with the same enchant placeholder
  handling (cross-spell refs, etc.), with English fallback for any string a
  locale is missing. The English-only structural heuristics (scroll-prefix
  detection, obsolete-item filtering) never run on translated data, so the
  recipe set can't drift between languages.
- **LibStub MINOR bumped to 2** — signals the expanded multi-locale data set to
  consumers. The public API is unchanged.
- **Clean lint** — added a scoped `---@diagnostic disable: undefined-global` to
  `LibProfessionDB-1.0.lua`; the shared TOG multi-root workspace disables the
  Lua 5.1 builtin library, which otherwise false-flags `pairs`/`table`/etc.

---

## [v1.0.0] (2026-05-30) - Initial release

### New Features

- **LibProfessionDB-1.0** — Standalone offline profession/recipe database
  exposed as a LibStub library. Resolves a crafting recipe to its name,
  reagents, skill-up difficulty tiers (orange/yellow/green/grey), required
  skill, produced item, and enriched effect text — with no trade-skill window
  open and no scan. API: `IsReady`, `Count`, `GetMeta`, `GetProfessions`,
  `HasProfession`, `ProfessionCount`, `GetRecipes`, `GetRecipe`, `HasRecipe`,
  `GetName`, `GetReagents`, `GetEffect`, `GetDifficulty`, `GetRequiredSkill`,
  `GetItemID`, `GetCraftedItemID`, `Search`, `Iterate`. Data is loaded via
  `LoadRecipes(profId, recipes)` from shipped, pre-built data files.
- **Point-in-time data per game version** — recipe difficulty, required skill,
  reagents, names, and effect text are NOT merged across expansions; each
  flavour ships exactly its own wago build's recipes. Vanilla/enUS through
  Mists/enUS captured (16,845 recipes across the five flavours).
- **Enriched, searchable effect text** — enchant recipes carry their effect
  name (`+5 Weapon Damage`, `+1 All Stats`, …) resolved from
  SpellItemEnchantment, including cross-spell placeholder resolution. `Search`
  matches both recipe name and effect text. Crafted gear ships no synthetic
  stat line (the client's real item tooltip is authoritative).
- **Ships for every flavour except Retail** — per-flavour TOCs for Vanilla/Era
  (11508), TBC (20505), Wrath (30405), Cataclysm (40402), and Mists (50503).
  Each TOC lists only its own game's profession data files.
- **Guild version-check** — `ProfessionDB.lua` registers a `{ GetName =
  "LibProfessionDB", Version }` host with VersionCheck-1.0 at `PLAYER_LOGIN`.
  Hard dependencies on **Ace3** and **VersionCheck-1.0** are declared in every
  `.toc` and in `.pkgmeta` (`required-dependencies`).

---

<!-- charset-ok: a developer changelog. It is published verbatim as the GitHub release body and
     read on CurseForge; the WoW client never renders a byte of it, so the font limit the charset
     law protects does not apply here. The em dashes and arrows it flags are all inside RELEASED
     entries, which this project's rules forbid editing -- so the only compliant alternative would
     be rewriting shipped history. Declared 2026-08-19. New entries still prefer ASCII. -->
