# Changelog

## [v0.3.0] -- toggle chips, a tab strip that scrolls, a top-right window button, a strip row without an empty caption band, and Whitemane in the TOC

### Compatibility -- MINOR 39 -> 40

New: the `LAGW-Chip` AceGUI widget type (Version 1) and `W:AddChips`, the `LAGW-TabStrip` widget
type (Version 1), and `W:AttachHeaderButton` / `W:DetachHeaderButton` with `ClearFrame:SetHeaderButton`.
Feature-detect with `AceGUI:GetWidgetVersion("LAGW-Chip")` or `if W.AddChips then`,
`AceGUI:GetWidgetVersion("LAGW-TabStrip")`, and `if W.AttachHeaderButton then` /
`if win.SetHeaderButton then`. Changed: a `LAGW-Strip` row with no
caption on any of its controls no longer reserves the caption line, so a strip whose second row is
captionless is shorter by one caption line; a consumer that sized a window floor from
`W:StripRowWidth` is unaffected (only the height moved). `ClearFrame`, `GroupFrame` and `TLabel`
move 31 -> 32 together, because a ClearFrame without `SetHeaderButton` must not win a tie.

### New

- **`LAGW-Chip`, an on/off pill button** (Grouper contract `c98a1eab`; their operator: "ask widgets to
  add a toggle chip, i think it could be good"). `SetText`, `SetValue` / `GetValue`, `SetDisabled`, and
  `OnValueChanged(value)` on a click, as AceGUI's CheckBox does; `SetValue` is silent. On is the
  library accent (tinted fill, accent border, white text), off is the dark fill and grey border of the
  dropdown box; hover adds the button highlight; disabled is dimmed and ignores clicks but keeps its
  tooltip. Sized to its label, following the UI scale. The frame is a Button, so
  `W:AttachWidgetTooltip` answers on it, and it drops into `W:StripAdd` like any control.
- **`W:AddChips(container, order, labels, values, onChanged)`** builds one chip per key in `order`,
  lit from `values[key]`. A click writes `values[key]` and then calls `onChanged(key, value, chip)`.
  Returns the chips keyed by key.
- **`LAGW-TabStrip`, tabs added at runtime that scroll with `<` and `>`** (Dibs contract `cb965300`;
  their operator: "all you have to do is have < and > arrows at either side of the tabs so you can
  scroll back and forth between tabs"). `AddTab(value, text)` (a value already there is re-labelled),
  `SetTabText`, `RemoveTab`, `ClearTabs`, `SelectTab(value)` (silent, and scrolls the tab into view),
  `GetSelected`, `GetTabs`, `SetMaxTabWidth`, `GetVisibleRange`, and `OnTabSelected(value)` on a
  player's click of another tab. A tab is its label plus 10 a side, capped at 140 (scale-1.0); a longer
  label is cut short and shows in full on hover. The arrows appear only when the tabs overflow, each
  scrolls one tab, and each is disabled at its end. The strip only: the consumer draws what a tab
  shows. Looks like the chips: the selected tab in the accent, the rest grey.
- **A text button in a window's top-right corner** (Grouper contract `12c62f8b`; their operator: "can
  you add a button in the top right to switch the user back to the legacy UI ... we'll need the legacy
  ui to have the same button to switch to the new UI"). `W:AttachHeaderButton(widget, text, onClick,
  tipTitle, tipBody)` works on a stock AceGUI `Frame` and on a `ClearFrame`, which also has it as
  `win:SetHeaderButton(...)`; both go through the one builder, so the two windows cannot drift apart.
  Inside the border, 14 in from the right, its bottom level with the content's top (27 down), sized to
  its label (10 a side, at least 40) and lifted above the resize strips. On a ClearFrame it sits a
  further 4 in and 6 down (Grouper inbox `e62d2977`): with the stock numbers the operator saw it
  straddle the ClearFrame's top border ("it kinda overlaps the border in the new UI") while the stock
  Frame's was "perfect". I have not found the cause in the code; the offset is set from what was seen,
  and the operator rechecked it in game after the move: "perfect". Calling again re-labels the
  same button; `text = nil` hides it. It follows the UI scale on a ClearFrame and stays at 1.0 on a
  stock Frame, whose chrome does not scale. Release hides it and drops its handler, tooltip and scale
  listener, so AceGUI's pool cannot hand it to another addon's window; `W:DetachHeaderButton` does
  that early.

### Changed

- **A strip row with no captions has no caption band** (raised with the chip request). I reserved the
  caption line on every row, so a captionless second row sat under an empty band.

### Fixed

- **The TOC now lists 38000 (Whitemane) beside 38002 (Titan Reforged)** (Peer Review `2bd6dff2`). I
  left it out, so on Whitemane the library read as out of date while Grouper, which depends on it
  there, was current. 38002 stays.

### Tests and docs

- **Tests.** New `Tests/chip_spec.lua`, `Tests/tabstrip_spec.lua` and `Tests/headerbutton_spec.lua`
  (placement against a real AceGUI Frame and ClearFrame, the scale, and what a released window keeps);
  `Tests/strip_spec.lua` covers a captionless row, and `Tests/dock_spec.lua` covers two windows sharing
  one saved table. The suite runs 1049 checks, 0 failing, and every shipped `.lua` file is at
  100% line coverage (6380/6380).
- **Docs.** README's filter-strip entry now says a captionless row reserves no caption line. The
  CurseForge page lists the chips and the tab strip, carries a MINOR 40 example and the two new widget
  type names, and keeps the last five versions under Recent Updates.
- **Docs made to agree with the code and with each other** (a full README-against-CurseForge read).
  The CurseForge page said a window given both PersistWindow and DockWindow is kept in the
  diagnostics record; it is only refused and printed (`otherOwner` calls `_Say`, not `_Report`). It
  said a dialog parented into a window "closes with that window"; since MINOR 33 it goes off screen
  with it and comes back still open, `onHide` unrun. It said `/lagw debug` is remembered, which holds
  only when the library is installed as its own addon. README still said the three legacy widget
  types register at 31, and never mentioned the filter menu's Select all / Clear all, which act on
  every value drawn or not. The CurseForge page now also names the smaller helpers the README
  documents (scale helpers, named cooldowns, `TriggerVersionCheck`, the click-binding text helpers,
  `ToggleMenu`, `SetAllExpanded`, RowList column widths, and the read-back partners).

## [v0.2.9] -- library chat lines only in debug, a /lagw switch, your own item-row hover, and a menu that closes on a bad pick

### Compatibility -- MINOR 38 -> 39

New: the `debug` field on `Configure` (`true`, or a function returning a boolean), `W:IsDebug()`,
`W:SetDebug(true|false|nil)`, the `/lagw debug [on|off|reset]` slash command, the `LibAceGUIWidgetsDB`
SavedVariables (standalone addon only), and `onEnter` / `onLeave` / `onClick` on a `CreateFormDialog`
`kind = "item"` row. Feature-detect with `if W.IsDebug then` (the item-row callbacks ship in the same
MINOR). Changed: the library prints nothing to chat unless debug is on. `W:Diagnostics()` records
exactly what it did before, so a consumer spec asserting on it is unaffected. A menu item whose
`onClick` raises now closes the menu and reports the error through `geterrorhandler()`; a consumer
wrapping its own handlers in `pcall` for this can drop the wrapper. No widget type Version moves.

### New

- **`/lagw debug`** (the operator: "you should add a / command to turn it on/off as well"). `on` and
  `off` force the library's chat diagnostics whatever any addon set; no argument toggles; `reset`
  hands the decision back to the addons. It answers in chat with the current state, and the choice
  is saved in `LibAceGUIWidgetsDB` when the standalone addon is installed (an embedded-only copy keeps
  it for the session). One registration per session; the handler finds the current copy through
  LibStub, so a newer MINOR loaded later still answers.
- **An item row can take the consumer's own hover and click** (TOGProfessionMaster contract
  `1d7a76ba`). `row.onEnter(button, link)`, `row.onLeave(button)` and `row.onClick(button, link,
  mouseButton)` each replace the built-in tooltip, hide or `HandleModifiedItemClick` when given, so a
  consumer's hold-to-compare hover and rebound chat-link click survive the move onto the library row.
  They are read from the row spec at event time, so a named dialog reused across opens follows the
  spec. None given: exactly the old behaviour. No callback runs for a row with no item.

### Fixed

- **A menu pick whose handler raises no longer leaves the menu open** (Peer Review `b64aa131`,
  measured by TOGProfessionMaster). The row's `OnClick` ran `item.onClick()` unprotected, so an error
  left before the close: the menu stayed up and `OnMenuClosed` never fired. I wrote it that way. It
  now runs the handler under `xpcall` (keeping its stack via `debugstack` where the client has it),
  closes (or, on a `keepOpen` row, refreshes the check), and then hands the error to the library's one
  `reportError` path so it still reaches the player's error display.

### Changed

- **Every chat line is behind the debug switch.** The empty-render line ("RowList has N row(s) but
  is showing none...") appeared in a player's chat between two guild messages; it, the duplicate
  column key report, the accent clash report and the PersistWindow/DockWindow refusal now go through
  one `lib:_Say`, which prints only when `config.debug` is on. I shipped them unconditional; they are
  developer diagnostics about a consumer's code that a player cannot act on. A debug function that
  raises counts as off, so a consumer's broken toggle cannot break a report.
- **Tests.** Specs for the debug gate (off by default, `true`, a live function, a raising function),
  `/lagw debug` and its SavedVariables restore, the item-row callbacks, and a raising menu pick in both
  row kinds. The specs that assert on chat now turn debug on first. The suite runs 1011 checks, 0
  failing.
- **Docs brought level with the code.** README now names RowList `opts.headerFont`, the form
  dropdown row's `menuWidth`, the stepper's `GetValue()` and its parts, `LAGW-ClickBinding`'s
  `GetValue()` / `SetDisabled()` / `OnEnter` / `OnLeave`, `dock:Relayout()` and `dock.sizes`, and what
  `OpenMenu`, `EscapeLayer` and `ShowDialog` hand back. The CurseForge page now mentions tick-box
  columns, text that shortens to fit, the form prompt's hint line and placement, and expandable-list
  lines with their own click, tooltip and colour. All of these shipped earlier and were only
  undocumented.

## [v0.2.8] -- a copy box with a copy glyph, a click binding you set by doing it, and a dock that lets go

### Compatibility -- MINOR 37 -> 38

New: `W:ShowCopyBox(text, opts)`, `W.COPY_ICON`, the `LAGW-CopyField` (Version 2) and
`LAGW-ClickBinding` (Version 1) widget types, `W:ClickBinding`, `W:ParseClickBinding`,
`W:ClickBindingText`, `W:IsClickBinding`, `W:UndockWindow` and the `DockWindow` handle's `:Undock()`.
Feature-detect with `if W.ShowCopyBox then`, `if W.IsClickBinding then`, `if W.UndockWindow then`, or
`AceGUI:GetWidgetVersion(type)`. Nothing existing changes for a consumer. `ShowDialog` clears the copy
box's read-only guard and glyph on every show, so a plain prompt after a copy box behaves as before. No
existing widget type Version moves. New shipped files: `LibAceGUIWidgets-ClickBinding.lua` (in the TOC
after the DatePicker) and `Textures/copy.tga`.

### New

- **`LAGW-ClickBinding`** (TOGProfessionMaster inbox `e0f3923e`, for ItemDB's "Where to get it"
  click, which collides with Gargul's Alt+click). The player sets a modifier + mouse button by doing
  it: click to arm ("Hold Alt, Ctrl or Shift and click here"), then click again holding the modifiers.
  AceGUI's own Keybinding cannot record a Left or Right click at all.
  - The value is one canonical string: modifiers in the order `ALT-`, `CTRL-`, `SHIFT-`, then the
    button as OnClick names it -- `"ALT-LeftButton"`, `"CTRL-SHIFT-RightButton"`. ItemDB already
    stores this form.
  - A click with no modifier is refused on every button, with a short message, and the widget stays
    armed. Escape (out of combat) or Cancel disarms and changes nothing. Armed in combat, it takes no
    keyboard, because it could not pass the other keys on; Cancel is the way out.
  - `SetValue` (silent, normalised; unreadable means unbound), `GetValue`, `SetLabel`, `SetDisabled`,
    `SetDefault` (adds a Default button). `OnValueChanged(binding)` fires on the player's changes,
    reset included, and only when the value changed. Hiding while armed disarms. Released disarmed
    with no value, label or default.
  - Frame-free helpers: `W:ClickBinding(alt, ctrl, shift, button)`, `W:ParseClickBinding(binding)`
    (any prefix order and case), `W:ClickBindingText(binding)` ("Alt + Left Click", the client's
    `NOT_BOUND` for none, modifier names from `ALT_KEY_TEXT` etc. where the client has them) and
    `W:IsClickBinding(binding, button)`: the modifiers held now must match exactly, and a nil button
    matches on modifiers alone.

- **`W:ShowCopyBox(text, opts)`** (TOGTools inbox `737274f2`). Addons cannot write the clipboard, so
  every one hand-rolled a popup whose box held the text, selected, for Ctrl+C. This is that popup as one
  call, on the shared `ShowDialog` frame. It returns `dialog, token`, so `W:CloseDialog(token)` closes it.
  - `opts.parent` defaults to `UIParent`, `opts.prompt` to "Press Ctrl+C to copy, then Escape.",
    `opts.okText` to `CLOSE` or "Close". `opts.onShow` and `opts.onHide` pass through to `ShowDialog`.
  - One button, and it closes. Enter and Escape close too. Nothing is called with the text on any close.
  - The box is focused and the whole text selected when it opens.
  - **Read-only.** A typed or deleted character is put back and the text selected again. A click in the
    box selects all again on mouse up, so it is never left partly selected.
  - Long text scrolls inside the single-line box; the dialog keeps `ShowDialog`'s size.
  - **A copy glyph in the box**, drawn the way the search box draws its magnifying glass: 14px at the
    box's left, the text inset 20 to clear it, white while focused or holding text and 0.6 grey
    otherwise. The picture is a new shipped file, `Textures/copy.tga` (64x64 32-bit white line art of
    two overlapping sheets, the same format as `calendar.tga`), and `W.COPY_ICON` names it. If the
    file cannot be set, the box draws no glyph and no inset. A plain `ShowDialog` after a copy box
    has neither.
  - The hooks go on the shared edit box once, not once per show.

- **`LAGW-CopyField`** (TOGTools inbox `513d5779`), the copy box inline in a window instead of a
  popup: an AceGUI widget type with `SetText`, `GetText` and `SetLabel`. The box follows
  `ShowCopyBox`'s rules: the copy glyph tinted like the search box's magnifier, read-only, the whole text
  selected on focus and click, long text scrolling in the box. Enter and Escape drop focus. AceGUI
  EditBox's geometry (26 tall, 44 with a label), scaled; works in List and Flow. Released with no text,
  label or focus. Feature-detect with `AceGUI:GetWidgetVersion("LAGW-CopyField") >= 2`. It ships at
  Version 2: Version 1 existed only in the working tree before this release and raised
  "FontString:SetText(): Font not set" on every Create in game, because the label got its font after its
  first `SetText` (TOGTools peer review `63629c29`).

- **`DockWindow`: `h:Undock()` and `W:UndockWindow(frame)`** (TOGTools inbox `2472500e`). The window
  leaves its target, a docked one is pinned where it is on screen, and `status.docked` is left alone,
  so a later `DockWindow` to a new target docks it again. Feature-detect `if W.UndockWindow then`.

### Fixed

- **A window docked to an AceGUI window followed that window's frame into another addon.** AceGUI
  pools frames: `Release` hands the same raw frame to the next `AceGUI:Create("Frame")`, and
  `DockWindow`'s hooks and list stayed on it, so when another addon showed that frame, our window
  re-docked onto theirs. TOGTools hit it docking its Explain window to its main window, and worked
  round it by re-pointing the dock at a hidden frame before every release. Now a target that is an
  AceGUI widget's frame is let go of automatically on that widget's release (through
  `OnWidgetRelease`), so no consumer has to do anything. Re-pointing `DockWindow` at a new target also
  now leaves the old target's list, instead of staying on it and being skipped.

### Tests

- Whole suite: 992 passed, 0 failed; coverage 5961/5961 executable lines (100%) over every shipped
  file, the new `LibAceGUIWidgets-ClickBinding.lua` included.
- `Tests/copyfield_spec.lua` (10 examples): a fresh construction through its whole lifecycle under the
  harness's "no SetText without a font" rule, text, label heights, the read-only guard, select-all on
  focus and click, Enter / Escape, no glyph without the file, the glyph's place and tint, the glyph
  following the scale, and a clean return from the pool.
- `Tests/dock_spec.lua` gains 5 examples: `Undock` pins and stops following, a later re-dock works,
  re-pointing leaves the old list, `UndockWindow`, and the automatic let-go on a pooled target's
  release, including the next owner showing that frame.
- `Tests/dialog_spec.lua` gains 11 examples: the glyph drawn, tinted and gone from the next plain
  prompt; no glyph when the file cannot be set; the TGA's shape; the defaults and the token, the
  `opts` overrides, a user edit put back, re-selection on click and focus, close on OK / Enter / Escape with `onHide` once each,
  a later plain prompt left writable with only one hook installed, a 500-character line with the dialog
  size unchanged, and nil / number text.
- `Tests/clickbinding_spec.lua` (19 examples): the string's canonical order, parsing and refusals, the
  display text, the exact-match rule, capture on every button, the refusal of an unmodified click,
  Escape and other keys, combat, Default, silent `SetValue`, disabled, the label, the UI scale,
  hide-while-armed, and a clean return from the pool.
- The `Tests/wowapi` harness pin moves to `8e053f2`. From `9c6c874` its library manifest loads the new
  `LibAceGUIWidgets-ClickBinding.lua` (WoWAPITesting inbox `00eb7ea8`); from `9c80f46` a FontString
  with no font refuses `SetText` with "Font not set", as the client does (inbox `6ceaea3f`).
- That rule turned two `formdialog_spec` examples red: the harness has no `GameFontRedSmall`, which the
  client does define, so the error line had no font offline. Harness `8e053f2` defines it (inbox
  `798ae268`), and "is drawn in the red font" now asserts the font exists, because
  with it missing both sides of its comparison were nil and it passed on nothing.
- Not verified in a client: that a mouse-up re-select beats the click's own cursor placement, and that
  `RegisterForClicks("AnyUp")` delivers Middle / Button4 / Button5 to OnClick on every flavour.

## [v0.2.7] -- a checkbox, a note and a paragraph in the form prompt, and the cell a list shows an entry in

### Compatibility -- MINOR 36 -> 37

New: `RowList:CellFrameFor`, the `kind = "check"` form row, `row.note`, `frame:SetNote`,
`frame.notes`, `opts.body`, `frame:SetBody` and `frame.body`. Feature-detect on `if rl.CellFrameFor then` or
`LibStub.minors["LibAceGUIWidgets-1.0"] >= 37`. Nothing existing changes: a form dialog that uses
neither a check row nor a note is built with the same points and the same height. No widget type
Version moves.

### New

- **`RowList:CellFrameFor(target, columnKey)`** (Dibs inbox `55767d11`). It returns the frame on screen
  that shows `target`'s cell in that column: the mouse overlay for a column with `onCellEnter`,
  `onCellLeave` or `onCellClick`, else the cell itself. `target` is an entry, a predicate, or an index
  in the drawn order. It is nil for an entry not in the view or scrolled off the page, an unknown
  column, a heading row, a cell the row is not showing, and a detached list. It is read-only: no scroll,
  no repaint. It answers for the current columns, so it follows `SetColumns`. Dibs' spec found the row
  by reading `rl.rows` and `rl:_getSortedData()`; this replaces both.
- **`CreateFormDialog`: a checkbox row and a note under a row** (Dibs inbox `8d5165f7`), so Dibs can
  drop its two hand-built officer dialogs.
  - `kind = "check"` puts a `UICheckButtonTemplate` box where the edit box goes, with the row's label
    to its right, wrapping. `fields[i]` is the box: `GetValue()` answers a boolean, `SetValue(bool)` is
    silent, `row.value` sets the start, `row.onChanged(value, dialog)` hears a click, and
    `row.tipTitle` / `row.tipBody` go on the box. The row is the usual 26 tall and follows the scale.
  - `row.note = "text"` draws a small grey `GameFontDisableSmall` line under that row's field,
    wrapping, and the dialog grows by its height. `frame:SetNote(i, text or nil)` adds, changes or
    removes it after build; a removed note leaves no gap. `frame.notes[i]` is the FontString.
  - `opts.body` and `frame:SetBody(text or nil)` (Dibs inbox `33a2bbce`) put a paragraph under the
    title and hint, above the rows, wrapped to the dialog's width on the scaled
    `GameFontHighlightSmall`. Setting it again, after `Show` included, replaces the text and the height
    follows; nil or "" hides it and it takes no space. `frame.body` is the FontString. This is for
    Dibs' Absences dialog, whose text is rebuilt on every open.
  - The rows are now re-hung by one routine shared by `SetHint`, `SetNote` and `SetBody`, so changing
    one keeps the space of the others.

### Tests

- `Tests/rowlist_minor37_spec.lua` (9 examples) checks each answer by what the frame does or shows:
  entering the returned overlay reaches the column's `onCellEnter` with the entry, and a text cell
  shows that entry's text.
- `Tests/formdialog_minor37_spec.lua` (13 examples) pins the unchanged layout of a dialog that uses
  none of the additions, then the check row, the note and the body, including a note on the last row,
  a body with no rows, and a `SetHint` after each.

### Dev tooling

- **`wow-version-replication.ps1` no longer deletes the replicas of a file the source still has**
  (TOGProfessionMaster peer review `0f76f963`). An editor that saves by replacing the file raises a
  `Deleted` event for a moment before the new file lands; the watcher removed the file from every other
  WoW install on that event. A `Deleted` for a path that still exists is now treated as `Changed` and
  copied. Dev-only: the script is not in the package. Not reproduced against a real replacing save.

## [v0.2.6] -- the suite orange by default, and nothing left on a released widget

### Compatibility -- MINOR 35 -> 36

New methods: `W:OnWidgetRelease`, `W:WidgetFrameScripts`, `W:RestoreWidgetFrameScripts`,
`W:AttachRawFrames`, `W:DetachRawFrames`, `W:AttachWidgetTooltip`, `RowList:CellWidth`,
`RowList:GetScrollOffset`, `RowList:SetScrollOffset`, `W:IsMenuOpenFor`, `W:IsInputFocusedIn`,
`W:OnMenuClosed`, `W:Flash`, `W:StopFlash`, `W:FlashScreen`, `W:AnchorPopup`, `W:ClampWindow`,
`W:SetWindowProfile`, `W:GetWindowProfile`, `W:SetWindowOpacity`, `W:GetWindowOpacity`,
`W:SetWindowScale`, `W:GetWindowScale`, `W:EscapeLayer`, `W:DropEscapeLayer`, and
`IsExpanded` on an expandable list, `W:CreateStepper` and the `LAGW-Stepper` widget type at Version 1,
`W:CreateSecureActionButton`, `W:NewDockLayout`.
Feature-detect on
`if W.AttachWidgetTooltip then` or `LibStub.minors["LibAceGUIWidgets-1.0"] >= 36`. Nothing existing
changes signature; `ScrollToEntry` gains an optional second argument. New RowList options:
`hoverHighlight`, `sortCycle`, `col.sortNone`, `searchText`, `searchTokens`, `onScroll`, `isHeader`,
`indentStep`, `indentKey`, `headerFont`, `reorderable` + `onReorder`, `fitContent` +
`onHeightChanged`, `col.show` / `col.text` / `col.tip` on a button column and `col.iconTexCoord`, all
off unless given. RowList now reads three entry fields: `_header`, `_expanded` (on a header row) and
`_indent`; an entry that already carried a truthy `_header` for its own reasons would now draw as a
heading. New field: `W.DEFAULT_ACCENT`. One visible change for existing calls: **the
default accent is now the suite orange `ffFF8000`, not gold `ffFFD100`.** An addon that never called
`Configure{ accent }` now draws orange header underlines, selection tints, `BrandTabGroup` bands and
`W:Brand` text. An addon that sets its own accent sees no change, and one that sets `ffFF8000` stays
silent, because the same colour is never an `accentClash`. No consumer has to change code.
`ClearFrame`, `GroupFrame` and `TLabel` move 30 -> 31 together, because `ClearFrame:SetInfoTooltip`
now takes `{ minWidth }` and AceGUI keeps the FIRST registration at a tie, so an older copy loaded
earlier would otherwise keep a ClearFrame that ignores it. `LAGW-DatePicker` stays at 3 and
`LAGW-SearchBox` at 1.

### New

- **Pool-safe additions to AceGUI widgets, undone on Release** (TOGProfessionMaster inbox `efe864ec`,
  `afb62bf8`). AceGUI pools each widget and its frames for every addon in the session. Its `Release`
  empties `widget.events` but never touches a raw script, a frame flag, or a raw frame parented into
  the widget, so all three followed the pooled frame into the next addon's window. TOGProfessionMaster
  carried six hand-rolled undo variants for this.
  - `W:OnWidgetRelease(widget, key, fn)` runs `fn(widget)` once when AceGUI releases the widget, then
    forgets it. It chains onto the widget's `OnRelease` method, the way `PersistWindow` does, so the
    consumer's `SetCallback("OnRelease")` slot stays free. A second call with the same key replaces
    the hook, `false` removes it, hooks run newest first, and one that raises is reported through
    `geterrorhandler` without stopping the rest.
  - `W:WidgetFrameScripts(widget, { OnMouseDown = fn, ... } [, target])` sets raw scripts on
    `widget.frame`, on a named sub-frame (`"editbox"`) or on a given frame. On Release each event gets
    back the script from before the first call, not nil, so a constructor's own dispatcher survives
    and the next owner's `SetCallback` still fires. A second call replaces the handler and still
    restores the original. `false` restores one event now, and `W:RestoreWidgetFrameScripts(widget)`
    restores everything now.
  - `W:AttachRawFrames(widget, frameOrList)` records raw frames parented into the widget. On Release
    each is hidden, loses its points and goes back to `UIParent`. The frames are not destroyed, so the
    consumer's own pool keeps them. `W:DetachRawFrames(widget)` does it now.
  - `W:AttachWidgetTooltip(widget, title, body [, opts])` is `AttachTooltip` for an AceGUI widget.
    `AttachTooltip(widget.frame, ...)` hooks with `HookScript`, which cannot be removed, and leaves its
    text and the disabled-hover flag on the pooled frame. This one answers on `widget.frame`, including
    the EditBox and Dropdown label area (whose mouse it enables), and on the widget's `editbox`,
    `button` and `slider`. Each frame's existing handler runs first, so the consumer's
    `SetCallback("OnEnter")` still fires. It draws through `ShowTooltip` with `opts.owner`,
    `opts.reason` and `opts.titleColor`, leaves through `HideTooltip`, and keeps a disabled button's
    hover. A second call updates the text. On Release the scripts, the mouse flag and the motion flag
    all go back to their prior values.
- **Tooltip `opts.minWidth`, and `W:AnchorPopup`** (TOGProfessionMaster inbox `c8d6892f`).
  `ShowTooltip`, `AttachTooltip` and `AttachWidgetTooltip` take `minWidth` (scale-1.0 px), so several
  paragraphs of help are not drawn as a tall narrow column. GameTooltip is shared with the whole UI
  and nothing resets `SetMinimumWidth` by itself, so the previous value is saved as both halves
  `GetMinimumWidth` returns (`width, forced`) and put back when the tooltip hides, through a hook on
  its `OnHide`, and before the next showing. `DressBottomRow` takes it per icon as `tipMinWidth`, and a
  ClearFrame's `SetInfoTooltip(tooltip, { minWidth })` takes it too. `AnchorPopup(popup, source, { gap })` places a floating panel under its source, or over it
  when there is no room below, slides it left to stay on screen and clamps it. Both frames are
  measured in UIParent units, so a scaled window is placed right.
- **`W:Flash`, `W:StopFlash` and `W:FlashScreen`, a finite attention flash** (TOGProfessionMaster inbox
  `759b8287`). `Breathe` loops until stopped; `Flash(region, { times, seconds, low, onDone })` dips the
  alpha `times` times (3 by default, 0.25s each way, down to 0) and stops by itself with the alpha back
  at 1. It is a BOUNCE group counting its own `OnLoop` calls that turn back to `FORWARD`, one per dip,
  which is right whether the client calls `OnLoop` at each end of a pass or once per cycle (the docs do
  not say which). `OnLoop` is a script the Classic Era client uses itself (`LFGFrame.lua`). A second call restarts it on the same group.
  `FlashScreen({ color, times, seconds })` flashes a full-screen edge glow on one shared frame at
  `FULLSCREEN_DIALOG` strata that never takes the mouse, then hides it. The glow is four flat-colour
  bars rather than a client texture, so there is no art to go missing on a flavour. The colour
  defaults to the accent; the hex parsing is now one local shared with `AccentRGB`.
- **`W:IsMenuOpenFor`, `W:IsInputFocusedIn` and `W:OnMenuClosed`** (TOGProfessionMaster inbox
  `8f507ee7`), for a consumer that defers a redraw while the player has one of its menus open or is
  typing. Both queries walk UP from the anchor or the focused box to the window asked about, never
  down its tree, so they are cheap on every event. Another addon's open menu answers false; submenus
  are the same stack and count. The focus query asks the client's `GetCurrentKeyBoardFocus` when it
  exists. That function has no call site in this box's Classic Era or Classic source trees, so the
  library also tracks focus on every edit box it builds (menu search, dialog, search box, form field,
  date picker) and falls back to that. `OnMenuClosed(owner, fn)` is one-shot per owner and also fires
  when another anchor's menu takes over the stack.
- **RowList `opts.hoverHighlight`** (TOGProfessionMaster inbox `0c477b45`) lights the row under the
  pointer. `true` uses the stock quest-log title highlight, ADD-blended; a string is a texture path;
  `{ r, g, b, a }` is a flat colour. It is drawn on `BORDER` one sublevel under the selection tint, so
  it covers the banding and never hides the selection. Only one frame holds the mouse at a time, so
  the row gets its `OnLeave` when the pointer moves onto one of its own mouse-enabled children (not
  yet seen in the client). Every child that takes the mouse (cell overlays, button
  cells, checkboxes, expanders, action icons) lights the row on enter, and a leave only puts it out
  when `row:IsMouseOver()` says the pointer is off the row entirely. A scroll moves entries under a
  pointer that never moved and fires no enter or leave, so each populate re-decides the highlight
  from `IsMouseOver`. A row showing no entry never lights. It is opt-in because the row has to take
  the mouse.
- **RowList three-state header sort** (TOGProfessionMaster inbox `1013eeea`). With
  `opts.sortCycle = "three"`, or `col.sortNone = true` on one column, the third click on the sorted
  column clears the sort, so a list whose unsorted order means something (a category tree) can get
  back to it. A `sortDescDefault` column cycles desc -> asc -> none. The clear writes the same state as
  `SetSort(nil)`, and `onSortChanged` now reports a cleared sort as `(nil, nil, rl)`. Lists stay
  two-state unless they ask.
- **`col.format` gets the cell's width and a measure** (TOGProfessionMaster inbox `c5476af2`), for a
  column that fits as many names as the space allows and then "+N". When the text is being drawn the
  formatter is called as `format(value, entry, width, measure)`: `width` is the cell's pixel width at
  the current scale, and `measure(text)` is that text's rendered width in the column's own font. A
  parent resize repaints, so the formatter re-fits. The filter labels, the search and the `autoFit`
  measure pass neither argument, so they see the full text. New `rl:CellWidth(key)` answers any
  column's width, the auto column included once a row has been laid out (nil before that); `ColumnWidth` keeps answering nil for the auto column so
  a consumer summing fixed widths is unchanged. Two-argument formatters are unaffected.
- **RowList search over hidden text, by words** (TOGProfessionMaster inbox `85482ed8`), so searching
  "stamina" finds every recipe that gives stamina. `opts.searchText(entry)` returns extra text the
  search reads, colour escapes stripped. With it, or with `opts.searchTokens = true`, `SetSearch`
  matches by `W:SearchMatch`'s rule: every word of the query somewhere in the shown cells and the
  hidden text, any order, any case. The text is built once per entry and kept until `SetData`,
  `Refresh` or `SetColumns`, so `searchText` does not run per keystroke. A list with neither keeps
  the plain-substring search it had. The search still ANDs with the column filters.
- **RowList scroll position, public** (TOGProfessionMaster inbox `bdf1159c`), so a tab reopens where
  the player left it. `rl:GetScrollOffset()` and `rl:SetScrollOffset(n)` work in rows; the setter
  clamps like every other scroll and repaints once. `opts.onScroll(rl, offset)` is called from the
  repaint whenever the offset differs from the last one reported, whatever moved it: the wheel, the
  scrollbar, the setter, `ScrollToEntry`, a `SetData` or search that went back to the top, a clamp.
  It is not coalesced across a frame, as the request asked, because that needs a timer standing in for
  the end of the frame. `rl:ScrollToEntry(target, opts)` takes `ifNeeded` (no scroll when the entry is
  already on screen; from below, it comes in at the bottom) and `context = n` (rows left beyond it,
  capped at one less than the page, then clamped at the list's ends).
- `SetSearch` now repaints without dropping the per-entry search text built for the previous query.
- **RowList group header rows and indent** (TOGProfessionMaster inbox `57b66577`). A row is a heading
  when `opts.isHeader(entry)` answers truthy or, without it, when `entry._header` is: a string is the
  heading's text, `true` uses the indent column's text. A heading row hides every cell, cell overlay,
  strike line and action icon, swaps its banding for an accent strip at 0.10, and draws one line of
  text across the row in the accent colour (`opts.headerFont`, default `GameFontNormal`). `entry._expanded`
  true or false adds the client's own craft-window minus or plus in front; nil adds nothing. A click
  on a heading reaches `onRowClick` with its entry, which is how a consumer toggles it; no selection
  or scroll predicate treats headings specially. A header sort sorts each heading's rows UNDER it and
  never moves a heading: rows before the first heading are their own group, and groups are flat, so a
  tree that wants nested groups sorted uses `externalSort`. Column filters never judge a heading and
  its cells add no filter values or `autoFit` width. With a filter or search active, a heading stays
  while any row of its group survives, or when the search matches the heading's own text.
  `entry._indent` is a level: level x `opts.indentStep` (scale-1.0 px, default 12) moves the indent
  column's text right while its right edge stays, so it still clips at the column. The indent column is
  `opts.indentKey`'s, else the first column that shows text; a heading is indented too. A formatter on
  that column is handed the narrower width. A pooled frame is re-laid only when the entry it shows
  changes level.
- **RowList button cells that hide per row** (TOGProfessionMaster inbox `337bb7d3`). On a `button`
  column, `col.show(entry)` false hides the button on that row: no mouse, a blank cell, and an empty
  label for the search and filter. `col.text(entry)` is the label per row, used as given (no `format`,
  no class tint). `col.tip(entry, button)` returns `title, body[, reason]` and is read on hover, so
  text about how old the data is was true when the player looked; the reason is the red last line, as
  on `CreateExplainedButton`, and `tip` wins over `cellTip`. Every one is re-read on each populate, so
  a sibling addon that loads late needs only `rl:Refresh()`. `_readonly` still disables and does not
  hide.
- **RowList `col.iconTexCoord` and `opts.fitContent`** (TOGProfessionMaster inbox `8680f2cc`).
  `iconTexCoord = { l, r, t, b }`, or `true` for the usual 0.07-0.93 crop of `Interface\Icons` art, is
  applied on every populate. A column without it sets the full texture back, because the holder is
  pooled and may have served a cropping column. `fitContent = true` or `{ maxRows = n }` sets the
  PARENT's height to the header bar plus one scaled row height per drawn row, up to `maxRows`, after
  which the list scrolls. It re-fits on every refresh, so a scale change, a search or new data resizes
  it. `onHeightChanged(rl, h)` hears each new height. No rows gives the header's height (0 without
  one), and that is not reported as an empty-render fault. The parent has to be anchored by its top
  alone: a frame anchored top and bottom ignores `SetHeight`.
- **RowList drag to reorder** (TOGProfessionMaster inbox `973a1ab1`). With `opts.reorderable` and
  `opts.onReorder(fromIndex, toIndex, entry, rl)`, dragging a row lifts a copy of it at `TOOLTIP`
  strata that follows the pointer, dims the row itself to 0.4, and draws a 2px accent line (scaled) at
  the row boundary nearest the pointer. Dropping calls `onReorder` with the entry's index in `data` and
  the index it should have after the move. The list moves nothing itself, so the consumer reorders its
  model and calls `SetData`. The client's own drag threshold keeps a click a click, and a right-click
  still reaches `onRowClick`. Held on the first or last drawn row, the list scrolls one row every 0.1s.
  Escape cancels out of combat: the lifted row takes the keyboard and lets every other key through.
  `EnableKeyboard` is protected and `SetPropagateKeyboardInput` restricted (Classic Era
  `SimpleFrameAPIDocumentation.lua`), so in combat the keyboard is not taken, and a drop off the list
  is the way to cancel. No call is made for a drop off the list, a drop in the slot it came from, or
  a drop after the data changed under the drag. A drag does not start while a header sort, a column
  filter or a search is active, because the drawn order must be the model's order. An `externalSort`
  list draws `data` as given, so it can be dragged. `Detach` cancels a drag in progress.
- **`W:ClampWindow` and `W:SetWindowProfile`** (TOGProfessionMaster inbox `72e8dd4b`). `ClampWindow`
  caps a window's size to the screen and moves it fully onto it, in the window's own units, and
  writes the result into `widget.status`. It changes only what is off the screen, so the floor is
  undercut only when the screen itself is smaller. `SetWindowProfile(widget, key, { width, height,
  resizable, minWidth, minHeight })` switches a persisted window between named sizes. A locked profile
  snaps to its size and turns resizing off: `SetEnabled(false)` on a ClearFrame's handle (grips
  hidden), `EnableResize(false)` on AceGUI's `Frame`, and `SetResizable(false)` on both so a drag is
  refused. A resizable profile restores its own size from `saved.profiles[key]` (else its defaults),
  raised to its own floor, and that floor follows the scale. Leaving a resizable profile saves the
  frame's size under its key, and so does releasing the window while that profile is active
  (TOGProfessionMaster inbox `7481d3a5`): a window dragged and then closed on a resizable tab used to
  reopen at the size saved at the last tab switch. `ForgetWindow` saves it before the record goes and
  before the widget's own `OnRelease` runs, through the same helper as the switch-away save. A locked size only ever lands in the table's ordinary `width`/`height`,
  so it cannot reach a resizable profile's save. Position is shared, and every switch ends in
  `ClampWindow`. `ForgetWindow`, and so Release, turns resizing back to how it was before the first
  profile.
- **`W:SetWindowOpacity` / `W:GetWindowOpacity`** (TOGProfessionMaster inbox `ae090bd5`) fade a
  window's background fills: its own backdrop, and the pane backdrop of every container inside it
  (`border`, `treeframe`, and the frame a container's `content` sits in, which is the only way to
  reach InlineGroup's). Text, icons, buttons, borders and `SetAlpha` are untouched. The fade is always
  from the stock colour, so it is idempotent and 1 is stock. Each widget remembers the frames it owns
  and restores them on its own Release, so a pane released by a tab switch goes back to the pool clean
  while the window stays open. A pane drawn after the call is not reached until the consumer calls it
  again.
- **`W:SetWindowScale` / `W:GetWindowScale`** (TOGProfessionMaster inbox `e5e1586a`) set one window's
  `frame:SetScale`, clamped to 0.5-1.5 and separate from the session-wide `W:SetScale` (0.8-2.0), which
  still multiplies inside it. The top-left corner stays on the same screen point (anchor offsets are
  in the window's own units, so they are multiplied by old/new), then the window is clamped. It is
  saved as `windowScale` in a persisted window's table, and `PersistWindow` re-applies it before the
  position, which was written in those units. Release puts the scale back to 1.
- **`W:EscapeLayer(window, childFrames)` / `W:DropEscapeLayer(window)`** (TOGProfessionMaster inbox
  `d8f15682`): Escape closes the most recently shown child first and the window on the press after
  the last child. Read in the Classic Era source (`UIParentPanelManager.lua:1041`),
  `CloseSpecialWindows` walks `UISpecialFrames` with `pairs` and hides every entry that `IsShown()`, so
  a window and its popup on that list close together on one press. The classic_anniversary and classic
  trees have the same function at the same line. So the window is represented by one proxy frame,
  shown only while the window is, and the window and its children come off the list while the layer
  lasts. The proxy's `OnHide` closes the newest shown child and shows itself again, or hides the window
  when none is left. A hide the proxy did not get from the walk (its window or UIParent hidden) leaves
  its own `IsShown` flag true and is ignored. Closing the window hides every shown child, which runs
  their `OnHide`, and hides the proxy so a closed window cannot swallow the next press. It is plain
  Lua hiding plain frames, so it works in combat. The hooks go on the window frame once and read the
  layer at event time. An AceGUI window's layer ends on Release, and the names come back onto the
  list. Known cost: `CloseWindows` also calls `CloseSpecialWindows` (line 1087), so loss of control and
  other panel opens also close only the newest child of a layered window.
- **`CreateExpandableList` at any depth** (TOGProfessionMaster inbox `7ab1cb56`), for a profession ->
  specialisation -> member tree. A child may carry `children` of its own, and the layout is now one
  recursive walk. A node with children is a group at any depth (header style, a toggle, indented
  `indent` per level). A node without is a leaf: header style at depth 0 and child style below, which
  is exactly the old two-level picture. Expand state is keyed by the path of keys, so two "Main" specs
  under two professions keep their own state. A top-level group's path is its own key, as its state key
  was before. `defaultExpanded` and `SetAllExpanded` reach every depth, and
  `list:IsExpanded(key, ...)` reads a path. Any node takes `color`, `onClick(node, mouseButton,
  rowFrame)` (a group toggles and then calls it) and `tooltip`, a `{ title, body }` pair or a function
  read on hover. Every script is set on each layout from the node drawn there, and a row with no
  click and no tooltip takes no mouse, as before. A pooled group row puts its font's own colour back
  when the next node has none. A toggle re-lays the pooled rows; no frame is rebuilt.
- **`W:CreateStepper` and the `LAGW-Stepper` widget type** (TOGProfessionMaster inbox `ea8db903`):
  `[-] [qty] [+] [MAX]`. Typing keeps digits only as they are typed, and commits on Enter or focus
  loss, clamped to `min` and `max()`. An emptied box and Escape revert. `-` and `+` step by `step`
  and are `CreateExplainedButton`s, so at a bound they grey out and the tooltip's red last line says
  which bound. MAX sets `max()`, read on every click; a max of 0 greys it. `SetValue` is silent, and a
  player's change calls `onValueChanged(value, stepper)` once, only when the value moved. Sizes are
  scale-1.0; the layout computes its widths from the scale, so it does not depend on which scale
  listener runs first. `LAGW-Stepper` (Version 1) wraps it and fires `OnValueChanged(value)`. It
  builds MAX once and shows it only after `SetMaxButton(true)`, and is reset on acquire. Not
  delivered: holding a button to repeat, which needs a per-frame tick while held.
- **`CreateFormDialog`: dropdown rows, item rows, `SetHint` and `anchorTo`** (TOGProfessionMaster inbox
  `6cf3b4e4`), all opt-in; existing rows build exactly as before.
  - A `kind = "dropdown"` row puts a `CreateDropdownBox` where the edit box goes. `items(query)`
    returns `{ text, value }` pairs, built fresh on each open with the current one ticked. Choosing
    one calls `onChanged(value, dialog)` only when it changed. `fields[i]` has `GetValue()` and a
    silent `SetValue(value[, text])`.
  - A `kind = "item"` row shows the item's icon and link from the label to the right edge. Hover draws
    the item's own tooltip; `SetHyperlink` is given the bare `item:` part. A click goes to the client's
    `HandleModifiedItemClick`. `fields[i]:SetItem(link[, icon])` changes it. The icon is `row.icon`,
    else `C_Item.GetItemIconByID(link)`, which the Classic Era, Anniversary and Classic docs all
    declare.
  - `frame:SetHint(text or nil)` adds, changes or removes the hint after build. The first row (or the
    error line) re-hangs under whichever of title and hint is showing, and the height is recomputed
    unless the caller gave one. OK/Cancel are anchored to the bottom, so they stay on the frame.
  - `opts.anchorTo` (with `point`, `relPoint`, `x`, `y`; default TOPLEFT to the owner's TOPRIGHT, 4px
    right) and `frame:SetAnchor(owner, ...)` place the dialog by its owner on every show, clamped by
    the floating frame. A later `SetAnchor` re-points a named dialog to whichever row opened it. An
    owner that is not visible leaves the dialog where it was.
- **`W:CreateSecureActionButton`** (TOGProfessionMaster inbox `3d04549b`), a secure button with combat
  guards. It registers for `AnyUp` and `AnyDown`: read in Classic Era `SecureTemplates.lua:789-823`,
  `SecureActionButton_OnClick` acts on exactly one of the two, chosen by `useOnKeyDown` or the
  `ActionButtonUseKeyDown` CVar, so it fires once under either setting. `SetAction(attrs)` and the
  button's own `SetPoint`, `ClearAllPoints`, `SetAllPoints`, `SetSize`, `SetWidth`, `SetHeight`, `Show`,
  `Hide`, `SetShown`, `SetEnabled`, `Enable`, `Disable` and `SetParent` (wrapped on the instance) run
  now, or are queued in combat. One session-wide queue runs once, in
  order, on `PLAYER_REGEN_ENABLED`. A scale change in combat queues the resize as well. The factory
  returns nil in combat. The tooltip is `CreateExplainedButton`'s and works while disabled; `preClick` /
  `postClick` are the consumer's. Not safe to pool: `SetParent` is `IsProtectedFunction` in all three
  Classic trees, and a frame that parents a secure button is itself protected (Warcraft Wiki; web, not
  client source). So it belongs in a frame the consumer owns, never in a pooled AceGUI frame.
- **`W:NewDockLayout`** (TOGProfessionMaster inbox `2f9efc9e`) splits a container into `top`, `right`,
  `bottom` and `center` (alias `left`). The panes are four raw frames the library owns, anchored into
  the container's `content`, so a live resize moves them through their anchors. No method of the pooled
  widget is replaced and none of its scripts is hooked. The sizes are re-decided by one extra frame of
  the library's over the content (its `OnSizeChanged`) and by a scale listener. `top`, `right` and a
  fixed `bottom` are scale-1.0; an `"auto"` bottom is the pixel height given to
  `SetBottomHeight(px)`. The bottom spans the full width. The centre never collapses: the top stops one
  pixel short of the height, the bottom takes only what is left under it, and the right leaves the
  centre `minCenter`. `SetPaneShown(name, bool)` gives a pane's space to the centre. An AceGUI
  container's Release releases the dock (every frame hidden and handed to UIParent, the scale listener
  dropped); a raw frame uses `dock:Release()`.

### Changed

- **The default accent is the suite orange** (TOGProfessionMaster inbox `8f931ba9`). The operator's
  words: *"have the library change it's color to our orange, not sure why it's gold."* Gold is
  Blizzard's `NORMAL_FONT_COLOR`, not the suite's brand, and the one-setter rule stopped a consumer
  from fixing it locally without becoming a second setter. `DEFAULT_ACCENT` is now one literal, read
  by the config table, `GetAccent` and `AccentRGB`. `AccentRGB`'s per-channel fallback for a malformed
  accent is now `1, 0.5, 0` to match. Colours the library draws as the client stay on
  `NORMAL_FONT_COLOR`: a tooltip header, the cooldown caption, the DatePicker label.
- **An upgrade in a live session moves the old default too.** `lib.config` survives an upgrade from an
  older copy, so a session where an addon with MINOR 35 or older loaded first would have stayed gold.
  On load, a config still holding the untouched gold default moves to orange. A consumer that set gold
  through `SetAccent` or `Configure` (recorded since MINOR 33) keeps it.
- **`PersistWindow` clamps the restored window to the screen.** A table saved on a larger screen or
  at a smaller UI scale used to restore a window partly or wholly off the screen, or bigger than it.
  It is now capped and moved on, and the table is updated to match. A window that fits is untouched.
- **README: "Auditing a consumer"**, a table from what a hand-rolled copy looks like in an addon's code
  to the library call that replaces it, for every window, list, control and look-and-feel feature
  with the MINOR that brought it. A feature was usually extracted FROM a consumer, and its original
  often survives there (ClassicCalendar's World Buff docking still carries its own copy of what
  became `DockWindow`). A per-version list does not show an auditor any of that.
- **RowList counts its visible rows with a small allowance for rounding.** At a scale where the row
  height is not a whole number, a parent exactly n rows tall could divide to just under n and show
  one row fewer. `fitContent` sets exactly such heights, so the count now adds 1e-6 before flooring.
- **Peer Review's verdicts on this batch's self-audit** (audit thread `231f14e7`):
  - The stepper's `Refresh()` and `SetBounds` no longer rewrite the box while it has focus. A consumer
    refreshing on `BAG_UPDATE` used to erase a half-typed number. The typed number is clamped against
    the new bounds when it commits. A click, `SetValue`, Escape and show still rewrite it.
  - The stepper snaps to the nearest multiple of `step` counted from `min`, rather than to a whole
    number, so a fractional step (0.5) works and a decimal point can be typed for one. An integer step
    from `min` 0 lands exactly where it did. A step of zero or less falls back to 1 instead of dividing
    by zero. `SetStep` re-snaps the current value onto the new grid, as `SetBounds` re-clamps it, so a
    click from a value set under the old step moves by exactly the new one.
  - `SetWindowScale` re-applies the window's own anchors with the offsets times old/new, instead of
    re-placing it TOP/LEFT on `UIParent`. A docked or consumer-anchored window stays attached, and its
    anchored point stays on the same screen spot.
  - README: a dock's content goes in the panes only, since AceGUI children of the same container are
    laid out over them.
  - The secure button's guard shadows widget methods with Lua fields. The Classic Era secure click path
    and the button's templates were read for a secure caller of any of them, and none exists; the
    reasoning, with line numbers, is in the code. Not verified in a client.

### Tests

- `Tests/poolsafe_spec.lua` (20 examples) drives the four helpers through real AceGUI-3.0 and its stock
  Button, EditBox and SimpleGroup. Every "the next owner finds nothing" case re-acquires the released
  widget and asserts the pool handed back the same table, so none of them can pass on a fresh widget.
- `Tests/tipwidth_spec.lua` (9 examples) pins the tooltip floor through the harness's modelled
  `SetMinimumWidth`/`GetMinimumWidth`, forced flag included, and the popup placement at the screen's
  edges.
- `Tests/flash_spec.lua` (5 examples) drives each pass by calling the group's own `OnLoop`, since the
  frame model builds animation groups but does not run them.
- `Tests/interaction_spec.lua` (8 examples) opens real menus on anchors nested inside a window and
  drives the focus query both with and without the client's `GetCurrentKeyBoardFocus`.
- `Tests/rowlisthover_spec.lua` (10 examples) fires enter and leave in the client's order (old frame's
  leave, then the new frame's enter) with each row's `IsMouseOver` answering for the pointer. Each
  child is also entered from a dark row, so the child's own enter is proven to light it.
- `Tests/rowlist_minor36_spec.lua` holds the other RowList requests of this release, starting with
  the sort cycle (7 examples), the formatter width (4), the word search (6) and the scroll position
  (6).
- `Tests/rowlist_groups_spec.lua` (47 examples) covers headings and indent, the button cells, the icon
  crop, `fitContent` and the drag. It drives the drag by placing the harness cursor and calling the
  row's `OnDragStart` / `OnDragStop` and the lifted row's `OnUpdate`. The harness models neither
  keyboard getter, so the Escape tests record `EnableKeyboard` and `SetPropagateKeyboardInput` calls.
  None of this has been tried in the client.
- `Tests/windowprofile_spec.lua` (25 examples) drives the clamp, the profiles, the opacity and the
  window scale through real AceGUI-3.0 `ClearFrame`, `Frame`, `TabGroup` and `InlineGroup`, and
  re-acquires the released widget where the point is that the next owner finds nothing.
- `Tests/escapelayer_spec.lua` (9 examples) presses Escape through a copy of the client's own
  `CloseSpecialWindows` loop, so the layer is tested against the walk it exists to work around.
- `Tests/expandable_depth_spec.lua` (7 examples) opens a three-level tree through the rows' own
  scripts, and the two existing expandable-list examples still pass unchanged.
- `Tests/stepper_spec.lua` (16 examples) drives the stepper through its own scripts and the widget
  type through real AceGUI-3.0, including a re-acquire from the pool.
- `Tests/formdialog_rows_spec.lua` (9 examples) drives the dropdown through a captured menu, the item
  row through stubbed `C_Item` and `HandleModifiedItemClick`, and the hint and anchor through the
  frame model's anchor points.
- `Tests/securebutton_spec.lua` (9 examples) swaps `InCombatLockdown` to enter and leave combat and
  fires the queue's own `PLAYER_REGEN_ENABLED` handler.
- `Tests/docklayout_spec.lua` (7 examples) reads the panes' anchors, and checks that the dock replaces
  no method on a real AceGUI `SimpleGroup` and lets go on its Release.
- The v0.1.11, v0.1.12 and v0.2.0 sections moved whole to `CHANGELOG_ARCHIVE.md` to keep this file under
  120,000 characters.
- `Tests/widgets_spec.lua` pins the new default, `AccentRGB`'s fallback, and the upgrade path: a
  simulated MINOR 35 table is reloaded over and moves to orange unless gold was set explicitly.
- The three specs that reset the accent after a test now reset it to `W.DEFAULT_ACCENT` rather than to
  a gold literal. The RowList selection-tint test paints with green, so it still proves the tint is
  read at paint time now that orange is the default.
- Two weak assertions rewritten (Writ inbox `943be786`). Each was `is_nil` on a literal key, which
  still passes if the key is misspelt or renamed. `bootstrap_spec.lua` now checks
  `W:TriggerVersionCheck()` returns false instead of reading `W._vc`. `widgets_spec.lua` checks that
  every config key `Configure` did not name is unchanged and that none was added, instead of
  `W.config.classColors`.
- `wow-version-replication.ps1` (dev only, not packaged) also copies into `_classic_beta_`, where the
  WoW Forever client installs.

## [v0.2.5] -- a released window takes its floor with it, one search box, and a filter strip that lines up

### Compatibility -- MINOR 34 -> 35

New methods: `W:ForgetWindow(widget)`, `W:NewStrip`, `W:StripAdd`, `W:StripRowWidth`,
`W:FitCheckBox`. New widget type: `LAGW-SearchBox` at Version 1. New AceGUI layout: `LAGW-Strip`.
Feature-detect on `type(W.ForgetWindow) == "function"`, `if W.NewStrip then`,
`AceGUI:GetWidgetVersion("LAGW-SearchBox")`, or `LibStub.minors["LibAceGUIWidgets-1.0"] >= 35`. One behaviour changes for existing calls:
`PersistWindow` wraps the widget's `OnRelease`, so releasing a persisted window now forgets it. The
widget type's own `OnRelease` still runs. The three widget types stay at Version 30 and
`LAGW-DatePicker` at 3. The TOC is unchanged.

### New

- **`LAGW-SearchBox`, the search box as an AceGUI widget** (Questbook inbox `293177a6`).
  `CreateSearchBox` returns a raw frame, so TOGBankClassic (`TOGBankSearchBox`) and Questbook
  (`QuestbookSearchBox`, a copy of TOGBank's) each wrapped it as their own AceGUI type to put it in a
  Flow row. This is that wrapper, with every method either copy had, so both can switch without
  losing one. `SetText` is silent. The player's typing and the clear-X fire
  `OnTextChanged(text)`, and the clear-X fires from its own `OnClick` because the template empties the
  box with a programmatic `SetText("")`. `SetPlaceholder(nil)` restores "Search", and `OnEnter` /
  `OnLeave` / `OnEnterPressed` pass through. The box is released empty. Its 24px height follows the UI
  scale, as the box's font already did. It lives in the core file, not a satellite, so the harness
  manifest did not have to change. Pinned by `Tests/searchboxwidget_spec.lua`.
- **`LAGW-Strip`, a filter-strip layout** (Questbook inbox `c2be4737`), from Questbook's
  `FilterStrip.lua`. AceGUI's Flow cannot line a strip up: a labelled EditBox puts its box 25px down a
  44px frame, a labelled Dropdown 14px down a 40px one, and buttons, checkboxes and the search box are
  24px with no label. Controls now go in unlabelled, and `W:StripAdd(strip, control, caption)` adds the
  caption as a separate gold `TLabel`. The layout puts every caption on one line and centres every
  control on one line under it, with one gap between each pair. A row that runs out of width wraps,
  and a hidden control takes no space and hides its caption. `W:NewStrip()` makes the group,
  `W:StripRowWidth(strip)` reports the widest row for a window floor, and `W:FitCheckBox(cb)` sizes a
  checkbox to its label. Two differences from Questbook's copy:
  - The gap, the row gap and the caption line follow the UI scale. A row is at least 26px and grows to
    its tallest control, so a scaled `LAGW-SearchBox` still centres. The strip re-lays itself on a
    scale change.
  - State lives in the group's `userdata`, which AceGUI empties on release, so a pooled group cannot
    read its last owner's captions.

  `LAGW-SearchBox` now re-runs its parent's layout when the scale changes its height, since AceGUI's
  `SetHeight` does not. Pinned by `Tests/strip_spec.lua`.

### Fixed

- **A released persisted window no longer resizes the next addon's window** (TOGBankClassic inbox
  `3d96003a`). AceGUI's widget pool is shared by every addon in the session. `PersistWindow` left three
  things on the pooled widget and frame when it was released: its record, that record's scale
  listener, and the resize floor it had raised. The next scale change then raised whatever window the
  pool had handed that frame to. TOGBank measured a released Guild Bank window growing from 900 to
  1568 wide on `SetScale(2)`. Release now drops the record and its listener and restores the bounds
  captured before the first `PersistWindow`. A `ClearFrame`'s resize handle is restored, not destroyed,
  because it is built once in the constructor and a destroyed one leaves the pooled frame with no
  grips. `W:ForgetWindow(widget)` does the same without a release. Pinned by
  `Tests/forgetwindow_spec.lua`, which includes TOGBank's contract check.

### Tests and docs

- 714 passed, 0 failed, and every executable line of **every** shipped file is reached: 4050/4050
  across `LibAceGUIWidgets-1.0.lua`, `-Resize.lua`, `-RowList.lua`, `-DatePicker.lua` and
  `LibAceGUIWidgets.lua`. The docs had claimed that for the whole library while it held only for the
  core file and RowList; the gate had been run on the core file alone. The missing lines:
  - `ForgetWindow`'s `SetMinResize` branch, for clients older than `SetResizeBounds`.
  - The resize handle restoring a saved position (`ApplyStatus` with both `left` and `top`).
  - `SetRange` pulling an open calendar's month into the new range.
  - The weekday-name backfill for a date popup built by a pre-MINOR-30 copy.
  - The whole `LibAceGUIWidgets.lua` bootstrap, now pinned by `Tests/bootstrap_spec.lua`.
- `README.md` was checked against every public function, constant, option and widget method in the
  code, and now documents what it lacked:
  - The named cooldowns (MINOR 24) and the version helpers.
  - The ClearFrame, GroupFrame and TLabel methods and callbacks, and the DatePicker's
    `OpenCalendar` / `CloseCalendar` / `IsCalendarOpen` / `GetText` and `W:DatePickerPopup()`.
  - The `W.DatePicker` helpers `ymd`, `isLeap`, `stepMonth`, `weekStart` and `GLYPH`.
  - The options of `OpenMenu` (`width`, `search`, `itemsFor`), `CreateDropdownBox`, `ShowDialog`,
    `CreateSearchBox`, `CreateFormDialog` (`strata`, `level`, `closeText`, row-button `width` /
    `onClick`), `CreateScrollFrame` (`barWidth`), `CreateExpandableList` (its group and child fields
    and `SetAllExpanded`), `ShowTooltip` (`titleColor`, `reason`, `owner`), `MakeLabel` and
    `StartCooldown` (`interval`).
  - The RowList basics: `rowCount`, `header`, `headerTip`, `sortable = false`, `font`,
    `color = "class"`, `classDisplay`, the `checkbox` column and `boxSize`, `SetData`'s
    `preserveScroll`, and `ClampOffset`.
  - The DockWindow handle's `IsDockEnabled` / `Dock` / `Restore` / `IsNearTarget`, and the resize
    handle's `SetStatusTable` / `ApplyStatus` / `SaveStatus` / `Destroy`.
  - `SetAccent` / `GetAccent`, `ClassColor`, `SetTooltipOwner` / `GetTooltipOwner`,
    `TabLabelRegion`, `SYMBOL_FONT` / `SYMBOLS`, and `classDisplay` / `refontHook` in the
    `Configure` example.
- Statements the code contradicted, corrected:
  - README and CurseForge dated the `PersistWindow` / `DockWindow` refusal to MINOR 31, or said
    "nothing enforces that". It shipped in MINOR 32 (v0.2.2). The two code comments that said 31 are
    corrected too.
  - A `checkbox` column writes `entry[key]` only when it has an `onToggle`.
  - A dialog parented into a window comes back with it, still open, rather than dying with it (MINOR 33).
  - The expandable list's toggle is an ASCII `-`, not a minus sign.
  - v0.1.11 brought four additions, not three.
  - The two README contract intros had not kept up with their own bullets.
  - The menu-item and `CloseMenuFor` paragraphs sat inside the form-dialog entry; they are under Menus
    now.
- The CurseForge page also gained the tab highlight, RowList icon columns, the named cooldowns, search
  in menus and dropdowns, and the diagnostics record.

## [v0.2.4] -- a RowList that filters, searches and sizes itself, tooltips that give the anchor back, and two crashes gone

### Compatibility -- MINOR 33 -> 34

New methods: `W:HideTooltip()`, `W:ShowTooltip()`, `W:MenuCapacity()`, `RowList:SetSearch()`,
`RowList:ClearFilters()` and `RowList:Detach()`; `W:AttachTooltip` takes an optional fourth
`opts`. Feature-detect on `type(W.HideTooltip) == "function"` or
`LibStub.minors["LibAceGUIWidgets-1.0"] >= 34`. The RowList options and column fields below are
opt-in fields on tables the caller passes, so gate those on the MINOR. Two behaviours change for
existing calls: every tooltip this library draws now hands the anchor back to the client's default
when the pointer leaves, rather than only hiding; and `RowList:Refresh()` / `ClampOffset()` now
rebuild the sorted view instead of reusing the cached one, which is what their documentation always
promised. Nothing else changes for a list that does not use the new fields: a header without
`filterable` still sorts on click, rows do not take hyperlink clicks unless `hyperlinks` is set, and
`_getSortedData` still returns `data` itself when nothing narrows or sorts it. The three widget
types stay at Version 30 and `LAGW-DatePicker` at 3. The TOC is unchanged.

### New

- **RowList: everything FastGuildInvite's own list has that this one did not** (inbox
  `7e28e319`), so FGI can retire `GUI/RowList.lua`, the file this list was extracted from.
  - `opts.externalSort` + `opts.onSortChanged(key, desc, rl)`. With `externalSort` a header click
    sets the key and the arrow and fires the callback, and the rows are drawn exactly as the
    consumer ordered them. FGI's Announce, Eligibility and Messages tabs sort parent rows with their
    children attached, which no flat per-row comparator can express. `onSortChanged` fires on an
    ordinary list too, for every sort the user makes, and never for the consumer's own `SetSort`.
  - An `expander` column: a +/- tree toggle bound to `entry[key]`, tri-state as FGI's is (`true`
    expanded, `false` collapsed, `nil` hidden, for a leaf row). The click reports the new value to
    `col.onToggle(entry, newValue, idx, rl)` and does not write the entry, because the owner
    rebuilds the data and a write here would flip it twice.
  - A `button` column: a clickable text cell with a hover highlight, `col.onClick(entry, idx, rl,
    mouseButton, cellFrame)` and `col.cellTip(entry)`, whose tooltip is titled with the header. It
    honours `col.justify`, forwards a right-click to `onRowClick` so a row menu still works over
    it, and builds no hover overlay, which would sit on top of it and take its clicks. A `cellTip`
    that answers nil or empty shows no tooltip at all; the first build drew a header-only one,
    found by FGI's suite on adoption.
  - `entry._readonly = true` disables that row's checkbox and button cells, re-applied in both
    directions on every populate because the row frames are pooled.
  - `opts.refontHook` and `opts.classDisplay` override the `lib.config` hooks for one list. FGI
    asked whether the session-global config was the right home for a per-consumer hook, and it is
    not: `lib.config` is one table for every addon in the session, so a hook set there by one
    consumer re-fonts and re-labels every other consumer's lists. The global hooks still apply to a
    list that sets none of its own.
- **RowList: the four things TOGTools' 11 tables need** (inbox `c571dee6`).
  - A `filterable` column's header opens a column menu: sort ascending and descending, Select all /
    Clear all, and one checkbox per distinct value of what the cell shows, with colour codes, icons
    and link wrappers stripped. The values cascade (a column's list comes from the rows every other
    filter lets through), `col.filterGroup(entry)` nests them under group submenus, and the list is
    capped at 200 with a line saying how many more there are. The menu has a search box that narrows
    the values as the player types. A header whose column is filtering shows an asterisk after its name.
    `opts.headerMenu` puts the menu on every header. The menu is `W:OpenMenu`, so it uses the same
    strata, pooling and click-outside close as every other menu here. A second click on the same
    header closes it.
  - `rl:SetSearch(text)`: a case-insensitive plain substring over every text and button cell's
    shown text (never a checkbox's `true`), composed with the filters; nil or empty clears it, and
    the list goes back to its top. `rl:ClearFilters()` drops every column filter.
  - `col.autoFit` (+ `col.minWidth`): the column is as wide as its widest cell over all of `data`
    (not the filtered view, so it does not jump while the player filters) plus 8px, and never
    narrower than its header. It is re-measured on `SetData`, `SetColumns` and a scale change, and
    it counts as a fixed column, not a second auto-width one.
  - `opts.hyperlinks`: `|H` links in cells hover into the tooltip (player links skipped) and click
    as they do in chat. A player right-click opens the chat-name menu, handed `DEFAULT_CHAT_FRAME` off
    Retail because Classic's Whisper reads the frame's `editBox` and a row has none; other clicks go
    through `HandleModifiedItemClick` and then a chat-link insert. Opt-in, because a row that takes
    hyperlink clicks takes the mouse. Feature-detected on `SetHyperlinksEnabled`. The row behaviour
    is **not verified in a client**, only offline.
- **`W:ShowTooltip(anchor, title, body[, opts])`**: the library's one title/body tooltip draw, made
  public so the RowList `button` column's `cellTip` goes through it rather than a copy.
- **One function for what a cell shows.** The draw, the filter labels, the search and the autoFit
  measurement all read `RowList:_cellText`, so "what you see is what you filter" holds by
  construction rather than by four copies agreeing.
- **The scroll range counts the rows drawn**, not `#data`, now that a filter or a search can make
  them differ. `Refresh`, `ClampOffset`, `SetData(…, true)` and the mouse wheel all read it.

- **A second round of consumer requests, from mapping real lists onto the first.**
  - `opts.tooltipOwner(frame)` (FGI inbox `df5ec079`) anchors every tooltip the list draws -- header,
    action icon, button cell, hyperlink -- in place of `lib.config.tooltipOwner` or the default, for that
    list only. FGI's owner also re-fonts non-Latin tooltip lines, which the global owner would have
    forced on every other addon's tooltips.
  - `rl:Detach()` (TOGTools inbox `c571dee6`, item 5): call it from the host widget's `OnRelease`. It
    closes a column menu the list opened, hides the rows, header and scrollbar, re-parents them to
    UIParent, and makes every later repaint, resize, rescale, scroll, wheel and `SetColumns` a no-op.
    AceGUI pools the frame a list is built in, and a `HookScript` on it cannot be removed, so without
    this a released list goes on re-laying its rows inside the next widget to get the frame.
  - `col.align` (item 6): the OPT-IN way to right-align a text cell. `col.justify` is still ignored on
    text cells, because consumers already pass it and honouring it now would move their columns.
  - `col.gapBefore` (item 7): extra space, a scale-1.0 value, to a column's left in the header and in
    every row, on both placement chains.
  - `col.sortDescDefault` (item 8): a column whose first header click sorts high-to-low.
- **`W:MenuCapacity(withSearch)`**: how many menu rows fit in 80% of the screen at the current scale.
  A menu does not scroll and is clamped to the screen, so a row past that number cannot be reached.

`Tests/rowlist_minor34_spec.lua` covers all of the above, and RowList is at 100% line coverage
(1217/1217). `LibAceGUIWidgets-1.0.lua` is at 100% too (1896/1896, was 95.77%): the new
`Tests/older_paths_spec.lua` drives 80 lines no spec had reached, all older than this release --
ClearFrame's title-bar move, Close, info icon, settings gear, status text and release; TLabel's image
layout, spacer height, tooltip owner, texcoord and font fallbacks; the dropdown box's click and search;
the search box's escape; the form dialog's hint; the scroll box's wheel; `SetAllExpanded`; a
TOP/BOTTOM dock; and `PersistWindow` on a client with only `GetMinResize`. The features FGI needs most (`externalSort`, read-only rows) and the H1 crash below were
each broken on purpose, and the spec went red before the code was put back.

### Fixed in this release before it shipped

Peer review of this MINOR (thread `af2ebd61`) found these in the working tree; none reached a player.

- **H1, and older than this release: a `SetColumns` with an identical column set left the column widths
  keyed by the OLD column tables.** `_colW` is keyed by table, and the same-set branch adopted the new
  tables without deriving their widths, so the next grow, resize or rescale raised `attempt to perform
  arithmetic on a nil value`. This has been live since MINOR 33 for any consumer that follows the
  file's own advice to call `SetColumns` on every repaint, which Dibs' Tracker does. The same-set
  branch now re-derives the widths.
- **H2: `Refresh` and `ClampOffset` drew a stale snapshot.** Both are documented for use after the
  consumer changes the data in place, but the filtered and sorted view was cached, so a removed row
  stayed drawn and clickable and `onRowClick` could hand back a deleted entry. The public `Refresh` and
  `ClampOffset` now drop the cache; the list's own repaints that change no data (a resize, a scale
  change, a scroll-to) keep it.
