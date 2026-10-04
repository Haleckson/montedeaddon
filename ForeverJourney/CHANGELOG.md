# Changelog

All notable changes to Forever Journey will be documented in this file.

## 0.1.0-beta.3

Memory and Chronicle usability update.

### Added

- Added manual memories with a title, note, automatic timestamp, and current location.
- Added editing and deletion for manual memories, including deletion confirmation.
- Added favorite stars for Chronicle memories.
- Added a Memorable Moments section to History for favorited memories.
- Added Chronicle filtering by memory type.
- Added multi-select Chronicle filters so several event categories can be viewed together.
- Added a Favorites-only Chronicle filter that can be combined with type filters.

### Improved

- Added presentation-safe memory fields for UI actions, including stable ID, favorite state, and edit/delete capability.
- Improved the manual-memory editor to match the journal visual style.
- Improved Chronicle action placement by aligning edit, delete, and favorite controls.
- Improved profession marker sizing in Chronicle and Memorable Moments.
- Improved the filter popup with opaque parchment presentation and clear selected-state highlighting.
- Chronicle updates immediately after creating, editing, deleting, favoriting, or unfavoriting a memory.

### Removed

- Removed the temporary A3 memory-action self-test slash command.

### Persistence

- Manual memories and favorite state are stored in existing schema v3 SavedVariables.
- No new SavedVariables migration is required from `0.1.0-beta.2`.

### Compatibility

Tested with:

- World of Warcraft: Forever `1.60.1.70170`
- Interface `16001`

### Known Limitations

- Previously recorded NPC names may remain in the client language in which they were originally captured.
- Exact pre-install chronology still cannot be reconstructed when the game does not expose it.


## 0.1.0-beta.2

Stability and compatibility update.

### Fixed

- Improved NPC killer-name capture for newly recorded death memories so the current client locale is preferred when the game can resolve the unit by GUID.
- Preserved the raw Death Recap source name separately as fallback/diagnostic data.

### Improved

- Upgraded persistent storage and memory records to schema v3.
- Added stable per-character memory IDs.
- Added recording metadata for newly created memories, including client locale, client build, and addon version.
- Added creature ID metadata to newly recorded combat deaths when exposed by the client.
- Added internal favorite state to the memory model for future journal features.
- Reworked quest and profession memory presentation around a central memory-type registry, removing chained presentation overrides.
- Verified journey persistence after full client restart with schema v3.
- Verified compatibility with World of Warcraft: Forever `1.60.1.70170`.

### Migration

- Existing `0.1.0-beta.1` SavedVariables are migrated automatically to schema v3.
- Existing event order, timestamps, recovered history, and historical text are preserved.
- Existing NPC names are not rewritten during migration.

### Compatibility

Tested with:

- World of Warcraft: Forever `1.60.1.70170`
- Interface `16001`

### Known Limitations

- Previously recorded NPC names may remain in the client language in which they were originally captured.
- Exact pre-install chronology still cannot be reconstructed when the game does not expose it.

## 0.1.0-beta.1

First public beta release.

### Added

- Persistent per-character journey journal
- Overview page
- Chronicle page
- History page
- Character portrait
- Character level, race, and class display
- Played time tracking
- Completed quest tracking
- Money tracking
- Death tracking
- Visited zone tracking
- Instance tracking
- Level-up memories
- Semantic memory format
- Recovered History for existing characters
- History-from-start behavior for new characters
- Quest milestones every 50 completed quests
- Profession tracking
- Learned profession memories
- Profession skill milestones every 75 skill points
- Profession-specific icons
- Death Recap enrichment
- Environmental death support
- Persistent minimap launcher
- Draggable minimap launcher position
- English localization
- Russian localization
- Custom journal-style interface
- Custom parchment, portrait, timeline, tab, and decorative assets
- Minimal Chronicle scrollbar
- Minimal History scrollbar
- SavedVariables migration
- Legacy memory migration

### Improved

- Overview timeline presentation
- Chronicle event grouping by date
- History retrospective presentation
- Existing-character recovery behavior
- New-character history behavior
- Profession presentation across Overview, Chronicle, and History
- Profession icon sizing
- Parchment rendering and layering
- Timeline alignment
- Scroll behavior
- Death source name handling
- Realm suffix handling
- Client restart persistence
- Release build cleanup

### Removed

- Development-only profession test commands
- Mutating level test command
- Automatic development chat spam
- Temporary profession debug module
- Unused PNG source assets from the release package
- Development workspace files
- Obsolete UI placeholder handlers
- Unsupported scrollbar glyphs

### Compatibility

Tested with:

- World of Warcraft: Forever `1.60.1.70058`
- Interface `16001`

### Known Limitations

- Exact pre-install chronology cannot be reconstructed when the game does not expose it.
- Existing quest milestones are not recreated retroactively.
- Existing professions are treated as the initial baseline.
- Profession skill milestones are recorded only after tracking begins.
- Death Recap detail depends on information exposed by the client.