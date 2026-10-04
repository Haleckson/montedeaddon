# LibAceGUIWidgets

A shared **AceGUI-3.0** widget and styling library — the common UI toolkit behind
the TOG suite of addons. It registers reusable, drop-in AceGUI widget types and
helpers so addons share one consistent look instead of each re-implementing the
same frames.

> **This is a library, not a standalone addon.** It has no window of its own —
> install it only because another addon lists it as a dependency (CurseForge
> does that automatically). Embeddable via LibStub. Its one setting is
> `/lagw debug [on|off|reset]`, which shows or hides its diagnostics for addon
> authors in chat (MINOR 39; see "Chat lines are debug-only" below).

## Developing this library: the AddOns folder is the working tree, and it is live

On the author's machine the WoW client loads this library from the same directory it is edited in, so
every save is in the game at the next login or `/reload` -- and seven addons on that install declare
it as a hard `## Dependencies`: ClassicCalendar, Dibs, GuildRoster, ItemDB, Questbook, TOGBankClassic
and VersionCheck-1.0. **"Not committed" is therefore not a safety margin.** It bounds the blast
radius for a CurseForge player and for a consumer's submodule pin; it bounds nothing for the person
sitting in the game, who is running the current contents of these files whether or not a release
exists.

Two things follow. A multi-step refactor passes through intermediate states that are valid Lua and
silently wrong -- a leftover block referencing a name that has moved scope raises nothing and simply
never runs -- so say up front that a reload will be needed rather than letting it be discovered. And
when a consumer reports a live symptom, establish **which snapshot their client holds** before
diagnosing the file on disk: the code in their process and the code in the editor are different
artefacts, and a blank panel with no error is exactly what a stale one looks like. Recorded after
Dibs raised it mid-session, 2026-09-22, while the author was looking at a blank list.

## What it provides

`local W = LibStub("LibAceGUIWidgets-1.0")`

- **Widget types** — `AceGUI:Create("ClearFrame" | "GroupFrame" | "TLabel")`:
  - `ClearFrame` — movable/resizable main window with a DialogBox title bar, saved
    size/position, and a bottom status bar: status text, Close button, info **"i"**
    tooltip, and an optional **settings gear**. Methods: `SetTitle(text)`, `SetStatusText(text)`,
    `SetInfoTooltip(text | function(GameTooltip))` (`nil` hides the "i"),
    `SetSettingsButton(handler, tipTitle, tipBody)` (a `nil` handler hides the gear and the status
    box takes the room back), `SetHeaderButton(text, onClick, tipTitle, tipBody)` (MINOR 40; see
    **Header button** below), `SetStatusTable(t)` / `ApplyStatus()` (width, height, top, left;
    700x500 centred by default). Fires `OnShow` and `OnClose`.
  - **Header button** (MINOR 40) -- `W:AttachHeaderButton(widget, text, onClick, tipTitle, tipBody)`
    puts a text button in the top-right corner of an AceGUI window: a stock `Frame` or a `ClearFrame`
    (which also has it as `win:SetHeaderButton(...)`, the same button). Inside the border, right-aligned
    14 in, its bottom level with the content's top (27 down), sized to its label (10 a side, at least
    40 wide) and lifted above the resize strips. On a `ClearFrame` it sits a further 4 in and 6 down
    (scaled): with the stock numbers it was seen straddling a ClearFrame's top border in game. `onClick(button, mouseButton)`; the tooltip is drawn
    from `tipTitle` / `tipBody`. Calling again re-labels the same button and replaces its handler;
    `text = nil` hides it. On a `ClearFrame` it follows the UI scale with the rest of the chrome; on a
    stock `Frame`, whose chrome does not scale, it stays at scale 1.0. Release hides it and drops its
    handler, tooltip and scale listener, so AceGUI's pooled frame never carries it into another addon's
    window; `W:DetachHeaderButton(widget)` does the same early. Returns the button (`nil` when hidden or
    when `widget` has no `frame`). Feature-detect with `if W.AttachHeaderButton then` /
    `if win.SetHeaderButton then`.

    ```lua
    local btn = W:AttachHeaderButton(classicWindow, "New UI", function() switchToNew() end,
        "New window", "Go back to the new Grouper window.")
    ```

  - `GroupFrame` — borderless movable/resizable container. Fires `OnShow` and `OnClose`.
  - `TLabel` — text + optional icon, with a multi-line tooltip: `SetText`, `SetColor(r, g, b)`
    (white by default), `SetImage(path[, texcoords])`, `SetImageSize(w, h)` (scale-1.0),
    `SetFontObject(font)` (through `ScaledFont`, so it follows the scale; default
    `GameFontHighlightSmall`), `SetFont(path, height, flags)` (taken literally, not scaled),
    `SetJustifyH` / `SetJustifyV`, `SetTooltip(text)` (lines split on `\n`).
  - `LAGW-DatePicker` (MINOR 28) -- a date picker: a label, a `YYYY-MM-DD` field with a small
    calendar glyph in it, and a button that opens a month calendar popup (prev/next, a day grid,
    **Today**, **Clear**). Value is `time()` of **local midnight** on the chosen day, or `nil` for
    "no limit". EditBox-shaped: `SetLabel`, `SetWidth`, `SetValue(ts|nil)`, `GetValue()`,
    `GetText()`, `SetDisabled`, and an `OnValueChanged(widget, event, ts|nil)` callback that fires on
    every **user** change and never on `SetValue`. `OpenCalendar()`, `CloseCalendar()` and
    `IsCalendarOpen()` drive the popup from code; `ClearFocus()` is a user leaving the field, so it
    commits what was typed. Typing a date works too (`YYYY-MM-DD`, `/` or `.` separators; a bad
    entry reverts, an emptied field commits `nil`). One shared popup per library, closed by Escape, a
    click elsewhere, the owning widget hiding, `OnRelease` or `SetDisabled`; `W:DatePickerPopup()`
    returns it, for a spec that wants the day grid.

    ```lua
    local since = AceGUI:Create("LAGW-DatePicker")
    since:SetLabel("Since")
    since:SetCallback("OnValueChanged", function(widget, event, ts) filter.since = ts; refresh() end)
    ```

    **Since MINOR 30 (widget Version 3)**, four per-widget settings, all reset when the widget returns
    to the pool:

    ```lua
    local when = AceGUI:Create("LAGW-DatePicker")
    when:SetRange(lastYearTs, nextYearTs)     -- outside days disabled, stepping stops, typing reverts
    when:SetTodayFunc(function()              -- whose "today": highlight, Today, default month/value
        local t = C_DateAndTime.GetCurrentCalendarTime()
        return t.year, t.month, t.monthDay
    end)
    when:SetRequired(true)                    -- never nil: no Clear, an empty field reverts
    when:SetFirstWeekday(2)                   -- 1 = Sunday (default) .. 7 = Saturday
    ```

    A range bound may be `nil` (open) and the two may come in either order. `SetValue` is **not**
    range-checked -- the range governs what the user can pick, and a stored date must still load --
    but a required picker handed `nil` takes today, pulled into the range. Gate on
    `AceGUI:GetWidgetVersion("LAGW-DatePicker") >= 3` or `if picker.SetRange then`.

    The pure arithmetic is public as `W.DatePicker` -- `parse(text)`, `format(ts)`, `midnight(y, m, d)`,
    `snap(ts)`, `daysInMonth(y, m)`, `grid(y, m[, firstWeekday])`, and since MINOR 30
    `inRange(ts, min, max)`, `clampMonth(y, m, min, max)`, `today(fn)` -- so a consumer with its own date
    parsing can drop it. Also `ymd(ts)` (the local `y, m, d`), `isLeap(y)`, `stepMonth(y, m, delta)`
    (wraps the year), `weekStart(n)` (1..7, anything else is Sunday) and `GLYPH`, the calendar icon's
    file path.
  - `LAGW-SearchBox` (MINOR 35) -- `W:CreateSearchBox` as an AceGUI widget, for a Flow or Table
    layout: the magnifier, the greyed placeholder and the clear-X. `SetText` is silent, as AceGUI's
    EditBox `SetText` is, so a tab that writes its saved query back on redraw cannot loop. The
    player's typing and the clear-X fire `OnTextChanged(widget, event, text)`. Also `GetText`,
    `SetPlaceholder(text)` (`nil` restores "Search"), `SetMaxLetters`, `SetDisabled`, `SetFocus` /
    `ClearFocus` / `HasFocus`, and the `OnEnter` / `OnLeave` / `OnEnterPressed(text)` callbacks.
    Released empty, 200 wide and 24 high (the height follows the scale). Gate on
    `AceGUI:GetWidgetVersion("LAGW-SearchBox")`.

    ```lua
    local box = AceGUI:Create("LAGW-SearchBox")
    box:SetPlaceholder("Quest or zone")
    box:SetCallback("OnTextChanged", function(widget, event, text) filter(text) end)
    strip:AddChild(box)
    ```

  - `LAGW-CopyField` (MINOR 38, widget Version 2) -- a read-only copy field inside a window: the copy
    glyph, select-all on focus and click, a typed key put back. `SetText`, `GetText`, `SetLabel`. See
    **A copy box** under the dialog helpers below.
  - `LAGW-ClickBinding` (MINOR 38) -- a modifier + mouse button captured by doing it
    ("Alt + Left Click"). See **Click bindings** below.
  - `LAGW-Stepper` (MINOR 36) -- `W:CreateStepper` as an AceGUI widget; see the stepper entry below.
  - `LAGW-Chip` (MINOR 40, widget Version 1) -- an on/off pill button sized to its label, for a filter
    strip. `SetText`, `SetValue` / `GetValue` (silent), `SetDisabled`, and `OnValueChanged(value)` on a
    click. On is the library accent, off is grey; disabled is dimmed but keeps its tooltip
    (`W:AttachWidgetTooltip` answers on it). `W:AddChips(container, order, labels, values, onChanged)`
    builds one per key in `order`, lit from `values[key]`; a click writes `values[key]` and then calls
    `onChanged(key, value, chip)`. Returns the chips keyed by key. Feature-detect with `if W.AddChips then`.

    ```lua
    local chips = W:AddChips(strip, { "dungeon", "raid" }, { dungeon = "Dungeon", raid = "Raid" },
        db.profile.filters.types, function(key, value) refresh() end)
    ```

  - `LAGW-TabStrip` (MINOR 40, widget Version 1) -- a row of tabs added at runtime that scrolls with
    `<` and `>` when the tabs outgrow it. The strip only; draw what a tab shows yourself, on
    `OnTabSelected(value)`, which fires for a player's click of another tab. `AddTab(value, text)`
    (re-labels a value already there), `SetTabText`, `RemoveTab`, `ClearTabs`, `SelectTab(value)`
    (silent; scrolls it into view), `GetSelected`, `GetTabs`, `SetMaxTabWidth(px)` (scale-1.0, default
    140; a longer label is cut short and shows in full on hover), `GetVisibleRange()`. The arrows show
    only on overflow, scroll one tab each and are disabled at their end. Feature-detect with
    `AceGUI:GetWidgetVersion("LAGW-TabStrip")`.

    ```lua
    local tabs = AceGUI:Create("LAGW-TabStrip")
    tabs:SetFullWidth(true)
    tabs:SetCallback("OnTabSelected", function(widget, event, itemID) showRolls(itemID) end)
    tabs:AddTab(itemID, itemName)
    tabs:SelectTab(itemID)
    ```

- **`LAGW-Strip`, the filter-strip layout** (MINOR 35) -- a row of captioned controls that lines up
  without hand-tuning. AceGUI's Flow cannot do it: a labelled EditBox puts its box 25px down a 44px
  frame, a labelled Dropdown 14px down a 40px one, and buttons, checkboxes and `LAGW-SearchBox` are
  24px with no label. So add controls **unlabelled** and give each its caption through `StripAdd`:

  ```lua
  local strip = W:NewStrip()                       -- a full-width SimpleGroup; optional start height
  window:AddChild(strip)
  W:StripAdd(strip, searchBox)                     -- no caption: the placeholder is its caption
  W:StripAdd(strip, zoneDropdown, "Zone")          -- returns the caption, a gold TLabel
  W:FitCheckBox(forMe)                             -- box + its words + 6px, not a guessed width
  W:StripAdd(strip, forMe)
  local floor = W:StripRowWidth(strip)             -- the widest row the last layout used
  ```

  Every caption sits on one line at the top of its row, left-aligned over its control and given its
  width, so a caption wider than its control wraps; keep them short. Every control is centred on one
  line under the captions, with `W.STRIP_GAP` (8) between each pair. A row that runs out of width
  wraps to the left edge, `STRIP_CAPTION + row + STRIP_ROW_GAP` lower. A row where no control has a
  caption reserves no caption line (MINOR 40): its controls start at the top of the row, and the row
  below it starts `row + STRIP_ROW_GAP` lower. A control whose frame is
  hidden takes no space and its caption hides too; call `strip:DoLayout()` after hiding or showing one.
  The gap, the row gap and the caption line (14) follow the UI scale. A row is at least `STRIP_ROW`
  (26, the unscaled AceGUI box) and grows to its tallest control. The group takes its height from the
  layout and re-lays itself on a scale change. Captions live in the group's `userdata`, which AceGUI
  empties on release. `W.StripLayout` is the layout function, registered as `W.STRIP_LAYOUT`. Gate on
  `if W.NewStrip then`.