- **H3: a hyperlink click passed the bare `item:...` link to `HandleModifiedItemClick`**, which wants
  the full `|H` text, so shift-click inserted nothing and a plain click opened nothing. Every non-player
  click now goes through `SetItemRef(link, text, ...)` as a chat frame's does.
- **M1**: Select all and Clear all now cover every value, not only the ones the menu has room to draw.
- **M2**: the filter menu draws only as many values as `MenuCapacity` says fit, with a line counting the
  rest; a group submenu and the group list are capped the same way. The first build could draw 200 rows,
  about 3,700px at scale 1.
- **M3**: a value excluded by a filter and then gone from new data is dropped from the filter, so the
  header's asterisk no longer points at a value the menu can't show.
- **M4**: a read-only row's button cell is disabled, and a disabled Button fires no `OnEnter` unless
  `SetMotionScriptsWhileDisabled` is set, so its `cellTip` went silent. It is set now.
- **L2**: a button column now calls `onCellEnter`, `onCellLeave` and `onCellClick` from its own scripts;
  the first build silently ignored them there.
- **L3**: Select all and Clear all redraw the open menu in place and keep the search text; re-opening it
  cleared the box. `W:OpenMenu`'s rows now read their check state from the item they carry at click
  time, not the one the click handler was built for.
