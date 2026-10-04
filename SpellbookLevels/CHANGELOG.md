# Spellbook Levels changelog

### 3.3.19-RC1 — October 2, 2026

- Fix a remaining learned-state path for Ghost Wolf: a rankless saved trainer entry is now matched to the live learned spellbook entry when the client supplies Rank 1 but no learned level and no future rank exists.
- A negative name-based API query no longer undoes positive learned spellbook evidence. Preserve separate future-rank protection.
- Add `/sbl learncheck Ghost Wolf` to print only matching spellbook and computed-row evidence for live diagnosis.
- Add a regression that failed with 3.3.18: rankless trainer entry, live Rank 1, zero learned level, and negative independent API query. Verify a sole cached higher rank remains unlearned when the book contains that future upgrade.
- All seven regression suites and package checks pass. The user's actual in-game outcome still needs confirmation after reload.

### 3.3.18-RC1 — October 2, 2026

- Fix learned unranked abilities such as Ghost Wolf appearing in Available now when saved trainer rows contain generated rank labels or duplicate entries and the active spellbook tab does not contain the spell.
- Use positive player-spell answers and live rank metadata across tabs. A confirmed known unranked ability overrides obsolete cached rank labels; ranked upgrades still require rank-specific evidence.
- Use recorded trainer spell IDs as additional positive learned evidence. Do not treat a negative answer for a replaced lower rank as proof that it is unlearned.
- A positive learned-spell answer overrides stale FutureSpell display flags after training. Actual spellbook Spell entries remain learned evidence during transient API disagreement.
- Add regressions for Ghost Wolf duplicates/rank labels on General, actual unlearning, stale future flags, ranked upgrades, and exact trainer IDs. All seven regression suites and Lua/ZIP/TOC checks pass. Live game verification remains pending.

## October 2, 2026

### 3.3.17-RC1

- Replace cycling category, source, training-view, and style buttons with explicit selection menus. Training views include Available now, All upcoming, and Learned; class views also include Next level and Next 5 levels.
- Explain empty training views and suggest changing filters or visiting a trainer. Apply the selected training view consistently in floating and docked companion panels.
- Expand selected-recipe materials into recipe details: recorded trainer/vendor, zone and coordinates, profession skill and character-level requirements, alongside bags, bank snapshot, total, required, and missing materials.
- Remember crafting quantity and materials-window position per character. Automatic materials mode follows native recipe selection; choosing a recipe manually pins it.
- Remember category, training view, source filter, window size, and window/host positions per character; migrate existing positions without clearing account-wide catalogs.
- Briefly highlight rows whose learned/available state changes and show a training-update message, preserving event coalescing and delayed recipe rechecks.
- Detect client-build changes and show a reminder to recheck cached training levels/prices at trainers. Retain discovered data rather than deleting it automatically.
- Validation: all six Spellbook Levels regression suites pass; all packaged Lua compiles under Lua 5.1 and ZIP/TOC integrity checks pass. Visual layout and behavior in the running game still need verification.

## October 1, 2026

### 3.3.14-RC1

- Opening Materials from Skill Levels selects a recipe from the active profession, with a recipe picker for other choices. Automatic mode follows profession changes; clicking a specific Skill Levels recipe pins it.
- Resolve saved rows with missing or teaching-spell IDs by exact unambiguous recipe name. Support classic native recipe selection.
- Preserve event-driven bag counts and dated bank snapshots. In-game verification is pending.

### 3.3.13-RC1

- Parent spellbook-page and profession-tab watchers to their native host windows, stopping their OnUpdate callbacks while those windows are hidden.
- Keep watchers hidden until a host is discovered. Preserve visible-window polling and existing host show/hide behavior.
- No measured in-game FPS claim; improvement requires live verification.
- Add `/sblperf` and `/sblperf reset` for on-demand CPU ranking of all installed addons when client profiling is enabled. No background profiler or automatic profiling setting changes.

### 3.3.12-RC1

- Add a saved Match Skin presentation mode for class and profession windows, using flat warm-dark surfaces, subtle borders, and white control labels.
- Expose it through the existing View button, `/sbl style match`, and `/sbl skin match`; `/sbl skin classic` restores the preceding style.
- Copy the live spellbook tab font onto addon controls when available and restore original fonts when switching styles. Preserve availability and requirement colors.
- Keep all implementation and release artifacts in the SpellbookLevels project. In-game visual verification is pending.

## September 30, 2026

### 3.3.11-RC1