- **`W.RowList:New(parent, opts)`** — virtual-scrolling data list: **value-aware sortable
  headers** (numeric columns sort by number, not lexically; `col.format` renders a raw value
  while it still sorts numerically, and `col.nilsLast` sinks blank/absent cells to the bottom
  in both directions), **icon columns** (`col.icon = function(entry) -> texturePath, desaturated`
  draws a per-row texture in the cell instead of text — a wishlist coin gold-when-on / grey-when-off,
  a won/standby/priority marker — while the column still sorts on `entry[col.key]`; `col.iconSize`
  sets the glyph size), alternating
  row banding, class-coloured columns, **stateful right-edge action icons** (the action `texture` may be a `function(entry)` returning `(texture,
  desaturated)`, so an icon reflects per-row state — e.g. a toggle coin; **`action.show =
  function(entry) -> boolean`** hides the icon on rows the action doesn't apply to; `onClick(entry, idx,
  rl, btn)` hands you the clicked button to anchor a menu to), a slim scrollbar, per-column
  header tooltips, and row-hover callbacks (`onRowEnter` / `onRowLeave`, symmetric with
  `onRowClick`).
  - **The basics.** `opts.rowCount` is the initial row pool (it grows to fill the parent) and
    `opts.rowHeight` the row height (16, scale-1.0). Per column: `key`, `width` (scale-1.0; at most
    one column omits it and fills the rest), `header` (a header bar appears when any column has one),
    `headerTip` (the header's tooltip body, titled with the header), `sortable = false` (an inert
    header), `font` (a global font name for the cell; `GameFontHighlightSmall` by default),
    `color = "class"` (colours the cell by `entry.classFile` through `W:ClassColor`) and
    `classDisplay = true` (shows `lib.config.classDisplay(entry.classFile)` in the cell). A
    `checkbox = true` column draws a tick box per row, `boxSize` square (16); with `col.onToggle(entry,
    value, idx, rl)` a click writes `entry[key]` and calls it, and without one the box is display-only.
    `rl:SetData(data[, preserveScroll])` scrolls back to the top unless `preserveScroll` is set, which
    keeps the offset, clamped. `rl:ClampOffset()` rebuilds the view and clamps the scroll after the
    array shrank.
  - **MINOR 34 additions.** `opts.externalSort` + `opts.onSortChanged(key, desc, rl)` (you order the
    data; the header still sets the key, the arrow and the callback). An **`expander`** column (a
    +/- tree toggle on `entry[key]`: `true` open, `false` closed, `nil` hidden; `col.onToggle(entry,
    newValue, idx, rl)`). A **`button`** column (a clickable text cell: `col.onClick(entry, idx, rl,
    mouseButton, cellFrame)`, `col.cellTip(entry)`). **`entry._readonly`** disables that row's
    checkbox and button cells. A **`filterable`** column's header opens a menu with the sort and a
    checkbox per distinct shown value, cascading across columns, with a search box
    (`col.filterGroup(entry)` nests them; `opts.headerMenu` puts the menu on every header). The menu
    draws only as many values as fit on screen, with an "N more (not shown)" line, and its
    **Select all** / **Clear all** rows act on EVERY value the menu stands for, drawn or not (each
    group submenu carries its own pair).
    **`rl:SetSearch(text)`** and **`rl:ClearFilters()`**. **`col.autoFit`** (+ `col.minWidth`)
    sizes a column to its widest cell. **`opts.hyperlinks`** makes `|H` links in cells hover and
    click. `opts.refontHook` / `opts.classDisplay` / `opts.tooltipOwner` override the session-global
    hooks for one list. **`rl:Detach()`** from your host widget's `OnRelease` takes the list off a
    pooled AceGUI frame for good. `col.align` right-aligns a text cell (opt-in; `justify` still
    applies to button cells only), `col.gapBefore` adds space to a column's left, and
    `col.sortDescDefault` makes a column's first click sort high-to-low.
  - **MINOR 36:** **`opts.hoverHighlight`** lights the row under the pointer: `true` for the stock
    quest-log title highlight, a texture path, or `{ r, g, b, a }`. It draws over the banding and
    under the selection tint, stays lit while the pointer crosses the row's cell overlays, button
    cells, checkboxes, expanders and action icons, and is re-decided on every populate so a scroll
    never leaves it on the wrong entry. The row takes the mouse to do this, which is why it is opt-in:
    with it on, a click on a row's blank space is caught by the row and no longer reaches whatever is
    under the list.
  - **MINOR 36:** **`opts.sortCycle = "three"`** makes a header cycle asc -> desc -> none, and the
    third click hands back the model's own order with no arrow (`col.sortNone = true` does it for one
    column). A `sortDescDefault` column cycles desc -> asc -> none. The clear leaves the same state as
    `rl:SetSort(nil)` and reports `onSortChanged(nil, nil, rl)`. Lists default to two-state.
  - **MINOR 36:** **`col.format(value, entry, width, measure)`** -- when the text is being drawn,
    `width` is the cell's pixel width at the current scale (the auto column's too) and
    `measure(text)` is its rendered width in the cell's font, so a formatter can fit "Ann, Bob +3"
    to the space. It re-runs on a parent resize. Filter labels, the search and `autoFit` pass neither,
    so they see the full text. **`rl:CellWidth(key)`** answers any column's current width, the auto
    one included; `ColumnWidth` still answers nil for the auto column.
  - **MINOR 36:** **`opts.searchText = function(entry) return text end`** lets `rl:SetSearch` also
    match text the row does not show (a tooltip, crafter names). With it, or with
    **`opts.searchTokens = true`**, the search uses `W:SearchMatch`'s rule: every word of the query
    somewhere, any order, any case. `searchText` runs once per entry until the next `SetData` or
    `Refresh`, not once per keystroke. Without either, the search is the plain substring it was.
  - **MINOR 36:** **`rl:GetScrollOffset()`** / **`rl:SetScrollOffset(n)`** read and set the scroll in
    rows (clamped, one repaint; call it after `SetData`), so a list can reopen where the player left
    it. **`opts.onScroll(rl, offset)`** hears every change of offset, from any cause, once per repaint
    that moved it. **`rl:ScrollToEntry(target, { ifNeeded = true, context = 2 })`** leaves an entry
    already on screen where it is, and brings one from off-page in with `context` rows beyond it.
  - **MINOR 37:** **`rl:CellFrameFor(target, columnKey)`** is the frame on screen showing that
    entry's cell (an entry, a predicate, or an index in the drawn order): the mouse overlay on an
    `onCellEnter` / `onCellLeave` / `onCellClick` column, else the cell. nil when the entry is not in
    the view or is scrolled off, the column is unknown, the row is a heading, the cell is hidden, or
    the list is detached. Read-only; rows are pooled, so hold the frame only until the next scroll.
    Use it to anchor a popup to a cell, or in a spec instead of reading `rl.rows`.
  - **MINOR 36:** **group header rows.** An entry whose `_header` is truthy (or for which
    `opts.isHeader(entry)` is) draws as one heading across the row in the accent colour, with no
    cells, no action icons and an accent strip instead of banding. A string is the heading; `true`
    uses the indent column's text. `_expanded = true/false` adds a minus/plus in front, and a click
    reaches `onRowClick` so you can toggle the group and call `SetData`. A header sort sorts rows
    under their heading and never moves a heading (flat groups; use `externalSort` for nested ones).
    Filters ignore headings, and a filtered or searched list keeps a heading only while a row of its
    group survives or the search matches the heading itself. **`entry._indent`** is a level, each
    `opts.indentStep` (default 12, scale-1.0) wide, moving the text of `opts.indentKey`'s column (default:
    the first text column) right inside the same column edge. `opts.headerFont` names the heading's
    font object (default `GameFontNormal`), scaled like every other font here.
  - **MINOR 36:** on a **`button`** column, **`col.show(entry)`** hides the button on rows it does not
    apply to (no mouse, blank cell), **`col.text(entry)`** is its label per row, and
    **`col.tip(entry, button)`** returns `title, body[, reason]` read at hover time. All three are
    re-read on every populate, so `rl:Refresh()` picks up late data.
  - **MINOR 36:** **`col.iconTexCoord = { l, r, t, b }`** (or `true` for the usual 0.07-0.93 icon crop)
    on an icon column. **`opts.fitContent = { maxRows = n }`** sets the PARENT's height to the header
    plus its rows, up to `maxRows`, then scrolls; `opts.onHeightChanged(rl, h)` hears each new height.
    Anchor that parent by its top only, or the height it is given has no effect.
  - **MINOR 36:** **`opts.reorderable = true`** with **`opts.onReorder(fromIndex, toIndex, entry, rl)`**
    lets the player drag rows. The lifted row follows the pointer, an accent line marks the drop slot,
    the list scrolls when held at its top or bottom row, and Escape (out of combat) or a drop off the
    list cancels. Move the item in your model and call `SetData`. A drag does not start while a header
    sort, a filter or a search is active; an `externalSort` list can be dragged.

- **`onRowClick(entry, idx, rl, button, rowFrame)`** (MINOR 27) -- the click handler now receives the
  mouse button (`"LeftButton"`, `"RightButton"`, ...) and the row frame, so a right-click menu can be
  anchored to the row without calling `GetMouseButtonClicked()` or stashing the frame from
  `onRowEnter`. Additive; a handler that takes only `entry` is unchanged.

  ```lua
  onRowClick = function(entry, idx, rl, button, rowFrame)
      if button == "RightButton" then
          W:OpenMenu(rowFrame, { { text = "Whisper", onClick = function() whisper(entry.name) end } })
      end
  end
  ```

  Feature-gate on `>= 27` if your addon can run against an older embedded copy -- before that,
  `button` and `rowFrame` are `nil` and a right-click branch silently never fires.

  ```lua
  actions = {
      { texture = "Interface\\Icons\\INV_Misc_Coin_02",
        tooltip = "Request from the guild bank",
        -- Optional (MINOR 23). Omit it and the icon always shows, as before.
        show    = function(entry) return Bank.CanRequest(entry.id) end,
        onClick = function(entry, idx, rl, btn) ... end },
  }
  ```

  Reach for `show` when an action is meaningful on only a *few* rows. Greying it via the
  `texture` function leaves an icon on **every** row, which reads as noise when the action is
  irrelevant to most of them — unlike a wishlist coin, where gold/grey means something on each
  row. Returning a `nil` texture is worse than it looks: the button keeps its highlight and its
  `OnClick`, so the row carries an invisible-but-clickable hitbox. `show` is re-evaluated on each
  populate, so if your gating data arrives late (a sibling addon still initialising its tables)
  you only have to call `rl:Refresh()`.

  **Feature-gate it** if your addon can run against an older embedded copy — a pre-23 library
  ignores `show` and renders the icon on every row:

  ```lua
  if (LibStub.minors["LibAceGUIWidgets-1.0"] or 0) >= 23 then
      table.insert(actions, myConditionalAction())
  end
  ```

- **`rl:SetSort(key[, desc])`** (MINOR 25) -- set the active sort **without a header click**. Call it
  before `SetData` and the first render is already sorted; pass a nil key to clear it and get the
  model's own order back. It writes the same fields the header handler does, so a later click on that
  column toggles direction rather than resetting.

  Before this there was no way to open a list in a useful order: `_getSortedData` returns your array
  verbatim until something sets a sort key, and the only thing that ever did was the user clicking a
  header. **If you have a tab that "should be sorted by date", it was not.**

  ```lua
  rl:SetSort("when", true)     -- newest first, before the first draw
  rl:SetData(entries)
  ```

  **A column can own its own hover (MINOR 30).** `onCellEnter(entry, idx, rl, cellFrame)` and
  `onCellLeave` give one column a tooltip of its own -- the row already has one. A text cell is a
  FontString and cannot take the mouse, so a column that asks gets a mouse-enabled overlay laid exactly
  over its cell (a column that does not ask builds none); `cellFrame` is that overlay, ready to own a
  tooltip. The entry is resolved when the pointer arrives, so a pooled row never hands over a stale one.
  In the client the overlay takes the mouse from the row, so `onRowLeave` fires as the pointer enters
  the cell and `onRowEnter` again as it leaves -- **not verified in a client**. A click on the overlay
  is forwarded to `onRowClick` with the **row** frame, so a right-click menu still works over that column.

  **And a column can own its own click (MINOR 33).**
  `onCellClick(entry, idx, rl, button, cellFrame) -> consumed` is the other half of that pair. A column
  asking for only the click still gets the overlay, and the cell handler is called **first**. Return
  `true` and the click is **consumed** -- `onRowClick` does not also run. Return `false` or nothing and
  it falls through to `onRowClick` unchanged, with the same `(entry, idx, rl, button, rowFrame)` the row
  handler always gets. That return is what lets one cell read as a hyperlink -- a plain left click opens
  its target -- while every other click on the same cell still does whatever the row does. The entry is
  resolved at click time, so a scroll cannot hand the handler a stale one. Gate on
  `LibStub.minors["LibAceGUIWidgets-1.0"] >= 33`.

  **A text column can strike its own text (MINOR 33).** `strike = function(entry) -> boolean` draws a
  hairline through that cell for the entries it answers true for -- a won, done or expired row that
  stays in the list so the player can see progress, instead of disappearing from it. WoW has no
  strikethrough font style and no FontString flag for one, so this is a texture: sized to the
  **rendered** text rather than the column, so it stops where the words do and an item link measures
  as the player sees it, and clamped to the cell so a string too long for its column cannot trail a
  line out over the next one. It takes the cell's own text colour at 0.8 alpha and follows the UI
  scale. It is resolved on every populate, which is the point of it being here: rows are pooled, a
  scroll changes which entry a frame shows without calling you, and a line drawn from outside would
  stay on the frame while the entry it belonged to moved. A column that does not ask builds no
  texture. Gate on `LibStub.minors["LibAceGUIWidgets-1.0"] >= 33`.

  **The column set can change on a live list (MINOR 33).** `rl:SetColumns(columns)` takes the same
  shape `New` does, validates it the same way, and rebuilds the header and every row's cells against
  it -- keeping the data, the scroll position and the row frames. For a column set that is
  **data-driven** (one column per raid, per season, per category), which otherwise means building a
  whole new list and orphaning the old one's frames, because WoW cannot destroy a frame. Cells and
  header buttons are pooled per row, so a set that comes and goes -- a tick box that adds two
  columns -- builds them once. It returns whether anything was rebuilt, and a set that differs only
  in its closures (`format`, `strike`, the cell handlers) is **adopted without a rebuild**, so it is
  safe to call on every repaint with a freshly assembled table. A sort on a column the new set drops
  is cleared. Gate on `type(rl.SetColumns) == "function"`.

  **A list with rows and no room to draw them tells you (MINOR 33).** The visible row count comes from
  the parent's height, so a list built in a pane whose height resolves to zero hides every row --
  correctly, silently, and with your own empty-state message not firing because the data is not
  empty. That shipped in a consumer and drew a blank panel for an unknown length of time. The list now
  records it in `W:Diagnostics()` and, **with `Configure{ debug = ... }` on (MINOR 39)**, prints one
  line the first time a populate has data but no visible rows, naming the row count and the
  parent's height: *"314 row(s) but is showing none: its parent frame is 0 pixel(s) tall"*. Once per
  list, not per populate. Pass `onEmptyRender = function(rl, dataCount)` to `New` to handle it
  yourself instead -- that replaces the print for that list and fires on every populate.

  **If you see that line, the fix is on your side**: give the frame a height, or anchor it by its TOP
  alone rather than top-and-bottom. A frame anchored on both edges has no say in its own height, so
  `SetHeight` will not save it.

  **Since MINOR 30 the sort is *stable* and can take a tiebreak.** Rows whose sort cells tie keep the
  order you gave `SetData` (before 30, `table.sort` left them anywhere). If the same data can arrive in
  a different order on different clients -- replicated, network-merged -- pass
  `tiebreak = function(a, b) return a.id < b.id end` to `New`: it decides ties before input order and is
  **not** flipped by the sort arrow. A column's `sortValue = function(entry) return key end` sorts the
  header on that key while the cell still shows `entry[key]` (an `MM/DD/YYYY` string sorting by a
  `YYYYMMDD` number); it runs once per entry per sort, not per comparison. Gate on
  `LibStub.minors["LibAceGUIWidgets-1.0"] >= 30`.

  **Jump to a row, and mark one (MINOR 31).** `rl:ScrollToEntry(entry)` -- or a
  `function(entry) -> bool` -- scrolls so that entry is the top visible row and returns whether it was
  found; nothing scrolls on a miss. It works in the order the rows are drawn (the active sort), and
  "top" holds only where the clamp allows: the list never scrolls past its own end, so an entry on the
  last page comes into view lower down, exactly where the scrollbar would leave it -- write your spec
  for that. `rl:SetSelected(entry | predicate | nil)` puts a persistent accent-tinted highlight on one
  row and returns the entry it selected; `rl:GetSelected()` reads it back. The highlight rides the
  **entry**, not the row frame: it follows through pooling, scroll and a re-sort, hides while off-page,
  and `SetData` drops it unless the same entry (identity) is still present -- an equal-looking row in a
  rebuilt model is a stranger. A target the list does not hold selects nothing and clears the old one.

  ```lua
  if rl.ScrollToEntry then
      rl:ScrollToEntry(function(q) return q.id == questId end)
      rl:SetSelected(function(q) return q.id == questId end)
  end
  ```

- **Menus & scrolling** — `W:OpenMenu` / `W:ToggleMenu` / `W:CloseMenu`: an anchored
  dropdown of check-marked rows with **cascading submenus** (`children`), **multi-select**
  (`opts.keepOpen`, live-updating checkmarks), and a placement override (`opts.point`);
  closes on click-outside, drawn above the window. Plus `W:CreateScrollFrame(parent, opts)`
  (a slim-scrollbar box for overflow: `{ scroll, content, scrollbar, SetContentHeight }`;
  `opts.barWidth`, default 10).

  An item is `{ text, checked = bool | function, onClick, children = list | function }`; a
  `children` function is called each time the submenu opens. `opts`: `width` (scale-1.0; default
  the anchor's width), `keepOpen`, `point`, and `search = true` with `itemsFor(query) -> items`,
  which puts a filter box at the top of the root menu and calls `itemsFor` on every keystroke --
  you own the matching rule. Pass the rows for the empty query as `items`. `W:ToggleMenu` opens, or
  closes the menu if it is already open for that anchor. `OpenMenu` returns the root menu frame.

  **Since MINOR 30, per item:** `isTitle = true` (a gold header: no click, no check, no hover),
  `disabled = true` (grey and inert; with empty `text` it is a spacer), `tooltipTitle` / `tooltipText`
  (shown on hover, disabled rows included), and `keepOpen = true|false`, which overrides the menu's
  `opts.keepOpen` for that row -- a keepOpen menu of toggles can still have one action that closes it.

  ```lua
  W:OpenMenu(anchor, {
      { text = "Ranks", isTitle = true },
      { text = "Officer", checked = function() return ranks.officer end,
        onClick = function() ranks.officer = not ranks.officer end },
      { text = "", disabled = true },
      { text = "Re-process Signups", keepOpen = false, onClick = reprocess,
        tooltipTitle = "Re-process", tooltipText = "Applies the rank filter again." },
  }, { keepOpen = true })
  ```

  **Close only what is yours (MINOR 31).** The menu stack is **one stack for every addon in the
  session**, so `W:CloseMenu()` closes whatever is open, whoever opened it. Opening yours already closed
  theirs, so that looks harmless -- until a menu is opened *after* yours went away and your own close
  path (Escape in a search field, say) fires. `W:CloseMenuFor(anchor, ...)` closes the open menu only if
  one of the anchors you name owns it, and returns whether it did. Same shape as `CloseDialog(token)`,
  for the same reason. Feature-detect with `if W.CloseMenuFor then`; below 31 there is no ownership
  check to be had short of reading a private field, so fall back to `CloseMenu()` and accept the
  collision.

  **A pick whose `onClick` raises still closes the menu (MINOR 39).** The handler runs under
  `xpcall`; a non-`keepOpen` row then closes the stack (so `OnMenuClosed` fires) and a `keepOpen` row
  refreshes its check, and only then is the error, with its stack, handed to the client's error
  handler. Before 39 the error left the click before the close, so the menu stayed up and every
  `OnMenuClosed` callback waited. A consumer wrapping its own handlers in `pcall` for this can drop
  the wrapper on 39 and up.

  **Pass `opts.anchor` and the box places itself (MINOR 33).** Without it the returned scroll is
  unanchored and the content is 1x1, so a caller has to remember two separate things -- place
  `box.scroll`, and give `box.content` a width -- and a caller who forgets gets a window that draws
  **nothing** while the rest of the UI says there is something in it. `anchor = <frame>` fills that
  frame with the scroll (`opts.inset`, default 0, on all four sides) and anchors the content's two
  top corners to the scroll, which is how AceGUI's own ScrollFrame gives a scroll child its width.
  The height stays `SetContentHeight`'s, so the box still scrolls. `anchor` need not be the parent.
  Omit it and nothing changes. Gate on `LibStub.minors["LibAceGUIWidgets-1.0"] >= 33`.

- **`W:CreateExplainedButton(parent, opts)` (MINOR 33)** -- a `UIPanelButtonTemplate` button whose
  tooltip says what it does and, when it is greyed, **why it cannot be pressed**. Three fields, read
  at **hover** and drawn in this order: `btn._lagwTipTitle` (gold header), `btn._lagwTipBody` (white,
  wrapped), `btn._lagwReason` (red, last). Read at hover rather than captured, because the same
  button is Need/Greed/Pass on one prompt and MS/OS/Pass on the next -- re-label by assignment, never
  by re-attaching. A reason on its own still draws, which is the case the factory exists for. It is
  **not** `AttachTooltip`: that hooks `OnEnter` additively and would paint over the reason line.
  `opts`: `width` / `height` (scale-1.0, default 80x22), `text`, `onClick`, and initial `tipTitle` /
  `tipBody` / `reason`. It also calls `SetMotionScriptsWhileDisabled(true)`, without which a disabled
  Button receives no `OnEnter` at all and the reason is dead in exactly the state it exists for.

- **`W:NewDockLayout(container, { top, right, bottom = n | "auto", minCenter })` (MINOR 36)** -- a
  toolbar strip on top, a side panel on the right, a detail panel across the bottom, and `dock.center`
  (also `dock.left`) taking what is left. Four raw frames anchored into an AceGUI container's `content`
  (or a raw frame), so they follow a live resize by their anchors; no widget method is replaced. Sizes
  are scale-1.0 except an `"auto"` bottom, which is the pixel height you pass to
  `dock:SetBottomHeight(px)`. The centre always keeps a real size: top, bottom and right give way
  first, and `minCenter` floors its width. `dock:SetPaneShown(name, bool)` hides a pane and gives its
  space to the centre. `dock:Relayout()` re-applies the sizes (after a scale change, say), and
  `dock.sizes` holds the last pixel sizes it laid out: `top`, `bottom`, `right`, `centerW`, `centerH`.
  It is released with an AceGUI container, or by `dock:Release()`. **Put content
  in the panes only:** AceGUI children added to the same container are laid out by the container over
  the panes, not around them.

- **`W:CreateSecureActionButton(parent, opts)` (MINOR 36)** -- a `SecureActionButtonTemplate` +
  `UIPanelButtonTemplate` button for casting or using something from your own UI. `button:SetAction({
  type = "macro", macrotext = "/cast ..." })` applies secure attributes now, or queues them in combat;
  the button's own anchor, size, visibility, enable and `SetParent` calls (every spelling: `SetPoint`,
  `SetAllPoints`, `SetWidth`, `Enable`, `SetShown`, ...) are guarded the same way, and the queue runs once, in order, on `PLAYER_REGEN_ENABLED`. It clicks on
  key down and key up both, because the client's secure handler acts on exactly one of them.
  `opts`: `name`, `text`, `width` / `height`, `action`, `preClick` / `postClick`, and the explained-button
  tooltip (`tipTitle`, `tipBody`, `reason`). It returns nil in combat. **Never parent it into a pooled
  AceGUI frame**: a frame holding a secure button becomes protected too, and so cannot be hidden in
  combat -- for you, and for the next addon handed that frame.

- **`W:CreateStepper(parent, opts)` and the `LAGW-Stepper` widget type (MINOR 36)** -- `[-] [qty] [+]
  [MAX]`. `opts`: `min` (0), `max` (a number, a function read on every click, or nil for none), `step`
  (1), `value`, `width` (the box, scale-1.0), `maxButton`, `onValueChanged(value, stepper)`, `tipTitle`,
  `maxTip`, `maxReason`. Typing keeps digits only (and one decimal point when `step` is fractional)
  and commits on Enter or focus loss, snapped to the nearest step counted from `min` and clamped; an
  emptied box and Escape revert. `Refresh()` and `SetBounds` leave the box alone while the player is
  typing in it. `-`, `+` and `MAX` are explained buttons that grey at the bounds (MAX
  when `max()` is 0) and say why. `SetValue` is silent; a player's change is reported once.
  `GetValue()`, `SetBounds(min, max)`, `SetStep(n)`, `SetDisabled(bool)`, `Refresh()` (re-reads `max`).
  The parts are `st.minus`, `st.edit`, `st.plus` and (with `maxButton`) `st.maxButton`. Holding a
  button does not repeat. The widget type fires `OnValueChanged(value)`, has `GetValue()`, adds
  `SetMaxButton(bool)`, and is reset on acquire.

- **`W:CreateFormDialog(opts)` (MINOR 33)** -- the small officer prompt: a movable, backdropped frame
  on `UIParent` at DIALOG strata with an accent-coloured title, an optional hint, labelled rows
  (label left, `EditBox` right, optionally the field plus its own button), a red error line and
  OK/Cancel at the bottom right. Returns the frame with `.fields[i]`, `.buttons[i]` (both by row),
  `.err`, `.ok`, `.cancel`, `.title`, `.hint`. `opts`: `name` (a global name, which also puts it on
  the Escape list), `title`, `hint`, `rows`, `okText`, `cancelText` (`false` collapses the pair to a
  lone Close), `onAccept(frame)`, `width` / `height`. Per row: `label`, `width`, `numeric` (a narrow
  field), `digitsOnly` (`SetNumeric(true)` -- separate, because a field that takes a typed minus sign
  must be narrow *without* it), `button` (a table, or a bare string for its text) and `tipTitle` /
  `tipBody` for that button.

  Three behaviours are deliberate and worth knowing before you build on it. **One frame per `name`**,
  handed back on every later call, since these are module-scope singletons. **OK does not hide** --
  that is what `.err` is for: a refused submission keeps what the player typed, with the reason under
  it. And **Enter is yours**: no `OnEnterPressed` is installed, so a consumer that confirms through
  `ShowDialog` before writing cannot have that skipped. Escape in any field hides the dialog. Also
  `opts.strata` (default `"DIALOG"`) and `opts.level` (100), `opts.closeText` for the lone button
  when `cancelText = false`, and per row-button `width` and `onClick(frame)`.

  **MINOR 36:** a row with `kind = "dropdown"` puts a `CreateDropdownBox` where the edit box goes:
  `items(query)` returns `{ { text, value }, ... }`, `onChanged(value, frame)` hears a real change, and
  `fields[i]:GetValue()` / `SetValue(value[, text])` read and set it (`value` / `valueText` / `search`
  on the row too, and `menuWidth` for the menu). A row with `kind = "item"` shows an item's icon and link (`link`, `icon`): hover
  draws the item's tooltip, a click goes to `HandleModifiedItemClick`, and `fields[i]:SetItem(link[,
  icon])` / `GetValue()` change and read it. Give the row `onEnter(button, link)`, `onLeave(button)`
  or `onClick(button, link, mouseButton)` to replace the built-in hover, leave or click with your own
  (MINOR 39; read at event time, never called for an empty row). `frame:SetHint(text or nil)` adds, changes or removes the
  hint after build and re-flows the rows and the height. `opts.anchorTo` (with `point`, `relPoint`,
  `x`, `y`; default beside, to the right) or `frame:SetAnchor(owner, ...)` places the dialog by its
  owner every time it is shown.

  **MINOR 37:** a row with `kind = "check"` puts a checkbox where the edit box goes, with the row's
  label to its right: `fields[i]:GetValue()` is a boolean, `SetValue(bool)` is silent, `value` sets the
  start, `onChanged(value, frame)` hears a click, and `tipTitle` / `tipBody` go on the box. Any row
  takes `note = "text"`, a small grey line under its field that the dialog grows to fit;
  `frame:SetNote(i, text or nil)` changes or removes it after build (no gap left), and
  `frame.notes[i]` is the FontString. `opts.body = "text"` is a paragraph under the title and hint,
  above the rows, wrapped to the dialog's width; `frame:SetBody(text or nil)` replaces it at any time,
  after `Show` included, and the height follows (nil hides it, no gap). `frame.body` is the
  FontString. A dialog with none of these lays out exactly as before.
- **A menu does not scroll, and is clamped to the screen.** `W:MenuCapacity(withSearch)` (MINOR 34)
  answers how many rows fit in 80% of the screen at the current scale (`withSearch` reserves the root's
  search box). A row past that is unreachable, so build a long menu to that count and add a
  `{ text = "N more", disabled = true }` line; RowList's column filter does exactly that.

- **Form helpers** — `W:CreateDropdownBox` (a labelled picker button), `W:ShowDialog`
  (a prompt/confirm dialog raised above its owner), `W:CreateSearchBox` + `W:SearchMatch`
  (a TSM-style search field with a tokenised any-field matcher).

  - `W:CreateDropdownBox(parent, opts)` returns the button; set its shown text with
    `box.label:SetText(...)`. `opts`: `width` / `height` (170x22, scale-1.0), `items(query) -> items`
    built fresh on every open, `search = true` (a filter box; `items` is re-called per keystroke with
    the typed text), `menuWidth`, `keepOpen`, `tipTitle` / `tipBody`.
  - `W:ShowDialog(parent, opts)` returns the dialog frame and a token. `opts`: `prompt`, `hasEdit`
    (default true), `default` (the edit box's starting text), `okText`, `cancelText`,
    `onAccept(value)` (the typed text, or `nil` without an edit box), `onShow`, `onHide`. Its parts
    are `dialog.prompt`, `dialog.edit`, `dialog.ok` and `dialog.cancel`; the frame is shared, so read
    them only while your prompt is the one showing.
  - `W:CreateSearchBox(parent, opts)` returns the EditBox. `opts`: `width` / `height` (160x20,
    scale-1.0), `placeholder`, `onChanged(text)` (every edit, the clear-X included), `tipTitle` /
    `tipBody`. For an AceGUI layout use the `LAGW-SearchBox` widget instead.
  - `W:SearchMatch(query, ...)`: every word of `query` appears somewhere in the fields given, in any
    order and case; an empty query matches everything and a `nil` field is skipped.

  **`W:ShowDialog` since MINOR 30:** `cancelText = false` gives one centred OK button; `onShow(dialog)`
  and `onHide(dialog)` run once per show, and `onHide` runs however it closes (OK, Cancel, Escape, or a
  later `ShowDialog` replacing it), so a `PushModal` / `PopModal` pair always balances. With
  `hasEdit = false`, Enter accepts and Escape cancels. That keyboard listening happens only when the
  dialog is shown **out of combat**: passing every other key on to the game needs
  `SetPropagateKeyboardInput`, which insecure code may not call in combat, and a dialog that could
  not pass keys on would stop the player moving. Escape also works in combat, through `UISpecialFrames`
  (the dialog is now named `LibAceGUIWidgets_Dialog`).

  **One frame is shared by every addon in the session**, and three consequences are worth knowing.
  `parent` is re-applied on every call -- the dialog is re-parented, re-anchored and re-levelled to
  whoever shows it, so it is never stuck inside an earlier caller's window. **What parenting costs:**
  the prompt inherits the parent's visibility, so a prompt parented into a window goes off screen with
  that window and comes back with it, still open -- for a confirm *about* that window that is the
  feature (a "delete this event?" parented to the calendar); for anything that should stay on screen
  regardless, pass `UIParent`. The window hiding is not a close: `onHide` does not run, and the token
  still matches (MINOR 33). And `dialog:Hide()` is
  **not** how you dismiss your own prompt: by the time you want to, the frame may be showing somebody
  else's question. Use the token instead (MINOR 30):

  ```lua
  local dialog, token = W:ShowDialog(parent, { prompt = "Delete this event?", hasEdit = false })
  -- later, e.g. because the thing being asked about went away:
  W:CloseDialog(token)   -- no-op unless that exact prompt is still up; returns whether it closed one
  ```

  `W:CloseDialog(nil)`, a token whose prompt has already closed, and a token belonging to a replaced
  prompt are all no-ops returning `false`. Feature-detect with `if W.CloseDialog then`.

  **A copy box (MINOR 38).** Addons cannot write the clipboard, so to hand the player a link or an
  error line, show it selected in a box and let them press Ctrl+C:

  ```lua
  local dialog, token = W:ShowCopyBox("https://discord.gg/...")
  -- opts: parent (UIParent), prompt ("Press Ctrl+C to copy, then Escape."), okText (CLOSE), onShow, onHide
  ```

  One button; OK, Enter and Escape all close it, and nothing is called with the text. The box is
  focused with the whole text selected, and it is read-only: a typed key is put back and the text
  selected again, and a click selects all again. Long text scrolls inside the box. A copy glyph sits
  in the box, styled and tinted exactly like the search box's magnifying glass (`W.COPY_ICON`,
  `Textures/copy.tga`).

  **Inline (MINOR 38):** the same box inside a window is the `LAGW-CopyField` widget type:
  `AceGUI:Create("LAGW-CopyField")`, then `SetText(text)`, `GetText()` and `SetLabel(label)` (no label
  takes no height). Same glyph, same read-only rule, same select-all; AceGUI EditBox's size, so it sits
  in a List or Flow beside other controls. Feature-detect with
  `AceGUI:GetWidgetVersion("LAGW-CopyField") >= 2` (Version 1 raised on every Create). It is the same shared
  frame as `ShowDialog`, so `CloseDialog(token)` closes it. Feature-detect with `if W.ShowCopyBox then`.
- **Click bindings** (MINOR 38) -- `LAGW-ClickBinding` lets a player set a modifier + mouse button by
  doing it. Click to arm, then click again holding Alt, Ctrl and/or Shift. An unmodified click is
  refused. Escape or Cancel disarms.

  ```lua
  local cb = AceGUI:Create("LAGW-ClickBinding")
  cb:SetLabel("Open 'Where to get it'")
  cb:SetDefault("ALT-LeftButton")        -- adds a Default button
  cb:SetValue(db.whereClick)             -- silent
  cb:SetCallback("OnValueChanged", function(_, _, binding) db.whereClick = binding end)
  -- in the click handler:
  if W:IsClickBinding(db.whereClick, button) then ... end   -- button nil: modifiers only
  ```

  The value is always `ALT-`, `CTRL-`, `SHIFT-` in that order, then `LeftButton` / `RightButton` /
  `MiddleButton` / `Button4` / `Button5`. `W:ClickBindingText(binding)` gives "Alt + Left Click", and
  `W:ParseClickBinding` / `W:ClickBinding` convert between the string and its parts. `IsClickBinding`
  needs the held modifiers to match exactly, so Alt + Left does not fire on Alt + Ctrl + Left. The
  widget also has `GetValue()` and `SetDisabled(bool)` (which disarms it), and fires `OnEnter` /
  `OnLeave` from its button. Feature-detect with `if W.IsClickBinding then`.
- **Floating frames** (MINOR 30) -- `W:CreateFloatingFrame(opts)` builds the panel this suite floats
  above a window with: `UIParent`-parented, **TOOLTIP strata** (strata beats level, so a RowList's cells
  cannot punch their text through it), the library backdrop, clamped to screen, mouse-enabled, and an
  opaque fill inset inside the border. `opts` takes `name` (a global name, which also puts it on the
  client's Escape list), `level` (default 100), `strata`, `parent` and `inset`; `frame.bg` is the fill.
  `W:OwnFloating(frame, { isOver, close })` closes it on a mouse-down anywhere that is not it or its
  owner -- `isOver(frame)` is what counts as "mine", `close(frame)` is what closing means (default
  `frame:Hide()`; the menus pass one, because closing the root must take the submenus with it). It
  listens only while shown, and registers immediately if the frame is already shown when you hand it
  over. `W:RegisterSpecialFrame(name)` appends a name to the Escape list once and says whether it did.
  The menus, the DatePicker popup and `ShowDialog` are the three callers.
- **`W:CreateCheckbox(parent, opts)`** (MINOR 30) -- a labelled checkbox bound to your setting:
  `{ label, tipTitle, tipBody, get = function() return db.x end, set = function(on) db.x = on end,
  size, font }`. It shows `get()` when built, every time it is shown and on `cb:Refresh()`; a click hands
  the new state to `set` and then shows `get()` again, so a setter that refuses is seen refusing.
  26x26 (the options size) on `UICheckButtonTemplate`, following the UI scale; `cb.label` is the text.
- **`W:DockWindow(frame, opts)`** (MINOR 30) -- a raw window that docks to another frame's edge and
  follows it:

  ```lua
  local h = W:DockWindow(myWindow, {
      to = CalendarFrame, point = "TOPLEFT", relPoint = "TOPRIGHT", x = 0, y = -16,
      snapDistance = 40,                 -- how near a drop must land to dock, in the window's units
      status = MyDB.window,              -- YOUR table: docked (nil = docked), left, top
  })
  ```

  Docked is the default. A docked window is **anchored** to the target, so it follows it; when the
  target hides the window stays where it is on screen, and when the target shows again a shown window
  re-docks. A drop decides docking only while the target is open: near the edge (anywhere along it)
  docks, anywhere else undocks and saves `left`/`top`. With the target closed a drag just saves the
  position. Distances are compared in screen units, so the two frames may have different scales. The
  drop and the show are heard through `OnDragStop` and `OnShow`, hooked, so set your own `OnDragStop`
  and `OnShow` **before** calling this (a later `SetScript` replaces the hook, and docking silently
  stops); a window moved some other way calls `h:Moved()`, and an `OnShow` set later calls `h:Apply()`. Also
  `h:SetDockEnabled(bool)` / `h:IsDockEnabled()`, `h:IsDocked()`, `h:Dock()` (anchors to the target
  and returns true, or false when docking is off or the target is closed), `h:Restore()` (the saved
  free position, or the screen centre), `h:IsNearTarget()` and `h:Apply()` (dock, else restore). For
  an AceGUI window use `PersistWindow` instead -- one position, one owner, and from MINOR 32 that is
  **enforced**: the second of the two calls on one window returns `nil` and, in debug (MINOR 39),
  prints once, naming the call to drop.

  **Letting go (MINOR 38).** `h:Undock()` or `W:UndockWindow(frame)` takes the window off its target:
  a docked window is pinned where it is on screen, `status.docked` is left alone, and a later
  `DockWindow` to a new target docks it again. Re-pointing `DockWindow` at a new target leaves the old
  one. **A target that is an AceGUI widget's frame is let go of automatically when that widget is
  released**, because AceGUI hands the same frame to the next addon's `Create`, and our window would
  otherwise re-dock onto theirs. Any other target frame that gets reused must be let go of by hand.
  Feature-detect with `if W.UndockWindow then`.
- **`W:DressBottomRow(widget, specs)` / `W:UndressBottomRow(widget)`** (MINOR 33) -- the row of icons
  left of AceGUI's Close button, with the status bar shortened to make room:

  ```lua
  local icons = W:DressBottomRow(window, {
      { key = "help", texture = "Interface\\Common\\help-i",
        tipTitle = "My Addon", tipBody = { "First paragraph.", "", "Second." } },
      { key = "gear", texture = "Interface\\Icons\\Trade_Engineering",
        texCoord = { 0.08, 0.92, 0.08, 0.92 },     -- Icons\ files carry transparent padding
        tipTitle = "Settings", tipBody = "Open the options panel.",
        onClick = function() MyAddon:OpenOptions() end },
  })
  -- icons[1] == icons.help, icons[2] == icons.gear
  ```

  `widget` is an AceGUI `Frame` (a `ClearFrame` too) or a raw frame. The first icon is 24 square with
  its right edge 133 in from the frame's bottom-right and 15 up; every later one is 20 square on the
  17 line, 8 apart -- the fleet's numbers, which put the row exactly 6px left of AceGUI's own Close
  button. Per spec: `texture` (required), `texCoord`, `size`, `y`, `gap`, `alpha`, `tipTitle` /
  `tipBody` (a string, an array of lines, or a `function(icon)`, **read on hover** so an icon whose
  text depends on state says the right thing), `onClick(icon, mouseButton)` and `key`. Each icon is
  lifted above AceGUI's resize strips, which would otherwise eat most of its hitbox, and gets the
  fleet's hit-rect insets and highlight.

  **Not scaled, deliberately** -- the row lines up with AceGUI's Close button and status bar, which do
  not follow `SetScale`. **Idempotent**: AceGUI pools frames, so a second dress re-points the same
  buttons rather than stacking another set, and a shorter one hides the leftovers. **Call
  `W:UndressBottomRow(window)` when the window closes**: it hides the icons and puts the status bar
  back where it found it. Both halves matter -- the pooled frame goes to another addon's window next,
  where your gear would open your settings and your status anchor would follow.
- **`W:CreateExpandableList(parent, opts)`** — a scrolling datasheet of collapsible
  `label + value` groups; a `+`/`-` toggle opens each to indented child rows. Pooled
  rows and persistent per-group expand state; `list:SetData(groups)` (re)fills it. For
  EP breakdowns, statsheets, and any drill-down tree. A group is `{ key, label, valueText, children,
  defaultExpanded }` (`key` defaults to `label` and keys the remembered state); a child is
  `{ label, valueText, color = { r, g, b } }`. `opts`: `barWidth` (8), `indent` (14) and `rowHeight`
  (16), both scale-1.0, and `childColor` (a grey). `list:SetAllExpanded(open)` opens or closes every
  group; anchor `list.frame`. **MINOR 36:** a child may have its own `children`, to any depth, each
  level indented one more `indent`; expand state is keyed by the path of keys, so two groups with the
  same name under different parents keep their own (`list:IsExpanded("prof", "spec")`). Any node
  takes `color`, `onClick(node, mouseButton, rowFrame)` (a group still toggles first) and `tooltip`,
  either `{ title, body }` or `function(node) return title, body end`, read on hover. Two-level data
  draws exactly as before.
- **`W:BrandTabGroup(tabGroup)`** — brand an AceGUI-3.0 `TabGroup` with the suite tab look: a soft **accent
  highlight band behind the selected tab's label** (the stock selected state only greys/`Disable()`s it — hard
  to spot) plus a fainter accent **mouse-over band** on the others. Call once after `AceGUI:Create("TabGroup")`;
  idempotent, pure styling (hooks the widget's own `BuildTabs`/`SelectTab`), and a no-op on a non-TabGroup table.
  **Requires MINOR 23 to actually render** — before that the band never appeared on any client (it anchored to
  a string and drew beneath the tab graphic); consumers need no code change, just the newer library.
- **`W:MakeResizable(frameOrWidget, opts)`** (MINOR 26) -- the resize framework: put ClearFrame's drag
  grips on **any** frame, or on any AceGUI widget's `.frame`, without being a ClearFrame.
  Defined in `LibAceGUIWidgets-Resize.lua` since MINOR 30 (it was in the core file before); the TOC
  loads it, so this matters only if you embed individual files rather than the folder.

  ```lua
  local h = W:MakeResizable(myWindow, {
      minW = 400, minH = 200, maxW = 1200, maxH = 900,   -- bounds; max is optional
      grips  = "SE S E",                 -- a SET of grips, not one corner; `false` for none
      gripSize = 25, showGrip = true,    -- strip width; the diagonal lines on the corner
      status = MyDB.window,              -- width/height/left/top, written when a drag ends
      restore = true,                    -- apply `status` immediately (default)
      onResizeStart = function(f, w, ht, handle) end,
      onResize      = function(f, w, ht, handle) list:Refresh() end,   -- LIVE, once per draw
      onResizeStop  = function(f, w, ht, handle) rebuildSomethingSlow() end,
  })
  h:SetEnabled(false)   -- a locked window: grips hidden, drags refused
  h:SetBounds(300, 150) -- change the bounds later
  h:IsResizing()
  h:SetStatusTable(t[, restore])  -- bind a new table; applies it unless restore == false
  h:ApplyStatus()       -- size from the table, and position when both left and top are saved
  h:SaveStatus()        -- write width/height/left/top now
  h:Destroy()           -- drop the grips, callbacks and scale listener; a later MakeResizable rebuilds
  ```

  **`onResize` is what you cannot hand-roll.** The client tells you a window was resized when the
  drag ends; a window whose contents must re-lay-out *while* it is being dragged has nothing to
  hook. This fires live, **throttled to at most one call per frame draw** through a hidden OnUpdate
  driver -- an un-throttled callback there is a full re-render per mouse pixel. It fires for a
  programmatic `SetWidth` too, not only for a drag.

  If your window is also **movable**, its mover must write `left`/`top` into the same `status`
  table: this never sees a move, so a moved-then-restored window would otherwise come back at its
  last *resized* position. ClearFrame's title bar already does exactly that.

  Calling it twice on the same frame is idempotent: you get the same handle back, reconfigured,
  never a second set of grips. Feature-detect with `if W.MakeResizable then`.

  **A second call MERGES (MINOR 30).** Options it passes replace; options it omits keep their value;
  `onResize = false` (or `onResizeStart` / `onResizeStop`) removes a callback. So adding a live
  callback to a ClearFrame is `W:MakeResizable(clearFrame, { onResize = fn })`, and the widget keeps
  its own size persistence and 400x200 minimum. **Before MINOR 30 that same call silently erased
  both** -- the window stopped remembering its size and could be dragged to nothing. On an older
  copy, set `W:GetResizeHandle(w).onResize = fn` instead, which is safe on every version.

  An AceGUI container (ClearFrame included) already re-lays out its children from its content
  frame's `OnSizeChanged` -- AceGUI wires that itself -- so reach for `onResize` for work AceGUI's
  layout does not do, not to call `DoLayout` a second time.
- **`W:PersistWindow(widget, savedTable, opts)`** (MINOR 28) -- make a `ClearFrame` (or AceGUI `Frame`)
  remember its position and size across open/close and `/reload`, from a table **you** own:

  ```lua
  W:PersistWindow(window, MyDB.char.windows.mailbox, {
      width = 560, height = 480,         -- defaults for an empty table
      minWidth = 420, minHeight = 300,   -- the floor: resize bounds, and a saved size under it is raised
  })
  ```

  The table goes straight to `SetStatusTable`, so AceGUI's own drag/resize writes land in your save and
  the library keeps no copy -- clear `top`/`left` and call `ApplyStatus` to recenter. `nil` table = no
  save; the defaults are applied to a fresh table, which is returned.

  **The floor follows the UI scale, live, for every window kind (MINOR 31).** `minWidth` / `minHeight`
  are scale-1.0 values and are multiplied; the saved size is pixels and never is. When the scale moves,
  the bounds are re-applied at the new scale, a window now under its floor is raised to it, and the
  **saved size is raised with it**, so the window the scale change grew is the one the next open
  restores. Before 31 only a `ClearFrame` did this (its resize handle carries the listener); an AceGUI
  `Frame` kept its draw-time floor and size until the next reload. The multiply is right for a floor
  made of things this library scales -- rows, icons, its fonts. A floor that is partly fixed art (stock
  AceGUI controls scale only their text; your own pixel insets scale nothing) is under its content
  below 1.0. For that case pass the floor as a **function of the scale**, evaluated at the call and
  again on every change: `minWidth = function(s) return fixedPx * math.max(1, s) / s end` grows above
  1.0 and holds its pixel value below it. (A pre-divided *number* is right only at the scale it was
  computed at, and re-calling `PersistWindow` from your own scale listener would race the library's --
  the function form has no race.)

  **Releasing a persisted window forgets it (MINOR 35).** AceGUI pools the widget and its frame for every
  addon in the session, so `widget:Release()` now drops the persist record and its scale listener and
  puts the resize bounds back to what they were before the first `PersistWindow`. The next owner of that
  frame no longer gets your floor. `W:ForgetWindow(widget)` does the same without a release, to stop
  persisting a window that stays open, and returns `true` when there was a record. A `ClearFrame`'s own
  resize handle is **restored, not destroyed**: it is built once in the constructor, so destroying it
  would leave the pooled frame without grips.

  **On screen, size profiles, opacity and scale (MINOR 36).** `PersistWindow` now ends with
  **`W:ClampWindow(widget)`**, which caps a saved size to the screen and moves the window fully onto it
  (writing the fix back to the table); call it yourself on any window. **`W:SetWindowProfile(widget,
  key, { width, height, resizable, minWidth, minHeight })`** switches a persisted window between named
  sizes: a locked profile snaps and turns resizing off, a resizable one restores its own size from
  `saved.profiles[key]` and uses its own floor, and position is shared (`W:GetWindowProfile` reads the
  key). A resizable profile's size is saved when you switch away from it **and** when the window is
  released (or `ForgetWindow` is called) while it is active, so a window dragged and closed on that
  profile reopens at the dragged size. **`W:SetWindowOpacity(widget, alpha)`** fades the window's backdrop and its TabGroup,
  InlineGroup and TreeGroup panes, nothing else; call it again after drawing a tab, with
  `W:GetWindowOpacity(widget)`. **`W:SetWindowScale(widget, 0.5 - 1.5)`** scales that one window, keeps
  its own anchors (a docked or consumer-anchored window stays attached, its anchored point on the same
  screen spot) and is saved as `windowScale` for `PersistWindow` to re-apply
  (`W:GetWindowScale` reads it). All of them are undone on Release.

  **Two-stage Escape (MINOR 36).** `W:EscapeLayer(window, { popup, dialog, ... })` makes Escape close
  the newest shown popup first and the window on the press after the last one. It takes frames or
  AceGUI widgets, takes them off `UISpecialFrames` while it lasts (the client closes every listed frame
  on one press), and ends on Release or with `W:DropEscapeLayer(window)`. It returns the proxy frame
  that stands in for the window on the Escape list. Works in combat. The client's
  close-everything paths (loss of control, some panel opens) go through the same function, so they
  too close one popup at a time on a layered window.
- **`W:Breathe(region [, opts])` / `W:StopBreathing(region)` / `W:IsBreathing(region)`** (MINOR 28) --
  the suite's attention-getter: an eased alpha pulse 1 -> 0.35 -> 1, one second each way, looping. One
  animation group per region, reused on every call (`opts = { low, seconds, smoothing }`); `StopBreathing`
  restores alpha 1. Put it on a **Frame** if your specs need to drive it offline.
- **A symbol font** (MINOR 28) -- `Fonts/DejaVuSans.ttf` ships with the library because the client's
  fonts cannot draw arrows, check marks, crosses or warning signs (they render as empty boxes on Classic
  Era). `W.SymbolFont` (12px) and `W.SymbolFontSmall` (11px) are font objects; `W:SymbolFontPath()` is the
  path for your own `SetFont`; `W:Symbol(name)` gives the UTF-8 character for `arrow_right` /
  `arrow_left` / `arrow_up` / `arrow_down` / `check` / `check_heavy` / `cross` / `cross_heavy` / `warning`
  / `le` / `ge` / `plusminus` / `bullet` / `star` / `star_hollow` / `play` / `refresh`, or `nil`.

  ```lua
  fs:SetFontObject(W.SymbolFont)
  fs:SetText((W:Symbol("check") or "[OK]") .. " Synced")
  ```

  **It works on FontStrings you own.** A GameTooltip line carries the tooltip's font and a chat line the
  chat frame's -- neither takes a second font per line -- so keep ASCII there, or draw that text on your
  own FontStrings. Never bundle a font per addon; the suite's fonts live here.
- **One UI scale, for the visually impaired** (MINOR 29) -- `W:SetScale(factor)` / `W:GetScale()`, clamped
  to `[W.SCALE_MIN, W.SCALE_MAX]` = `[0.8, 2.0]`; `W:Configure{ scale = n }` does the same. Every font,
  icon, row height, menu, dialog, header and resize minimum this library draws enlarges together, and
  every widget re-lays itself on the change -- a `RowList`, a `ClearFrame`, a menu, the date picker --
  without the consumer touching it. **In memory only**: you persist the factor and call `SetScale` at load
  and from your slider.

  ```lua
  W:SetScale(MyDB.global.uiScale or 1)                 -- at load
  slider.set = function(_, v) MyDB.global.uiScale = v; W:SetScale(v) end
  ```

  For the regions you draw yourself: `W:ScaledFont("GameFontNormalSmall")` is a font **object** at the
  base's size x scale, re-sized **in place** on every change, so a FontString pointed at it follows;
  `W:ScaledSize(px)` is `px x scale` rounded to a pixel; `W:SetScaledSize(frame, w, h)` keeps a frame at
  `(w, h) x scale`; `W:OnScaleChanged(owner, fn)` calls `fn(new, old)` after every change (one listener per
  owner; `nil` removes). Sizes you pass the library (`rowHeight`, `col.width`, `width`/`height`, `minW`) are
  scale-1.0 values and are multiplied; positions you pass (`x`/`y`) are yours and are not.
- **Helpers** -- `W:Brand`, `W:AttachTooltip`, `W:AnchorTooltip`, `W:HideTooltip` (MINOR 34 -- hide
  and hand the anchor back to the client's default; use it in any OnLeave whose OnEnter used
  `AnchorTooltip`), `W:ApplyMinResize`,
  `W:ApplyResizeBounds` (MINOR 26 -- `ApplyMinResize` with a maximum), `W:GetResizeHandle`,
  `W:CreateMenuInfo`, `W:MakeLabel`, `W:AccentRGB` (MINOR 28 -- the accent as `r, g, b` floats,
  for `SetVertexColor` / `SetTextColor`); shared `W.FrameBackdrop` / `W.PaneBackdrop`.
  - `W:ShowTooltip(anchor, title, body[, opts])` draws the library's one title-and-body tooltip and
    returns whether it showed anything. `opts`: `titleColor = { r, g, b }` (white by default),
    `reason` (a red line drawn last; a reason alone still draws) and `owner(frame)` (anchors this one
    tooltip instead of `AnchorTooltip`). `W:AttachTooltip(frame, title, body[, opts])` takes the same
    `owner`. **MINOR 36:** `opts.minWidth` (scale-1.0 px) floors the tooltip's width for that showing
    only -- the previous minimum, forced flag included, goes back when the tooltip hides or the next
    one shows -- in `ShowTooltip`, `AttachTooltip`, `AttachWidgetTooltip`, a `DressBottomRow` icon
    spec's `tipMinWidth`, and a ClearFrame's `SetInfoTooltip(tooltip, { minWidth })`.
  - `W:AnchorPopup(popup, source[, { gap = 2 }])` (MINOR 36) puts a floating panel under a row or
    button, left edges aligned, or over it when there is no room below; slides it left to stay on
    screen; clamps it. Call it every time the popup opens. Returns `"below"` or `"above"`.
  - `W:MakeLabel(parent, text, opts)` is an accent-branded label on a transparent Button so it can
    carry a tooltip. `opts`: `x`, `y`, `width` / `height` (120x12, scale-1.0), `justify`, `font` (a
    global font name, `GameFontNormalSmall` by default), `tipTitle` / `tipBody`. `btn.label` is the
    FontString.
  - `W:CreateMenuInfo(checkable)` is `UIDropDownMenu_CreateInfo()` with `notCheckable` set, unless
    `checkable` is true.
  - Theme accessors: `W:SetAccent(hex)` / `W:GetAccent()` (`"ffRRGGBB"`; `Configure{ accent }` goes
    through `SetAccent`), `W:ClassColor(classFile)` (your `classColors`, then `RAID_CLASS_COLORS`,
    then white), `W:SetTooltipOwner(fn)` / `W:GetTooltipOwner()`.
  - `W.TabLabelRegion(tab)` is the region `BrandTabGroup` anchors a tab's band to: its `Text` font
    string, or the tab itself. `W.SYMBOL_FONT` is the bundled font's path and `W.SYMBOLS` the
    name-to-UTF-8 table behind `W:Symbol`.
- **Named cooldowns** (MINOR 24) -- a rate-limited button that counts itself down.
  `W:BindCooldownButton(button, name, { label, seconds, onClick, format, colour, dim })` wires a
  button to a cooldown. While it runs, the caption is the whole seconds left, the text dims, the
  highlight hides and `onClick` is not called. `seconds` may be a function, read per click. Underneath:
  `W:StartCooldown(name, seconds[, { interval }])` (0 or less stops it; `interval` is the repaint tick,
  1 second by default), `W:StopCooldown(name)`, `W:OnCooldown(name)`,
  `W:CooldownRemaining(name)` and `W:OnCooldownTick(name, fn)`, which is called with the seconds left and
  with 0 exactly once when it ends. The remainder is computed from `GetTime()` against a stamped
  deadline, never decremented, so a loading screen or a dropped frame cannot leave it stuck. Starting a
  running cooldown cancels its ticker first.
- **Version helpers** -- `W:ResolveVersion(addonName)` is the display version for a status bar or
  about line: the TOC `Version` with the packager's `<Addon>-v` / `v` prefix stripped, `"?"` if there is
  none. An unpackaged checkout shows the raw `LibAceGUIWidgets-v0.3.0`. `W:EnableVersionCheck(nameOrHost[,
  version])` registers your addon with VersionCheck-1.0 (the "a guildmate has a newer build" nudge) and
  returns its handle, or `nil` when VersionCheck is not loaded. Pass the **raw** TOC version, not
  `ResolveVersion`'s, because VersionCheck needs the sentinel to recognise a dev build.
  `W:TriggerVersionCheck()` re-runs the check, from a settings button say, and returns whether it did.
- **Pool-safe widget additions** (MINOR 36) -- anything you add to an AceGUI widget, undone when AceGUI
  releases it. AceGUI pools widgets for every addon in the session and its `Release` never touches a
  raw script, a frame flag or a raw child frame, so without these they follow the pooled frame into
  another addon's window.
  - `W:OnWidgetRelease(widget, key, fn)` runs `fn(widget)` once on Release. It chains onto the
    widget's `OnRelease` method, so your `SetCallback("OnRelease")` stays yours. The same `key` again
    replaces the hook; `fn = false` removes it. Hooks run newest first, before the widget type's own
    `OnRelease`. Wrapping `widget.OnRelease` yourself is fine; replacing it without calling the old one
    breaks this chain, as it would break AceGUI's.
  - `W:WidgetFrameScripts(widget, { OnMouseDown = fn, ... } [, target])` sets raw scripts for events the
    widget has no callback for. `target` is `widget.frame` by default, a field name (`"editbox"`) or a
    frame. On Release each event gets back the script from before your FIRST call, so the widget's own
    dispatcher survives. `false` for an event restores it now; `W:RestoreWidgetFrameScripts(widget)`
    restores everything now.
  - `W:AttachRawFrames(widget, frameOrList)` for raw frames you parent into `widget.content`. On
    Release they are hidden, un-anchored and re-parented to `UIParent`, and left for your own pool.
    `W:DetachRawFrames(widget)` does it now.
  - `W:AttachWidgetTooltip(widget, title, body[, opts])` -- use this, not `AttachTooltip`, on an AceGUI
    widget. It answers on the label area too (enabling its mouse), runs the widget's own `OnEnter`
    first so your `SetCallback("OnEnter")` still fires, takes `ShowTooltip`'s `opts`, keeps a disabled
    button's hover, and a second call updates the text. On Release it puts every script and flag back.
- **A finite flash** (MINOR 36), beside the looping `Breathe`: "something just happened" rather than
  "this needs you". `W:Flash(region[, { times = 3, seconds = 0.25, low = 0, onDone = fn }])` dips the
  alpha `times` times, stops by itself and puts the alpha back at 1; a second call restarts it on the
  same animation group, and `W:StopFlash(region)` ends it now. `W:FlashScreen([{ color, times,
  seconds }])` flashes a full-screen edge glow in the accent (or `color`, `"ffRRGGBB"`) on one shared
  frame that never takes the mouse, then hides it. Nothing protected is touched, so both are safe in
  combat.
- **Is the player mid-interaction?** (MINOR 36) -- for a consumer that redraws on events and must not
  throw away an open menu or a caret. `W:IsMenuOpenFor(frameOrWidget)` is true while a menu this
  library opened (OpenMenu, ToggleMenu, a dropdown box, a RowList header) is showing with its anchor
  inside that window; submenus count, another addon's menu does not. `W:IsInputFocusedIn(frameOrWidget)`
  is true while the keyboard focus is an edit box inside it. `W:OnMenuClosed(owner, fn)` calls `fn()`
  once, the next time that window's menu closes or is replaced, so a deferred redraw needs no polling.

## Contracts worth knowing before you integrate

Ones that are not about RowList. The tooltip and resize contracts changed in MINOR 26; the
VersionCheck one in MINOR 27; four are MINOR 28; the scale one is MINOR 29; the disabled-hover one is
MINOR 33.

- **The UI scale multiplies every SIZE you hand the library and never a POSITION or a WINDOW.**
  `rowHeight`, `col.width`, `width`/`height` on `MakeLabel` / `CreateSearchBox` / `CreateDropdownBox`,
  and every `minW`/`minH`/`maxW`/`maxH`/`minWidth`/`minHeight` are scale-1.0 values -- write them for 1.0
  and the library multiplies (at 1.0 that is the identity, so nothing you have changes). `x`/`y` and
  anchor offsets are yours and are not touched: redraw your own regions on `OnScaleChanged` with
  `ScaledSize`. A window's size is the user's: `PersistWindow` saves real pixels and never scales them;
  only the floor is scaled, and a window under its enlarged floor is raised to it on a change. Nothing
  shrinks on a scale-down. `GameTooltip` is left alone (the client's one shared frame; a font set on a
  line sticks to that slot). `ScaledFont` caches ONE object per base and re-sizes it in place -- that is
  what makes a FontString follow -- so hold the object, never its `GetFont()` numbers. A tab label grows
  but AceGUI's tab art does not, so at 2.0 a label can exceed its band; an AceGUI container holding a
  `LAGW-DatePicker` or `TLabel` needs your `DoLayout` on the signal to re-flow the new height.
  (`LAGW-SearchBox` re-runs its parent's layout itself, and a `LAGW-Strip` re-lays itself.)
- **`LAGW-DatePicker`'s value is a day, and `SetValue` is silent.** `GetValue` is `time()` of *local
  midnight* on the chosen day or `nil`, and `SetValue` snaps whatever you pass to the same -- compare
  like with like in a range filter. `SetValue` fires nothing (as AceGUI's `EditBox:SetText` fires
  nothing); every user action fires `OnValueChanged`, only on a real change. A click in the field opens
  the calendar and never closes it; the arrow toggles. The popup is one shared frame on `UIParent` --
  do not parent your window's layout to it, and expect it to close when your window hides.
- **`W:PersistWindow` keeps no copy of your coordinates, and the floor applies to the saved size.**
  Your table goes straight to `SetStatusTable`; clear `top`/`left` and call `ApplyStatus` to recenter.
  A saved width/height under `minWidth`/`minHeight` is raised in the table before it is applied.
  Passing one floor keeps the frame's current other bound. `nil` table = defaults into a fresh table,
  returned. A widget without `SetStatusTable` gets `nil` back and nothing done.
- **`W:Breathe` reuses one animation group per region.** Call it again to change `low`/`seconds`; it
  never stacks a second group. It returns `nil` for a region that cannot animate (offline, every
  Texture and FontString; in game, nothing you will meet) rather than raising. `StopBreathing` restores
  alpha 1 whether or not the pulse was running.
- **The symbol font works on FontStrings you own, and only those.** `W:Symbol(name)` answers `nil` for
  an unknown name so `W:Symbol("check") or "[OK]"` degrades on an older copy. A GameTooltip line
  carries the tooltip font and `SetFont` on it sticks to that line *slot* for every later tooltip; a
  chat frame has one font for every line. Keep ASCII in both. Never bundle a font per addon.

- **`W:EnableVersionCheck` keeps looking after a miss, as of MINOR 27 -- before that, one miss was
  cached for the whole session and for every consumer.** The lookup is lazy, so calling it from your
  own `ADDON_LOADED` is fine. On an earlier copy it was not: `_vc` lives on the shared library table,
  and the first consumer to call before VersionCheck-1.0's file had loaded froze the miss. Every
  addon loading afterwards got `nil` back from a library that had stopped looking, silently, with the
  symptom being a missing update reminder nobody attributes to load order.

  Nothing to change on your side; take the newer copy. **A bug fix cannot be feature-detected**, so
  `MINOR` is the signal if you need to depend on it:

  ```lua
  if (LibStub.minors["LibAceGUIWidgets-1.0"] or 0) >= 27 then
      -- calling EnableVersionCheck early is safe
  end
  ```

- **`W:AttachTooltip` is idempotent, and it used not to be.** It installs its `OnEnter`/`OnLeave`
  hooks once and stores the text on the frame, so calling it again **updates** what is shown. Before
  MINOR 26 it installed a fresh `HookScript` pair per call -- and `HookScript` appends rather than
  replaces, so a consumer re-attaching to refresh a tooltip whose title reports a value the same
  control changes ended up with one handler per refresh, all firing on a single hover, with the
  *first* call's stale text still being drawn on the way past. If you wrote a guard to avoid
  re-attaching, you can drop it.
- **`W:AttachTooltip` takes only strings and numbers as text.** Anything else -- a table, a boolean,
  a function -- draws no line. The old guard was `if title and title ~= ""`, which is truthiness plus
  an equality test and not a type check, so a table passed it and `GameTooltip:SetText` then raised
  `bad argument #1 to 'SetText'` **inside the `OnEnter` handler**, once per hover, with a traceback
  naming the library rather than your call site. A control whose tooltip has silently gone missing is
  now the symptom of a bad argument; that is deliberate, and it localises the caller for you.