- **L4**: filter values sort as the header does -- numbers by value, text case-folded.
- **L5**: a column set that changes only `font`, `justify`, `align` or `gapBefore` is a rebuild, not a
  no-op.
- **L6**: `headerMenu` leaves a header that can neither sort nor filter inert, instead of opening a
  title-only menu.
- **L7**: a filterable column's header is measured with its asterisk, so a tight column fits it.

- **L1**: a leave no longer hides a tooltip another frame or addon has taken since. `ShowTooltip`
  records who the tooltip was actually handed to, and `HideTooltip(frame)` does nothing unless that
  owner still holds it. The guard is on the RECORDED owner, not the hovered frame, so a tooltip a
  consumer's `tooltipOwner` anchored elsewhere is still hidden rather than left stuck on screen.

Not changed, with the reason. **M5**: with `hyperlinks` on, a link click may
also run the row's `OnMouseDown`. That ordering is client behaviour I can't reproduce offline, so it
stays open (not verified).

### Fixed

- **`RowList:SetColumns` with a new column set raised in the client on any list with a plain text
  column** -- `FontString:SetScript(): Doesn't have a "OnClick" script`, which left the list
  half-rebuilt. Shipped in MINOR 33 (v0.2.3), when `SetColumns` arrived. Found by ItemDB in the client
  on Classic Era (inbox `91e50ebd`). Releasing a pooled cell cleared its `OnClick` whenever the cell
  had a `SetScript` method. A text cell (a FontString) and an icon cell (a plain Frame) both have
  one, and neither has an `OnClick` script, so the client raised. The clear now runs only for the
  kinds built as buttons: checkbox, expander and button. The offline suite never saw it because the
  test harness accepts `SetScript("OnClick")` on a FontString; the new spec makes the text and icon
  cells raise the way the client does, and fails against the old guard. A same-set `SetColumns`
  returns before the release, which is why a consumer calling it on every repaint never hit it.
