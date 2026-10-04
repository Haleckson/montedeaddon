<!-- charset-ok: the archived sections below are released entries moved here BYTE FOR BYTE from
     CHANGELOG.md, which has used em dashes since v0.1.0; re-spelling them would edit released history,
     which this repo's rules forbid. This header itself is ASCII. -->
# Changelog archive -- LibAceGUIWidgets

The oldest released sections of [`CHANGELOG.md`](CHANGELOG.md), moved here whole and unedited.

**Why this file exists:** the BigWigs/CurseForge packager publishes the entire live `CHANGELOG.md` as the
GitHub release body, and GitHub refuses a release body over 125,000 characters -- so an over-long
changelog silently breaks releases while the CurseForge upload itself succeeds. The live file is kept
under ~120,000 characters by moving the oldest versions here, always at a version boundary so every
section stays whole. Nothing is ever deleted, reworded or re-ordered.

## [v0.2.2] -- one owner per window, one tooltip draw, and the edit boxes' fonts on the record

### Compatibility -- MINOR 31 -> 32

No new methods; nothing a consumer calls changes shape. Two behaviours move: a window handed to both
`PersistWindow` and `DockWindow` now gets the second call refused (nil, one printed line) instead of
two owners fighting, and the ClearFrame settings gear draws a body-only tooltip where it used to
draw nothing. Feature-detect the guard on `LibStub.minors["LibAceGUIWidgets-1.0"] >= 32` if it
matters; no shipped consumer calls `DockWindow` yet. The three widget types stay at Version 30 and
`LAGW-DatePicker` at 3. The TOC is unchanged from v0.2.1.

### Not changed: the TOC, and why

- **`## OptionalDeps: VersionCheck-1.0` stays, and VersionCheck's TOC keeps naming this library.** A
  `failure to load: missing` report for this library, from a *World of Warcraft: Forever* player, was
  read here as a load-order cycle between the two TOCs, and both were edited for it during the day.
  The user's observation overturned that: the pair had run on Classic Era for ten days with no
  warning, so the client tolerates it, and "missing" on Forever meant the folder was not there -- a
  player with VersionCheck v1.5.1 (which requires this library and claims `16001`) but without
  v0.2.1, the first build of this library that claims `16001`. v0.2.1 is the fix; both TOCs are
  back exactly as v0.2.1 shipped them, VersionCheck's likewise, and the two specs written against the
  edited state are gone. Nothing in this entry ships.

### Changed

- **`PersistWindow` and `DockWindow` refuse each other's window.** Both own a window's position -- one
  through the AceGUI status table, one through an anchor -- and the docstrings called them mutually
  exclusive while nothing enforced it; peer review named the gap on 2026-09-15, 2026-09-17 and
  2026-09-20. Now the second call on a window the other already owns returns `nil` and prints once per
  window, naming both calls so the consumer knows which to drop. The raw frame is the identity
  (`PersistWindow` takes the widget, `DockWindow` takes `widget.frame`, AceGUI's `frame.obj` joins
  them). No shipped consumer calls `DockWindow` yet, so nothing changes on screen. Three specs in
  `Tests/dock_spec.lua`; the two refusal directions are red with the guard removed (checked).
- **One tooltip draw, by call.** `AttachTooltip`, the menu rows and the ClearFrame settings gear each
  carried the same anchor / white title / wrapped body / show block by copy, agreeing only because
  each was pasted from the last (peer review 2026-09-17 (ii)). They now share one local. The one
  visible change is the settings gear: it used to show nothing when only a body was given, and now
  draws the body like the other two -- and its title goes through the same type guard, so a non-string
  title is skipped rather than raising in `SetText`. A spec in `Tests/menu_spec.lua` drives a menu row
  and an `AttachTooltip` control with five title/body pairs (a body only, a number, a table, an empty
  string) and asserts the tooltip ends in the same state either way. The `UISpecialFrames` duplicate
  from the same review round was already closed in v0.2.0 (`RegisterSpecialFrame`); nothing to do.
- **The four edit boxes' fonts are asserted.** The MINOR-29 audit listed `EditBox:SetFontObject` as a
  harness no-op, so the field font on the search box, the dialog, the date picker and a searchable
  menu was provable nowhere offline. The harness has stored it since 2026-09-17; five specs in
  `Tests/scale_spec.lua` now pin every box on the scaled `ChatFontNormal` (the search box's
  instructions on the scaled disabled font) and that the font follows a live scale change. Red with
  the search box pointed at another font (checked). No library code changed.

## [v0.2.1] -- a floor that follows the scale on every window, a menu you can close only if it is yours, a list that can jump to and mark a row

### Compatibility -- MINOR 30 -> 31

Everything here is additive; every existing call behaves as before. Feature-detect on
`LibStub.minors["LibAceGUIWidgets-1.0"] >= 31`, or per method (`if W.CloseMenuFor then`,
`if rl.ScrollToEntry then`). The three widget types stay at Version 30 and `LAGW-DatePicker` at 3 --
nothing about their frames changed. `## Interface` gains `16001`.

### Fixed

- **A window persisted through `W:PersistWindow` that is AceGUI's own `Frame` (no resize handle) kept
  its draw-time floor and size across a live scale change.** Only a `ClearFrame` re-applied its floor
  when the scale moved, because the handle carries the scale listener; the no-handle branch registered
  nothing, so at 200% a window drawn at the 100% minimum sat at the 100% size with twice the text inside
  until the next reload, and at 80% the reverse. That is the widget kind `PersistWindow` was requested
  for. Now a record on the widget re-runs the raise-and-bounds on every scale change on BOTH branches
  (idempotent with the handle's own listener, whichever fires first), and the **status table is raised
  with the frame**, so the window a scale change grew is the one the next open restores -- "a raised
  window's size is not saved until the next drag" was a v0.1.12 known cost and is gone. The kept bound
  on a one-floor call is remembered as a scale-1.0 value and re-applied, not re-read and scaled twice. A
  second `PersistWindow` re-points the record; no floor registers nothing. Reported by TOGBankClassic
  (inbox `b29617a5`), traced from a player's v1.6.0 "widget overflow after resizing" at 80%; their
  `SCALE-FLOOR-001` stand-in can go. Seven specs in `Tests/scale_spec.lua`; five of them red with the
  listener removed (one pins that no floor registers nothing; the seventh is the function floor below).
- **Which floors the multiply is right for, and a floor that is a function of the scale.**
  `ApplyMinResize` / `PersistWindow` multiply a floor on the reading that everything under it scales. A
  floor that is partly fixed art (stock AceGUI controls scale only their text; a consumer's own pixel
  insets scale nothing) is under its content below 1.0 -- TOGBank's second point, and they pre-divide a
  number (`minW * max(1, s) / s`) for it. A pre-divided NUMBER is right only at the scale it was
  computed at, and a consumer re-calling `PersistWindow` from its own scale listener would race the
  library's (whichever ran first, the stale floor could raise the window past the fresh one, and
  nothing shrinks). So `minWidth` / `minHeight` may now be a **`function(scale)`** returning a scale-1.0
  value, evaluated at the call and again on every change, on both branches -- the handle is handed the
  fresh value so its own listener re-applies that rather than a frozen number. The docstrings say
  which floors the plain multiply is right for.

### Added