- **`W:AttachTooltip` keeps a button's hover while it is disabled (MINOR 33).** A disabled Button
  gets no `OnEnter` unless `SetMotionScriptsWhileDisabled(true)` is set, so a tooltip attached here
  used to go silent the moment you greyed the control -- exactly when the one explaining why is
  wanted. It now sets the flag on any frame that has the method, once. **That flag belongs to the
  frame**, so your own `OnEnter` / `OnLeave` on the same button also runs while it is disabled from
  now on; a highlight that assumed a disabled button is never hovered will light up. Drop any
  hand-rolled `SetMotionScriptsWhileDisabled` call at sites that go through `AttachTooltip` or
  `CreateDropdownBox`, gated on `LibStub.minors["LibAceGUIWidgets-1.0"] >= 33`.
- **`W:AttachTooltip` is for frames YOU own, not for a pooled AceGUI widget (MINOR 36).** Its hooks
  cannot be removed, so on `widget.frame` the tooltip follows the frame to the next addon that
  acquires it. Use `W:AttachWidgetTooltip(widget, ...)` for AceGUI widgets.
- **`W:MakeResizable` never sees a MOVE.** It persists `width`/`height`/`left`/`top` when a drag ends.
  If the window is also movable, its mover has to write `left`/`top` into the same table, or a
  moved-then-restored window comes back at its last *resized* position. ClearFrame's title bar
  already does this, and its status table is interchangeable with the one `MakeResizable` writes.