- **A tooltip left the GameTooltip owned by our frame after it hid.** Found by Questbook on
  adopting `DressBottomRow` (inbox `7271976e`): `BottomIcon_OnLeave` was `GameTooltip:Hide()` and
  nothing else, and `Hide` does not clear the owner `AnchorTooltip` set. The next addon to call
  `GameTooltip:Show()` without a `SetOwner` of its own drew its tooltip at our icon, at the bottom
  of our window, until something re-anchored it. Questbook's hand-rolled row had always handed the
  anchor back; the shared one did not. The same bare `Hide` was in seven more leave handlers --
  `AttachTooltip`, the menu rows, `CreateExplainedButton`, the ClearFrame info and settings icons,
  `TLabel`'s control, and RowList's row icons -- so the fix is one function, `W:HideTooltip()`,
  that hides and then calls `GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)` (present in the
  Classic Era tree at `SharedTooltipTemplates.lua:87`, feature-detected all the same), and all
  eight sites go through it. Questbook's workaround of re-setting `OnLeave` on our icons after each
  dress is no longer needed. `Tests/bottomrow_spec.lua` pins the hand-back and the no-raise path on
  a client without the function.

## [v0.2.3] -- a button that says why it is greyed, a list that reports it cannot draw, and a row of icons the fleet stops hand-rolling