- Detect profession-rank training separately from crafting recipes. Apprentice, Journeyman, Expert, and Artisan rows use the current profession skill cap to determine whether they are learned.
- Cache skill-cap lookups within each panel refresh. Existing skill-change/training events refresh the panel after upgrades.
- Use profession APIs, legacy skill-line data, and the current profession's maximum skill level as supported by the client.
- Preserve ordinary recipe learned checks and avoid matching recipe names that merely contain rank words.
- Regression checks cover upgrade caps, current skill versus maximum skill, rank-shaped names, and legacy API fallback. In-game verification is pending.

### 3.3.10-RC1

- Invalidate the profession cache on trainer updates, spell-learning events, new recipe events, and skill-line changes, not only profession-list events.
- Refresh the open profession panel after those changes, with a coalesced follow-up check for delayed client recipe data.
- Keep the indexed catalog and event batching from 3.3.9; no continuous full-catalog polling was added.
- Regression checks cover learning-event invalidation, event coalescing, and delayed rechecks. In-game verification is pending.

### 3.3.9-RC1

- Merge each profession's static recipe database once per session instead of on every panel refresh.
- Replace repeated full-list searches with recipe-ID and profession/name lookup tables.
- Cache live learned-recipe information until profession events invalidate it; ordinary searches, pagination, and display refreshes reuse the cache.
- Cache recipe source text and query the player's profession skill once per catalog scan.
- Combine bursts of profession events into one deferred refresh and deduplicate tab-layout scheduling.
- Remove full saved-list copies from each profession event; save on logout, with existing trainer/vendor saves retained.
- Regression check with 2,000 recipes confirms 100 unchanged refreshes issue no additional recipe-info, source-text, or profession-skill queries. Invalidation refreshes learned state without remerging static data.
- Existing spell, merchant, materials, Lua compilation, and package checks passed. In-game opening latency remains to be measured.

### 3.3.8-RC1

- Moved the profession training-price summary from the header to the reserved footer, fixing its overlap with the search clear button and Materials button.
- Kept footer totals to the left of the pager in both docked and floating profession panels.
- Removed the redundant floating profession hint from the same footer row.
- Lua compilation and package checks passed. In-game layout verification is pending.

### 3.3.7-RC1

- Added a selected-recipe Materials window, opened with the profession panel's Materials button, by clicking a Skill Levels recipe row, or with `/sbl materials`.
- Added batch quantity (number of crafts), ingredient bag/bank/total counts, required quantities, and missing materials.
- Added material-limited craft counts from bags and from bags plus bank.
- Added per-character, dated bank snapshots refreshed while the bank is open. Unscanned bank stock displays as unknown rather than zero.
- Bag counts update as inventory changes. Native recipe selection follows the crafting form on supported clients; clicking a Skill Levels recipe explicitly selects that recipe.
- Added ingredient-name loading and a scrollable reagent list.
- Calculation and snapshot regression tests passed. In-game layout, native selection, and Forever bank API behavior still require verification.

### 3.3.6-RC1

- Added support for the newer merchant API so recipe vendor sources can update on Forever clients without the older API.
- Added a delayed merchant scan to handle inventory arriving after the merchant window opens.
- Added search bars to the profession and spell-training panels. Search ignores case and supports multiple words across names, ranks, professions, and source details.
- Added clear-search buttons, reset pagination when searching, and improved empty-result messages.
- Added a tab-independent learned-state check for single, unranked abilities such as Ghost Wolf.
- Added an additional refresh after learning spells to allow the live spell data to update.
- Added a visible diagnostic message if a merchant scan raises an error.

### 3.3.5-RC1

- Updated class spell detection to keep future spell ranks from replacing the highest learned rank.
- Matched saved trainer entries without rank text against the live learned spell's training level.
- Stopped treating stale saved learned flags as sufficient evidence when a spell is absent from the live spellbook.
- Added merchant recipe discovery by teaching-item ID across all merchant inventory pages.
- Added saved vendor names, zones, map coordinates, and recipe purchase prices.
- Preserved discovered vendor sources when refreshing the profession catalog.
- Confirmed that the Alchemy recipes shown at Apothecary Durelle already exist in the embedded database; missing acquisition sources caused them to be hidden by the Known source filter.

### Validation

- All shipped Lua files compiled under Lua 5.1.
- Regression checks passed for learned ranks, future ranks, rankless trainer rows, stale learned state, slot ordering, and tab-independent Ghost Wolf detection.
- Merchant checks passed for inventory pagination, teaching-item mapping, repeated scans, item-link fallback, modern and legacy APIs, and saved location/price values.
- Search checks passed for case handling, multiple words, source matching, literal punctuation, and empty queries.
- ZIP integrity and referenced TOC files were checked.
- Full in-game verification on Forever is still pending.