## RowList contracts worth knowing before you integrate

Rules that are easy to get wrong from the outside, each of which used to fail quietly or
confusingly. The first two date from MINOR 25, the width one from MINOR 29, and the key and
diagnostics ones from MINOR 33.

- **`actions` may contain holes.** `cond and action or nil` inside the constructor is fine -- `New`
  compacts the array, so the entry is neither dropped nor fatal, and the reserved icon strip is sized
  for what survives. Previously a nil anywhere but the last slot **raised mid-draw**, out of your own
  `SetData`/`Refresh` call. (A *trailing* conditional was always safe, for a Lua reason rather than a
  library one: assigning nil in a table constructor creates no key at all.) Prefer `action.show` when
  the action exists but does not apply to a given **row**; omitting it removes the action from every
  row and shrinks the strip.
- **At most ONE column may omit `width`.** That one is the auto-width column and it fills the space
  between the fixed columns. A second is now a **construction-time error naming the offending
  columns**; before, it was silently dropped -- no cell, no header, no anchor, no message. If you build
  your `columns` table at runtime (a loop, or a column behind a config check), give every appended
  column a width: the error only reaches the users whose configuration produces the second one, and
  yours may not be among them.
- **A column with no `key` is now a construction-time error naming its position (MINOR 33).** It
  already failed -- as Lua's bare `table index is nil`, from deep inside the build, with nothing in
  the traceback naming your table -- so nothing that works today starts failing; the message just
  tells you which column.