### Compatibility -- MINOR 32 -> 33

Seven new methods -- `DressBottomRow`, `UndressBottomRow`, `CreateExplainedButton`,
`CreateFormDialog`, `RowList:SetColumns`, `Diagnostics` and `ClearDiagnostics`; feature-detect on
`type(W.DressBottomRow) == "function"` or `LibStub.minors["LibAceGUIWidgets-1.0"] >= 33`. Also
two per-column RowList fields, `onCellClick` and `strike`, and two new `CreateScrollFrame` options,
`anchor` and `inset` -- all four are opt-in fields on a table the caller passes, so gate on the
MINOR, since a field's absence is not detectable from outside. Four behaviours change for existing
calls: a `ShowDialog` prompt parented into a window no longer treats that window hiding as a close, a
button given a tooltip through `AttachTooltip` now receives its hover scripts while disabled, a
RowList that has rows but no room to draw them prints one line saying so, and a RowList header
underline takes the configured accent rather than a hardcoded gold (no change on the default accent,
which is that gold). Two column-set mistakes that were previously silent or cryptic are now named at
construction: a column with **no `key`** is an error (it already raised, less legibly, so nothing
working starts failing), and **two columns sharing a key** prints one warning and carries on. A
column set that was already correct is unaffected by either.
The three widget types stay at Version 30 and `LAGW-DatePicker` at 3. The TOC is unchanged.