- **`W:CloseMenuFor(anchor, ...)`** -- closes the open menu only if one of the given anchors owns it;
  returns whether it did. The menu stack is one stack for every consumer, so `CloseMenu()` reaches
  whatever is open, whoever opened it -- and the collision only shows with a menu opened AFTER yours went
  away (ClassicCalendar: Escape in their name field while another addon's menu is up), which no blind
  test catches because opening yours already closed theirs. The anchor-hide hook in `OpenMenu` has made
  this check for itself since it was written; this is the same check for a consumer's own close path.
  Same shape and reason as `CloseDialog(token)`. Asked for on inbox `4d698ce3` (reply 9), where
  ClassicCalendar had been reading `_menuAnchor` to do it; they can stop. Five specs in
  `Tests/menu_spec.lua`, driven from an explicit close rather than from hiding the anchor (their testing
  note: the hide path was already guarded, so a spec written that way passes with the guard removed).
  The one that carries the point -- another anchor's later menu is left alone -- is the one that went
  red with the ownership check removed.
- **`rl:ScrollToEntry(entry | predicate) -> boolean`** -- scrolls so the entry is the TOP visible row
  where the clamp allows, in the order the rows are drawn (the active sort). An entry on the last page
  comes into view lower down, exactly where the scrollbar would leave it: the list never scrolls past
  its own end, and that clamp is `Refresh`'s, not a second one. Nothing scrolls on a miss.
- **`rl:SetSelected(entry | predicate | nil) -> entry`, `rl:GetSelected()`** -- a persistent
  accent-tinted highlight (18% alpha, between the banding and the cells) on ONE row, by entry identity,
  resolved per populate like the per-row icons: it follows through pooling, scroll and a re-sort, hides
  off-page, and `SetData` drops it unless the same entry is still present -- an equal-looking row in a
  rebuilt model is a stranger and does not inherit it. A target the list does not hold selects nothing
  and clears the old selection. Both from Questbook (inbox `6b742a0a`): their Rewards tab jumps to the
  Browse tab with the quest in view and marked, and had "in view" working by reading `_getSortedData`
  and writing `listOffset` from the consumer side. Eleven specs in `Tests/rowlist_spec.lua`, real frames,
  a 48px parent so exactly three rows are visible and the last-page clamp is assertable; the
  SetData-clears-a-stranger spec is the one driven red by mutation.
- **`## Interface: 16001`** -- World of Warcraft: Forever (the retail client running classic-era
  content). FastGuildInvite v2.14.0 ships a `_Camelot` TOC and reaches this library through
  VersionCheck-1.0 and GuildRoster, both hard dependencies of it; this was the last link on that client
  without the number (inbox `c4fcee21`). One TOC covers every flavour, so no `_Camelot` file here. The
  operator confirms a 16001 TOC went through the packager and CurseForge without error for FGI. Pinned
  on its own in `Tests/toc_spec.lua` because Ace3 does not claim it yet and the floor assertion cannot
  carry it. **Not verified on a Forever client** -- none is installed on this box.

### Changed

- **`ShowDialog` docstring: what parenting costs.** `parent` is re-applied on every call (so a later
  caller's prompt is never trapped in an earlier caller's window), and the prompt inherits the parent's
  visibility -- parented into a window, it dies with that window. For a confirm about that window that is
  the feature; for anything that should outlive it, pass `UIParent`. Suggested by ClassicCalendar after
  the parent question cost both sides two corrections.

### Verified / not verified

Suite: 416 passed, 0 failed (`lua Tests/wowapi/run.lua`, 2026-09-20). luacheck clean on every file
touched; markdownlint clean on the three docs. **Nothing in this release has been seen in a game
client**: not the scale-change raise on a live AceGUI Frame, not the selection tint against real
banding, not a Forever client at all. Also unverified until the release publishes: whether the
packager maps `16001` on a multi-value `## Interface` line to a CurseForge game version the way it did
for FGI's separate `_Camelot` TOC -- check the release's game-version list (FGI's note, inbox
`7633ac4b`).

## [v0.2.0] -- a date picker that knows its range, menus that can say no, and one floating-frame implementation

### Compatibility -- MINOR 29 -> 30

**Why 0.2.0 rather than 0.1.13:** one call changed MEANING rather than gaining an option. A second
`W:MakeResizable` on a frame that already has a handle now MERGES instead of replacing, so code written
against the old behaviour can be silently wrong rather than loudly broken -- the case a patch number
should not carry. Everything else in this release is additive, and the previous two releases (v0.1.11's
four features, v0.1.12's whole UI scale) stayed on the patch number for exactly that reason.

**That one behaviour change, stated fully.** Before, the second call assigned every option straight from
`opts`, so anything it left out was reset: callbacks to nil, bounds to 0, the grip set to the default
three. Now it merges. A consumer that relied on
a re-call CLEARING a callback by omission must pass `false` for it instead; nothing in the fleet was read
doing that (Dibs fetches the handle rather than re-calling, precisely because of this defect).
`ClearFrame` / `GroupFrame` / `TLabel` stay at Version 30 (no change to them); `LAGW-DatePicker` moves 2 -> 3
for the additions below, which are purely additive -- a picker that calls none of the four new methods
behaves exactly as before.

```lua
if (LibStub.minors["LibAceGUIWidgets-1.0"] or 0) >= 30 then
    W:MakeResizable(clearFrame, { onResize = fn })   -- keeps ClearFrame's persistence and minimum
else
    W:GetResizeHandle(clearFrame).onResize = fn       -- safe on every version with the framework
end
```

**One new FILE, which matters only if you embed individual files rather than the folder.** The resize
framework moved to `LibAceGUIWidgets-Resize.lua` (see below); the TOC loads it immediately after the
core file. Embedding the folder -- the intended and documented way -- needs no action. Embedding file
by file and omitting it means `W:MakeResizable` is nil and the first `ClearFrame` you build raises,
which is deliberate: the alternative is a window that silently cannot be resized.

### Fixed

- **`W:MakeResizable(clearFrame, { onResize = fn })` silently broke the window.** It nil-ed ClearFrame's
  own `onResizeStop`, which is what writes width/height/top/left into the status table, so the window
  stopped remembering its size -- nothing errored, and only a reload showed it. The same call reset the
  400x200 minimum to 0. A re-call now merges: options it passes replace, options it omits keep their value
  (callbacks, each bound separately, and the grip set), and `onResize = false` removes a callback.
  `ResizeHandle:Destroy` forgets the grip set, so a call after it still rebuilds the default three.
  Reported by Dibs (inbox `974624ba`, their `DIBSREQ-LAGW-003`).

### Added -- `LAGW-DatePicker` Version 2 -> 3

- **`picker:SetRange(minTs, maxTs)`** -- days outside it are disabled and greyed, month stepping stops at
  the months it touches, the popup opens inside it, Today is refused while today is outside it, and a
  typed date outside it reverts and fires nothing. Either bound may be nil; the two are snapped to their
  days and accepted in either order. `SetValue` is deliberately not range-checked, so a stored date loads.
- **`picker:SetTodayFunc(fn)`** -- `fn()` returns year, month, day and becomes "today" for the highlight,
  the Today button, the month opened with no value and a required picker's default. A function that names
  no real day falls back to local `time()`; nil restores it.
- **`picker:SetRequired(bool)`** -- the value can never become nil: Clear is disabled, an emptied field
  reverts, `SetValue(nil)` takes the default, and turning it on with no value sets today (pulled into the
  range) without firing `OnValueChanged`.
- **`picker:SetFirstWeekday(1..7)`** -- rotates the weekday header and the grid; anything that is not an
  integer 1..7 is Sunday.
- **`W.DatePicker.inRange`, `clampMonth`, `today`, `weekStart`**, and `grid(y, m, firstWeekday)`.
- All four settings reset when the widget returns to AceGUI's pool, and the shared popup reads them from
  its current owner on every paint, so one picker's range or week start cannot leak into the next.
- Requested by ClassicCalendar for its World Buff dates (inbox `4d698ce3`, item 1). The always-open inline
  grid (their 1e, "nice to have") is **not** in this release.

### Added -- the rest of ClassicCalendar's adoption request (inbox `4d698ce3`, items 2-6)

- **Menu items** (`OpenMenu` / `CreateDropdownBox`): `isTitle` (a gold header that does not click, check
  or highlight), `disabled` (grey and inert; an empty one is a spacer), `tooltipTitle` / `tooltipText`
  (shown on hover, disabled rows included), and a per-item `keepOpen` that overrides the menu's in either
  direction. All four are re-applied on every render, because menu rows are pooled.
- **`ShowDialog`**: `cancelText = false` for a single centred OK; `onShow(dialog)` and `onHide(dialog)`,
  with `onHide` run exactly once however the dialog closes, including when a second `ShowDialog` replaces
  an open one -- so the first consumer's cleanup runs before the second's setup. Without an edit box,
  Enter accepts and Escape cancels, but only for a dialog shown out of combat: passing other keys on
  needs `SetPropagateKeyboardInput`, which is combat-restricted (`HasRestrictions`,
  `SimpleFrameAPIDocumentation.lua:1233`), and a dialog that swallowed keys would stop the player
  moving. Escape also works in combat through `UISpecialFrames`; the dialog frame is now named
  `LibAceGUIWidgets_Dialog` so it can be listed there.
- **`W:CloseDialog(token)`, and `ShowDialog` now returns that token as its second value.** One dialog
  frame is shared by every addon in the session, so "close the prompt I opened" could not be
  `dialog:Hide()` -- by the time a consumer wants to dismiss its own prompt, the frame may be showing
  somebody else's question, and hiding it would run THEIR `onHide`: an unbalanced `PopModal`, or a
  confirm that silently answers itself. `CloseDialog` closes only the prompt that token identifies and
  returns whether it did; a token for a prompt that has already closed, or been replaced, matches
  nothing. Tokens are monotonic for the session, so an old one can never come to mean a later prompt.
  **Raised by ClassicCalendar** while adopting item 3 (their reply on `4d698ce3`): they needed exactly
  this and settled on keeping a flag their own `onHide` cleared, explicitly *not* filing it as a request.
  It is in because that is reasoning every consumer of a shared frame would otherwise repeat.
  Feature-detect with `if W.CloseDialog then`.
- **RowList sorting is stable**: rows whose sort cells tie keep their `SetData` order, which Lua 5.1's
  `table.sort` never guaranteed. `New` takes `tiebreak(a, b)`, which decides ties before input order and is
  not flipped by the sort arrow, and a column may carry `sortValue(entry)` to sort on a different key than
  the one it displays. `sortValue` runs once per entry per sort. This supersedes the README note that
  told consumers the sort was not stable.
- **`W:CreateCheckbox(parent, opts)`**: a labelled, tooltipped checkbox bound to `get` / `set`, on
  `UICheckButtonTemplate` at the 26x26 options size, following the UI scale. It re-reads `get()` when
  shown and after every click, so a refused change is shown as refused.
- **A RowList column can own its own hover** -- `col.onCellEnter(entry, idx, rl, cellFrame)` and
  `col.onCellLeave`, for a tooltip that belongs to ONE cell rather than the whole row. A text cell is a
  FontString and cannot take the mouse, so a column that asks gets a mouse-enabled overlay laid exactly
  over its cell by the layout chains; a column that does not ask builds nothing. The entry is resolved
  when the pointer arrives, never captured when the pooled row was built. **The overlay takes the mouse
  from the row**, so in the client the row's `onRowLeave` fires as the pointer enters a cell and
  `onRowEnter` fires again as it leaves -- not verified in a client -- and a click on the overlay is
  forwarded to `onRowClick` with the **row** frame so a right-click menu still works over that column.
  Requested by Dibs (inbox `3cffa42a`, their DIBSREQ-LAGW-004), which had been reading `rl.rows`,
  `rl.listOffset` and `rl:_getSortedData()` from the consumer side to do this by hand.
- **`W:DockWindow(frame, opts)`**: docks a raw window to another frame's edge, following ClassicCalendar's
  own World Buff docking rule by rule -- docked by default, anchored so it follows the target, pinned in
  place when the target hides, re-docked when it shows, and a drop decides docking only while the target
  is open. "Near" is measured in screen units. Asked for as an option on `PersistWindow` or
  `MakeResizable`; built standalone instead, because `PersistWindow` owns an AceGUI window's position and
  two owners of one position would fight.

### Changed -- one floating-frame implementation instead of three

- **`W:CreateFloatingFrame(opts)`, `W:OwnFloating(frame, opts)` and `W:RegisterSpecialFrame(name)`**, and
  the three places that had each built this by hand now call them: the pooled menu frames, the DatePicker
  popup, and `ShowDialog`'s Escape registration (which only became a third copy earlier in this release).
  **Behaviour is unchanged** -- every existing menu, popup and dialog spec passes untouched, which is what
  makes it a refactor rather than a rewrite. The v0.1.12 self-audit raised it as finding 2 and named the
  cost: the menu copy had already taken a strata fix ("strata beats level") that a later copy would not
  have inherited, and a third copy then appeared before the finding was acted on.
- **What each caller keeps, because it is genuinely theirs:** the menus close a whole STACK (they pass
  `close`, since hiding the root alone would leave a submenu floating), the popup forgets its owner on
  hide, and the dialog is parented INTO its consumer's window at that window's strata, so it shares only
  the Escape registration. `OwnFloating` registers immediately when handed an already-shown frame, which
  is the rule `OpenMenu` depends on -- it shows the root before owning it, so an OnShow-only registration
  would miss the first open.

### Changed -- the resize framework moved into `LibAceGUIWidgets-Resize.lua`

- **`W:MakeResizable`, `W:GetResizeHandle`, `W:ApplyResizeBounds` and the `ResizeHandle` methods now live
  in a satellite file**, loaded immediately after the core file by both the TOC and the test harness.
  **Nothing about them changed but their address** -- the code moved verbatim, and the suite ran the same
  388 specs before and after. **No consumer action:** an embedder that ships the whole folder, as the TOC
  and `.pkgmeta` describe, gets both files and sees no difference.
- **This repo's `CLAUDE.md` has always prescribed one file per component.** The framework went into the
  core file on 2026-08-21 for one reason: the offline harness loads a library from a hand-kept file list,
  so a satellite it did not list was invisible -- the library would load *without* `MakeResizable`, and
  every `ClearFrame` constructor would raise. Harness contract 2 (2026-09-08) made a new TOC file
  detectable, and the harness added the manifest line on 2026-09-17 (`2aac908`, thread `0045274d65c3`),
  which is what unblocked the move.
- **One new name on the library table, and it is not consumer API.** The OnSizeChanged hook was a
  file-local that `ClearFrame` and `GroupFrame` re-hook after `AceGUI:RegisterAsContainer` replaces their
  script; a local cannot cross a file boundary, so it is published as `lib.ResizeOnSizeChanged`.
  `MakeResizable` installs it for you -- there is no reason to call it. (It is why the harness's
  `verify-libs` now counts 56 methods rather than 55.)
- **If the satellite is missing, the first `ClearFrame` raises** on the existing `assert` around
  `MakeResizable`, rather than quietly building a window that cannot be resized. That loud failure is
  deliberate and is not guarded against.

### Fixed -- the date picker's weekday header was clipping two days

- **`Mon` and `Wed` rendered as `M...` and `W...`** in the calendar popup. The weekday labels are the
  client's own `date("%a")` abbreviations and are clamped to one day cell, which was 22px -- wide enough
  for five of the seven and not for the two built from the widest letters. Day cells are 26px now, so the
  popup is 206px wide at scale 1.0 rather than 178. **Found by the operator in game**, in TOGBankClassic's
  Since/Until filters; the harness has no text metrics, so no spec here could have measured it, and the
  code comment beside those labels had asserted the opposite ("'Sun' fits a 22px cell in the small font
  anyway") -- true of Sun, never checked against M or W. The two pinned popup widths in
  `Tests/scale_spec.lua` move with it. **The fix itself is not verified in a client.**

### Not changed, and why

- **ClearFrame does not add a `DoLayout` to `onResize`**, which the same request asked for. AceGUI's
  `RegisterAsContainer` already sets the content frame's `OnSizeChanged` to `ContentResize`, which calls
  `DoLayout` (`Ace3/AceGUI-3.0/AceGUI-3.0.lua:497-518`), and ClearFrame keeps that hook. The content frame is
  sized by two anchors, so a drag changes its size on every step; Blizzard's own `ScrollBox` depends on the
  client firing `OnSizeChanged` for exactly that kind of change (`ScrollBox.lua:119-129`). So the contents
  should already follow the drag, and a throttled `DoLayout` on top would be a second full layout per
  draw. **Not verified in game.** The offline harness does not model anchor-driven `OnSizeChanged`
  (harness contract 1's response, 2026-08-27), which is why no offline run shows the reflow.

### Tests

- `Tests/resize_spec.lua`: five specs under *"a second call MERGES into the handle"* (callbacks kept and
  still firing through a real drag, `false` clears, bounds kept per key, grip set kept, Destroy rebuilds the
  default). `Tests/scale_spec.lua`: a real ClearFrame keeps its `onResizeStop` and minimum when a consumer
  adds `onResize`. Four of the first five and the ClearFrame spec were run RED against the old code first
  (306 passed / 5 failed); the Destroy spec passed before the change and pins the case the new `_gripSpec`
  must not break. Suite after that change: 311 passed / 0 failed.
- `Tests/datepicker_spec.lua`: 19 new specs for the DatePicker additions (pure week start, `inRange`,
  `clampMonth`, `today`; the widget's range, today function, required mode, week start, the shared popup
  not leaking one owner's settings, and a pooled widget coming back clean), plus the Version pin 2 -> 3.
  Run against the old code first: 19 failed -- 18 of the new specs plus the Version pin (the bad-week-start
  spec already passed, because the old `grid` ignored a third argument). Suite after that change: 330 passed /
  0 failed.
- `Tests/menu_spec.lua` (7), `Tests/dialog_spec.lua` (8): run before the code, 13 failed; the two that
  passed pin behaviour that already held (a pooled row stays usable; the edit-box dialog keeps its own keys).
- `Tests/dialog_spec.lua`, "CloseDialog" (4): all four run RED first (388 passed / 4 failed, every one
  of them `attempt to call method 'CloseDialog' (a nil value)`). The one that carries the point asserts
  the NEGATIVE -- a stale token must not close, and must not run, another addon's prompt.
- `Tests/rowlist_spec.lua`, "RowList deterministic order" (7): 6 failed before the code, including both
  stability specs, which use 30 rows because a small input can survive quicksort in order by luck.
- `Tests/checkbox_spec.lua` (6) and `Tests/dock_spec.lua` (12). **The checkbox code was written before
  its specs were run**, so red was established afterwards by mutation: removing the re-read after `set()`
  and the refresh on show failed exactly the two specs about them. The dock specs first failed only
  because the method did not exist, which proves little, so they were also mutated: dropping the screen-unit
  conversion and the target-hidden pin failed exactly the scale spec and the target-closes spec.
- Two spec-side defects found on the way, both mine. `dock_spec`'s window helper left the window shown
  (a new frame is shown), so every "on show" example was acting on a window already docked at
  construction. And `datepicker_spec` depended on running before any other file that loads the library
  with AceGUI; the new `checkbox_spec` sorts first and 19 popup specs failed. It now empties AceGUI's
  widget registry first, as `scale_spec` already did.
- `Tests/rowlist_spec.lua`, "RowList per-column cell hover" (6): all six run RED against the old code
  before the overlay existed.
- `Tests/floating_spec.lua` (12): 10 for the new helpers, all ten RED before they existed, plus 2 that
  pin the callers through their own surfaces (a click outside closes a menu STACK, submenu included; the
  dialog is on the Escape list exactly once however often it is rebuilt) -- those two passed before the
  refactor and after it, which is the point of them.
- **The file split carried six specs with it, and that is the part worth knowing.** `breathe`, `cooldown`,
  `symbolfont`, `rowlist`, `resize` and `widgets` load the library by file path rather than through the
  harness manifest, so each had to gain the `LibAceGUIWidgets-Resize.lua` line in TOC order -- most
  sharply `resize_spec`, whose entire subject had just moved out from under it. The specs that go through
  `libs.load` / `libs.fresh` needed no change, and their passing is what proves the harness manifest line
  is doing its job. Suite before the move and after it: **388 passed / 0 failed** both times.
- Harness submodule pin moved `2365af4` -> `b887eb7a` to pick up that manifest line. The adoption log's
  entries since the old pin cost this library nothing -- the suite was green on the new pin before any
  code moved, which is how the two changes stay separable.
- `Tests/wowapi/tools/verify-libs.lua` against this tree: **9 verified, 0 failed**, and
  `LibAceGUIWidgets-1.0` reports `OK` with **no TOC DRIFT** -- the red it deliberately showed while the
  satellite was listed-but-empty is now clear.
- Whole suite after: **392 passed / 0 failed**. luacheck clean on all five library files and on the
  spec files touched; markdownlint clean across all 38 markdown files in the repo.

## [v0.1.12] -- one UI scale for the visually impaired

### Compatibility -- MINOR 28 -> 29

**Backwards compatible at scale 1.0, which is the default, and every existing size assertion in the suite
still passes there.** New public API (`SetScale` / `GetScale` / `ScaledSize` / `ScaledFont` /
`SetScaledSize` / `OnScaleChanged`, `SCALE_MIN` / `SCALE_MAX` / `SCALE_DEFAULT`, `RowList:ColumnWidth`,
`Configure{ scale = }`); the three widget-type Versions move 29 -> 30 together and `LAGW-DatePicker` 1 -> 2,
so the scale-aware widgets win over a MINOR-28 copy in the same session. One `MINOR` for the release, for
the one TOGBankClassic request of 2026-09-15 (inbox `05264c5f`, their `LIBREQ-LAGW-SCALE-001`).

**Two things a consumer can observe without ever calling `SetScale`, stated plainly:**

- **`RowList:New` no longer writes the header-fitted width back into your `columns` table.** It used to
  widen `col.width` in place; the effective width now lives on the instance and is read with
  `rl:ColumnWidth(key)`. Every consumer in the fleet was read for a read-back of `col.width` after
  construction and none does one (`Dibs`, `TOGBankClassic`, `GuildRoster`, `ItemDB`, `VersionCheck-1.0`).
  A scaled number written back would be scaled again on the next change, which is why it stopped.
- **`ApplyMinResize` / `ApplyResizeBounds` / `MakeResizable` / `PersistWindow` treat every minimum and
  maximum as a scale-1.0 value and multiply.** At 1.0 that is the identity. Nothing about the SAVED size
  changes: PersistWindow's table holds real pixels and is never scaled.

Feature-detect on the method or the number:

```lua
if W.SetScale then W:SetScale(db.global.uiScale or 1) end   -- or (LibStub.minors["LibAceGUIWidgets-1.0"] or 0) >= 29
```

### Added

- **One library-wide UI scale (`W:SetScale(factor)` / `W:GetScale()`), clamped to `[W.SCALE_MIN,
  W.SCALE_MAX]` = `[0.8, 2.0]`, default `W.SCALE_DEFAULT` = 1.0; `W:Configure{ scale = n }` routes through
  it.** In memory only: the CONSUMER persists the factor (TOGBank: `db.global`, per client, never
  guild-synced) and calls `SetScale` at load and from its slider. Requested by TOGBankClassic after its
  operator asked for "a visibility feature that makes the font/icons/rows larger on a slider for the
  visually impaired" and ruled that it lives here, so every consumer gets it at once and carries only the
  slider.

- **Scaled FONTS, not `frame:SetScale`.** `W:ScaledFont(base)` -- `base` a global font name
  (`"GameFontHighlightSmall"`) or a font object (`W.SymbolFont`) -- returns a font OBJECT
  (`LAGWScaled_<base>`) at the base's size x scale, path and flags kept, colour and shadow copied. **One
  object per base, re-sized IN PLACE on every change**, so a FontString pointed at it follows without
  anybody re-fonting it. The request asked for a cache "per (base, scale)"; that is the one thing done
  differently, deliberately: a per-(base, scale) cache would hand out a *different* object after a change
  and leave every FontString on the old one, which is the opposite of "FontStrings already pointed at it
  follow". The base is re-read by NAME on each change, so a font-face addon that replaces the global is
  honoured. `nil` for a font that does not exist, so a typo is visible at the call site.
  `W:ScaledSize(px)` is `px x scale` rounded to a whole pixel, for icon and row geometry a consumer draws
  itself; `W:SetScaledSize(frame, w, h)` keeps a frame at `(w, h) x scale` across changes.

- **A change signal: `W:OnScaleChanged(owner, fn)`**, `fn(newScale, oldScale[, owner])`, the same shape
  as the cooldown tick hook (the request offered CallbackHandler as the alternative; the library carries
  no CallbackHandler and its own idiom is a listener list). ONE listener per owner -- a re-registration
  replaces, `fn = nil` removes -- so nothing stacks the way `AttachTooltip` once did. Listeners fire
  AFTER the fonts have been re-sized, so one that measures text sees the new metrics; each runs under
  `pcall` with the error handed to the client's handler, so a consumer's raise cannot stop the library's
  own widgets from re-laying. The table is weak-keyed, and every listener the library registers for
  itself is a module-level function taking the owner as its third argument rather than a closure over it
  -- Lua 5.1 has no ephemerons, and a weak key whose value closes over it is never collected.

- **`RowList:ColumnWidth(key)`** -- the effective (scaled, header-fitted) pixel width of a fixed column,
  which is what `col.width` used to be widened to in place.

### Changed

- **Every widget this library draws honours the scale, and re-lays itself on the signal without the
  consumer touching it.** What follows the scale, in one line per rule so a consumer can predict it:
  every font the library draws (through `ScaledFont`); every SIZE the library chooses -- and a size a
  consumer passes in (`rowHeight`, `col.width`, `width` / `height` on `MakeLabel` / `CreateSearchBox` /
  `CreateDropdownBox`, `minW` / `minH` / `maxW` / `maxH`, `minWidth` / `minHeight`) is a SCALE-1.0 value
  and is multiplied, so nothing written for 1.0 needs a change. What does NOT: a position a consumer
  passes (`x` / `y` on `MakeLabel`, an anchor offset) -- the consumer owns its layout and redraws its own
  regions on the signal; the size of a WINDOW -- the user sizes windows and `PersistWindow` saves real
  pixels, and a window under its (now larger) minimum is raised to it on a change, nothing else moves;
  and **GameTooltip**, which the request allowed to be left alone -- it is the client's one shared
  frame, and a font set on one of its lines sticks to that line slot for every later tooltip (the same
  reason the symbol font stops at the tooltip). Per widget:
  - **RowList** -- `rowHeight` (16), the action icon size (14), the icon gap and left pad, the header
    height (20) and its font, every cell font (`col.font` through `ScaledFont`), the checkbox (16) and
    icon-cell (14) sizes, the sort arrow and its allowance, the column gaps. The header-fit probe
    measures with the SCALED header font. `_recomputeVisibleRows` re-pools on the new row height and
    `Refresh` repaints. `_buildRow` and `_buildHeader` are now creation only; the geometry lives in
    `_layoutRow` / `_layoutHeader`, applied at build and on every change, and the header/row alignment
    pins in `Tests/rowlist_spec.lua` hold at 0.8, 1.5 and 2.0 (`Tests/scale_spec.lua`). The refont hook
    is handed the scaled font object. The scrollbar lane is the one thing left at its pixel size.
  - **MakeLabel**, **CreateSearchBox** (box, field font, placeholder font, magnifier, clear button and
    the text insets that clear them -- the template's own 10 / 17 / 16 / 20 read from
    `Blizzard_SharedXML/Shared/InputBox/InputBoxTemplates.xml`), **CreateDropdownBox** (box, arrow, label
    font), **OpenMenu / ToggleMenu** rows (row height 18, the check and submenu-arrow glyphs, the paddings,
    the search box, the 160 width floor; a consumer's `width` is a scale-1.0 value, the anchor's own width
    is pixels and is not scaled twice), **ShowDialog** (re-laid on every show: frame, prompt, field,
    buttons and their three font slots), **CreateScrollFrame**'s wheel step (24 x scale, read at wheel
    time), **CreateExpandableList** (row height, indent, fonts; re-lays on the signal), **BrandTabGroup**
    (the three tab font slots, applied BEFORE AceGUI measures the text by wrapping `CreateTab`, re-applied
    after every `SelectTab` because AceGUI resets the disabled slot there, and the band heights; a change
    rebuilds the tabs so their widths follow), the **DatePicker** (label and field fonts, the field and
    button heights, the glyph and its inset, the whole popup grid), **TLabel** (`SetFontObject` resolves
    through `ScaledFont` and follows in place, where it used to copy the base's size into `SetFont` and
    freeze it; `SetImageSize` takes scale-1.0 sizes), **ClearFrame** (title font and band, status-bar
    height and font, the Close button and its fonts, the info / settings icons, the content's top and
    bottom insets -- AceGUI's `height - 57` is kept exactly at 1.0 as `27 + 40 - 10`, the 10 being the
    fudge AceGUI's own Frame carries and every consumer's layout was written against), **GroupFrame** (the
    400x200 floor now goes through `MakeResizable` with `grips = false`, so it follows).
  - **The resize helpers scale their minimums and maximums**: `ApplyMinResize`, `ApplyResizeBounds`,
    `MakeResizable` (the handle keeps the unscaled numbers and re-applies them on a change, raising a
    window that now sits under its floor -- the client's bounds only constrain a drag and never grow a
    frame) and `PersistWindow` (the floor is scaled when a saved size is raised to it; the saved size
    itself is real pixels and is never scaled, so a saved 640x480 is 640x480 at every scale). Nothing
    shrinks on a scale-down.

- **KNOWN COSTS, stated rather than hidden.** (1) A tab's label grows but AceGUI's tab ART is a fixed
  height (~20px rows), so at 2.0 a tab label can exceed its band; the widths follow, the height cannot.
  (2) An AceGUI container holding a `LAGW-DatePicker` or a `TLabel` sees the widget's height change on
  the signal but AceGUI does not re-run the container's layout for it; the consumer's own redraw on the
  signal (a `DoLayout`) is what re-flows it -- a ClearFrame re-lays its own content. (3) A window raised
  to a new floor is not written to its status table until the next drag.

### Fixed

- **A programmatic resize of a `ClearFrame` (or `GroupFrame`) never fired `onResize` -- since MINOR 26.**
  Both Constructors call `MakeResizable` and then `AceGUI:RegisterAsContainer`, and the latter does
  `frame:SetScript("OnSizeChanged", ...)` -- SetScript, not HookScript -- which silently REPLACED the
  hook the resize framework had installed to wake its driver. A drag never needed the hook (the grip's
  mouse-down wakes the driver itself), so `resize_spec`'s drag examples stayed green and nothing noticed;
  a consumer's `W:MakeResizable(window, { onResize = ... })` on a ClearFrame fired only during drags,
  never for a `SetWidth`. Found by this release's own audit, driven red by removing the fix
  (`scale_spec.lua`, "fires a consumer's onResize for a PROGRAMMATIC resize of a ClearFrame"), and fixed
  by re-hooking after AceGUI's own handler.
- **`TLabel:SetFontObject` froze the font size at the moment of the call** (it copied the base's
  `GetFont()` into `SetFont`), so nothing could ever re-size a TLabel's text in place. It now sets the
  scaled font object, which follows.

### Tests

- `Tests/scale_spec.lua` (62 examples): the clamp, `Configure{ scale }`, `ScaledSize` rounding,
  `ScaledFont` (size = base x scale, path and flags kept, colour copied, cached per base, re-sized in
  place, base re-read by name, nil for a typo), the signal (fires with `(new, old)`, one per owner,
  raising listener isolated, fires after the fonts, weak owners), `SetScaledSize`, the resize
  minimums (bounds x scale, handle keeps unscaled, raise-to-floor, a destroyed handle stops following,
  no shrink on scale-down),
  `PersistWindow` (saved pixels untouched, floor scaled, the one-floor branch not scaled twice), RowList
  at 1.0 / 1.5 / 2.0 / 0.8 (row height, icon size, strip, header, checkbox, row stacking, header/row
  alignment to the pixel, action clearance, fonts, `ColumnWidth`, header-fit allowance, re-pooling, the
  refont hook), the menus, MakeLabel / DropdownBox / SearchBox, ShowDialog, ExpandableList, ClearFrame and
  GroupFrame (including the programmatic-resize fix above), TLabel, the DatePicker and BrandTabGroup.
  **One harness trap it found and documents:**
  `libs.fresh` gives a file its own library table, but AceGUI's registry keeps the constructors an
  EARLIER file's instance registered, and those close over that instance -- every widget built through
  `AceGUI:Create` ignored `SetScale` until `ace.fresh("AceGUI-3.0")` emptied the registry first.
- `Tests/datepicker_spec.lua` pins the widget at Version 2.
- Suite: **305 passed, 0 failed, 0 pending** (`lua Tests/wowapi/run.lua`, 2026-09-15).

---

## [v0.1.11] -- a date picker, a window that remembers its place, a breath, and a font for symbols

### Compatibility -- MINOR 27 -> 28

**Fully backwards compatible.** One new widget type, one new satellite file listed in this library's own
TOC, new public helpers (`PersistWindow`, `Breathe` / `StopBreathing` / `IsBreathing`, `AccentRGB`, the
`DatePicker` arithmetic table, and the symbol font: `SymbolFont` / `SymbolFontSmall` / `SymbolFontPath` /
`Symbol`), and two shipped asset folders (`Textures/`, `Fonts/`). Nothing was removed or changed in
signature; the three existing widget-type Versions stay at 29. A consumer that depends on this library
as an addon needs no change to either of its TOCs -- the library loads its own files. One `MINOR` for the
release, covering the four TOGBankClassic requests of 2026-09-13 and the two in-game follow-ups that
came out of the operator's first look at the date picker (the field click and the bundled glyph).

Feature-detect on the type or the number:

```lua
if AceGUI:GetWidgetVersion("LAGW-DatePicker") then   -- or (LibStub.minors["LibAceGUIWidgets-1.0"] or 0) >= 28
    since = AceGUI:Create("LAGW-DatePicker")
end
```

### Added

- **`AceGUI:Create("LAGW-DatePicker")` -- a date picker.** A label, a field showing the date as
  `YYYY-MM-DD` with a small calendar glyph inside it, and a month calendar popup (prev / next month, a
  day grid, **Today**, **Clear**) that opens on a click **in the field** or on the arrow beside it. The
  field click was added after the operator's first look: with only the 20px arrow as an opener they
  clicked the field, got a caret, and concluded there was no picker (TOGBankClassic inbox `bb9c59be`).
  A click in the field only ever *opens* -- a second one is the caret being placed, and closing the
  popup under it would fight typing; the arrow keeps its toggle. Its value is a plain number -- `time()` of
  **local midnight** on the chosen day -- or `nil` for "no limit"; the consumer does the range arithmetic.
  Requested by TOGBankClassic (inbox `3ecad6a6`, 2026-09-13) for the Since / Until filters on its guild
  bank log, whose two typed edit boxes it replaces.

  ```lua
  local since = AceGUI:Create("LAGW-DatePicker")
  since:SetLabel("Since")
  since:SetWidth(140)
  since:SetCallback("OnValueChanged", function(widget, event, ts)   -- ts is a midnight stamp, or nil
      filter.since = ts
      refresh()
  end)
  ```

  The EditBox-shaped contract, as asked: `SetLabel`, `SetWidth`, `SetValue(ts|nil)`, `GetValue()`,
  `SetDisabled(bool)`, `OnValueChanged(widget, event, ts|nil)`; plus `OpenCalendar` / `CloseCalendar` /
  `IsCalendarOpen` and `GetText`. Three rules worth knowing:

  - **`SetValue` is programmatic and fires nothing**, as AceGUI's `EditBox:SetText` fires nothing. Every
    user action -- a day click, Today, Clear, a typed date committed with Enter or by leaving the field --
    fires `OnValueChanged`, and only when the value actually changed.
  - **`SetValue` snaps to midnight of the local day it falls in**, so `GetValue` never hands back a
    mid-day stamp whatever was passed in. A range filter built on it compares like with like.
  - **Typing is the fallback, the calendar is the affordance.** The field accepts `YYYY-MM-DD` (also `/`
    or `.` as the separator, one- or two-digit parts, and a trailing `HH:MM` that is accepted and dropped,
    since the widget picks a day). An unparseable entry reverts to the current value and fires nothing;
    an emptied field commits `nil`. Escape reverts. `2026-02-30` is refused rather than normalised to
    March 2nd, which is what a bare `time{}` would have done.

  **The popup is one shared frame per library instance**, re-anchored and re-owned per widget. It sits on
  `UIParent` at TOOLTIP strata for the reason the menus do -- a popup parented into a consumer's window
  inherits its clipping, and one inside an AceGUI ScrollFrame would be cut off at the scroll edge -- so it
  is re-**owned** rather than literally re-parented, which is the property the request was after. It
  closes on Escape (its name is in `UISpecialFrames`, and Escape inside the field closes it too), on a
  click anywhere else (`GLOBAL_MOUSE_DOWN`), when the owning widget hides (window closed, tab released),
  on `OnRelease`, and on `SetDisabled`. A widget handed back to the pool mid-typing does **not** fire
  `OnValueChanged` out of `OnRelease` -- AceGUI clears the callback table only after `OnRelease` returns,
  so a commit there would have reached a consumer that had let go of the widget.

  **The day cells are plain buttons** -- a font string and the stock quest-title highlight, no Blizzard
  calendar textures. Classic Era is missing many textures later clients have (TOGBankClassic BROOM-001),
  and a grid that always renders beats a prettier one that goes blank. The selected day carries a locked
  highlight and the accent colour; today is accent-coloured.

  **The in-field glyph** is styled exactly as `SearchBoxTemplate` styles its magnifying glass -- read from
  `Blizzard_SharedXML/Shared/InputBox/InputBoxTemplates.xml` and `.lua`, not eyeballed: at the field's LEFT
  +1,-1, the text inset to clear it, vertex colour 0.6 grey while idle and empty, white while focused or
  holding a date. **The picture is a file this library ships: `Textures/calendar.tga`**, a 64x64 32-bit
  TGA of a white line-art calendar page (outline, header rule, two binder rings, three day dots) with an
  alpha channel, drawn at 14px. It was first the Wrath+ minimap calendar button cropped to 10px, and the
  operator's Era screenshot (TOGBankClassic inbox `62583e69`) showed why that was wrong: full-colour gold
  art at 10px reads as *"a small gold-ish square blob"* beside the magnifier's crisp grey line work. A
  bundled file renders identically on every flavour, which is the property a library-owned widget needs;
  its header layout is the one TOGBankClassic's own `broom.tga` uses, known to load on Era, TBC and retail.
  `SetTexture`'s documented `success` return is still checked and a miss -- the file absent from a checkout
  -- falls back to a page silhouette drawn from flat colour, which cannot go blank. `widget.glyphIsFallback`
  says which branch ran. **`.pkgmeta` must never ignore `Textures`**, and a spec now fails if it does, or if
  the file is missing or not a 64x64 32-bit TGA. The generator is a 60-line Lua script; the shape can be
  regenerated in seconds if the operator's first look wants it adjusted.

  Widget-type Version **1**: a new type with no competing copy anywhere, so there is no tie to break. The
  type name is prefixed (`LAGW-`) because there is no legacy name to preserve, unlike the three unprefixed
  types whose names are pinned by the FastGuildInvite fork.

- **`lib.DatePicker` -- the pure date arithmetic, public.** `midnight(y, m, d)`, `daysInMonth(y, m)`,
  `isLeap(y)`, `parse(text) -> ts | nil, reason`, `format(ts)`, `ymd(ts)`, `snap(ts)`, `grid(y, m)` (42
  Sunday-first cells, six rows always), `stepMonth(y, m, delta)`. A consumer that already parses dates by
  hand (TOGBankClassic's `Browse:ParseDate`) can use `parse` and stop maintaining a second copy of the
  rule.

- **`W:PersistWindow(widget, savedTable, opts)` -- a window that remembers its position and size**,
  across open/close and `/reload`, from a table the **consumer** owns (its SavedVariables slot, an
  AceDB char/profile sub-table). Requested by TOGBankClassic (inbox `3ba9f0f7`, 2026-09-13) after their
  mailbox window opened at 560x480 mid-screen on every open: they had spelled `SetStatusTable(pos.<key>)`
  five ways across five windows and the fifth had none. Every AceGUI-window addon in the fleet carries
  the same five lines.

  ```lua
  W:PersistWindow(window, MyDB.char.windows.mailbox, {
      width = 560, height = 480,         -- applied when the table has no size yet
      minWidth = 420, minHeight = 300,   -- the floor: resize bounds AND a raise of a saved size
  })
  ```

  Works on anything with `SetStatusTable` -- a `ClearFrame`, AceGUI's own `Frame`. Fills an empty table
  with the defaults, **raises a saved size under the floor to it** (AceGUI applies a status table as-is,
  so a saved 300x200 under a 420x300 floor came back as a window that could not be dragged wider than it
  already was), hands the table to `SetStatusTable` so AceGUI's own drag/resize writes land in the
  consumer's save, and sets the bounds -- through the `ClearFrame`'s existing resize handle when it has
  one, so the handle and the frame agree. A `nil` table means "no save": a fresh table with the defaults
  is applied and returned. **The library keeps no copy of the coordinates**, so a consumer that recenters
  by clearing `top`/`left` and calling `ApplyStatus` sees exactly that. A corrupted saved size (`"560px"`)
  is replaced rather than handed to `SetWidth`. Returns `nil` for a widget with no `SetStatusTable`; a raw
  frame wants `MakeResizable` with its `status` option instead. **One defect caught by the session's own
  audit before release:** on a widget with no resize handle, giving `minWidth` alone reached
  `ApplyResizeBounds(w, 420, nil)`, whose `minH or 0` reset the frame's existing minimum height to zero.
  A missing floor now keeps the frame's current bound; driven red (`{420, 0}` against `{420, 250}`), then
  fixed.

- **`W:Breathe(region [, opts])` / `W:StopBreathing(region)` / `W:IsBreathing(region)` -- the fleet's
  alpha-pulse attention-getter as one call.** Requested by TOGBankClassic (inbox `370504bb`, 2026-09-13),
  who had the identical eight lines three times -- a cancelled request's date glow, the bank window's help
  icon, the status bar's urgent line -- with the numbers copied by hand and a comment saying "the same as
  Requests" with nothing asserting it. FastGuildInvite and Dibs use the same idiom.

  ```lua
  W:Breathe(statusLine)                                     -- 1 -> 0.35 -> 1, one second each way, eased
  W:Breathe(icon, { low = 0.5, seconds = 0.6, smoothing = "IN_OUT" })
  W:StopBreathing(statusLine)                               -- Stop + SetAlpha(1); no-op if it never breathed
  ```

  **The defaults are the fleet's existing breath** -- `0.35` / `1.0` / `IN_OUT` / `BOUNCE` -- so lifting a
  call site onto this changes nothing on screen. **Idempotent:** the animation group lives on the region
  under one library-owned key, so a second call re-parameterises the same group rather than stacking
  another, and a pooled AceGUI frame handed back and reacquired reuses it. Works on a Frame; on a Texture
  or FontString too where the client allows (they are AnimatableObjects everywhere this library ships),
  but a consumer that wants a harness-driveable breath puts it on a **Frame** -- the offline model's
  regions cannot animate, and `Breathe` returns `nil` rather than raising for a region that cannot.

- **A symbol font the library ships -- `Fonts/DejaVuSans.ttf`, with `W.SymbolFont`, `W.SymbolFontSmall`,
  `W:SymbolFontPath()` and `W:Symbol(name)`.** The client's fonts have no arrows, check marks, crosses
  or warning signs: TOGBankClassic's tooltip `select -> split -> attach -> send` arrows (U+2192) drew as
  empty boxes on Classic Era. The operator's ruling (inbox `b7f9981a`, 2026-09-13): *"those fonts should
  be in the widgets library, so every addon can use them, no reason to get them per addon"* -- so
  per-addon font bundling is ruled out for the suite, and a glyph is either drawn through this font or
  replaced with ASCII.

  ```lua
  fs:SetFontObject(W.SymbolFont)                 -- 12px; W.SymbolFontSmall is 11px
  fs:SetText(W:Symbol("check") .. " Synced")     -- or W:Symbol("check") or "[OK]" on an older copy
  fs:SetFont(W:SymbolFontPath(), 14, "")         -- a FontString you size yourself
  ```

  The font is **DejaVu Sans 2.37** (757 KB), its licence beside it -- Bitstream Vera terms plus
  public-domain DejaVu additions, which permit redistribution with the notice. Its identity and coverage
  were read from the file's own `name` and `cmap` tables before it shipped, not assumed from its path,
  and a spec re-reads the cmap on every run: **every code point `W:Symbol` names must map to a glyph**,
  so the symbol table and the font cannot drift apart. Seventeen names: the four arrows, `check` /
  `check_heavy`, `cross` / `cross_heavy`, `warning`, `le` / `ge`, `plusminus`, `bullet`, `star` /
  `star_hollow`, `play`, `refresh`. `Symbol` answers `nil` for an unknown name rather than `""`, so
  `W:Symbol("check") or "[OK]"` degrades on an older copy or a typo. The two font objects are named
  globals (`LAGWSymbolFont`, `LAGWSymbolFontSmall`) built once and reused on a re-run of the file.

  **What it can and cannot do, confirmed rather than taken from the request:** a FontString the consumer
  *owns* -- a RowList cell, a label, a status line -- takes the font wholesale. A GameTooltip line is one
  of the tooltip's own FontStrings (`GameTooltipTextLeftN`) carrying the tooltip font: `SetFont` on it is
  legal but sticks to that line *slot* for every later tooltip until reset, so it is not a per-line font
  and this library does not do it. Chat text goes through the chat frame's one font. A tooltip or chat
  line keeps ASCII whatever font ships, unless the consumer draws that text on FontStrings of its own.
  `.pkgmeta` must never ignore `Fonts`; the spec fails if it does. Whether DejaVu Sans renders at 11-12px
  on Era the way it does elsewhere is the operator's in-game check; the file has not been seen in game.

- **`W:AccentRGB()` -- the accent as `r, g, b` floats, public.** It was a file-local in the core, which
  the satellite files could not reach: the DatePicker needed the accent as floats, and the alternatives
  were a second hex-to-float conversion in that file (one concept, two spellings) or reaching into the
  core through an undocumented field. Same value `BrandTabGroup` tints the tab band with.

- **`Tests/datepicker_spec.lua`** -- 53 examples, and the widget half constructs the widget through real
  AceGUI-3.0 against the frame model, opens the popup, clicks day buttons and reads the grid back, which
  is TOGBankClassic's contract point 4 verbatim. The clock is pinned per test to local midday of a named
  day with `time{}` and every expectation is built with the same `time{}`, so the box's time zone cancels
  out -- the harness default epoch is 2026-01-01 00:00 **UTC**, which is 2025-12-31 in every western zone.
  100% line coverage of the new file, including the "client has the texture" branch, driven by making the
  model's `SetTexture` answer the documented `success = true` for one construction. Two things the harness
  at the current pin cannot reach, said plainly: `IsMouseOver` is always false offline, so "a click inside
  the popup keeps it open" is not exercised; and its EditBox model had no `GetTextInsets`. The harness
  shipped `GetTextInsets` the same afternoon (`e519858`) and this release adopts that pin, so the 20px
  left inset IS asserted now, and the spec loads the satellite through `libs.fresh` like the other files
  instead of by hand.

- **`Tests/persist_spec.lua`** (11 examples) drives `PersistWindow` against this library's own
  `ClearFrame` built through real AceGUI-3.0 -- its `SetStatusTable` / `ApplyStatus` are the real code
  paths and its resize handle the one the helper has to keep in step with -- including the recenter case
  and the corrupted-save case. **`Tests/breathe_spec.lua`** (7 examples) pins one group per region, the
  fleet's numbers by default, re-parameterise-not-stack, and alpha restored on stop; the model builds
  real AnimationGroup objects but does not run them, so no alpha is asserted mid-pulse. Both new helpers
  are at 100% line coverage. **`Tests/symbolfont_spec.lua`** (4 examples) pins the path, the two font
  objects' sizes, `Symbol`'s answers, and parses the shipped `.ttf` -- family name and format-4 cmap --
  to prove every named symbol has a glyph, that the licence ships, and that `.pkgmeta` packages `Fonts`.

### Harness

- **`tools/verify-libs.lua` reported TOC DRIFT for this library the moment the satellite was added, and
  that is the tool working.** Its manifest lists this library's files explicitly and pins the count of
  unlisted TOC entries; the new satellite made that count wrong, and it said so by name. Raised on the
  harness inbox (`1a7caf76`) and delivered the same day as `e519858` -- the manifest line plus a real
  `EditBox:GetTextInsets`. **This release moves the harness pin `c9f3199` -> `2365af4`** (origin/main,
  past that commit); `verify-libs` reports the library at 43 methods with no drift, and a consumer suite
  loading this library through `libs.load` now gets the DatePicker type registered. The pin was briefly
  blocked by one operator-approved permission line sitting uncommitted in the *submodule's*
  `.claude/settings.json`; the harness committed it as `2365af4`, which is why the pin lands there.

## [v0.1.10] -- right-click a row, an update nudge that could go missing, and the interface list guards itself

### Compatibility -- MINOR 26 -> 27

**Fully backwards compatible.** One method gained two trailing optional arguments; nothing was removed
or changed in signature, and no widget structure moved, so the three widget-type Versions stay at 29.
A consumer on any earlier copy needs no code change, and nothing that worked before behaves
differently -- except the load-order case in *Fixed* below, where the old behaviour was the defect.

One `MINOR` for the release, covering both the API addition and the fix. The addition is the ordinary
reason to bump. The fix would have needed one on its own, and the reason is LibStub rather than the
API: `NewLibrary` is `if oldminor and oldminor >= minor then return nil end` -- read from the vendored
`libs/LibStub/LibStub.lua`, not recalled -- so **equal minors resolve by load order**. This library is
embeddable and several addons ship their own copy: leaving both the fixed and the unfixed copy at 26
means whichever loads first wins, and an addon carrying the stale copy would silently supply the
broken `EnableVersionCheck` to everybody. That is the same trap peer-review finding 12 caught one
level down, where three widget types sat tied with a vendored fork and the registry quietly undid a
declared dependency.

Feature-detect on the number, since a bug fix has no new symbol to look for:

```lua
if (LibStub.minors["LibAceGUIWidgets-1.0"] or 0) >= 27 then
    -- onRowClick receives (entry, idx, rl, button, rowFrame), and
    -- EnableVersionCheck will keep looking, so calling it early is safe
end
```

**One internal changed shape and nothing outside reads it:** `lib._vc` no longer takes the value
`false`, only nil or the VersionCheck handle. Checked across every addon on this box rather than
assumed -- no consumer touches it, and `TriggerVersionCheck` treats nil and `false` identically.

### Added

- **`RowList` `onRowClick` now receives the mouse button and the row frame:**
  `onRowClick(entry, idx, rl, button, rowFrame)`. Both were in hand at the call site and discarded,
  so a consumer wanting a right-click menu had to call `GetMouseButtonClicked()` inside the handler
  and stash the row frame from `onRowEnter` -- inferring widget internals for facts the widget
  already held. Additive: a three-argument handler is unchanged. Raised by VersionCheck-1.0 for a
  right-click-to-whisper menu on its roster window.

  ```lua
  onRowClick = function(entry, idx, rl, button, rowFrame)
      if button == "RightButton" then
          W:OpenMenu(rowFrame, whisperItems(entry))
      end
  end
  ```

- **`Tests/toc_spec.lua` -- the interface list is now pinned against Ace3 instead of re-fixed by
  hand.** Peer review wrote the rule down in August: *a shared library's interface list must contain
  every value any of its consumers ships.* It has been violated twice, because both times the
  instance was fixed and the rule was left unasserted -- and the second violation was found by a
  consumer being unable to take a hard dependency, not by anything here.

  The spec asserts that this library claims every client `../Ace3/Ace3.toc` claims. Ace3 is this
  library's own hard `## Dependencies`, so it is a floor that moves with the ecosystem when Ace3 is
  updated: claiming more than Ace3 is meaningless because this library cannot load where Ace3 cannot,
  and claiming **less** is the defect that stops consumers loading. A hardcoded list of current
  values was rejected deliberately -- that is the transcription the review objected to, restated as a
  test, and it would need editing every patch by somebody who knew to.

  **Driven RED, not merely written:** removing `11508` and `120100` from the TOC gives
  *"LibAceGUIWidgets.toc is NARROWER than Ace3.toc, which it hard-depends on. Missing: 11508,
  120100"*, and takes the companion assertion (that this library claims the two clients actually
  installed on this machine, per `.build.info`) with it. Reverted.

  A missing Ace3 is a **failure**, not a skip -- a checkout without it is a broken dev environment,
  and an assertion behind a condition that may not hold reads as a passing test.

- **`Tests/resize_spec.lua` now covers the PROGRAMMATIC resize path**, which had no coverage at all
  -- not weak coverage, no way to reach it. A consumer calling `SetWidth`, or a parent re-laying out,
  reaches `onResize` through an `OnSizeChanged` hook rather than through a drag; the harness pin this
  release adopts is what made that reachable, and harness contract 1 named it as the thing to write
  once it was. It asserts the same once-per-draw promise the drag path has, because `SetWidth` and
  `SetHeight` arrive as two separate size changes and firing per change would double-render every
  programmatic resize. **Driven RED** by dropping the hook in `MakeResizable`: *"two setters in one
  draw produced 0 callbacks"*.

  **The same mutation leaves the drag-path coalescing test green**, which is worth knowing: the drag
  wakes the throttle through the grip's own mouse-down and never needs that hook. The two paths are
  genuinely independent, and only the new test covers the second one.

- **The coalescing test now counts its INPUTS, not just its output.** It asserted that ten size
  changes produce one callback -- but never that ten size changes actually arrived, so a harness that
  dispatched nothing would have satisfied it just as happily. That is not hypothetical: it was
  exactly this file's state before the harness pin moved, when the same assertion passed while
  measuring nothing. **This one is a tripwire rather than a verified assertion and the spec says so**
  -- what it guards against is a harness regression, and `Tests/wowapi` is a submodule this repo must
  never edit, so it cannot be driven red from here.

### Fixed

- **`W:EnableVersionCheck` stopped looking for VersionCheck-1.0 after one miss, for the whole
  session and for every consumer.** The lookup cached its result as `LibStub("VersionCheck-1.0",
  true) or false`, guarded by `if self._vc == nil` -- and `false` is not `nil`, so the first call
  decided the answer permanently. `_vc` lives on the shared library table and VersionCheck is a
  separate addon, so any consumer calling this from its own `ADDON_LOADED` **before** VersionCheck's
  file has run froze the miss: every addon that loaded afterwards, including ones that hard-depend
  on VersionCheck, got `nil` back from a library that had given up. Only a hit is cached now; a miss
  re-resolves on the next call, which costs one LibStub table index. Found while confirming for
  VersionCheck-1.0 that this library's soft dependency on it creates no cycle -- the lazy resolution
  is what makes that safe, and it was only lazy once.

### Changed

- **The `## Interface` list now matches Ace3's, plus the current Retail build.** Added `38002`
  (the Wrath-family client), `120100` (Retail 12.1.0 -- the installed client here, per
  `.build.info`; the list previously stopped at `120007` = 12.0.7 and so read as out of date),
  and the previous-patch entries Ace3 itself carries, `11508` / `20505` / `50503`.

  **This is not cosmetic for a consumer that hard-depends on this library.** An addon whose own
  TOC lists a client this one omits shows this library as out of date on that client, and unless
  the player has ticked *Load out of date AddOns* the library does not load -- which takes the
  dependent addon down with it. Ace3 is this library's own hard dependency, so its list is the
  correct floor: this library cannot usefully claim more clients than Ace3, and claiming fewer is
  exactly the failure above. Raised by VersionCheck-1.0, which is taking a hard dependency on this
  library for its guild-roster window.

  **The three retail values carried forward were checked too, and they do not all rest on the same
  evidence.** `120007` and `120005` are shipped by addons maintained well outside this suite --
  BugSack, Bagnon, Bartender4, `LibDualSpec-1.0`, `LibActionButton-1.0`, DBM's Mainline TOCs -- which
  is corroboration rather than an echo, because nothing propagates a value between them. **`110207`
  is weaker: exactly one genuinely third-party TOC carries it** (`HereBeDragons`, vendored inside
  GatherMate2, and itself an older list). Every other appearance is this suite's own addons or its
  own test harness, quoting each other. It is kept because a retired-but-real value costs nothing and
  removing one can only ever narrow what this library claims -- which is the direction that breaks
  consumers -- but it is the one number here nobody has sourced properly, and saying so beats a third
  round of reporting all of them as "current".

  This part is packaging rather than API -- a `.toc` line is not code, and a dev checkout was never
  affected, since the `## Interface` list only decides whether the client marks the addon out of date.
  It reaches players on the next published build.

## [v0.1.9] -- any window can be resized now, not just a ClearFrame, and a tooltip that spammed errors on hover

### Added -- MINOR 26

- **`W:MakeResizable(frameOrWidget, opts)` -- the drag grips, without having to be a ClearFrame.**
  Attaches the same three sizer strips ClearFrame has to **any** frame (or any AceGUI widget's
  `.frame`), with resize bounds, live callbacks and size persistence. Returns a handle:

  ```lua
  local h = W:MakeResizable(myWindow, {
      minW = 400, minH = 200, maxW = 1200, maxH = 900,
      grips  = "SE S E",              -- a SET, not one corner; `false` for none
      status = MyDB.window,           -- width/height/left/top persisted on drag end
      onResize     = function(f, w, ht) list:Refresh() end,   -- LIVE, once per draw
      onResizeStop = function(f, w, ht) rebuildTheExpensiveThing() end,
  })
  h:SetEnabled(false)                 -- a locked window
  h:IsResizing()
  ```

  **What it replaces is thirty lines of copy-paste.** Resizing was a property of *being* a
  ClearFrame: three anonymous sizer frames and four local `OnMouseDown` handlers inside that
  widget's constructor, reachable only by constructing one. A consumer with its own window had to
  reproduce them, and three things it could not get at all -- no live callback (ClearFrame persists
  on mouse-up only, so a window whose contents must re-lay-out *while* the user drags has nothing to
  hook), no maximum size, and persistence welded to AceGUI's `status` table, which a plain frame
  does not have.

  **`onResize` is throttled to at most one call per frame draw**, coalesced through a hidden
  OnUpdate driver that is shown only while a size change is pending. That is not a nicety: an
  un-throttled live callback means a full re-render per mouse pixel, which is why "just hook
  `OnSizeChanged`" is the wrong answer and why the live callback is safe to offer at all.

  Consumers on an older copy feature-detect with `if W.MakeResizable then`.

- **`W:ApplyResizeBounds(frameOrWidget, minW, minH[, maxW, maxH])`** -- `ApplyMinResize` with a
  maximum. Same modern-`SetResizeBounds` / Classic-`SetMinResize` fork, and it only touches
  `SetMaxResize` when a maximum was actually given, since a bound of 0 is not the same as no bound.
  `ApplyMinResize` is unchanged and still works.

- **`W:GetResizeHandle(frameOrWidget)`** -- the handle a previous `MakeResizable` attached, so a
  consumer can re-point callbacks or read `IsResizing()` without holding the constructor's return.

### Changed -- MINOR 26

- **ClearFrame builds its grips through the framework rather than beside it.** Identical geometry,
  identical `StartSizing` points, identical persistence -- the difference is that there is now one
  implementation instead of two that happen to agree. Its `SetResizable` call and its
  `SetResizeBounds`/`SetMinResize` fork are gone from the constructor too; the framework is the only
  place in this library that has to know the two spellings.

  **GroupFrame did not gain grips.** It has never had any, and adding them would change shipped
  behaviour for consumers of a widget that only ever asked to be resizable programmatically.

- **Widget registration Versions 28 -> 29** for `ClearFrame`, `GroupFrame` and `TLabel`.
  ClearFrame's frame structure genuinely changed (an extra child frame -- the throttle driver); the
  other two move with it because `Tests/widgetversion_spec.lua` requires the three to stay equal,
  and the last time one was raised alone the other two sat tied with FastGuildInvite's vendored fork
  for an unknown length of time with nothing saying so.

- **`docs/LIBRARY_CONTRACTS.md`** -- a new inbound board where consuming addons raise work against
  this library, answered here in place. It settles the process point that has been open on
  `docs/AUDIT.md` since round 3: **consumers request, this library authors.** A shared library
  changed from inside whichever consumer happened to be open is a change to ~20 addons decided by
  accident, and until now Dibs' own `CLAUDE.md` ("put a reusable widget in the library") and the
  fleet rule ("consumers adopt, never author") could not both be satisfied. `Tests/HARNESS_CONTRACT.md`
  is the outbound counterpart and now exists too, carrying two contracts this work raised against
  the test harness.

### Fixed -- MINOR 26

- **`W:AttachTooltip` no longer raises `bad argument #1 to 'SetText'` on hover, and no longer stacks
  a handler per call.** Reported in game against v0.1.9; the defect is older than that release and is
  mine either way. Two separate faults in one helper:

  - **The guard was `if title and title ~= ""`, which is not a type check.** A table, a boolean or a
    function passes both halves, and `GameTooltip:SetText` is a C function that then raises --
    **inside an `OnEnter` handler**, so the consumer gets a red error every time the cursor crosses
    the control and nothing in the traceback points at their own call site. Text is now taken only
    when it is a string or a number; anything else draws no line instead of raising.
  - **`HookScript` APPENDS a handler and never replaces one**, so every re-attach installed another
    closure holding its own copy of the text. A consumer refreshing a tooltip whose title reports a
    value the same control changes ended up with one handler per refresh -- which is where an `11x`
    error count comes from, and it meant the *first* call's stale text was still being drawn on the
    way past. The text now lives on the frame and the hooks install once, so a later call **updates**
    what is shown. The refresh use case gets better rather than worse.

  Both driven RED first, and the reverted guard reproduces the reported message verbatim:
  `bad argument #1 to 'SetText' (Usage: self:SetText(text [, color, alpha, wrap]))`, plus
  `10 OnEnter handlers were installed by 10 calls`. Nine new specs; suite **160 passed / 0 failed**.

- **The suite asserts geometry for the first time** (peer review finding 8): `Tests/resize_spec.lua`
  computes grip rects from real `GetLeft`/`GetRight`/`GetBottom` and pins that the bottom strip and
  the corner grip share no pixels -- a band where the two overlap is a drag decided by hit-test
  order rather than by which grip the user aimed at. Driven RED first, by moving the S strip's
  offset.

- **RowList's header is pinned to its rows, closing the oldest half of finding 8.** `_buildHeader`
  has its own placement chain, structurally parallel to `_buildRow`'s and **not shared** -- the same
  rule written out twice in two functions, with nothing asserting they agree. Five new specs assert
  from real rects that the bar spans the same extent as a row, that **every header column sits over
  its own cells to the pixel**, that both reserve the same action-icon strip and move by the same
  amount when actions are added, and that the bar shares no pixels with row 1.

  The chains are deliberately **not merged**: one function serving a Button-with-sort-arrow and a
  FontString-or-CheckButton is a bigger change than the defect justifies. Pinning the agreement is
  what makes the duplication safe -- an edit to one chain now has to touch the other or go red.
  Driven RED first: 2 px added to the header's left offset gives `column 'name': header starts at
  x 8.0, its cells at x 6.0`.

  Suite **152 passed / 0 failed** (was 122), on harness pin `1ffc8b4`.

## [v0.1.8] -- a peer-review round closed, an initial sort for RowList, a searchable dropdown, and named cooldowns

### Added — MINOR 25

- **`RowList:SetSort(key[, desc])` -- a list can finally open in a useful order.** Sets the active sort
  column without a header click; call it before `SetData` and the first render is already sorted. A nil
  key clears the sort and restores the model's own order.

  **What it replaces is nothing at all.** `_getSortedData` returns `self.data` verbatim when there is no
  `sortKey`, and the only writer of `sortKey` was the header's `OnClick`. So the sole mechanism a
  consumer had for a sorted list was **asking the user to click a header**, and every list opened in
  whatever order its model handed over. Dibs' Loot Log opened in the raw append order of a
  network-merged store while its own module asserted in writing that the tab sorted on time -- and
  since peers receive in different orders, two players looking at the same data saw different lists.

  It writes the same two fields the header handler does, so the two compose: a later click on the
  sorted column toggles direction rather than resetting. `desc` is normalised to a real boolean for
  exactly that reason -- a nil left in place would make the first click produce descending when the
  caller had asked for ascending. Consumers on an older copy feature-detect with `if rl.SetSort then`.

  **Peer review finding 14, remedy 1**, confirmed from the consumer side and still wanted after Dibs
  fixed its own model: *"a consumer sorting its model to work around a widget gap is a workaround, not
  a design."* Remedy 2 (a total comparator via a `tiebreakKey`) is deliberately **not** in this entry --
  Dibs withdrew the pressure behind it, because two awards can share a whole-second stamp and differ in
  nothing the row carries, so only the consumer can supply a genuinely unique key.

- **A dropdown menu can carry a SEARCH box.** `CreateDropdownBox{ search = true, items = function(query) … }`,
  or `OpenMenu`/`ToggleMenu` with `opts.search` plus `opts.itemsFor(query)`. The box sits above the rows in the
  **root** menu only, takes focus on open, and re-runs the items function on every keystroke. Escape closes the
  stack.

  **The library owns the box; the consumer owns what a query means.** That split is the whole design: the
  library cannot know whether `agi` should match a name, a stat, an item level or a class token, so it never
  tries — it hands the typed text back and renders whatever comes out. Which also means "top 5 by score" and
  "…and 30 more" are the consumer's rows, not a feature here.

  Two details that are load-bearing rather than incidental:

  1. **The box is built once per pooled menu frame and reused**, and `_onSearch` is re-pointed on every render.
     Without the indirection a keystroke would re-run the items function captured at the open that first
     created the box, which for a per-category dropdown is a *different category's* list.
  2. **`OnTextChanged` gates on the `user` flag.** `OpenMenu` clears the box on every open, and that
     programmatic change fires the handler too — reacting to it would render every menu's list twice, once
     with the query the caller already passed and once with the same empty string.

  Submenus deliberately never get a box: a submenu is the *result* of a selection in the root, so filtering one
  would be filtering a filter.

  First consumer is Dibs' Planner > Buffs picker, where a single group is several hundred consumables and the
  previous answer — cascading sub-menus by primary stat — could not answer "which food gives me agility?"
  because the item names don't say.

  **Peer review finding 5, fixed before release.** "The search box is on" was spelled two different ways and
  they disagreed: the render guard required `search` **and** `itemsFor`, the focus call required `search`
  alone. Menu frames are pooled and the box outlives the open that created it, so a later call passing
  `search` without `itemsFor` hid the box and then focused it — keyboard focus on an invisible frame, with
  `OnEscapePressed` bound to something that would not receive it. There is now a single `hasSearch(opts)`
  used by both. The value is not the branch; it is that the predicate stops being two spellings that can
  drift apart.

### Fixed — MINOR 25

- **`RowList` has geometry tests for the first time.** Three assertions computed from real
  `GetLeft`/`GetRight` rects: the reserved icon strip is sized from the actions surviving construction;
  no action button overlaps the rightmost column; and a row's cells are separated by a real gap. This
  library's product is positions and pixels and its suite asserted none, so a layout defect could ship
  green. Peer review finding 8. No shipped behaviour changed.

  **Each was driven RED by mutating the code it guards, and that caught a defect in one of the tests.**
  All three describe properties that are correct by construction, so none could be proven by a real
  bug. Written first as `cellRight <= nextCellLeft`, the third stayed **green** when the inter-column
  gap was deleted -- losing the gap makes adjacent cells touch rather than overlap, and `<=` accepts
  touching. It is a strict `<` now, and goes red on that mutation with `gap 0.0`. A geometry assertion
  that has never been seen to fail may not be able to.

- **Three stale interface versions corrected: Wrath `30403` to `30405`, Cata `40400` to `40402`, MoP
  `50503` to `50504`.** The other five values in the list were already current.

  **This matters more on a library than on an addon, and more than "out of date" usually implies.**
  `LibAceGUIWidgets` is a hard `## Dependencies` of Dibs, not an `## OptionalDeps`. A hard dependency
  that the client refuses to load takes the consumer down with it -- so on a Cata client, for a user
  who has not ticked "Load out of date AddOns", the symptom is not a widget that looks wrong. It is
  **Dibs missing from the AddOn list with nothing saying why.**

  **Peer review findings 1 and 6.** Finding 1 was declined first, correctly: *"copying an unverified
  snapshot into a TOC that five addons share is exactly how the stale value got there. Needs a source,
  not a transcription."* Finding 6 supplied a source -- the suite's own per-flavour TOCs -- and noted
  its own weakness, that a fleet agreeing with itself could be stale together.

  **That weakness is now closed, by a source neither finding used.** Every one of these three values is
  independently shipped by third-party addons on this machine, maintained by people with no connection
  to this suite: `30405` by DBM, Details, BugSack, BasicMinimap and LibDualSpec; `40402` by DBM,
  Details, AddonUsage, autograts and BugSack; `50504` by DBM, Details, Bagnon, BasicMinimap and
  BugSack. Independent agreement across unrelated maintainers is the evidence a shared list could not
  provide on its own.

- **`GroupFrame` and `TLabel` register at widget Version 28, so a declared dependency on this library
  actually delivers this library's widget.** Both sat at 26 -- the same version FastGuildInvite's
  vendored fork registers them at. AceGUI's guard is `if oldVersion and oldVersion >= Version then
  return end`, so **equal versions resolve by load order**, and load order between two addons with no
  dependency relationship is something neither can control. A consumer could declare this library, have
  the loader honour it, and then be handed the fork's widget by the registry. `ClearFrame` was never
  affected: it was already 28 and won on the number.

  **The bump is to break a tie, not because the frame structure changed** -- which is the usual reason
  to move a widget Version here, so it is called out. All three now sit at 28 together.

  **Nobody can currently observe this**, and that is stated rather than dressed up: FGI is the only
  consumer of those two types and it owns the competing copy, so whichever wins is method-identical,
  and Dibs -- the one addon that declares this library properly -- uses only `ClearFrame`. It matters
  the moment a second addon declares this library and creates a `TLabel`. A prefix was the other
  option and was rejected: this library's purpose is to BE the shared implementation, and renaming its
  types would strand the consumers already using them by name.

  **Peer review finding 12.** Each of the three declarations now carries a comment naming the other
  registrant and the version rule, because `RegisterWidgetType` returns nothing and logs nothing --
  neither side can detect which registration took effect, so a comment is the only thing that makes
  the next divergence visible.

  **`Tests/widgetversion_spec.lua` is new and pins it**: all three types register, each STRICTLY above
  the competing copy's 26 (a tie is not good enough -- it resolves by load order, so "equal" and
  "loses" are the same outcome from a consumer's seat), and all three stay equal to each other so one
  cannot silently fall behind again. It is the first spec here to load real AceGUI-3.0, because the
  library's three `LibStub("AceGUI-3.0", true)` lookups are silent and skip registration entirely
  without it -- which is why no earlier spec had ever observed a widget Version.

- **The word "stable" is gone from the sort comment and from a spec title, because it was a category
  error.** `RowList`'s comparator was described as having *"a stable case-sensitive tiebreak"*, and a
  spec was titled *"...so the order is stable"*. **A tiebreak is not stability.** A tiebreak gives a
  total order over values that DIFFER; stability preserves input order for values that are EQUAL, and
  `table.sort` is quicksort in Lua 5.1 and reorders freely. On exactly equal cells the comparator
  returns false in both directions and those rows land wherever the sort leaves them -- and two equal
  numbers return at the numeric branch and never reach the tiebreak at all.

  **Why the wrong word is worth a changelog line.** A consumer read "stable" as a promise that a
  pre-sorted order would survive the widget's re-sort. It does not. The comment now says what actually
  holds, and says that a consumer needing determinism has to supply a genuinely unique key -- the
  widget cannot invent one, because uniqueness lives in the consumer's entries.

  **Peer review finding 11, whose own open question this closes.** It asked whether any spec asserted
  stability, noting that if one did it was *"either wrong or testing the tiebreak and named
  misleadingly"*. It was the second: the spec is correct and its title was not. Renamed, and a second
  spec now pins the exactly-equal case so nobody re-reads "tiebreak" as "stable" later.

  **The released v0.1.4 entry further down this file still contains the phrase and is LEFT ALONE** --
  released entries are not edited here. This entry is the correction.

- **A second width-less `RowList` column is now a construction-time error instead of a column that
  silently is not there.** `autoIdx` is the FIRST column with no `width` and both placement chains stop
  there, then guard on `col.width` with no `else`. So any later width-less column got no cell, no
  header and no anchor, and the populate loop swallowed the miss with `if cell then`: **no error, no log
  line, and a column the consumer had declared simply absent from the widget.** `New` now raises,
  naming every offender.

  **Raising was chosen over quietly defaulting the extra to zero width**, which would draw a column the
  caller cannot see -- that reads as "no data" rather than as a bug, and sends the next person looking
  at their data source instead of their column list. The docstring states the rule now as well, since
  it previously taught `width = nil` as an ordinary per-column option and never mentioned a limit.

  **Checked before shipping a hard error, because turning silence into a raise can break a consumer
  that was quietly getting away with it:** all twelve `RowList` construction sites in Dibs were read,
  and every one declares exactly one width-less column. Nothing shipped is affected.

  **Peer review finding 10.** Driven red first -- construction *succeeded* with two width-less columns
  before the change, which is the defect stated as a test.

- **A hole in `RowList`'s `actions` array no longer crashes the draw.** `opts.actions` was taken verbatim
  and every read of it used `#`, which is **undefined** on a holed table in Lua 5.1. A consumer writing
  `cond and action or nil` anywhere but the last slot produced a table whose `#` reported the full length;
  the draw loop then handed nil to the icon builder and **raised** -- out of the public `SetData`/`Refresh`,
  mid-draw, into the consumer's own call site, since nothing in the file protects the path. `New` now
  compacts the array once, with `table.maxn` rather than `ipairs`, because `ipairs` stops at the first hole
  and would drop exactly the entries at risk. Every later `#self.actions` is honest as a result, the
  reserved icon strip included.

  **A TRAILING nil is not part of this and never was**, which corrects how the defect was first described.
  Assigning nil in a table constructor creates no key, so `{a, nil}` is indistinguishable from `{a}` -- to
  `#`, to `ipairs` and to `table.maxn` alike. A consumer whose last entry is conditional simply passes one
  action and gets one action. The whole real population is a leading or interior hole.

  **This is a documented capability, not a consumer error to be scolded for.** `show = function(entry)` and a
  nil `texture` both exist to say "this action may not apply", so reaching for `cond and action or nil` in the
  constructor follows the grain of the API. The docstring now says holes are fine, and points at `show` for
  per-row visibility, since omitting an action removes it from every row and shrinks the strip.

  **Peer review finding 7, raised from the consumer side.** It had already shipped at two of Dibs' four
  `RowList` call sites, while two others had independently discovered the safe idiom
  (`if x then table.insert(...) end`) -- the usual sign that an API's easy path is the wrong one. Fixing it in
  Dibs protected Dibs; this protects every other consumer. Driven red first: the three hole-exercising specs
  failed with `attempt to index local 'action' (a nil value)` before the change.

- **Blank cells no longer lead an ascending sort.** `RowList`'s nil ordering was the exact inverse of the two
  comments beside it: `if av == nil then return not desc end` returns true ascending, so a nil-valued row
  sorted *before* a valued one. The header handler sets ascending whenever you click a **new** column, so
  ascending is what a user gets first — meaning the first click of every sortable column floated every empty
  cell to the top, above all the real data. On an EP-delta column, that is a screen of "n/a" rows.

  The two returns are swapped back. `nilsLast` is unaffected: a column that opts in still keeps blanks at the
  bottom in both directions.

  **The specs are the part worth reading.** Two of them pinned the defect and their titles said so out loud —
  *"currently sorts nils FIRST ascending (comment says last)"*. That is more honest than silently encoding it,
  and it was still a decision nobody made, sitting green for weeks: code, comments and tests in three-way
  disagreement, each reading as corroboration for whichever you looked at first. They now assert the intent,
  and carry a note saying they used to assert the opposite.

- **The bootstrap uses this library's own `EnableVersionCheck`.** It was hand-rolling the LibStub lookup and
  `Enable` — the exact pattern the helper exists to remove, in the addon that ships the helper. Two edges went
  with the hand-roll: `(C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata` was then *called*
  unguarded, which is a hard error at file scope rather than a missing version on a client with neither
  spelling; and the `or "dev"` fallback sorts below every real version while **not** tripping the dev-build
  suppression, so such a host would nag against every peer it heard from. The bootstrap now makes no metadata
  call at all.

- **`OpenMenu` no longer writes into the caller's options table.** It resolved a missing `width` by assigning
  it back into the table it was passed, so a consumer holding a module-level options constant and reusing it
  across anchors of different widths got the first anchor's width baked in permanently. It shallow-copies
  now. Not reachable through `CreateDropdownBox`, which builds a fresh table per click — but `OpenMenu` is
  public and documented.

### Changed — MINOR 25

- **`RowList` column `format` now receives `(value, entry)`** instead of `(value)`. Additive and
  backwards-compatible: every existing `function(v)` formatter ignores the second argument and behaves
  identically.

  **Why it was needed.** `RowList` sorts on the raw field (`entry[col.key]`), which is right — it is what
  makes a numeric column sort 3 before 12 rather than lexically. But the common item cell has to *display*
  `|Ticon|t |cff…|Hitem:…|h[Name]|h|r` and *sort* on the plain name, and a one-argument formatter cannot
  reach the icon or the link to build that. So consumers put the display string in the sorted field instead,
  and the header then sorted by the **icon path** at the front of it — a sort control that visibly does
  nothing when clicked.

  Found in Dibs' Loots tab, where the Item column had never sorted. The fix on the consumer side is now
  `{ key = "name", format = function(_, e) return e.display end }` — the field stays sortable, the cell still
  renders the icon and the link.

- **`RowList:New` is declared as `RowList.New(_, parent, opts)`.** No call-site change (`RowList:New(...)`
  desugars to exactly that); it removes the `self` shadowing luacheck flags as W412.

### Added -- MINOR 24 (named cooldowns: the rate-limited button that counts itself down)

- **Named cooldowns.** `W:StartCooldown(name, seconds)`, `W:CooldownRemaining(name)`, `W:OnCooldown(name)`,
  `W:OnCooldownTick(name, fn)`, `W:StopCooldown(name)`, and `W:BindCooldownButton(button, name, opts)`.
  Ported from FastGuildInvite's scan cooldown (`fn.startScanCooldown` in `functions.lua`, plus the button
  treatment in `GUI/Tabs/Scan.lua`'s `ScanTab.SetCooldown`), which is the UX reproduced: while the cooldown
  runs the caption becomes the seconds remaining, the text dims, the highlight is hidden, and the click is
  refused **at the UI layer** rather than fired and bounced somewhere deeper.

  Two things are deliberately **not** copied from FGI, both because they were bugs there:

  1. **FGI decrements a counter per tick**, so the number displayed is only as good as the ticker firing — a
     loading screen or a dropped frame leaves it wrong, or stuck above zero for good. Here the deadline is
     stamped once and every reader **computes** the remainder from the clock, so the ticker only repaints. A
     missed tick shows a stale number for one second instead of permanently.
  2. **FGI fans each tick to three named views by hand** (`setCompactCooldown` / `setMainScanCooldown` /
     `setLegacyCooldown`), so adding a fourth view meant editing the driver. A cooldown here is keyed by name
     and carries a listener list, so a view registers itself and the driver never learns about it.

  FGI's re-entrancy rule **is** kept: starting a named cooldown that is already running cancels the in-flight
  ticker first, so two starts never leave two tickers driving one display.

  First consumer is Dibs' loot-roll **Resend** button, whose rate limit is an officer setting.

  **+21 unit tests**, including that the remainder is correct when *no* tick has fired at all.

### Changed -- MINOR 24

- **Added a `.luacheckrc`.** Without one, luacheck ran on bare Lua 5.1 and every WoW global — `LibStub`,
  `CreateFrame`, `GameTooltip`, the font objects, the whole `UIDropDownMenu` surface — read as an undefined
  variable: 97 warnings across two files, none of them real. A checker whose output is entirely noise is one
  nobody reads, which is how a genuine warning gets to hide in it. Both files are now clean.

## [v0.1.7] — RowList per-row action visibility & the tab glow actually shows

### Fixed

- **`W:BrandTabGroup`'s selected-tab glow never appeared** — on any client or flavour. Two independent faults,
  either of which alone was enough to hide it:
  1. **The band anchored to a string.** Blizzard's `PanelTemplates_SetDisabledTabState` assigns
     `tab.text = tab:GetText()`, and AceGUI runs that on the **selected** tab (it's how the active tab is
     greyed). `BrandTabGroup` resolved its anchor as `tab.text or tab.Text or tab`, so it picked up a
     **string**; `SetPoint` then treats that as a global frame *name*, which resolves to nothing. It failed on
     exactly the one tab that shows the glow, which is why the feature looked like it did nothing at all
     rather than looking half-broken. Now resolved through **`lib.TabLabelRegion(tab)`**, which takes AceGUI's
     real font string (`tab.Text`) and rejects anything without a `SetPoint`, so a future field of the wrong
     type can't reintroduce it.
  2. **Wrong draw layer.** The band was created in `BACKGROUND`, but AceGUI builds each tab's own
     `Left`/`Middle`/`Right` graphic in `BORDER` — which draws *over* `BACKGROUND`. Even correctly anchored,
     the band sat behind an opaque tab. Now `ARTWORK`: above the tab graphic, still below the button's own
     font string. The mouse-over highlight shared the same anchor and is fixed by the same change.
  **+5 unit tests** on the anchor resolver (real font string preferred, a string `text` ignored, both-fields
  present, an unanchorable `Text` rejected, nil-safe). The draw layer is rendering, so it's verified in-game
  per the suite's "don't unit-test rendering" rule.

### Added

- **`RowList` action `show`** (MINOR 23) — an entry in `actions` may set **`show = function(entry) -> boolean`**
  to control whether that icon is **present on that row**. This is the action-side counterpart of the icon
  column's "return a `nil` texture to hide the cell" (MINOR 22); actions were the only per-row element with no
  way to be absent.
  **Why:** an action that applies to only a *few* rows had no good rendering. Greying it via the `texture`
  function leaves an icon on **every** row, which reads as noise when the action is irrelevant to almost all of
  them (unlike a wishlist coin, where gold/grey is meaningful on each row). Returning a `nil` texture is worse
  than it looks: the button keeps its `ButtonHilight-Square` highlight and its `OnClick`, so the row shows an
  invisible-but-hoverable, invisible-but-clickable hitbox. The motivating consumer is Dibs' `[Bank]` request
  icon, which is meaningful only on the handful of gear rows a guild banker actually holds.
  **Compatibility:** absent `show` = always visible, so every existing consumer is unaffected — no call sites
  change. `show` is re-evaluated on each populate, so a consumer whose gating data arrives late (a sibling
  addon still initializing its tables) only has to call `Refresh`.
  **+9 unit tests** driving the real `_renderRows` against recording stub buttons: gating true/false, absent
  `show` unchanged, the `texture` callback skipped entirely on a hidden row, function textures + desaturation
  still applied when shown, string textures gated too, per-action independence when a row has several, a
  **pooled row re-showing** a previously hidden button when repopulated (the bug class that would otherwise
  leave icons permanently missing after a scroll), rows beyond the data never consulting `show`, and a missing
  button slot not erroring.

## [v0.1.6] — RowList icon columns & branded tab glow

### Added

- **`RowList` icon columns** (MINOR 22) — a column may set **`icon = function(entry) -> texturePath, desaturated`**
  to render a small **texture** in its cell (a fixed-size, desaturatable texture in a per-cell holder frame)
  instead of text, resolved per-row from the row's state. Return a `nil` texture to hide the cell; a truthy
  second return renders the icon **greyed** (an "off" state) — so a marker can show gold-when-on / grey-when-off,
  like the Loots wishlist coin. `col.iconSize` sets the glyph size (default 14). The column **still sorts by
  `entry[col.key]`**, so the consumer supplies a sort value (e.g. `1` present / `0` absent) and the header sorts
  marker-first/-last like any column (pairs with `nilsLast` if wanted). Reusable for a wishlist coin, a "won" /
  standby / priority marker in the DKP/EPGP loot lists, and similar row-state glyphs, so consumers stop
  hand-rolling per-cell textures. Default behaviour is unchanged for columns that don't set `icon`. The texture
  drawing itself is frame rendering, so verified in-game (per the suite's "don't unit-test rendering" rule), but
  the **sortability** contract is unit-tested (**+1 test**: an icon column sorts by its `entry[col.key]` value —
  the 1/0 grouping that pulls marked rows together — and the icon renderer is never invoked during a sort).

- **`W:BrandTabGroup(tabGroup)`** (MINOR 21) — brand an AceGUI-3.0 `TabGroup` with the suite tab look: a soft
  **accent highlight band behind the SELECTED tab's label** (bright centre fading to the ends, like a selected
  menu row) plus a fainter accent **mouse-over band** on the others. The stock AceGUI selected state only greys
  and `Disable()`s the active tab, which is hard to spot;
  this makes the current tab obvious in the brand accent. Call once, right after `AceGUI:Create("TabGroup")` —
  it's idempotent and pure styling: it hooks the widget's own `BuildTabs` (where tabs are created lazily and
  recycled) to decorate each tab, and `SelectTab` to move the glow, never changing which tab is selected or any
  callback. A no-op on a non-TabGroup table, and feature-detectable (`if W.BrandTabGroup then …`) so a consumer
  degrades gracefully on an older library. Frame styling, so it's verified in-game rather than unit-tested (per
  the suite's "don't unit-test rendering" rule); the accent→RGB parse it uses is exercised by the config tests.

## [v0.1.5] — stateful action icons, nils-last sort & an offline test suite

### Added

- **`RowList` column `nilsLast` sort option** (MINOR 20) — a column may set `nilsLast = true` so rows whose cell
  for that column is `nil`/absent always sort to the BOTTOM, in both ascending and descending directions,
  instead of the default behaviour (nils flip top↔bottom with the sort arrow). For a numeric column that mixes
  real values with "n/a" — e.g. an EP-delta column where some rows have no EP score — this keeps the no-value
  rows out of the way regardless of direction while the real values sort numerically. Pairs naturally with the
  existing `col.format` display hook: store the raw number in the cell (so the sort is numeric) and format it
  for display. Default behaviour is unchanged for columns that don't opt in. **+2 unit tests.**

- **`RowList` action textures may be a `function(entry)`** (MINOR 19) — a row's right-edge action icon can now
  reflect that row's STATE, not just a fixed icon. Pass `action.texture` as a function and it's resolved for
  each entry on every render (pooled rows), so e.g. a wishlist coin can render gold when the item is listed and
  grey when it isn't. The function may return `(texture, desaturated)` — a second truthy value greys the SAME
  icon, so an on/off state needs only one texture. A plain string texture behaves exactly as before (set once
  at creation).

- **The shared WoWAPITesting harness, as a submodule at `Tests/wowapi`** — the same offline test
  environment the rest of the suite uses, so the library's pure logic is verified without a game
  client. Scaffolding only; no library code changed and **no MINOR bump** (the shipped API is
  untouched). Tests are **runnerless and local only** — no CI test workflow, and none may be added;
  `release.yml` stays the repo's only workflow. Run the whole suite from the library root with
  `lua Tests/wowapi/run.lua`, which needs only a Lua 5.1 interpreter. `busted` is not used and must
  not be installed (the `.busted` shim is vestigial config, not the entry point). `.pkgmeta` ignores
  `Tests`, so none of it reaches the released zip. A `tests.yml` workflow was created during the
  adoption, following the harness README's then-current Step 5, and has been **deleted**; the README
  now says the opposite and `release.yml` is again this repo's only workflow.
- **`CLAUDE.md` — a "Testing: runnerless, local only" section.** The repo had no testing guidance at
  all. It pins the entry point (`lua Tests/wowapi/run.lua` from the repo root), forbids using or
  installing `busted` and forbids adding any CI test job, requires the **whole** suite to be run with
  its **real** output reported (never a pass count carried forward from another session), and records
  what is and isn't testable here — including that widget *registration* against real AceGUI-3.0
  does work offline, while construction and rendering don't (see `docs/widget-testing-design.md` in
  the harness repo).
- The `Tests/wowapi` submodule pin was moved to the harness commit carrying the file-scope-hook fix.
  Before the bump the suite could not pass — `widgets_spec.lua` died on load with `attempt to index
  field '?' (a nil value)` (**20 passed, 1 failed**), because its file-scope `before_each` crashed the
  older runner. After the bump: **59 passed, 0 failed**, observed 2026-07-31.
- **`Tests/widgets_spec.lua` + `Tests/rowlist_spec.lua` — 59 specs over every frame-free code path.**
  Beyond the core helpers below, `ApplyMinResize` (modern `SetResizeBounds` → legacy `SetMinResize`
  → neither, plus AceGUI `.frame` unwrapping and zero defaults) and `AnchorTooltip`'s auto-flip
  (consumer `tooltipOwner` short-circuit, above vs below by room on screen, the `tooltipHeight`
  budget, unknown frame top). `RowList`'s frame-free methods are covered too: `_getSortedData`
  (numeric strings by value — the v0.1.4 lexical-sort bug — real numbers, number-vs-string,
  case-insensitive text with a case-sensitive tiebreak, nil handling, descending, and the sorted
  cache), `SetData` (offset reset, `preserveScroll` clamping, nil data, cache invalidation),
  `ClampOffset`, and `_recomputeVisibleRows` (row arithmetic and pool growth).
- **`Tests/widgets_spec.lua` — the core helpers.** `Configure` / accent
  get-set (including that a non-table argument is ignored and untouched config keys survive a
  partial merge); `Brand` (accent wrapping, `tostring` coercion, nil → empty); `ClassColor` across
  all four resolution paths (consumer override → `RAID_CLASS_COLORS` → white, plus an override that
  lacks the class falling through correctly); `ResolveVersion` (git-tag prefix strip, bare leading
  `v`, plain version untouched, the raw `LibAceGUIWidgets-v0.3.0` dev token preserved, `?` when metadata
  is missing or empty, and the `C_AddOns` → bare-global fallback); `SearchMatch` (empty/nil query,
  case-insensitivity, every-token-must-match in any order, nil fields skipped and numbers
  stringified, whitespace runs collapsed, and that the query is matched as **literal text** — a
  `.` or `(x86)` in the query must not act as a Lua pattern); `CreateMenuInfo`'s `notCheckable`
  preset; and the optional `EnableVersionCheck` / `TriggerVersionCheck` wiring (string name wrapped
  into a host with `GetName`, explicit raw version attached, a host table passed through with its
  existing `Version` never overwritten).
- The widget types themselves (`ClearFrame` / `GroupFrame` / `TLabel`) and RowList's construction and
  render paths are deliberately **not** covered: they build real frames and register with AceGUI, so
  they need the game client. The harness tests logic, not UI.

### Known issue (documented; opt-out available via `nilsLast`)

- **RowList's DEFAULT nil-cell sort order is inverted relative to its own comments.**
  `_getSortedData`'s comparator says `-- nils last in ASC` / `-- nils first in DESC`, but
  `if av == nil then return not desc end` returns **true** ascending, so a row with a nil cell sorts
  *before* valued rows — nils lead ascending and trail descending, the opposite of the stated intent.
  The specs pin the shipped default so the suite is truthful, and it's left as the default because
  swapping the two returns would change visible list ordering for every existing consumer. A column
  that wants the usual "blanks at the bottom regardless of direction" now sets **`nilsLast = true`**
  (MINOR 20, above) rather than relying on a default change.

## [v0.1.4] — version resolver, VersionCheck integration & sort/tooltip fixes

### Fixed

- **RowList sorts numeric columns numerically, not lexically** (MINOR 18) — the header-click sort only
  compared numerically when both cells were already `type == "number"`; a consumer that stored
  pre-formatted display strings (`"3"`, `"12"`) got a lexical sort, so `"3"` landed after `"12"` and an
  EP / iLvl column came out "all over the place." The comparator now uses `tonumber` on both sides and
  orders by value whenever both parse as numbers — so any numeric column sorts right regardless of whether
  the consumer stored numbers or strings, with no per-column flag to remember. Text columns are unchanged
  (still case-insensitive lexical with a stable tiebreak); nil still sorts to the end.

### Added

- **`lib:ResolveVersion(addonName)`** (MINOR 15) — the addon's DISPLAY version for a status bar / about line,
  shared across the suite — the SAME thing FastGuildInvite shows: reads the TOC `Version` (via
  `C_AddOns.GetAddOnMetadata`, bare-global fallback) and strips the BigWigs git-tag prefix (`Dibs-v0.1.7` →
  `0.1.7`, and a leading `v`). It is the **addon** version, not the game client version: an unpackaged dev
  checkout shows the raw `LibAceGUIWidgets-v0.3.0` token (the packager replaces it for players). No game-version
  fallback, no "dev" substitution.
- **Dropdown-box labels no longer wrap out of the box** (MINOR 17) — `CreateDropdownBox`'s label FontString is
  width-constrained between the left edge and the arrow, but never had word-wrap disabled, so a long label
  ("Import / Export") wrapped onto a second line and spilled out of the 22px box. It now sets
  `SetWordWrap(false)` + `SetMaxLines(1)` — a long label clips cleanly on one line instead.
- **Auto-flipping tooltip placement** (MINOR 17) — `lib:AnchorTooltip(frame[, tooltipHeight])` (and every
  `AttachTooltip`) no longer centers the tooltip over the control with a fixed `ANCHOR_TOP` (which overlapped
  the thing you were hovering). It now uses FGI's auto-flip: anchor **above** (`ANCHOR_TOPRIGHT`) when there's
  room, else **below** (`ANCHOR_BOTTOMLEFT`) when the frame sits near the top of the screen — corner anchors, so
  the tooltip sits beside/below the control, never on top of it. A consumer `tooltipOwner` still overrides.

- **`lib:EnableVersionCheck(nameOrHost[, version])`** + **`lib:TriggerVersionCheck()`** (MINOR 16) — one-call
  **VersionCheck-1.0** integration, now an **optional** dependency of the library (moved from `Dependencies` to
  `OptionalDeps` in the TOC). VersionCheck is the suite's "a guildmate is running a newer build" awareness (a
  one-time update nudge); every consuming addon was hand-rolling the same `LibStub("VersionCheck-1.0", true)`
  lookup + `:Enable(host)` wiring (FGI, Dibs, …). `EnableVersionCheck` does that lookup once and registers the
  host — accepting either an addon **name string** or a **host object** `{ GetName, Version }` — and returns the
  VC handle (or nil if VC isn't loaded). It is a **soft dep**: with VersionCheck absent both calls are no-ops,
  so an addon can ship without it and simply have no update reminder. Pass the **raw** TOC version (the
  `LibAceGUIWidgets-v0.3.0` sentinel in a dev checkout), not `ResolveVersion`'s display value — VC needs the sentinel
  to recognise a dev build and suppress the popup.

## [v0.1.3] — multi-select menus, settings gear, placement & menu fixes

### Added

- **Multi-select cascading menus** (MINOR 12). `ToggleMenu` / `OpenMenu` now support building a menu where
  each row's `checked` may be a **function** (evaluated live), and with `opts.keepOpen = true` a leaf click no
  longer closes the stack **and updates that row's checkmark in place** — so a menu of toggleable options
  (class/spec filters, tag pickers, …) works as a true multi-select instead of closing after every pick.
- **`opts.point`** on `OpenMenu` (MINOR 12) — a placement array `{ menuPoint, relFrame, relPoint, x, y }`
  overriding where the root opens (default is below the anchor's bottom-left). Lets a consumer drop the menu
  from a specific corner (e.g. `{ "TOPRIGHT", frame, "BOTTOMRIGHT", 0, -2 }`) instead of directly under a
  full-width anchor. Combined with `opts.width`, a menu can be narrow and positioned independently of its anchor.
- **`ClearFrame:SetSettingsButton(handler, tipTitle, tipBody)`** (MINOR 13) — a native settings **gear** in the
  window's bottom bar, just left of the info "i" icon (FastGuildInvite's `Trade_Engineering` icon, same
  TexCoord crop + `-2` hit-rect slop so the whole 20×20 box is clickable). The status box shrinks to make
  room, so it lines up like FGI's icon row. `handler` fires on click; the tooltip shows `tipTitle` + wrapped
  `tipBody`; a nil handler hides it. The gear is lifted above the resize strips like the other bottom-row
  controls (the sizer/border-overlap fix), so consumers get a managed, always-clickable settings button
  instead of hand-rolling one per addon.
- **RowList action `onClick` now receives the clicked button** as a 4th arg — `onClick(entry, idx, rl, btn)`
  (MINOR 14). Backward-compatible (existing handlers ignore it); lets a consumer anchor a menu/popup to the
  row action it came from (e.g. drop a per-row edit menu from that row's gear icon) instead of a fixed corner.

### Fixed

- **Menu rows crowded the top/bottom border** (MINOR 14). `OpenMenu`/`ToggleMenu` rows started only 6px from
  the frame edge, but `FrameBackdrop`'s border inset is 8px — so the first and last row's text sat under the
  border. Rows now use a dedicated **`MENU_VPAD` (12px)** top/bottom inset (kept separate from the horizontal
  `MENU_PAD`), clearing the border with breathing room; the menu's total height and the cascading-submenu
  anchor offset track it, so a submenu's first row still lines up with its parent row.
- **Click-outside didn't close the menu on its first open.** `OpenMenu` registered `GLOBAL_MOUSE_DOWN` via an
  `OnShow` script, but `renderMenu` had already `:Show()`n the frame before that script was assigned — so the
  event was never registered on the first open and a click outside couldn't dismiss the menu (later opens
  happened to work, making it look flaky). The root now registers `GLOBAL_MOUSE_DOWN` **directly** at open
  time (idempotent), with `OnHide` still unregistering it — so clicking anywhere outside the menu/anchor
  closes the whole stack from the very first open.
- **Open menu outlived its window / tab.** The menu frames live on `UIParent` at `TOOLTIP` strata (so they
  never clip inside the window), which meant they didn't hide when the anchor's window closed or its tab was
  released — the stack kept floating and reappeared over the next tab you opened. `OpenMenu` now hooks the
  anchor's `OnHide` (once per anchor) and closes the stack when the anchor hides (a window close / tab switch
  fires `OnHide` on the anchor as a descendant), only if that anchor still owns the open menu.

## [v0.1.2] — expandable list (collapsible datasheet tree)

### Added

- **`CreateExpandableList(parent, opts)`** (MINOR 11) — a scrolling datasheet of collapsible groups. Each
  group is a header row (a `+`/`−` toggle glyph + a left label + a right-aligned value) that expands to
  indented child rows (left label + right value); `list:SetData(groups)` (re)fills it, where a group is
  `{ key?, label, valueText?, children?, defaultExpanded? }` and a child is `{ label, valueText?, color? }`.
  Built on `CreateScrollFrame`; header and child rows are **pooled and reused** across `SetData` calls, and
  per-group expansion **persists** (keyed by `key`, defaulting to `label`) so a refresh keeps what the user
  opened/closed. Re-lays-out on resize; `list:SetAllExpanded(open)` opens/closes everything at once. Factors
  the EP-breakdown/statsheet tree so any addon in the suite gets a reusable expand/collapse datasheet.

## [v0.1.1] — form helpers (dropdown box, dialog, search, cascading menus)

### Added

- **Cascading submenus in `OpenMenu`/`ToggleMenu`** (MINOR 10) — a menu row may now carry
  `children = { …rows… }` (a list, or a function returning one, evaluated on hover). Such a row shows a
  ▶ arrow and opens the next-level submenu anchored to its right; hovering a sibling collapses deeper
  levels, and selecting a leaf closes the whole stack. Menu frames are pooled per depth, so arbitrarily
  deep trees reuse a fixed handful of frames. Lets consumers replace a giant flat picker (e.g. every
  raid/dungeon/zone in one list) with grouped categories. Backward-compatible: rows without `children`
  behave exactly as before. The submenu **▶ arrow shows only on the hovered row** (inset so it never sits
  over the menu border), rather than permanently on every parent row.
- **`CreateDropdownBox(parent, opts)`** — a labelled dropdown box: a bordered button with a down-arrow
  and a text label that opens a `ToggleMenu` on click. Factors the picker pattern every consuming
  addon was hand-rolling (loadout / character / event / enchant / spec selectors). `opts.items` is a
  function returning the menu rows, evaluated fresh on each open so dynamic lists stay current;
  `opts.width`/`height`/`menuWidth`/`keepOpen` size it, `opts.tipTitle`/`tipBody` wire an
  `AttachTooltip`. Set the shown text via `box.label:SetText(...)`.
- **`ShowDialog(parent, opts)`** — a small prompt/confirm dialog parented into (and raised above) the
  given frame, so it never hides behind a high-strata window the way Blizzard StaticPopups do.
  Optional text input (`opts.hasEdit`), `opts.onAccept(value)` callback, `okText`/`cancelText` /
  `default` / `prompt`. Factors the naming/confirm dialog the consuming addons hand-rolled.
- **`CreateSearchBox(parent, opts)`** — a TSM-style search box (Blizzard `SearchBoxTemplate`: magnifier
  icon, "Search" placeholder, clear-X) as a raw frame for manual layouts, with an `onChanged(text)`
  callback and optional `placeholder`/tooltip. (Ported from TOGProfessionMaster's search field, decoupled
  from its internals.)
- **`SearchMatch(query, ...)`** — the matcher: tokenised, case-insensitive substring search returning
  true when every whitespace-separated token of `query` appears in the combined haystack strings
  (name, source, zone, stat names, …). Empty query matches all; nil fields are skipped. Pure.
- These register at **LibStub MINOR 9** (the dropdown box + dialog at MINOR 7 / 8).

### Fixed

- **Dropdown menu appeared "see-through" over window content** — the real cause was DRAW ORDER, not
  backdrop alpha. The shared menu re-parented to its anchor and rendered at the anchor's frame level
  within the window's `FULLSCREEN_DIALOG` strata; a RowList's cells in that same window sit at a higher
  effective level, so their text drew on top of the menu's (opaque) backdrop. The menu now renders at
  the **`TOOLTIP` strata** — above the window entirely — so no window content can overdraw it, at any
  level. (An opaque dark backdrop colour is still set, as `ClearFrame` does for itself.)

## [v0.1.0] - Initial library

### Added

- **LibAceGUIWidgets-1.0** — a shared, embeddable AceGUI-3.0 widget library for
  the TOG suite, extracted and decoupled from FastGuildInvite's GUI code.
  - **Widget types** (`AceGUI:Create`): `ClearFrame` (movable/resizable window with
    a DialogBox title bar), `GroupFrame` (borderless container), `TLabel` (text +
    optional icon with multi-line tooltip). Registered with per-type version guards
    so each installs independently.
  - **RowList** (`W.RowList:New`) — virtual-scrolling data list: sortable headers,
    alternating row banding, class-coloured columns, right-edge action icons, and a
    hand-built Blizzard-style scrollbar.
  - **Helpers**: `Brand`, `AttachTooltip`, `AnchorTooltip`, `ApplyMinResize`,
    `CreateMenuInfo`, `MakeLabel`; shared `FrameBackdrop` / `PaneBackdrop`.
  - **Addon-agnostic config API** (`Configure`, `SetAccent`/`GetAccent`,
    `SetTooltipOwner`, `ClassColor` — falling back to WoW `RAID_CLASS_COLORS` — plus
    optional `classDisplay` / `refontHook` hooks). All FGI state (`FGI.Tooltip.Owner`,
    `addon.BrandColor`, `addon.color`, `addon.ClassDisplay`, `addon.FontStringByText`,
    `entry.NoLocaleClass`) was routed through this API; the class field is the generic
    `entry.classFile`.
  - Composes with LibLocaleOverride for tab/dropdown/release helpers rather than
    duplicating them.
- **ClearFrame persistence** (widget v27, lib MINOR 2) — `SetStatusTable` binds a
  saved table; the mover/sizer writes top/left/width/height into it and a new
  `ApplyStatus` restores them (default centered 700×500). Consumer windows now
  persist size/position across sessions, and ClearFrame self-positions on open
  (previously the consumer had to place it or it wouldn't render).
- **ClearFrame bottom status bar** (widget v28, lib MINOR 3) — a PaneBackdrop bar
  with status text (`SetStatusText`), a Close button, and an info "i" icon
  (`SetInfoTooltip`; string or `function(GameTooltip)`), all lifted above the resize
  strips so they don't clip (the `LiftAboveSizers` technique). Replaces addons'
  border-clipping top-corner close buttons.
- **Scroll frame helper + slimmer RowList scrollbar** (lib MINOR 6) —
  `lib:CreateScrollFrame(parent, opts)` returns a vertically-scrolling box with a **slim
  thumb scrollbar** (`{ scroll, content, scrollbar, SetContentHeight }`) for arbitrary
  content that overflows. RowList's own scrollbar was slimmed (12px track, 24px buttons,
  narrower gutter) to hand a little more width back to the rows.
- **Dropdown menu helper** (lib MINOR 5) — `lib:OpenMenu(anchor, items, opts)` /
  `ToggleMenu` / `CloseMenu`: a reusable anchored menu with check-marked rows (radio-style
  selection), click-outside / anchor-toggle to close (via `GLOBAL_MOUSE_DOWN`), rendered at
  the anchor's window strata so it never hides behind the window. Replaces consumers'
  hand-rolled dropdowns.
- **RowList row-hover callbacks** (lib MINOR 4) — `onRowEnter(entry, idx, rl, rowFrame)`
  and `onRowLeave(...)` opts, symmetric with `onRowClick`, so a consumer can show a
  tooltip (e.g. a game item tooltip) while the pointer is over a row. Rows enable mouse
  when any of click/enter/leave is supplied.
- **Standalone scaffolding** — TOC (multi-flavour interface list), vendored LibStub,
  a VersionCheck-1.0 bootstrap, `.pkgmeta`, GitHub release workflow, MIT license,
  markdownlint/luarc config, the `wow-version-replication.ps1` dev-sync watcher, and
  a CurseForge description under `docs/`.