- **Two columns sharing a `key` now print one warning, and the list still draws (MINOR 33).**
  `cells[col.key]` overwrites, so only the last of them is live: the earlier column's cell stops
  being re-populated, never returns to the pool and never hides, leaving a frozen cell drawing stale
  text on every row for the life of the list. That was silent before. It **warns rather than
  raising** on purpose -- a column set is assembled at runtime from your own data, so a duplicate
  can appear in one player's configuration and in nobody else's, and taking their whole tab down
  over a stale cell would be the worse failure. One line per key per session, naming both positions
  (printed only in debug as of MINOR 39; always recorded in `W:Diagnostics()`).
- **`New` no longer writes into the `columns` table you pass** (it did before MINOR 29, widening fixed
  columns in place to fit their header text). The effective width -- scaled, and widened for the header
  -- is `rl:ColumnWidth(key)`; `col.width` stays the scale-1.0 number you wrote. A test that asserts a
  column width reads it from there, not from the table.
- **`W:Diagnostics()` -- assert in your own suite that this library reported nothing (MINOR 33).**
  Three faults are reported rather than raised, because each is in *your* code and none is worth
  killing a player's window over: two columns sharing a `key`, a RowList with rows and no room to
  draw them, and two addons setting different accents. Each appends an entry here (and, in debug,
  prints one line -- see the next item), because a printed line reaches a player who cannot act on it
  and no test can assert on a chat line. Build your windows in a spec, then `assert.equal(0, #W:Diagnostics())` -- that
  assertion, on Dibs' side, would have caught the zero-height list that cost an afternoon before
  anyone opened the game. Entries carry `kind`
  (`duplicateColumnKey` / `emptyRender` / `accentClash`), the `message` that was printed, and that
  kind's own fields (`key`/`first`/`second`, `rows`/`parentHeight`, `previous`/`replacement`).
  `W:ClearDiagnostics()` empties it; it deliberately does **not** re-arm the once-per-fault guards,
  so calling it in a `before_each` cannot turn one standing fault into a warning per example. A
  RowList with `onEmptyRender` records nothing -- you handled it, so it is not an unhandled fault.
  Gate on `type(W.Diagnostics) == "function"`.