### New

- **`W:Diagnostics()` and `W:ClearDiagnostics()` -- everything this library reported, in a form a
  consumer's spec can assert on.** From peer review of this MINOR's self-audit (thread `0eca0c8b`),
  against the duplicate-column-key report delivered earlier the same day. Their objection, which is
  right and applies to all three of this release's reports: **a printed line is a developer's
  diagnostic delivered to a player**, and the player cannot act on it, because every one of these
  faults is in the *consuming addon's* code rather than anything they configured. So a print alone
  is noise where it lands and invisible where it would help -- no consumer's offline suite can
  assert on a chat line.

  Each report now goes to both: one line for whoever is watching chat, one entry for the spec.
  `duplicateColumnKey` carries the key and both positions, `emptyRender` the row count and the
  parent's height, `accentClash` the two colours. A consumer builds their windows in a spec and
  asserts `#W:Diagnostics() == 0` -- which, on Dibs' side, would have caught the zero-height list
  that cost an afternoon and a release before anybody opened the game.

  **`ClearDiagnostics` does not re-arm the once-per-fault guards**, deliberately: clearing a log
  must not become a way to make the library shout, or a consumer calling it in `before_each` would
  get a fresh warning per example for one standing fault. A RowList with `onEmptyRender` records
  nothing, because a consumer who handles the state has dealt with it and recording it as unhandled
  would fail their own zero-assertion for doing the right thing.

  **It also folded three reports into one path.** The empty-render line, the duplicate key and the
  accent clash were each written separately during this release, each with its own `_warnedX` flag
  and its own copy of the `[LibAceGUIWidgets]` chat prefix -- the same duplication class the self-audit
  had just finished removing from the gold literal and the disabled-hover rule, forming while the
  audit was being written. Once-ness stays at the call site, because the three correct answers
  differ: once per session for the accent, once per key for a column, once per list for a render.

