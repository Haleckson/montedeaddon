# Spellbook Levels 3.3.19-RC1

Changes since published version 3.3.4 (October 2, 2026).

## Spells and training

- Improved learned-spell detection across spellbook tabs, including Ghost Wolf, rankless trainer records, duplicate entries, and stale future-spell flags.
- Keep genuinely unlearned higher ranks visible without letting future ranks replace the highest learned rank.
- Refresh training information after learning spells and briefly highlight changed entries.
- Correct profession-rank training checks for Apprentice, Journeyman, Expert, and Artisan using the profession's maximum skill cap.
- Refresh open profession views after training, recipe learning, and skill changes, with a delayed recheck for client data that arrives later.
- Warn when a client-build change means saved trainer levels and prices should be rechecked.

## Easier browsing

- Add spell and profession search with case-insensitive, multiword matching across names, ranks, professions, and source details.
- Replace cycling controls with explicit menus for categories, sources, training views, and styles.
- Add Available now, All upcoming, and Learned views; class spells also offer Next level and Next 5 levels.
- Explain empty results and suggest useful filter changes or trainer visits.
- Save category, training-view, source-filter, window-size, and position preferences per character.
- Move profession training-price totals into the footer to prevent overlap with search and Materials controls.

## Recipes, vendors, and crafting materials

- Discover recipe vendors across merchant inventory pages using modern and legacy merchant APIs.
- Record vendor names, zones, coordinates, and purchase prices; preserve discovered sources during catalog refreshes.
- Add selected-recipe details and materials, accessible through the Materials button, a recipe row, or /sbl materials.
- Show recorded acquisition source, location, profession-skill requirements, and character-level requirements when known.
- Show Bags, Bank, Total, Need, and Missing ingredient counts for a chosen number of crafts.
- Show material-limited crafting capacity from bags and from bags plus bank.
- Save dated bank snapshots per character; unknown bank quantities remain unknown until the bank is visited.
- Update bag counts after inventory changes and remember crafting quantity and materials-window position.
- Follow native recipe selection automatically, or pin a recipe chosen manually.
- Resolve recipe records with missing or teaching-spell IDs by an exact, unambiguous name match.

## Performance and appearance

- Merge static profession catalogs once per session and use indexed recipe lookups.
- Cache learned-recipe data and source text until relevant events require a refresh.
- Combine bursts of profession events and avoid repeatedly copying full saved catalogs.
- Stop native-window watchers while their host windows are hidden.
- Add Match Skin and Obsidian Gold styles, plus the Forever appearance variant through /wowftheme forever; /wowftheme obsidian restores the original variant.

## Diagnostics and validation

- Add /sblperf and /sblperf reset for on-demand addon CPU profiling when client profiling is enabled.
- Add /sbl learncheck Ghost Wolf to inspect live spellbook and computed learned-state evidence.
- Seven regression suites pass; Lua 5.1 compilation, ZIP integrity, and referenced addon files have been checked.
- This package remains a release candidate. The latest Ghost Wolf correction and visual changes still require confirmation in the running game.