- **Chat lines are debug-only (MINOR 39).** Every line this library prints -- the three reports above
  and the PersistWindow/DockWindow refusal -- goes to chat only when `W.config.debug` is on. It is
  off by default; the `Diagnostics()` record is kept either way. Pass `true`, or a function read at
  each report so it follows your own live toggle: `W:Configure{ debug = function() return
  MyAddon.db.profile.debug end }`. `W:IsDebug()` answers the current state (a function that raises
  counts as off). The switch is session-global like the rest of `Configure`, so any one addon in
  debug turns the lines on. Gate on `if W.IsDebug then`. **The player has the last word:** `/lagw
  debug on|off` forces it either way over every addon's setting (saved in `LibAceGUIWidgetsDB` when
  the standalone addon is installed), `/lagw debug` toggles, and `/lagw debug reset` hands it back.
  `W:SetDebug(true|false|nil)` is the same switch from code.
- **`Configure` is SESSION-GLOBAL, not per-addon.** There is one LibAceGUIWidgets in a session, so
  there is one `lib.config`: your `W:Configure{ accent = ... }` sets the accent for **every** addon
  using this library, not just yours. That is deliberate -- this is the shared toolkit for one
  suite, and the suite is meant to share one look, so a per-consumer accent was requested
  (DIBSREQ-LAGW-012) and declined. **At most one addon in a suite should set the accent.** From
  MINOR 33, a second addon setting a *different* one reports it once (printed in debug): with two
  setters the winner is decided by addon load order, which is a property of the player's
  installation rather than of anyone's code, so two players with the same addons would otherwise see
  different colours with nothing to explain it. Re-asserting the *same* accent is silent, so calling
  `Configure` on every window open stays free.