- **`W:DressBottomRow(widget, specs)` and `W:UndressBottomRow(widget)` -- the icon cluster left of
  AceGUI's Close button.** Requested by Questbook (inbox `54ae87da`, QBREQ-LAW-001). Four addons --
  TOGBankClassic, FastGuildInvite, TOGProfessionMaster and Questbook -- carry this row by hand with
  the same constants and the same three fixes, and the fault that raised the contract is exactly what
  a shared helper prevents: Questbook's third icon was placed with the right numbers and the wrong
  texture and rendered at about half the gear's size beside it.

  The numbers are now **derived and asserted** rather than copied. AceGUI's stock Frame puts its Close
  button at BOTTOMRIGHT (-27, 17) at 100x20 (`AceGUIContainer-Frame.lua:199-204`), so its left edge
  is 127 in from the right and the first icon's right edge at -133 is that less a 6px gap; the first
  icon is 24 square at y 15, every later one 20 square at y 17, 8 apart. `Tests/bottomrow_spec.lua`
  pins the gap against AceGUI's own constants, so the day AceGUI moves its Close button this says so.

  Per icon: `texture` (required -- a spec without one is skipped rather than built blank), `texCoord`
  (Blizzard's `Icons\` files carry a transparent margin, which is what made the reported icon look
  half-sized), `size`, `y`, `gap`, `alpha`, `tipTitle` / `tipBody`, `onClick(icon, mouseButton)` and
  `key`. The tooltip halves take a string, an array of lines, or a `function(icon)`, and are **read at
  hover**, so an icon whose text depends on state (Questbook's stop icon says "nothing to stop" while
  nothing is tracked) is right without re-dressing, and `icon._lagwTipBody = ...` re-labels by
  assignment. An array joins through the one `showTooltip` draw v0.2.2 consolidated, keeping a blank
  entry as the paragraph break the hand-rolled copies write.

  **Not scaled, deliberately**, and the comment says so where someone would "fix" it: everything else
  this library draws follows `SetScale`, but this row lines up with AceGUI's own Close button and
  status bar, which do not. **Idempotent**, which is required rather than tidy -- AceGUI pools frames
  for the session, so a second dress re-points the same buttons instead of stacking a set on top, and
  a shorter one hides the leftovers. `UndressBottomRow` hides every icon and puts the status bar back
  **where it actually was**, read at the first dress rather than assumed: AceGUI's stock number is
  -132 but a `ClearFrame` pins its bar to its own info icon, and restoring one to the other's number
  would move a bar nobody asked to move. Both halves of the undress matter on a pooled frame, which
  goes to another addon's window next -- icons left shown arrive there, where this addon's gear opens
  this addon's settings, and a status bar still pinned to a hidden icon of ours arrives short on the
  right anchored to a button that is not theirs.

  `liftAboveSizers` is now one function. AceGUI lays `sizer_s` / `sizer_se` along the bottom edge at
  parent level + 1, so a control on the bottom row keeps only a middle sliver of its hitbox;
  FastGuildInvite found it (`functions.lua:32-38`), three more addons re-derived it, and this file's
  ClearFrame block carried its own identical local. One copy, used by both.

- **A RowList column can own its own click: `onCellClick(entry, idx, rl, button, cellFrame)`.**
  Requested by Dibs (inbox `6ca7454a`, DIBSREQ-LAGW-005), the click half of the `onCellEnter` /
  `onCellLeave` pair MINOR 30 shipped for the same reason. A column that sets it gets the same
  mouse-enabled overlay a hover column gets -- a column asking for only the click still gets one --
  and it is called **before** the row's handler.

  **The return is the contract**, and it is why this is not a plain handler. Return `true` and the
  click is consumed: `onRowClick` does not also run. Return `false` or nothing and it falls through
  unchanged, with the same `(entry, idx, rl, button, rowFrame)` the row handler always receives. That
  is what lets one cell read as a hyperlink -- Dibs' Source column opens the quest in Questbook on a
  plain left click -- while every other click on that same cell still does what the row does, which in
  their Planner is slot the item. The entry is resolved at click time through the same `entryAt` the
  hover uses, never captured when the row was built, so a scroll cannot hand the handler the entry
  that frame used to be showing.

  What it removes on the consumer side is the point of it: Dibs' click lived in an overlay of their
  own, laid over the cell from `onRowEnter` and reading `rl.rows`, `rl.listOffset` and
  `rl:_getSortedData()` -- the three internals DIBSREQ-LAGW-004 named for the hover, read again for
  the click. Eight specs in `Tests/rowlist_spec.lua`, including the two that would have shipped a dead
  feature: that a column asking for *only* the click still builds an overlay, and that a list with no
  `onRowClick` at all still installs the script.

- **A RowList text column can strike its own text: `strike = function(entry) -> boolean`.** Requested
  by Dibs (inbox `466f7370`, DIBSREQ-LAGW-006) for a wishlist that keeps a won item in the list
  rather than removing it, so the player can see progress. WoW has no strikethrough font style and no
  FontString flag for one, so this is a 1px texture over the cell -- what every addon that strikes
  text draws.

  **It is sized to the rendered text, not to the column**, so the line stops where the words do, and
  it follows the FontString rather than the raw string, so an item link with its colour escapes
  measures as the player sees it. **Clamped to the cell**, which the request did not ask for and the
  screen requires: a string too long for its column is truncated on screen while `GetStringWidth`
  still reports the whole of it, so an unclamped line trails out across the next column. The colour
  is the cell's own text colour at 0.8 alpha -- the line belongs to the text, not to the theme, so a
  class-coloured or link-coloured cell is struck in its own colour -- and the 1px follows the UI
  scale like every other size this list draws, since a re-scale ends in `Refresh`.

  **It lives in `_renderRows`, and that is the whole reason it belongs in the library.** The rows are
  pooled: a scroll changes which entry a frame is showing and calls nobody, so a line drawn from
  outside stays on the frame while the entry it belonged to moves away, and an open item reads as
  won. A consumer cannot avoid that without reading `rl.rows`, `rl.listOffset` and
  `_getSortedData()` on every scroll -- the same internals-reading cost DIBSREQ-LAGW-004 and -005
  named for the hover and the click. Nine specs, one of which is exactly that scroll.

  A column that sets no `strike` builds no texture, and a list where no column asks builds no table.

- **`CreateScrollFrame` can place itself and its content: `opts.anchor` and `opts.inset`.** Requested
  by Dibs (inbox `8a1f713e`, DIBSREQ-LAGW-007). The function returned an **unanchored** scroll whose
  scroll child was `SetSize(1, 1)`, so every caller had to remember two separate, unrelated-looking
  things -- put `box.scroll` somewhere, and give `box.content` a width -- and a caller who did
  neither got rows laying themselves out inside a one-pixel frame that was nowhere. The window then
  draws **nothing**, which is the worst shape this bug can take: an empty window is indistinguishable
  from an empty list, and Dibs' officer Requests window sat like that for six weeks with the count
  beside it saying a request was pending. Twelve of their thirteen call sites got it right by hand;
  a second site records the same function tripping a different consumer earlier. Two independent
  failures on one return shape is a library problem, so the option removes the class rather than the
  instance.

  `anchor = <frame>` fills that frame with the scroll (TOPLEFT/BOTTOMRIGHT, `inset` on **all four**
  sides, default 0) and anchors the content's two **top** corners to the scroll -- the shape AceGUI's
  own ScrollFrame widget uses. Two corners, not four, deliberately: pinning the bottom as well would
  tie the content to the visible box and there would be nothing left to scroll, which would place the
  frame correctly and silently disable scrolling -- a worse bug than the one being fixed, because the
  window looks right. The height stays `SetContentHeight`'s, and a spec asserts the scroll range
  after it. The width comes from the anchor and never from a `GetWidth` read at build time, which
  would be whatever the frame measured before layout and would never be corrected, since
  `OnSizeChanged` fires only on a change. `anchor` need not be the parent.

  **This function had no specs at all before now**, which is part of how the shape survived. There
  are nine, and two of them pin the *old* behaviour -- an unanchored scroll and a 1x1 content -- so
  the thirteen call sites that place the box by hand are covered against this addition.

- **`W:CreateExplainedButton(parent, opts)` -- a button whose tooltip says why it is disabled.**
  Requested by Dibs (inbox `0df95b2b`, DIBSREQ-LAGW-008). Three fields on the returned button, read
  at **hover** and drawn in order: `_lagwTipTitle` (gold header), `_lagwTipBody` (white, wrapped) and
  `_lagwReason` (red, last) -- what pressing it would do, then why it cannot be pressed.

  **Read at hover, not captured at construction**, because the same button is Need/Greed/Pass on one
  roll and MS/OS/Pass on the next and Bid/Pass on an auction row: a consumer re-labels by assignment
  and never by re-attaching. A button with none of the three shows nothing; a **reason on its own**
  still draws, which is the case the whole factory exists for -- a greyed control with no other text
  is exactly when a player wants to know why.

  **It is not `AttachTooltip`, and could not be.** That one hooks `OnEnter`, and `HookScript` is
  additive: it runs *after* whatever the frame already had, so a button with its own handler gets its
  red reason line painted over by the plain title/body draw. This factory owns the handler, so the
  order is fixed. It also calls `SetMotionScriptsWhileDisabled(true)` -- without it a disabled Button
  receives no `OnEnter` at all, so the reason is dead in precisely the state it was written for, and
  the failure is silent: the field is set, the handler is installed, and the player sees nothing.

  The library's single tooltip draw was **extended, not forked**: `showTooltip` gained an optional
  `titleColor` and a `reason` line, so there is still one function that knows how this library paints
  a GameTooltip. That matters here more than usual, because the request came from two byte-identical
  copies of one hover handler in one addon, and from what their drift cost: for a while the second
  copy rendered only the reason, so an explanation written into the body field was never once visible
  to a player, while a spec asserting the *field* stayed green. Every spec here asserts the drawn
  tooltip instead.

  **Two departures from the request.** The suggested signature was `(parent, width, height)`; this
  takes `(parent, opts)` like every other factory in the library, with `width` / `height` in it.
  And the tooltip anchors through `AnchorTooltip` -- the library's one placement policy, which a
  consumer overrides globally with `config.tooltipOwner` -- rather than the requested fixed
  `ANCHOR_RIGHT`, since a second anchoring rule in one factory is the drift this delivery is about.

- **`W:CreateFormDialog(opts)` -- the small officer prompt, once.** Requested by Dibs (inbox
  `4a289891`, DIBSREQ-LAGW-009), who had two hand-rolled copies of it in one file: the same backdrop
  block, the same title placement, the same local `field()` / `row()` builder written twice, the same
  red wrapped error line, the same 22px buttons at BOTTOMRIGHT. Their own peer review named it as the
  two-copies class and asked for this instead of a third copy when the next officer form arrives.

  A movable, backdropped frame on `UIParent` at DIALOG strata: accent-coloured title, optional hint,
  labelled rows (label left, `EditBox` right, optionally the field plus its own button), a red error
  line, and OK/Cancel at the bottom right. Returns the frame with `.fields[i]`, `.buttons[i]`,
  `.err`, `.ok`, `.cancel`, `.title` and `.hint`. Built on `CreateFloatingFrame`, so the backdrop,
  the screen clamp and the Escape-list registration are the library's one implementation of those
  rather than a fourth copy.

  **Three behaviours are deliberate**, and each would look like a bug to someone tidying the file.
  **One frame per `name`**, handed back on every later call, because these are module-scope
  singletons on the consumer side and a second frame under one global name leaves the first orphaned
  on screen. **OK does not hide** -- that is what `.err` exists for: a caller validates in
  `onAccept`, and a refusal has to leave the dialog open with the reason under the fields, or the
  player loses everything they typed each time they get it wrong. Cancel always hides. **Enter is the
  caller's**: no `OnEnterPressed` is installed at all, because the consumer confirms through
  `ShowDialog` before writing and an Enter bound to accept would skip that confirmation. Escape in
  any field hides the dialog.

  **`numeric` and `digitsOnly` are separate on purpose**, and the request is the reason: a DKP
  adjustment is narrow *and* must accept a typed minus sign, which `SetNumeric(true)` refuses
  outright. So `numeric` sets the narrow width and `digitsOnly` sets `SetNumeric`; a field can have
  either without the other. Twenty-three specs, including the two that pin the behaviours above by
  asserting the dialog is still shown after OK and that no `OnEnterPressed` exists.

- **`RowList:SetColumns(columns)` -- a new column set on a live list.** Requested by Dibs (inbox
  `a21b2369`, DIBSREQ-LAGW-010). Their Raids tab carries one column per tracked raid, keyed by
  position against a sorted raid list, and that list changes under a drawn window -- a new raid key
  sorting ahead of an old one renumbers every column. With the columns fixed at construction the
  column headed "MC" went on showing Blackwing Lair's counts until the window was reopened: a wrong
  number with nothing odd-looking about it. Their correct remedy was a whole new RowList on a fresh
  host frame, which orphans 22 pooled rows, a header and a scrollbar on every change, because WoW
  cannot destroy a frame.

  The header and every row's cells are rebuilt against the new set, validated exactly as `New`
  validates (the auto-width check is now one function both call); the data, the scroll position, the
  scrollbar and the row **frames** are kept. Cells, overlays, strike lines and header buttons are
  **pooled per row by kind**, so a set that comes and goes builds its regions once for the session.
  A sort on a column the new set drops is cleared rather than left ordering the list by a field
  nothing on screen shows.

  **Two design points found by the specs, not by the first draft.** The no-op check compared only the
  layout fields, so a set that newly asked for a `strike` or a cell handler was judged identical and
  nothing was built for it; it now also compares, by *presence*, what each column causes to be built.
  And the no-op must still **adopt** the new table: a consumer calling this on every repaint hands
  over fresh closures each time, and discarding them would pin `format`, `strike` and the cell
  handlers to whatever the first call carried. So every cell script now resolves its column as
  `rl.columns[ci]` when it fires instead of closing over a column table -- the same rule this widget
  already applied to the entry -- and adopting the table is enough to make them current.

  This also moved every cell's construction into one `_buildRowCells`, which `_buildRow` and
  `SetColumns` share; the full suite stayed green across that refactor before any `SetColumns` spec
  existed. Nineteen specs, and the RowList file's coverage rose from 87.6% to 94.5% because the checkbox
  and icon cells are now exercised as a side effect of testing their reuse.

### Tests

