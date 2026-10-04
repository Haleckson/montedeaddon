# Lib: Graph-2.0

<!-- charset-ok: ships in the zip but is never drawn by the game client -- it is read on GitHub and the CurseForge page, both browsers. -->

Line graphs, filled area graphs, scatter plots with linear regression, scrolling realtime bar graphs, and pie charts for WoW addons. A `LibStub` library.

**Nothing in the drawing code has a dependency** — embed the folder and it works with LibStub alone. The **standalone addon** declares `Ace3` and `VersionCheck-1.0`, which exist only so the standalone install can tell you when it is out of date; see [Version checking](#version-checking).

Works on Classic Era, TBC Classic, Wrath Classic, Cataclysm Classic, MoP Classic, Retail, and WoW Forever.

This is the maintained continuation of Cryect and Xinhuan's original library (GraphLib, SVN r68), published as one shared copy so the addons that embed it stop drifting apart.

## Quickstart

```lua
local Graph = LibStub("LibGraph-2.0")

local g = Graph:CreateGraphLine("MyGraph", UIParent, "CENTER", "CENTER", 0, 0, 300, 200)
g:SetXAxis(0, 60)
g:SetYAxis(0, 5000)
g:SetGridSpacing(10, 1000)
g:AddDataSeries({ {0, 1200}, {15, 3400}, {30, 900}, {45, 4100}, {60, 2600} }, {1, 0, 0, 1})
```

`CreateGraphLine` returns an ordinary `Frame` with the graph methods attached, so it positions, parents, sizes and hides like any other frame. It redraws itself on its own `OnUpdate`; `ResetData()` clears the series.

Swap `CreateGraphLine` for `CreateGraphScatterPlot`, `CreateGraphRealtime` or `CreateGraphPieChart` for the other three types — the signature is identical.

## Embedding it

Add the folder to your addon's `Libs` directory and load the Lua file from your TOC before anything that uses it:

```text
Libs\LibGraph-2.0\LibGraph-2.0\LibGraph-2.0.lua
```

The nested folder is not a mistake: the library finds its own textures by parsing `debugstack`, so the `.lua` must sit in the same directory as the `.tga` files. Do not flatten it.

If you use the BigWigs packager, add it to your `.pkgmeta` as an external instead of vendoring a copy by hand.

**An embedded copy needs nothing else.** `Ace3` and `VersionCheck-1.0` are declared by the standalone addon's TOC, which an embedded copy never loads, so embedding does not drag them in.

## Version checking

The **standalone addon** registers itself with [VersionCheck-1.0](https://www.curseforge.com/wow/addons/versioncheck-1-0), which does one batched guild-wide check at login and pops a single alert if a guildmate is running a newer copy. That is what `## Dependencies: Ace3, VersionCheck-1.0` is for — VersionCheck needs Ace3's AceComm and AceSerializer and does not embed them, and CurseForge installs both automatically.

**An embedded copy deliberately does not register**, and the gate is `GetAddOnMetadata("LibGraph-2.0", "Version")` returning a real version — non-nil only when a genuine addon folder of that name is installed. Two reasons:

- A copy loaded from inside `Recount/libs/` is not an addon the client has metadata for, so it would report its version as unknown.
- It could not act on the answer anyway. An embedded copy is updated when its host is, so telling the player their LibGraph is out of date is advice with nothing behind it.

A working copy straight from git is also skipped: the TOC ships `## Version: LibGraph-2.0-v2.0.8` and only the packager substitutes it, so an unpackaged copy would otherwise broadcast the literal placeholder.

Nothing about this touches the drawing API, and there is no host-side call to make — `VersionCheck-1.0` is not a dependency of embedding.

## What this copy adds over stock

| | |
| --- | --- |
| `graph.LabelHook` | Set it to a function and it is handed each axis label's `FontString` after the text is set and before it is shown — enough to substitute a locale's own digits, or apply a font that can draw them, without the library knowing anything about localisation. |
| `graph.XLabelsEnabled` | Set it to `true` and a line graph labels its X gridlines along the bottom, on the same spacing the gridlines use, skipping the rightmost so it cannot run off the edge. The original labelled only the Y axis. |
| `minor` bumped `+2000`, and rising per release | Every consumer embeds its own copy and LibStub loads whichever registers the highest minor. Without the bump, an addon shipping a stock copy would win the load race and the two additions above would silently not exist. It is `+2000` rather than `+1000` because LibStub refuses an _equal_ minor, and `+1000` tied an existing private fork that still carries the Retail 12.0 crash — the bands are `+0` stock, `+1000` a private fork, `+2000` this shared copy. The revision after the band is this copy's own release counter (upstream's SVN stopped at 68; v2.0.8 is 69), so a newer release also outranks an older copy of _itself_ that another addon bundles. |

```lua
graph.LabelHook = function(fontString)
    fontString:SetText(MyLocale:Digits(fontString:GetText()))
    fontString:SetFont(MyLocale:FontPath(), 10)
end
graph.XLabelsEnabled = true
```

## API

Four constructors, all with the same signature `(name, parent, relative, relativeTo, offsetX, offsetY, width, height)`:

- `lib:CreateGraphLine` · `lib:CreateGraphScatterPlot` · `lib:CreateGraphRealtime` · `lib:CreateGraphPieChart`

Data:

- **Line / scatter** — `AddDataSeries(points, color, n2, lineTexture)`, `AddFilledDataSeries(points, color, n2)`, `ResetData()`
- **Realtime** — `AddTimeData(value)`, `AddBar(value)`, `GetValue(time)`, `GetMaxValue()`
- **Pie** — `AddPie(percent, color)`, `CompletePie(color)`, `ResetPie()`, `SetSelectionFunc(fn)`

Both series functions take **two shapes**, and `n2` picks between them:

```lua
g:AddDataSeries({ {0, 1200}, {15, 3400} }, color)              -- a list of {x, y} pairs
g:AddDataSeries({ {0, 15}, {1200, 3400} }, color, true)        -- two parallel arrays: {xs, ys}
```

With `n2` omitted the shape is inferred, and the guess is only reliable when the table is not
exactly two elements long — pass `true` explicitly for the parallel-array form.

The table is stored **by reference and not copied**, so do not mutate it after handing it over.
It must be a proper sequence: a hole makes the graph stop drawing at the gap, which looks like a
shorter line rather than an error. Since v2.0.7 the library prints one chat line naming the call
that was given the bad table, once per graph per entry point.

Axes and scaling:

- `SetXAxis(min, max)`, `SetYAxis(min, max)`, `SetYMax(max)`, `SetMinMaxY(value)`
- `SetAutoScale(bool)`, `LockXMin(bool)`, `LockXMax(bool)`, `LockYMin(bool)`, `LockYMax(bool)`

Gridlines, colours and labels:

- `SetGridSpacing(x, y)`, `SetGridSecondaryMultiple(x, y)`, `SetAxisDrawing(x, y)`, `CreateGridlines()`
- `SetAxisColor(color)`, `SetGridColor(color)`, `SetGridColorSecondary(color)`, `SetBarColors(bottom, top)` — colours are `{r, g, b, a}` tables
- `SetYLabels(left, right)`, `SetLineTexture(texture)`, `SetBorderSize(border, size)`

`SetBorderSize("LEFT"|"RIGHT"|"TOP"|"BOTTOM", size)` replaces the automatic 10% autoscale margin on
one edge. **Mind the sign — it is not symmetric.** The size is _added_ to the data extreme on every
edge, so a positive value widens the axis at the **top and right** but moves it _inward_, cropping
the data, at the **bottom and left**. Pass a negative number on those two. This is the original
library's behaviour and is kept deliberately so any copy of LibGraph-2.0 renders a graph identically.

Realtime tuning and fitting:

- `SetMode(mode)`, `SetFilterRadius(r)`, `SetDecay(d)`, `SetUpdateLimit(seconds)`
- `SetLinearFit(bool)`, `LinearRegression(data)`, `RefreshGraph()`

| Realtime mode | What it does |
| --- | --- |
| `"FAST"` | Default. Scrolls by whole bars and convolves only the newly exposed ones. Cheapest. |
| `"SLOW"` | Rebuilds every bar from the raw samples each frame. Smoothest, most expensive. |
| `"EXP"` | Exponentially decaying running value, recomputed per bar. |
| `"EXPFAST"` | As `EXP`, but the running total is computed once and scrolled. |
| `"RAW"` | Does nothing until `AddBar` is called — you push bars yourself, no time convolution. |

`graph.Filter` is a **field, not a setter**: `"RECT"` (default) or `"TRI"` for a triangular
weighting. It applies to `FAST` and `SLOW` only.

**Stop feeding a realtime graph you have hidden.** `AddTimeData` appends one sample and bounds
nothing; samples are reclaimed only by the graph's own per-frame update, and the game does not run
that on a hidden frame. A feed left running against a hidden graph allocates until it stops. Unhide
it, stop the feed, or call `ResetData()`. Recount is the reference here — it unregisters its
tracking callback when a realtime window closes. If you get this wrong the library tells you: the
first time a graph that is not visible passes 10,000 retained samples it prints one chat line naming
the cause and those two remedies, once per graph, and changes nothing else.

Drawing primitives, usable on any frame without creating a graph:

- `lib:DrawLine(frame, sx, sy, ex, ey, width, color, layer, texture)`, `lib:DrawVLine(frame, x, sy, ey, width, color, layer)`, `lib:DrawHLine(frame, sx, ex, y, width, color, layer)`
- `lib:DrawBar(frame, sx, sy, ex, ey, color, level)`, `lib:HideLines(frame)`, `lib:HideBars(frame)`

`DrawBar`'s optional `level` puts the bar in a sub-frame at `frame:GetFrameLevel() + level`, and
lifts the frame's `TextFrame` above it if that would bury the text. Omit it and the bar is drawn on
the frame itself.

Every texture these produce is pooled and reused, so a graph that redraws each frame does not leak.
`HideLines` / `HideBars` return them to the pool rather than destroying them, and the graph types
call these for you on each refresh.

## Development

Not shipped in the zip — `Tests`, `tools` and `docs` are excluded by `.pkgmeta`.

- **Offline test suite** — `lua Tests/wowapi/run.lua` from the repo root, with only a Lua 5.1 interpreter. No busted, no CI. `Tests/wowapi` is the shared [WoWAPITesting](https://github.com/Pimptasty/WoWAPITesting) harness as a git submodule; clone with `--recurse-submodules`.
- **Coverage** — `lua Tests/wowapi/coverage.lua LibGraph-2.0/LibGraph-2.0.lua`.
- **`lua tools/check-minor-band.lua`** — run before a release. It reads the installed AddOns tree and exits non-zero if any other copy of LibGraph-2.0 ties or beats this one's `minor`, which is the one thing the suite cannot check: LibStub refuses an _equal_ minor and the losing copy bails silently, so a lost load race looks exactly like a successful one.
- **Peer review and harness contracts** — carried by writ's inbox, not by files in this repo. The former `docs/AUDIT.md` and `Tests/HARNESS_CONTRACT.md` boards were imported and removed on 2026-09-20; git history at `f155fe7` holds them as last committed.

## Licence

Three bodies of work, three sets of terms — read [LICENSE](LICENSE) before redistributing:

- The **original library** (Cryect, Xinhuan) is **All Rights Reserved** to its authors.
- **Maintenance from v2.0.6 onward** (Pimptasty) is **MIT**.
- **`LibStub.lua`** is **public domain**.

## Links

- [Changelog](CHANGELOG.md)
- [Discord](https://discord.com/invite/bY2R5TmBSz)