- **The default accent is the suite orange, `ffFF8000` (MINOR 36).** It was Blizzard's gold
  (`ffFFD100`) until then, so an addon that never called `Configure` drew gold header underlines,
  selection tints, tab bands and `W:Brand` text. Now no addon in the suite needs to set the accent at
  all, and one that sets `ffFF8000` anyway stays silent (the same colour is never a clash). An addon
  that wants gold back sets it explicitly. `W.DEFAULT_ACCENT` holds the value.
- **The header underline follows your configured accent (MINOR 33).** It was a hardcoded gold, which
  was then `W:GetAccent()`'s default -- so nothing changed for an addon on the default,
  and an addon that set its own accent got a header underline in it rather than in the default
  gold, matching the selection tint that already did. **This is the only visible change in MINOR 33
  for a consumer who adopts nothing**, and it needs no code change from you. Colours the library
  draws as the *client* rather than as the library -- a `GameTooltip` header, a `BindCooldownButton`
  caption, the AceGUI DatePicker's own label -- deliberately stay on Blizzard's `NORMAL_FONT_COLOR`
  and do **not** follow the accent, so your controls keep looking like the rest of the player's UI.

## For developers and AI agents

**Consume it through LibStub and feature-detect; never vendor a copy.** Two addons registering the
same widget type is resolved by AceGUI as `oldVersion >= Version` -> keep the old one, so a *tie*
is decided by load order, which neither addon controls.

```lua
local W = LibStub("LibAceGUIWidgets-1.0", true)   -- silent: nil if not installed
if not W then return end

local minor = LibStub.minors["LibAceGUIWidgets-1.0"] or 0
if W.RowList and minor >= 25 then rl:SetSort("when", true) end
```

`LibStub.minors["LibAceGUIWidgets-1.0"]` is the version to gate on. Additions are made so an older
embedded copy degrades rather than errors, which is why a `if W.MakeLabel then` style check is enough
for most helpers.

| MINOR | Brings |
| --- | --- |
| 23 | `action.show` per-row icon visibility; `BrandTabGroup` actually renders |
| 24 | Named cooldowns (`StartCooldown` / `BindCooldownButton` / ...) |
| 25 | `col.format(value, entry)`; dropdown `search`; `RowList:SetSort`; holed `actions` tolerated; a second width-less column raises |
| 26 | The resize framework: `MakeResizable` / `GetResizeHandle` / `ApplyResizeBounds`; `AttachTooltip` becomes idempotent and stops raising on non-string text |
| 27 | `onRowClick(entry, idx, rl, button, rowFrame)`; `EnableVersionCheck` keeps looking after a miss |
| 28 | `LAGW-DatePicker` + `W.DatePicker` arithmetic; `PersistWindow`; `Breathe` / `StopBreathing` / `IsBreathing`; the symbol font (`SymbolFont` / `SymbolFontSmall` / `SymbolFontPath` / `Symbol`); `AccentRGB`; shipped `Textures/` and `Fonts/` |
| 29 | The UI scale: `SetScale` / `GetScale` / `ScaledSize` / `ScaledFont` / `SetScaledSize` / `OnScaleChanged`, `SCALE_MIN` / `SCALE_MAX` / `SCALE_DEFAULT`, `Configure{ scale }`; `RowList:ColumnWidth`; every widget re-lays on a change; `New` stops writing `col.width` back |
| 30 | A second `MakeResizable` call merges into the handle instead of replacing every option; `false` removes a callback; `LAGW-DatePicker` Version 3: `SetRange` / `SetTodayFunc` / `SetRequired` / `SetFirstWeekday`, `W.DatePicker.inRange` / `clampMonth` / `today`, `grid` takes a week start; menu items `isTitle` / `disabled` / `tooltipTitle` / `tooltipText` / `keepOpen`; `ShowDialog` `cancelText = false`, `onShow` / `onHide`, Enter / Escape without an edit box; RowList stable sort, `tiebreak`, `col.sortValue`, `col.onCellEnter` / `col.onCellLeave`; `CreateCheckbox`; `DockWindow`; the floating-frame helpers `CreateFloatingFrame` / `OwnFloating` / `RegisterSpecialFrame`; the date picker's day cells widen 22 -> 26 so `Mon` and `Wed` stop clipping; `ShowDialog` returns a token as its second value and `CloseDialog(token)` closes only that prompt; the resize framework moves to `LibAceGUIWidgets-Resize.lua` (no API change) |
| 31 | `PersistWindow`'s floor follows a live scale change on every window kind (not only a `ClearFrame`) and raises the saved size with the frame; `minWidth` / `minHeight` may be a `function(scale)`; `CloseMenuFor(anchor, ...)`; `RowList:ScrollToEntry` / `SetSelected` / `GetSelected`; `## Interface` gains `16001` (World of Warcraft: Forever) |
| 32 | `PersistWindow` and `DockWindow` refuse a window the other already owns (nil, one printed line naming both calls); the ClearFrame settings gear draws a body-only tooltip; no new methods |
| 33 | `DressBottomRow` / `UndressBottomRow`, the bottom-row icon cluster; a hidden PARENT no longer closes a `ShowDialog` prompt -- its keys, its token and its `onHide` survive the window going away; a RowList column may carry `onCellClick`, whose return says whether the cell consumed the click, and `strike`, a hairline through the cell's text per entry; `CreateScrollFrame` takes `anchor` / `inset` and places both the box and its content; `CreateExplainedButton`, a button whose tooltip says why it is disabled; `CreateFormDialog`, the small officer prompt; `RowList:SetColumns`, a new column set on a live list; `AttachTooltip` keeps a disabled button's hover; a RowList with rows and no room to draw them says so once (`onEmptyRender`); `Diagnostics` / `ClearDiagnostics`, the record of everything reported, for a consumer's own suite to assert is empty; a column set is validated -- no `key` raises naming the position, two columns sharing one print a warning and the list still builds; the RowList header underline takes the configured accent instead of a hardcoded gold; `Configure` is documented session-global and routes `accent` through `SetAccent`, which reports a second, different setter once |
| 34 | `HideTooltip` (every tooltip here hands the anchor back when the pointer leaves), `ShowTooltip`, `MenuCapacity`, and `AttachTooltip`'s optional `opts.owner`; RowList `externalSort` / `onSortChanged`, `expander` and `button` columns, `entry._readonly`, the `filterable` column menu with `filterGroup` and `headerMenu`, `SetSearch` / `ClearFilters`, `autoFit`, `hyperlinks`, `Detach`, `col.align` / `gapBefore` / `sortDescDefault`, and per-list `refontHook` / `classDisplay` / `tooltipOwner`; two `SetColumns` crashes from 33 fixed -- a same-set call left the widths keyed by the old tables, and a new set raised on any text column in the client |
| 35 | `ForgetWindow`; `Release` of a `PersistWindow` window forgets it, so its floor and scale listener no longer follow the pooled frame to its next owner; the `LAGW-SearchBox` widget type; the `LAGW-Strip` layout with `NewStrip` / `StripAdd` / `StripRowWidth` / `FitCheckBox` |
| 36 | The default accent is the suite orange `ffFF8000` (was gold `ffFFD100`), with `W.DEFAULT_ACCENT`; the pool-safe widget additions `OnWidgetRelease` / `WidgetFrameScripts` / `RestoreWidgetFrameScripts` / `AttachRawFrames` / `DetachRawFrames` / `AttachWidgetTooltip`; `IsMenuOpenFor` / `IsInputFocusedIn` / `OnMenuClosed`; `Flash` / `StopFlash` / `FlashScreen`; tooltip `opts.minWidth`; `AnchorPopup`; RowList `hoverHighlight`, `sortCycle` / `col.sortNone`, `col.format`'s `width` / `measure` and `CellWidth`, `searchText` / `searchTokens`, `GetScrollOffset` / `SetScrollOffset` / `onScroll`, `ScrollToEntry`'s `ifNeeded` / `context`, group header rows and `_indent`, button-column `show` / `text` / `tip`, `iconTexCoord`, `fitContent`, drag to reorder; `ClampWindow` (now run by `PersistWindow`), `SetWindowProfile`, `SetWindowOpacity`, `SetWindowScale`, `EscapeLayer` / `DropEscapeLayer`; `CreateExpandableList` at any depth, with per-node `color` / `onClick` / `tooltip` and `IsExpanded`; `CreateStepper` and the `LAGW-Stepper` widget type; `CreateFormDialog` dropdown and item rows, `SetHint` and `anchorTo` / `SetAnchor`; `CreateSecureActionButton`; `NewDockLayout` |
| 37 | `RowList:CellFrameFor`; `CreateFormDialog` `kind = "check"` rows, `row.note`, `SetNote` and `notes`, `opts.body`, `SetBody` and `body` |
| 38 | `ShowCopyBox`, the read-only "press Ctrl+C" popup on the shared dialog, with its copy glyph (`COPY_ICON`), and the same box inline as the `LAGW-CopyField` widget type; the `LAGW-ClickBinding` widget type and `ClickBinding` / `ParseClickBinding` / `ClickBindingText` / `IsClickBinding`; `DockWindow`'s `h:Undock()` / `W:UndockWindow`, and a docked window lets go of a pooled AceGUI target on its release |
| 39 | Chat diagnostics are debug-only: `Configure{ debug }`, `IsDebug`, `SetDebug`, the `/lagw debug` slash command and the `LibAceGUIWidgetsDB` SavedVariables; `CreateFormDialog` item-row `onEnter` / `onLeave` / `onClick`; a menu pick whose `onClick` raises still closes the menu and reports the error |
| 40 | The `LAGW-Chip` widget type and `AddChips`; the `LAGW-TabStrip` widget type; a `LAGW-Strip` row with no captions takes no caption line; `AttachHeaderButton` / `DetachHeaderButton` and `ClearFrame:SetHeaderButton` (ClearFrame, GroupFrame and TLabel at widget Version 32) |

**Widget types register at Version 32** (`ClearFrame`, `GroupFrame`, `TLabel`; 32 since MINOR 40). If you are looking at
an older vendored fork of these widgets, it registers at 26 and this library wins -- which is the
point, and is pinned by `Tests/widgetversion_spec.lua`. The three move together on purpose: raising
one alone is how two of them once sat tied with the fork for an unknown length of time.
`LAGW-DatePicker` registers at Version 3 (1 before the scale, 2 before MINOR 30's range / today / required /
week start): it has no competing copy anywhere and no
legacy name to preserve, which is why it is prefixed. Gate on it with
`AceGUI:GetWidgetVersion("LAGW-DatePicker")`. `LAGW-SearchBox` registers at Version 1, for the same
reason. `LAGW-Strip` is a layout, not a widget type, and AceGUI keeps no version for layouts; gate on
`if W.NewStrip then`.

### Auditing a consumer: hand-rolled code this library already provides

**Every row below is a duplication finding** when a TOG-suite addon carries its own version. The
left column is what the hand-rolled copy looks like in the consumer's code, so a reader can recognise
it. The right column is what replaces it. Most of these features were extracted FROM a consumer, so
the original copy often still lives in the addon it came from -- ClassicCalendar's World Buff window
docking (`WorldBuff.lua`) is the source of `DockWindow` and still carries its own copy. Report it to
that addon's inbox as a finding; never edit the consumer from here.