- **The harness pin moves to `3165d77`, and two specs changed with it -- one of them because it was
  wrong.** Nothing ships from this: `Tests` is in the `.pkgmeta` ignore.

  The pin was taken for a contract this library raised and WoWAPITesting delivered:
  `GameTooltip:SetText` used to take the text alone and silently discard the colour arguments, so the
  GOLD of `CreateExplainedButton`'s tooltip title could not be asserted while the red reason line
  could. That was left as a written comment in the spec rather than covered by a weaker assertion;
  it is now a real test, and a second one pins that an ordinary `AttachTooltip` title stays **white**,
  so the shared draw cannot start colouring every caller's header by accident.

  **The spec that was wrong is the more useful half.** `breathe_spec.lua` proved "a region that
  cannot animate is refused" by handing `Breathe` a FontString and asserting nil -- which worked only
  because the old model gave FontStrings no `CreateAnimationGroup`. The client has always given them
  one. So that test was pinning a gap in the harness and reporting it as a property of this library,
  and the same call succeeds in game. It went red the moment the model became faithful, which is
  adoption doing its job. The refusal is now driven by things that genuinely have no animation group
  anywhere -- a bare table, a string, a number -- and a new test asserts that a FontString **does**
  breathe, which is what a player actually sees.

### Changed

- **The RowList header underline follows the configured accent instead of a hardcoded gold.** From
  the MINOR 33 self-audit's F1, which reported one gold `{1, 0.82, 0}` spelled in five places --
  and the audit was half wrong about it, which is the useful part. Reading the five sites showed
  **two concepts wearing one colour**, invisible because `W:GetAccent()` defaults to `ffFFD100`,
  which is that same gold to the eye:

  - What the library draws **as the library** -- the RowList's header underline and its selection
    tint. The tint already read `AccentRGB()`; the underline was a literal, so a consumer who set
    their own accent got a gold line under an orange-branded window. That is the fix, and it is the
    **only visible change in MINOR 33 for a consumer who adopts nothing**. On the default accent
    nothing changes, and no consumer has to touch code either way.
  - What the library draws **as the client** -- a `GameTooltip` header, a `BindCooldownButton`
    caption, the AceGUI DatePicker's label on re-enable. These must *not* follow the accent, and
    "folding the duplicate literals together" would have broken them. Verified against Ace3 on
    disk rather than assumed: AceGUI's own EditBox, Slider, MultiLineEditBox and DropDown all
    restore their labels with exactly `(1, .82, 0)`, so an accented DatePicker label would be the
    one control in a row of five not matching its neighbours. The two core-file sites now share a
    named `NORMAL_FONT_GOLD`; the DatePicker's literal stays, with the citation beside it.

  A fourth spelling went with it: the selection tint's `ar or 1, ag or 0.82, ab or 0` fallbacks were
  unreachable (`AccentRGB` always returns three numbers, and the line is only reached when the
  accent was read), so they were dead code *and* a copy of the gold.

- **`Configure` is documented as session-global, and a second addon setting a different accent now
  says so once.** Raised by Dibs as DIBSREQ-LAGW-012 (inbox `c9394cf5`), out of the MINOR 33
  consumer sweep -- they found it in their own code and filed it against themselves, which is the
  right instinct and worth recording.

  **The per-consumer accent they asked for is DECLINED**, and the reason is the library's purpose
  rather than the cost: this is the shared toolkit for one author's suite, so that the suite shares
  one look. Per-consumer accents would put Dibs in orange beside ClassicCalendar in gold inside
  windows meant to read as one product -- and the request came from a consumer whose own
  `Constants.lua:15` calls its accent "family brand orange", the *suite's* colour rather than that
  addon's. Sharing the accent is the feature.

  **What was genuinely wrong is narrower, and is fixed.** With one setter the shared table is
  correct; with two, the winner is whichever addon loaded last -- a property of the player's
  installation and of nobody's code. Two players with the same addons see different colours, nothing
  errors, and no author's choice is honoured. That is the silent-wrong-answer shape this library
  reports rather than tolerates, so `SetAccent` now prints one line naming both colours when a
  second, *different* accent arrives. Re-asserting the same accent is silent, because a consumer
  calling `Configure` on every window open (as Dibs does, from two files) is correct and must not be
  nagged. It reports and does not arbitrate: the last writer still wins, because picking for two
  consumers who never asked this library to choose would be the worse failure.

  `Configure` now routes `accent` through `SetAccent` rather than writing the table directly -- the
  check would otherwise be unreachable, since every consumer sets the accent through `Configure` and
  none calls `SetAccent`. A spec pins exactly that wiring, driven red against the direct write.

  Measured rather than assumed while answering this: **Dibs is the only consumer that calls
  `Configure` at all**, so the practical blast radius today is one setter, not several fighting.

- **A RowList that has rows and is showing none now says so, once.** Raised by Dibs (inbox
  `6f3a8405`) after it cost an evening. Their Planner gear list drew a completely blank panel in the
  author's own client -- no rows, no empty-state text, no Lua error -- and the measurement that
  finally ended it was **314 rows built, 0 shown, host 0 pixels tall**. Their list host was anchored
  top *and* bottom with no height of its own; the controls above it grew past the area's bottom, the
  anchor chain resolved to zero, and `_recomputeVisibleRows` divided a zero height by the row height
  and correctly hid every row.

  **Nothing in this widget was wrong, which is exactly why it has to be the one that speaks.** The
  consumer's own "no items match" hint could not fire, because the data was not empty. No error was
  raised, so BugGrabber had nothing. Three sessions and three offline suites -- theirs, mine, and a
  reproduction built from their literal column set -- all rendered correctly, because no suite builds
  a host whose anchors resolve to nothing. A list holding data and showing none is **always** a
  consumer bug, and this widget is the only party that can see both halves cheaply.

  So it prints one line, naming the row count and the parent's height, because *"314 rows, parent is
  0 pixels tall"* is the entire diagnosis in one sentence -- and it names the fix (give the frame a
  height, or anchor it by its top alone) rather than the symptom. **Once per list for the life of the
  instance**, not per populate, or a list parked behind an unopened tab would bury the message that
  matters. Same idiom as MINOR 32's `PersistWindow` / `DockWindow` refusal: a silent wrong state is
  worse than a noisy right one.

  `onEmptyRender(rl, dataCount)` on `New` lets a consumer draw their own message instead, and
  replaces the print for that list; unlike the print it fires on every populate, since a consumer
  rendering their own text needs to know each time. **The hook alone would not have helped here**,
  and that is worth saying: an opt-in is set by the consumers who already thought about this case and
  never by the one that silently broke. Seven specs.

- **A tooltip attached with `AttachTooltip` now keeps showing on a disabled button.** Requested by
  Dibs (inbox `22fb9fbe`, DIBSREQ-LAGW-011). A disabled Button receives no `OnEnter` / `OnLeave` at
  all unless `SetMotionScriptsWhileDisabled(true)` is set, so every tooltip attached through this
  library went silent the moment its consumer greyed the control -- which is precisely when the
  tooltip explaining *why* it is greyed is wanted. Dibs found it across ten of their own surfaces at
  once: settings rows under a master toggle, push buttons documented as "disabled with the reason in
  the tooltip", loot buttons, a bank Send, and more, all showing nothing on hover since they shipped.

  `AttachTooltip` now sets the flag on any frame that has the method (Button and its subtypes;
  feature-gated, so an EditBox or plain Frame is untouched and nothing raises), once per frame
  however often it is re-attached. `CreateDropdownBox` draws its own tooltip through `AttachTooltip`,
  so it gets the same flag by the same path. `CreateExplainedButton` sets the flag itself, at
  construction -- the one other call site, because that factory owns its `OnEnter` outright and must
  not go through `AttachTooltip`'s additive hook. Two sites, one rule, the same comment on each.

  **This is a behaviour change for every consumer**, which is why it is under Changed: the flag
  belongs to the *frame*, not to this library's hook, so any other `OnEnter` / `OnLeave` a consumer
  put on the same button now also runs while it is disabled. A highlight that assumed a disabled
  button could never be hovered will now light up. That is the client's own semantics for the flag,
  and the reason Blizzard sets it only on buttons that explain themselves.

  Pinned as "the call was made", on stub frames the spec builds and on a real dropdown box whose
  method is shadowed before the tooltip is attached. The rule itself -- no hover on a disabled button
  without the flag -- cannot be asserted offline yet: the harness models the method as a no-op and
  specs drive `OnEnter` directly. Dibs' harness contract `41375f5c` asks for it.

### Fixed

- **A column set is now validated for missing and duplicate keys, from `New` and `SetColumns`
  alike.** Both were found by this library's own self-audit of MINOR 33 (peer-review thread
  `0eca0c8b`, findings F6 and F5), filed there rather than fixed, and fixed here. Both rules run in
  the same place the existing at-most-one-auto-width rule does, and are pinned by specs driven red
  against the previous code.

  A column with **no `key`** raised Lua's bare `table index is nil` from inside `_buildRowCells`,
  two call paths from the table that caused it and with nothing in the traceback naming the column.
  It now names the position. This carries **no regression risk** and the reason is structural: the
  old code raised on exactly this input too, so no consumer can be shipping one.

  A **duplicate key raised nothing at all**, which is the worse fault and the more interesting fix.
  `cells[col.key] = fs` overwrites, so the earlier column's FontString stops being reachable from
  `row.cells`: never re-populated by `_renderRows`, never released into the pool, never hidden. A
  frozen cell drawing stale text on every row, for the life of the list, with no error anywhere.

  **It warns rather than raising, and that was a reversal made while checking the consumers.** The
  rule was written as an error, beside the width rule. Reading Dibs' `columnsFor` -- which builds a
  column per raid from the guild's own raid list -- made the severity obviously wrong: a column set
  is assembled at RUNTIME from a consumer's data, settings and guild state, so a duplicate can exist
  in one player's configuration and in nobody else's, including the author's. Raising there kills
  that player's whole tab over a fault whose real cost is one stale cell, and neither the library
  nor the consumer can enumerate the configurations in advance. So it prints one line per key per
  session -- the same "the party who can cheaply see the problem says so" idiom as the empty-render
  warning above -- and the list still builds. The width rule keeps raising, because a second
  auto-width column has no defined behaviour to fall back to and a duplicate key has one.

- **Three things this library had implemented twice, each now written once.** Also from the MINOR 33
  self-audit (F1, F3, F4). None of them changes what a consumer calls.

  **The disabled-hover rule** (`SetMotionScriptsWhileDisabled`) was spelled out in both
  `AttachTooltip` and `CreateExplainedButton`, joined by nothing but a comment -- so the next
  condition it acquired would have landed on one of them. Both now call one `allowHoverWhileDisabled`.

  **The RowList header probe** -- the hidden FontString that measures header text so a fixed column
  can be widened to fit its own header -- was built in `New` and again in `SetColumns`. Change its
  font in one and a list that *gained* its header at runtime measures in a different font from one
  born with a header, putting columns a few pixels out depending on which path built the list. Both
  now go through `_syncHeaderState`.

  **A cell's pool** was found through `row._cellPool[row._cellKinds[key]]`, a table kept beside
  `row.cells` and keyed by column key. Any cell reaching `row.cells` without its kind written in the
  same breath became `row._cellPool[nil]` and raised `attempt to index a nil value` out of
  `SetColumns` into the consumer -- and keying by column key made it worse than a plain invariant,
  since two columns sharing a key collapse to one kind entry while still being two cells. The kind
  now rides **on the cell**, where it cannot drift from it, and a cell the library did not build is
  dropped from the pool rather than raising. Driven red against the old shape before the fix.

- **A hidden parent no longer kills an open `ShowDialog` prompt.** Reported by Dibs (inbox
  `b0490b1b`, 2026-09-21, found reading this library while reparenting a confirm; filed
  client-unverified and confirmed here since). `OnHide` runs on a frame when its own flag clears
  **and** when any ancestor hides, because an ancestor's hide cascades to every descendant it makes
  invisible -- `IsShown()` stays true for the second, `IsVisible()` does not. `Dialog_OnHide` cleared
  the show's state on either, so a prompt parented into a window and carried off screen with it came
  back **dead**: Enter did nothing on the no-edit path (the `OnKeyDown` script had been nil'd),
  `CloseDialog(token)` returned false for a prompt visibly on screen (`_token` was nil), and -- the
  half that costs a consumer -- the consumer's `onHide` never ran on the real close, leaving a
  `PushModal` paired in `onShow` one push up.

  The guard is `d:IsShown()`, which tells the two hides apart exactly. The other half is the close
  that dispatches nothing: hiding a dialog whose parent is already hidden changes no effective
  visibility, so no `OnHide` fires at all and the hook had to be run explicitly -- every close in this
  file now goes through one `hideDialog`, and `Dialog_OnHide` remains the catch-all for the closes
  that do not (Escape through `UISpecialFrames`, or a consumer hiding the named global by hand).
  The invariant both halves serve, and what `Tests/dialog_spec.lua` pins: **`onHide` runs exactly once
  per `ShowDialog`, on the close, whatever the parent did in between.** Three specs; two are red with
  the guard removed and the third asserts the hook has *not* run at the moment the window hides, which
  is the assertion the old code passed for the wrong reason (checked).

Older releases (v0.2.2 and earlier) are in [`CHANGELOG_ARCHIVE.md`](CHANGELOG_ARCHIVE.md), moved there
whole and unedited to keep this file under the size GitHub accepts as a release body.
