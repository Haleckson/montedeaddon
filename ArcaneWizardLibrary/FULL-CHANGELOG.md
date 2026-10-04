**v1.38 (2026-10-03)**
- Added: Freely placeable gray horizontal separators with three centered dots and softly fading ends in the options menu
- Added: Optional New badges for settings
- Updated: Logo
- Updated: Compatibility with the beta client [forever]

**v1.37 (2026-09-27)**
- Removed: Deprecated game-version alias `GAME_TYPE_VANILLA`
- Minor code adjustments

**v1.36 (2026-09-24)**
- Changed: Renamed the Classic flag to `GAME_TYPE_CLASSIC`, retaining `GAME_TYPE_VANILLA` for compatibility
- Removed: Combined game-version flag `GAME_TYPE_MAINLINE`

**v1.35 (2026-09-22)**
- Added: Separate version checks for Retail and Forever
- Added: Centralized settings and GUID-based profiles with shared defaults and version-based cleanup
- Changed: Character profile labels now include the current character's name
- Changed: Standardized and shortened API comments
- Deprecated: Combined game-version flag, retained for compatibility

**v1.34 (2026-09-18)**
- Added: Shared helpers for character GUIDs and migration of existing addon data, while retaining name-based identity helpers for existing addon versions
- Added: Shared handling for aborting addon initialization when the player identity is unavailable
- Added: Support for 'Forever'

**v1.33 (2026-09-13)**
- Updated: GitHub links following the organization rename to 'arcane-wizard-dev'

**v1.32 (2026-09-06)**
- Added: TOC version for patch 12.1.5 [retail]

**v1.31 (2026-08-30)**
- Minor code adjustments

**v1.30 (2026-08-21)**
- Added: Reusable single-page changelog windows with an options-menu button
- Added: Clear buttons for populated input fields
- Added: Optional Escape-key closing for windows and popups
- Added: Matching silver and gold border styles with rounded corners for windows and popups
- Changed: Window, popup, control, and scroll-frame creation now uses named configuration tables
- Changed: Windows and popups now use the MEDIUM frame strata
- Changed: Default popup border style renamed to library
- Changed: Solid title background style renamed to solid library
- Changed: Minimum popup size reduced to 64 x 48 pixels
- Changed: Minimum window size now depends on whether a portrait is shown
- Changed: Scrollbar elements are now larger and more visible with a slightly thinner track
- Changed: Dark pattern backgrounds now use more natural random variation
- Removed: Addon update-notice chat handling from the Library API
- Fixed: Overlapping windows now retain the correct drawing order

**v1.29 (2026-08-18)**
- Added: Reusable single-page changelog windows with an options-menu button
- Added: Clear buttons for populated input fields
- Added: Optional Escape-key closing for windows and popups
- Changed: Scrollbar elements are now larger and more visible with a slightly thinner track
- Changed: Dark pattern backgrounds now use more natural random variation
- Removed: Addon update-notice chat handling from the Library API
- Fixed: Overlapping windows now retain the correct drawing order

**v1.28 (2026-08-14)**
- Removed: TOC version for patch 12.0.7 [retail]

**v1.27 (2026-08-12)**
- Added: Window tabs, scroll frames, input fields, dropdown menus, reusable solid background presets, and an optional red button style
- Changed: Reusable UI elements now use dedicated APIs, a consistent visual style, and clearer control states

**v1.26 (2026-08-04)**
- Added: Reusable UI elements - Windows, popups, buttons, checkboxes, and option groups with consistent styling across supported game versions

**v1.25 (2026-07-27)**
- Minor code adjustments

**v1.24 (2026-07-26)**
- Added: TOC version for patch 1.15.9 [classic]
- Added: Boolean-controlled update notice chat messages for new addon versions
- Removed: TOC version for patch 1.15.8 [classic]

**v1.23 (2026-07-21)**
- Minor code adjustments

**v1.22 (2026-07-18)**
- Minor code adjustments

**v1.21 (2026-07-12)**
- Added: Optional Wago link button for the About section
- Removed: TOC version for patch 5.5.3 [mists of pandaria - classic]
- Removed: TOC version for patch 2.5.5 [burning crusade - classic anniversary edition]

**v1.20 (2026-07-09)**
- Minor code adjustments

**v1.19 (2026-07-06)**
- Removed: Addon context chat and debug output helpers

**v1.18 (2026-07-04)**
- Added: TOC version for patch 12.1.0 [retail]
- Added: TOC version for patch 2.5.6 [burning crusade - classic anniversary edition]
- Removed: TOC version for patch 12.0.5 [retail]

**v1.17 (2026-06-19)**
- Minor code adjustments

**v1.16 (2026-06-16)**
- Minor code adjustments

**v1.15 (2026-06-14)**
- Minor code adjustments

**v1.14 (2026-06-13)**
- Added: Addon context API for registration, debug handling, settings category access, chat output, minimap buttons, and AddonCompartment integration

**v1.13 (2026-06-07)**
- Added: Optional CurseForge link button for the About section
- Changed: About section now determines game version and game flavor from the library

**v1.12 (2026-06-02)**
- Added: Character and realm utility function with separate return values

**v1.11 (2026-06-01)**
- Added: Deep table copy utility

**v1.10 (2026-05-30)**
- Minor code adjustments

**v1.9 (2026-05-26)**
- Added: Utility API for common addon helper functions
- Changed: Profile settings helpers were moved into the Settings API
- Removed: Standalone Profiles module

**v1.8 (2026-05-24)**
- Added: Height presets for settings info text rows
- Changed: CreateExpandableHeader was renamed to AddExpandableHeader

**v1.7 (2026-05-24)**
- Added: Profile helper API for character keys and localized profile texts

**v1.6 (2026-05-23)**
- Added: Optional cancel callback support for confirmation dialogs
- Added: TOC version for patch 12.0.7 [retail]

**v1.5 (2026-05-10)**
- Added: TOC version for patch 5.5.4 [mist of pandaria - classic]
- Removed: TOC version for patch 12.0.1 [retail]

**v1.4 (2026-05-01)**
- Removed obsolete code for better maintainability

**v1.3 (2026-04-28)**
- Added: API wrapper for sliders to simplify settings menu creation

**v1.2 (2026-04-25)**
- Added: API wrappers for checkboxes, dropdowns, buttons, and info texts to simplify settings menu creation
- Added: Expandable sections and combined checkbox-slider elements for advanced settings layouts
- Updated: UI templates and mixins to support the new modular settings components

**v1.1 (2026-04-21)**
- Updated: Logo
- Minor code adjustments

**v1.0 (2026-04-17)**
- Initial release

**v1.0-alpha.2 (2026-04-16)**
- Initial release

**v1.0-alpha.1 (2026-04-15)**
- Initial release