| In the consumer you see | Use instead | MINOR |
| --- | --- | --- |
| **Windows** | | |
| `SetStatusTable(db.<window>)` per window; clamping a saved size to a floor or to the screen | `W:PersistWindow` (now also clamps on restore), `W:ClampWindow` | 28, 36 |
| A window snapped against another frame's edge, undocked by a drag, re-docked near the edge | `W:DockWindow` | 30 |
| Per-tab window sizes: fixed on some tabs, a remembered size on others, a "suppress save" flag | `W:SetWindowProfile` | 36 |
| A "window scale" setting doing `frame:SetScale` on a window | `W:SetWindowScale` (restored on Release) | 36 |
| A "background opacity" setting fading `SetBackdropColor` on a Frame and its TabGroup | `W:SetWindowOpacity` | 36 |
| A hidden proxy frame in `UISpecialFrames` so Escape closes a popup before the window | `W:EscapeLayer` | 36 |
| Overriding a container's `LayoutFinished` to pin a toolbar, list, side panel and detail panel | `W:NewDockLayout` | 36 |
| `SetResizable` + grips + `SetMinResize` / `SetResizeBounds` forks | `W:MakeResizable`, `W:ApplyResizeBounds` | 26 |
| An icon row left of AceGUI's Close button, shortening the status bar | `W:DressBottomRow` | 33 |
| A frame parented to UIParent at TOOLTIP strata, closed by a click outside or Escape | `W:CreateFloatingFrame`, `W:OwnFloating` | 30 |
| Popup placement under a row, flipped above near the screen bottom | `W:AnchorPopup` | 36 |
| **Pooled AceGUI widgets** | | |
| `SetScript` / `HookScript` / raw child frames added to an AceGUI widget's frame, undone by hand in `OnRelease` | `W:WidgetFrameScripts`, `W:AttachRawFrames`, `W:OnWidgetRelease`, `W:AttachWidgetTooltip` | 36 |
| **Lists** | | |
| A pool of row frames with manual scroll offset, banding, sort arrows or a filter menu | `W.RowList` | -- |
| Header rows in a list that hide the icon and cells; names padded with spaces to indent | RowList `_header` / `isHeader`, `_indent` | 36 |
| `_StartDrag` / `_DragUpdate` / `_StopDrag` with an insert line on a list | RowList `reorderable` + `onReorder` | 36 |
| `[Bank]` / `[AH]` text buttons per row, shown only when they apply | RowList `button` column with `show` / `text` / `tip` | 36 |
| `SetTexCoord(0.07, 0.93, 0.07, 0.93)` on row icons | RowList `col.iconTexCoord = true` | 36 |
| A list panel whose height is measured and set from its row count | RowList `fitContent` | 36 |
| Saving and restoring a list's scroll position; a manual "scroll to this entry" | RowList `GetScrollOffset` / `SetScrollOffset`, `ScrollToEntry` | 31, 36 |
| A row highlight texture shown on enter and hidden on leave | RowList `hoverHighlight` | 36 |
| A group -> child -> grandchild tree with its own expand-state table | `W:CreateExpandableList` (any depth) | 36 |
| **Controls** | | |
| `- [qty] + MAX` built from an EditBox and three buttons | `W:CreateStepper`, `LAGW-Stepper` | 36 |
| A button whose tooltip explains why it is greyed | `W:CreateExplainedButton` | 33 |
| A `SecureActionButtonTemplate` button with `InCombatLockdown` guards and a regen queue | `W:CreateSecureActionButton` | 36 |
| A small dialog with labelled fields, an error line and OK/Cancel; a dropdown or item row in it | `W:CreateFormDialog` | 33, 36 |
| A yes/no or text prompt built from `StaticPopup` or a raw frame | `W:ShowDialog` | -- |
| A bordered button that opens a picker menu | `W:CreateDropdownBox`, `W:OpenMenu` / `W:ToggleMenu` | -- |
| A search box that filters on typing; a filter row of captioned controls | `W:CreateSearchBox`, `LAGW-SearchBox`, `W:NewStrip` | 35 |
| A date field with a calendar popup | `LAGW-DatePicker` | 28 |
| **Look and feel** | | |
| `GameTooltip:SetOwner` + `SetText` + `AddLine` + `Show` for a title/body tooltip | `W:ShowTooltip` / `W:AttachTooltip` / `W:HideTooltip` | 34 |
| An alpha pulse or a one-off flash to draw the eye | `W:Breathe`, `W:Flash`, `W:FlashScreen` | 28, 36 |
| A hardcoded brand colour, or font sizes multiplied by an addon's own scale setting | `W:Configure{ accent }`, `W:SetScale` / `W:ScaledSize` / `W:ScaledFont` | 29 |
| Checking whether a menu is open or a text box has focus before redrawing | `W:IsMenuOpenFor`, `W:IsInputFocusedIn` | 36 |
| A "press Ctrl+C" popup for a link or an error line | `W:ShowCopyBox` | 38 |
| A read-only copy field inside a window | `LAGW-CopyField` | 38 |
| Letting the player choose a modifier + click ("Alt + Left Click") | `LAGW-ClickBinding`, `W:IsClickBinding` | 38 |
| A multi-select dropdown or a row of hand-made toggle buttons for on/off filters | `LAGW-Chip`, `W:AddChips` | 40 |
| Hand-built tab buttons added at runtime, or a TabGroup that runs off the edge with too many tabs | `LAGW-TabStrip` | 40 |
| A hand-built button in a window's top-right corner | `W:AttachHeaderButton`, `ClearFrame:SetHeaderButton` | 40 |

A row marked `--` has been in the library from the start. When the consumer's copy does something this
library does not, that difference is a request to this library, not a reason to keep the copy.

### Asking this library for something

If you consume it and need a widget, helper or behaviour it does not have, **do not add it from your
own repo** -- a shared library changed from inside whichever consumer happened to be open is a change
to every consumer, decided by accident. Send the request to this library's inbox (writ: `{"tool":"review",
"action":"send","to":"LibAceGUIWidgets@classic_era", ...}` -- what, why, the contract, and what you
staged meanwhile), keep whatever unblocks you inside your own addon, and say it is waiting. A
LibAceGUIWidgets session implements it, specs it, bumps `MINOR` once per release and replies on the
thread. The four additions in v0.1.11 all arrived that way, from one consumer, in one afternoon, each
adopted from the working tree within the hour. What this library asks of the WoWAPITesting harness goes
the same way, to `WoWAPITesting`.

### Running the tests

Offline, no game client, no CI, no `busted` -- a Lua 5.1 interpreter is the whole dependency:

```sh
lua Tests/wowapi/run.lua                        # the whole suite
lua Tests/wowapi/run.lua Tests/rowlist_spec.lua # one file
lua Tests/wowapi/coverage.lua LibAceGUIWidgets-1.0.lua LibAceGUIWidgets-Resize.lua \
    LibAceGUIWidgets-RowList.lua LibAceGUIWidgets-DatePicker.lua LibAceGUIWidgets-ClickBinding.lua \
    LibAceGUIWidgets.lua
```

The coverage run exits non-zero below 100% of executable lines, and every shipped file is at 100%.

The harness is the shared **WoWAPITesting** submodule at `Tests/wowapi`. Nothing under `Tests/` ships.

**Writing a spec against this library:** `Tests/rowlist_spec.lua`'s `instance()` helper builds a
`RowList` table by hand and deliberately **bypasses `New`**, so anything testing constructor behaviour
must call the real constructor -- and that needs `require("env.frames")`, because `env.wow`'s hollow
`CreateFrame` cannot build the textures `New` creates. To exercise **widget registration** you need
real AceGUI, which `require("env.libs")` plus `libs.fresh("LibAceGUIWidgets-1.0")` supplies; use
`fresh` rather than `load` so LibStub is evicted first, or the file bails at its own
`if not lib then return end` and registers nothing.

**Three traps this suite has actually paid for, worth knowing before you write a spec here:**

- **A spec's `before_each` must call `frames.reset()` ALONE.** `env.wow` owns a *hollow* `CreateFrame`
  whose every unknown key is a truthy no-op; `env.frames` replaces it with the real model at require
  time; and `wow.reset()` reinstalls the hollow one. Adding it to a `before_each` here killed
  `rowlist_spec.lua` -- a **different file, later in the run** -- with `attempt to index local 'bg'`,
  and nothing at the failure site said why. Run the whole suite, never one file.
- **A permissive stub makes the assertion vacuous.** `widgets_spec.lua`'s `AttachTooltip` block uses a
  `GameTooltip` stub that *rejects* non-strings with the client's own error message. A stub that
  accepted a table happily would have left every one of those specs green against a library that still
  raises in game.
- **Geometry is asserted from real rects** (`GetLeft`/`GetRight`/`GetTop`/`GetBottom`), never from the
  offsets that were passed to `SetPoint`. An assertion that only proves `SetPoint` was *called* proves
  nothing about where anything landed. Drive each one red before trusting it -- two of the grip specs
  were written that way, and the header/row alignment specs go red on a 2 px drift. **An unplaced frame
  answers `nil`** for all four -- a widget built by `AceGUI:Create` has no anchors until a container
  gives it some, so a spec that reads its rect must `SetPoint` it first or every rect assertion is
  arithmetic on nil.
- **Pin the clock in local time.** The harness epoch defaults to 2026-01-01 00:00 **UTC**, which is
  2025-12-31 in every zone west of Greenwich, so "today is in January" is true on a UTC box and false
  here. `datepicker_spec.lua` sets `wow.epoch = time{ year=, month=, day=, hour = 12 }` per test and
  builds every expected value with the same `time{}`, so the box's zone cancels out.
- **A shared frame outlives the test that opened it.** The DatePicker popup and the menu frames live on
  the library table, not the spec; one test leaving the popup shown left it registered for
  `GLOBAL_MOUSE_DOWN`, and the next test's `frames.fireEvent` was delivered to two frames. Hide it
  before dropping the reference (`if W._datePopup then W._datePopup:Hide() end`), then nil it.
- **Drive the "client has it" branch by making the model say so.** `SetTexture` answers nothing
  offline, so the DatePicker's real-texture branch was uncovered until one example wrapped the model's
  `SetTexture` to return `true` for a single construction (`symbolfont_spec` reads the shipped `.ttf`'s
  cmap for the same reason: prove the file, not the path).
- **`libs.fresh` gives your file its own library table; AceGUI's registry does not follow.** The
  constructors an EARLIER file's instance registered stay in `AceGUI.WidgetRegistry` (the `< Version`
  guard keeps them), and they close over THAT instance -- so a widget built through `AceGUI:Create` in
  your file carries the other instance's state. `scale_spec.lua` measured every widget ignoring
  `W:SetScale` for exactly this reason; `ace.fresh("AceGUI-3.0")` before `libs.fresh(...)` empties the
  registry so your instance is the one that registers.
- **A colour texture is read back with `GetColorTexture`, not `GetVertexColor`.** The model stores
  `SetColorTexture` in its own slot and `GetVertexColor` does not read it, so a spec asserting the
  selection tint through `GetVertexColor` sees `1 1 1` and fails against correct code
  (`Tests/wowapi/env/frames.lua:980-987`). The RowList selection spec paid for this.
- **Adding a library FILE is two edits, not one, and the second is easy to miss.** A new satellite needs
  a line in the harness's own manifest (`Tests/wowapi/env/libs.lua`, which only a harness session may
  write -- ask on the `harness` channel) so that `libs.load` / `libs.fresh` pick it up. But **six specs
  here load the library by path** with `wow.loadAddonFile` and the manifest does nothing for them:
  `breathe`, `cooldown`, `symbolfont`, `rowlist`, `resize` and `widgets` each need the new file added by
  hand, in TOC order. Moving the resize framework into `LibAceGUIWidgets-Resize.lua` at MINOR 30 hit
  exactly this -- `resize_spec` would have failed on `MakeResizable` being nil, its whole subject having
  moved out from under it. The reverse is also worth knowing: the `libs.load` specs need no change, so
  **their** passing is what tells you the manifest line actually landed.
- **The model accepts scripts the client refuses.** `SetScript("OnClick", ...)` on a FontString or a
  plain Frame is silent here and raises in the client (`Doesn't have a "OnClick" script`). That let a
  `SetColumns` crash ship in MINOR 33 with every spec green; ItemDB found it in game. Where a path
  touches scripts on a mixed pool of frames, make the cells in your spec raise the client's error
  themselves -- `rowlist_minor34_spec.lua` does -- rather than trusting the model to.
- **The harness loader RAISES on a listed file it cannot read**, so the file must exist before the
  manifest names it -- never the other way round, or every consumer suite that loads this library breaks,
  not just this one.

### Peer review and contracts

Findings, requests and harness deliveries travel as writ inbox documents: read with
`{"tool":"review"}`, answer with `action:"reply"`, close with `action:"state"`. Three append-only
markdown boards did this job until 2026-09-17 -- `docs/AUDIT.md` (peer review), `docs/LIBRARY_CONTRACTS.md`
(what consumers asked of us) and `Tests/HARNESS_CONTRACT.md` (what we asked of the harness). **They were
deleted that day**: their items and answers are in the inbox, their reasoning is in this repo's writ bank,
and everything since arrives on the desk. Older `CHANGELOG.md` entries still name them, as history.

**A defect is a finding; a gap is a contract.** A finding names a `file:line` that is wrong today. A
contract names a call you want to be able to make tomorrow. Something the *test harness* cannot do is
neither -- it goes to the harness's inbox, never fixed by editing `Tests/wowapi`, which is a submodule
checkout whose edits the next pull discards. A session's own self-audit is a request for peer review:
it goes on the `audit` channel **to Peer Review**, never to this workspace's own inbox. The v0.1.11
one (`a7e1cb7d`) found and fixed a real `PersistWindow` defect before release, and the MINOR 34 one
(`af2ebd61`) found three crashes and stale-data bugs in the working tree before it shipped, which is
what the exercise is for.

## Addon-agnostic theming

The library owns structure and styling; each consumer supplies its own identity. Every field is
optional. The accent already defaults to the suite orange `ffFF8000` (MINOR 36), so a suite addon
leaves it out:

```lua
local W = LibStub("LibAceGUIWidgets-1.0")
W:Configure{
    accent       = "ffFF8000",               -- optional; the default. Session-global -- see above
    tooltipOwner = function(frame) --[[ anchor GameTooltip ]] end,  -- optional
    classColors  = { WARRIOR = "ffc79c6e" }, -- optional; falls back to RAID_CLASS_COLORS
    classDisplay = function(classFile) return coloredName end,  -- optional; col.classDisplay cells
    refontHook   = function(fontString, fontObject) end,        -- optional; re-font a cell after text
    scale        = MyDB.global.uiScale,      -- optional (MINOR 29); the same as W:SetScale
}
```

`Configure` is **session-global** (see above): a hook set there reaches every addon's widgets. For a
RowList, pass `tooltipOwner`, `refontHook` and `classDisplay` to `W.RowList:New` instead (MINOR 34);
they apply to that list only and override the global ones.

Compose with **LibLocaleOverride** for localized tab/dropdown fonts and widget
recycling — this library does not duplicate those helpers.

## Requirements

- **Ace3** (for AceGUI-3.0). **VersionCheck-1.0** is optional — it powers the shared
  out-of-date reminder via `W:EnableVersionCheck`; absent, that's simply a no-op.

## Credits & License

- **Author:** Pimptasty. Widget code extracted and decoupled from FastGuildInvite.
- [MIT](LICENSE) © 2026 Pimptasty
