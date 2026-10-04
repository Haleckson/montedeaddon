# Lib: Graph-2.0

<!-- charset-ok: never drawn by the game client -- published as the GitHub release body and on the CurseForge page, both browsers. -->

## [v2.0.8] (2026-09-20) — A hidden-feed diagnostic, WoW Forever, review round 7, and a minor that moves with every release

### New — a hidden realtime graph that is still being fed says so, once

v2.0.7 documented the hazard and stopped there. Review (round 7) asked for more than documentation
and less than a bound: a documented invariant is a rule placed where the person who breaks it is not
looking — the consumer that forgot its unregister is by definition not reading the `AddTimeData`
comment — while a cap or an ingest-side prune would change what every consumer draws and duplicate
the window arithmetic that lives in one place. And the bug-for-bug rule does not protect unbounded
retention, because nothing on the public surface lets a consumer observe a retained sample: the
convolution prunes to the window before drawing, so a change nobody can observe is not a semantic
change.

So `AddTimeData` now counts. The first time a graph holds more than 10,000 samples **while it is not
visible** — `IsVisible()`, so a hidden ancestor counts, because that is exactly when the client stops
running the `OnUpdate` that would prune — it prints one chat line naming the cause and the two
remedies (stop the feed, or `ResetData`), and does nothing else. It removes nothing, so no drawing
changes; it reads no window, so the prune arithmetic is still in one place; and it reports once per
graph, never re-armed, for the reason the sparse-series warning does. The ceiling is a sanity bound,
not a window — a visible graph never warns however much it holds, because a ticking graph prunes on
its own.

Five specs: warns once naming the cause; stays at one line however long the feed continues; silent
for a visible graph past the ceiling; silent for a hidden graph under it; and a hidden _parent_ counts
as hidden. Mutation run: disabling the check turns exactly the three warning specs red and leaves
274 green. The 500-sample "bounds nothing" spec is unchanged and still true.

### New — a TOC for World of Warcraft: Forever

`LibGraph-2.0_Camelot.toc`, `## Interface: 16001`, with exactly the `_Mainline` file list. Forever
(Battle.net product `wow_classic_beta`, codename Camelot) is the retail client running Classic-era
content, and the client reads `<Addon>_Camelot.toc` ahead of `_Mainline` — so without one, an addon
that hard-depends on this library does not load there at all. FastGuildInvite v2.14.0 is that addon,
and this was raised from its workspace on 2026-09-20. A drawing library has nothing Forever-specific
in it: the code path is the retail one it already runs. Not run in a Forever client — there is no
Forever install on this box — and the same `16001` TOC shape went through the packager and
CurseForge without error for FastGuildInvite, which is the only evidence there is.

### New — a flavour spec, so six of seven TOCs are no longer exercised by nothing

`Tests/flavour_spec.lua` loads the library on every flavour the harness models — Classic Era, TBC,
Wrath, Cata, Mists, Mainline — plus Forever's build (Mainline project, Interface 16001), and on each
one registers at the shared minor, builds all four graph types, draws through each, and takes the
`SetGradient` branch of the one feature-detect the library has. Twenty-nine specs. What it proves is
that the library has no flavour-dependent path, which is what "one source" needs; what it cannot
prove is that any client other than the one the harness models draws it the same, and the file says
so. It also puts the flavour back to Classic Era afterwards and asserts that it did, because the
suite shares one Lua state and a spec that switches flavour and does not switch back breaks every
file after it.

### Changed — the library's minor is `92069`, and from now on it moves with every release

`+2000` beats every stock copy and every private fork, which is what it was for. It cannot beat an
older release of _this_ copy, and on 2026-08-25 Recount re-vendored this library at exactly
`92068` — the same number v2.0.7 shipped with, since the revision never moved. So the moment this
release changed behaviour, two copies with different code shared one minor and LibStub let load
order pick between them (alphabetical: the standalone wins where both are installed, Recount's copy
wins where only Recount is). Found by `tools/check-minor-band.lua` on 2026-09-20 and filed as
peer-review F1: a fork that wins every race owes the field a distinct minor for every distinct
behaviour, its own earlier releases included.

So upstream's dead `$Revision$` keyword is now this copy's release counter: r69 is v2.0.8, and each
release that changes behaviour bumps it in the same change. The spec fixture that records the
minors the number has to clear now lives in one place (`Tests/helper.lua`) — until today
`libgraph_spec.lua` kept its own copy and nothing read the helper's, so a bump would have moved one
and not the other. Recount's vendored copy stays at `92068` until Recount next re-vendors, and loses
the race to this one by design in the meantime.

### Changed — the `SetBorderSize` usage assert is back to upstream's wording

v2.0.7 extended it with the sign rule, on the theory that the assert was the one diagnostic a
sign-confused caller sees. Review (finding 7) showed it is not: a caller who passes a positive LEFT
hits the `"left"` branch and returns `true`, so the usage assert is unreachable for exactly the
reader it was written for — only a wrong edge name reaches it. A positive LEFT is a legal call with
a defined meaning, so no runtime diagnostic can tell "meant to crop" from "got the sign wrong"; the
comment on the function is the only place the rule can live, and it stays. The string is upstream's
again so the three-way diff against the other forks stays clean. No spec asserted the message.

### Changed — the test harness pin moved from `1f8fe09` to `69c727d`

Twenty-six days of harness deliveries, including the two this library asked for: `StatusBar` gained
`SetOrientation` / `GetOrientation`, and `Region:IsMouseOver` exists. The first is now doing the
work the local stand-in did, and that half of `Tests/env_local.lua` is gone. The second could not be
adopted the way it was meant to be: the harness's `IsMouseOver` is a constant `false` — "no cursor
offline" — so a stand-in written to fill in only where the method was absent stopped firing, and
seven pie-chart hover specs went red with the selection callback never called. The stand-in is now
an override, labelled as one, and a contract asks the harness to answer `IsMouseOver` from the
cursor position it already holds. Suite 272 passing on the new pin; line coverage 98.10%, the same
29 dead-code lines as before. Dev-only; nothing in the shipped zip changes.

### Fixed — a demo spec that passed or failed on garbage-collection timing

`demo_spec.lua`'s "leaves the realtime demo fed by its own OnUpdate driver" searched the harness's
object registry for the demo's driver frame — a bare `CreateFrame("Frame")` referenced by nothing but
its own `OnUpdate` closure. The registry holds weak references, so a collection between the demo and
the search removed the frame and the test went red on a run where only comments had changed. In the
client a frame is engine-owned and never collected; the harness models that through
`frames.retainDuring`, which pins at creation, and the spec now runs the demo inside it. Dev-only.

### Changed — one language-server rule is disabled for the library file, and it is said out loud

`need-check-nil` is off for `LibGraph-2.0/LibGraph-2.0.lua` only, by a `---@diagnostic` line at the
top with the reason beside it. The WoW API annotations type `CreateFrame`'s return as nilable, so all
four constructors, the realtime bar loop and the demo lit up thirty-one warnings on lines upstream
wrote and every consumer of this library relies on — the client does not return nil from
`CreateFrame` for a valid frame type. Guarding thirty-one upstream lines would be noise in every
future three-way diff against the other forks. The specs guard their own `CreateFrame` results and
keep the rule on. Dev-only; the client never reads the directive.

### Removed — the two review boards, now that writ carries the conversation

`docs/AUDIT.md` and `Tests/HARNESS_CONTRACT.md` were the append-only files a peer-review session and
the test harness wrote into, and they had the flaw v2.0.6 warned about: a reply only reached a reader
who happened to be watching the file. Both boards' last blocks — the harness's 2026-08-28 delivery
and the reviewer's round 7 — sat unread for 23 days for exactly that reason. On 2026-09-20 every item
on both was imported into writ's inbox (eleven findings, two contracts; five findings that had been
answered far below their heading were closed by hand), the two still-open items went onto the todo
list, and the files were deleted. Git history at `f155fe7` holds both files as last committed; the
two blocks written after that commit were never committed and now exist only in writ. Code comments
that cite `AUDIT.md finding N` still mean that history. Dev-only; nothing in the shipped zip changes.

## [v2.0.7] (2026-08-25) — The realtime graph dropped only half its stale samples

### New — the standalone addon now tells you when it is out of date

All six TOCs declare `## Dependencies: Ace3, VersionCheck-1.0`, `.pkgmeta` lists both under
`required-dependencies` so CurseForge installs them alongside this addon, and the library registers
itself with [VersionCheck-1.0](https://www.curseforge.com/wow/addons/versioncheck-1-0) — which runs
one batched guild-wide check at login and pops a single alert if a guildmate is on a newer copy.
Ace3 is there because VersionCheck needs its AceComm and AceSerializer and does not embed them, not
because any drawing code uses Ace3.

Those two lists have to agree and nothing checks that they do: the TOC line decides whether the
addon **loads**, the `.pkgmeta` line decides what gets **installed**. A slug in one and not the
other is a dependency the player never receives, or an addon that silently refuses to load.

**An embedded copy does not register, and that is the load-bearing half.** This file ships inside
other addons' `Libs` folders, and a copy loaded from there is not an addon the client holds metadata
for — it would report its version as unknown, and could not be updated on its own even if the report
were right. So registration is gated on `GetAddOnMetadata` returning a real version for an addon
folder actually named `LibGraph-2.0`, which is true of the standalone install and nothing else. A
working copy straight from git is skipped too, since its version is still the packager's
`LibGraph-2.0-v2.0.8` placeholder and broadcasting that would be worse than staying quiet.

**Embedding is unaffected.** An embedded copy never loads this TOC, so it pulls in neither Ace3 nor
VersionCheck, and the drawing code still depends on nothing but LibStub. There is no host-side call
to add.

Six specs cover it, and three of them assert that nothing happens — removing the gate turns exactly
those three red.

### Fixed — five prune loops removed from a table while iterating it

`OnUpdateGraphRealtime` ages old samples out of `self.Data` in five places — SLOW/RECT, SLOW/TRI,
FAST/RECT, EXP and EXPFAST — and every one of them did it as `for k, v in pairs(self.Data) do …
tremove(self.Data, k) … end`. `tremove` shifts every later element down one while the iterator
counts up, so the element that slides into the vacated slot is never visited.

**This is not undefined behaviour, and the distinction is the whole explanation.** The Lua 5.1
manual makes `next` undefined only if you assign to a _non-existent_ field, and then says: _"You may
however modify existing fields. In particular, you may clear existing fields."_ `tremove` shifts
existing fields and clears the last, so the traversal was explicitly permitted. What it is instead
is a **deterministic** shift-versus-increment race — which is why the loss is exactly half rather
than arbitrary. Undefined behaviour has no signature; this one does.

**Measured, with a backlog of six stale samples: three survived.** Exactly half, in SLOW/RECT,
SLOW/TRI and EXPFAST. EXP escaped only because its outer per-bar loop re-runs the prune enough
times to clear up after itself.

All five now walk the table backwards with a numeric `for`, so a removal only affects indices
already passed. Every accumulation in those loops is a sum, so visiting in reverse changes nothing
else.

The consequence in game was never a crash: `self.Data` only grows while a feed is live, and a
leaked sample keeps contributing to the convolution — so a busy realtime graph plausibly read a
little high and held values a little too long. That part is not demonstrated and is not claimed.

**Every prune path was already covered and already green.** The four existing specs each dropped
exactly one sample, which cannot expose this — there is no following element to skip. Coverage said
the lines ran; it could not say an assertion would notice the traversal going wrong. Four new specs
drive the bulk case and go red without the fix.

### Changed — four loops that needed an order were asking for one that is not promised

Four `pairs` loops iterate sequences where the **order is the meaning**, not a convenience:

- `AddPie` and `CompletePie` walk the slice textures halving the piece size each step, so they are
  only correct largest-piece-first.
- `RefreshLineGraph` chains a segment from each point to the next, for both line and filled series
  — the sequence order _is_ the graph.

The Lua 5.1 manual is explicit: _"The order in which the indices are enumerated is not specified,
**even for numeric indices**. (To traverse a table in numeric order, use a numerical `for` or the
`ipairs` function.)"_ That "even for numeric indices" is the sentence that removes the it-is-a-plain-
array defence, and the parenthesis names the remedy. `pairs` walks an array part in order in
practice, which is why this has always drawn correctly — the code was relying on an implementation
detail to draw a graph. All four are now `ipairs`, which states the requirement.

### New — a sparse data series is diagnosed at ingest instead of drawn short

`AddDataSeries` stores the caller's points table by reference and never checked it was dense, so a
consumer building points with explicit indices, or from a filtered source that skips entries, could
hand the library a table with a hole. Neither drawing behaviour was a diagnosis: the old unordered
walk drew every point chained arbitrarily — a visible scribble — and the ordered walk draws a
**clean, plausible, shorter line**, which is worse, because the graph looks correct and is missing
data.

Both entry points now compare a counted walk against the length and **warn**, naming which call was
given the bad table, before storing it — **once per graph per entry point**, not once per call.
`AddDataSeries` is half the reset-then-re-add refresh idiom, so a chart redrawing on a timer would
otherwise produce one chat line per refresh, forever, naming a function the player never called. It
is deliberately not re-armed by `ResetData`, because that reset _is_ the refresh cycle.

**It warns rather than refuses because refusing would not fix anything.** The rendering outcome for
a sparse series is truncation either way — the ordered walk stops at the hole whatever
`AddDataSeries` decided earlier. So the choice was never refuse-or-truncate, it was **truncate
loudly or truncate silently**; a refusal would replace a quiet wrong picture with a hard error and
_still_ not draw the missing points.

Raised in review, which also corrected the spec that pinned truncation as the _correct_ rendering of
a sparse series. It is the **chosen** behaviour for malformed input, and the spec now says so.

**The first version of this check was blind on the one form real consumers use, and that is the
fourth time the same mistake has been found here.** Both entry points accept two shapes: a list of
`{x, y}` pairs, and two parallel arrays (`{times, values}`, the `n2` form). On the `n2` form the
library **rebuilds** the series by walking `points[1]` with `ipairs` — so the table it hands on is
dense by construction whatever went in, and the tail past a hole is dropped on that line. The check
inspected the rebuilt table, so it could never fire there however sparse the caller's data was. Both
entry points now check `points[1]` _before_ the rebuild, and the message names which array it is.

This matters because `n2` is not the exotic form. Reading the two live consumers on this machine:
**Details never calls `AddDataSeries` at all** — its framework draws with `DrawLine` directly
(`Details/Libs/DF/panel.lua:2916`) — and **Recount passes `n2` at all four of its call sites**
(`GUI_Graph.lua:497`, `:571`; `GUI_CompareGraph.lua:313`, `:403`). So the diagnostic was armed only
on the shape nobody passes. Neither addon builds a sparse table — Recount's arrays are appended
densely and decimated with `table.remove` in lockstep (`GUI_Graph.lua:73-146`, `:148-192`) — so this
is a latent gap rather than an observed failure, and that is all it is claimed to be.

Four specs, none of which the suite had: every existing sparse spec drove the list-of-pairs form.
Removing the fix turns the two warning specs red and leaves the other 260 green — including the one
that pins the truncation itself, which is the cost the warning reports and is present either way.

### Fixed — two defects in `DrawBar`, both reachable only through the public drawing primitive

`DrawBar` is reached two ways, and `self` means something different on each: internally it is called
as `self:DrawBar(self, …)` where `self` is the graph, and publicly as `lib:DrawBar(frame, …)` — the
documented primitive — where `self` is the library table shared by every graph in the install.

**The redraw request went to the wrong object.** When a bar's level would bury the graph's text, the
library lifts the text frame and asks for a re-render. That request was addressed to `self`, so on
the public path it set a field on the shared library table that nothing anywhere reads: the lift
happened and the re-render never came. It now asks the frame being drawn into, which is the same
object on both paths.

**A recycled bar kept the parent of whoever used it last.** The pool returns a bar with `Hide()`
alone and never restores its parent, while the parent was only ever set when a level was given. So a
levelled bar, once recycled, would be drawn by an _unlevelled_ call at the level the previous caller
happened to use — a wrong frame level chosen by pool order. Bars now return to the frame they were
drawn into when no level is asked for.

Neither is reachable from inside the library, which always passes a level — so no existing graph
renders differently. Both are pinned by specs that go red without the fix.

### Changed — feeding a hidden realtime graph is now a documented hazard instead of an undocumented one

`AddTimeData` appends one table per sample and bounds nothing. The only code that ever removes an
entry is the prune inside the graph's own per-frame update — and the client does not run `OnUpdate`
on a hidden frame. So a consumer that keeps feeding a **hidden** realtime graph allocates for as
long as the feed runs, with nothing able to reclaim it: the graph that would prune is the graph that
is not ticking.

Recount, the realtime consumer this was checked against, is safe by its own discipline rather than
by anything the library does — it unregisters its tracking callback when a realtime window closes,
so the feed stops with the window. That is a consumer holding an invariant the library never stated.

**No cap was added**, for the same reason the `SetBorderSize` sign was left alone: a bound would
silently change what every existing consumer's graph draws, and winning LibStub's race means they
cannot decline that by shipping their own copy. The invariant is now written on the function, in the
API documentation, and pinned by a spec that drives 500 samples through a graph that never updates
and finds all 500 still there.

Distinct from, and adjacent to, the idle-prune behaviour raised in review: **that** one is bounded
and self-healing — nothing new arrives, and the first sample after a silence prunes normally — so it
is deliberately unchanged.

### Changed — `SetBorderSize`'s sign is now documented where a developer will actually hit it

`SetBorderSize(edge, size)` replaces the automatic 10% margin on one edge, and every edge is applied
as `extreme + size`. The default it replaces is **not** symmetric — `XMin` and `YMin` subtract while
`XMax` and `YMax` add — so a positive size widens the axis at the **top and right** and moves it
**inward, cropping the data, at the bottom and left**. The same parameter means opposite things on
opposite edges.

**The behaviour is unchanged and will stay unchanged.** It is upstream's, and the `+2000` band is
what makes leaving it correct rather than merely convenient: winning LibStub's race in every install
removes every other consumer's ability to _decline_ a behaviour change by shipping their own copy. A
fork that wins every race owes the field bug-for-bug compatibility on everything except the bug it
forked to fix.

What was wrong was that the rule was written down in the CurseForge store listing — read by players
deciding whether to install, and by nobody integrating the library — while the function itself said
nothing, and its usage assert named the four edges and was silent on sign. A developer who passes
`10` for LEFT, sees their data cropped and goes looking would read the function, then the error, and
find the explanation in neither. The rule is now in a comment on the function, and the assert says
that LEFT and BOTTOM need a negative size.

### New — `tools/check-minor-band.lua`, because the spec that "pinned" the band could never fail

The suite asserted that this copy's `minor` beats every other LibGraph-2.0 installed. It did that by
comparing a constant against three **hardcoded** constants — the copies measured on 2026-08-25 — so
it could not fail, could not notice anything, and would pass forever. Its name claimed to watch a
live, changing fact; its assertion was a claim about one day.

That gap has teeth: if another addon's private fork is bumped above ours, LibStub hands it the load
race, this library's body never runs, and **nothing reports it** — the losing copy bails silently at
`if not lib then return end`. The suite would have stayed entirely green.

The spec is now named for what it actually witnesses (the decision, and the date it was measured),
and the live question moved to a tool that reads the real AddOns tree, parses every copy's `minor`,
and exits non-zero if anything ties or beats us. **Run it before a release** — that is when the
answer matters and when somebody is present to act on it. It is deliberately not a spec: a suite
that read the installed AddOns tree would fail on a machine without these addons and pass vacuously
everywhere else.

Both raised in review.

### Fixed — the pie-chart hover used the wrong scale, and nothing could have noticed

`PieChart_OnUpdate` converts the cursor from screen space with `GetEffectiveScale`, which is right —
but every spec fed the cursor through a helper that multiplied by the same getter the code divides
by. The term cancelled, so swapping it for `GetScale`, or dropping the conversion entirely, left
every assertion passing while the cursor and the pie disagreed by the scale factor in game.

Two specs now put the scale on an **ancestor**, so `GetScale` and `GetEffectiveScale` genuinely
differ, and supply it to the cursor as a literal. Verified by making the one-word change the review
described: both go red, every other pie-chart assertion stays green.

### Fixed — the pie chart's `k == 7` was `#PiePieces` written as a literal

`AddPie` set a boundary-line fudge on the last slice by comparing the loop index against `7`, which
is the length of the slice table spelled out. Add a `"1-256"` slice — the obvious way to increase
pie resolution — and it fires one iteration early; remove one and it never fires, so the boundary
line is drawn slightly short on every full pie. Neither case errors and neither is visible in a
percentage: the arithmetic stays self-consistent and only the picture is wrong. Now `#PiePieces`.

Raised in review as surviving the `pairs` → `ipairs` change untouched, which it did — `ipairs`
yields the same integer keys, so the fix next door would have left it sitting there. A new spec
drives `AddPie` and `CompletePie` over the same percentage and requires the same decomposition,
because they are line-for-line the same loop and nothing asserted they stayed in step.

No behaviour change on any well-formed input, and the suite is identical either way, which is the
point: nothing would have caught someone changing it back. **One real difference, now pinned by a
spec:** a caller passing a _sparse_ points table gets a line truncated at the hole rather than
segments joined in arbitrary order. Truncated-but-coherent is the better failure.

The other eighteen `pairs` loops in the file were checked and left alone — they set a property on
each element, or accumulate a sum, and order genuinely does not matter.

## [v2.0.6] (2026-08-25) — One shared copy: the FastGuildInvite and Recount forks merged, and the Retail 12.0 crash fixed

LibGraph-2.0 had been carried around as a private copy inside every addon that used it, and the
copies had drifted. This release is the point where they stop drifting: one repository, merged from
the two forks that had real changes in them, published so consumers can embed the same file.

### Fixed — 148 identical errors per session on Retail 12.0

`GraphFunctions:PieChart_OnUpdate` tested the mouse with the `MouseIsOver` global. Retail 12.0 no
longer defines it, and this file caches its globals as upvalues at load time — so the upvalue was
`nil` for the entire session and every frame the pie chart updated threw. One sitting produced 148
copies of the same error.

The call is now `self:IsMouseOver()`. That is not a workaround: the global was only ever a one-line
forwarder to this widget method (`Blizzard_UIParent/Shared/UIParent.lua:530`), and the method is a
`SimpleScriptRegion` member documented in Classic Era's own API tree as well as Retail's. It is
correct on every flavour and needs no version guard, so the `local MouseIsOver = MouseIsOver`
upvalue is gone rather than made conditional.

### Fixed — `DrawHLine` drew its texture upside down

The FastGuildInvite copy had replaced the 8-parameter `SetTexCoord(0,0, 0,1, 1,0, 1,1)` in
`lib:DrawHLine` with the 4-parameter `SetTexCoord(0, 1, 1, 0)`, described in its own comment as the
simpler equivalent. It is not equivalent. The 4-parameter argument order is
`(left, right, bottom, top)` — per `SimpleTextureBaseAPIDocumentation.lua:395` — so that call swaps
the last two and draws `sline` vertically flipped.

It is now `SetTexCoord(0, 1, 0, 1)`, which is the true 4-parameter equivalent of the 8-parameter
identity mapping the original used. This keeps the simplification the fork was after without the
flip. In fairness this may never have been visible: if `sline.tga` is symmetric top to bottom, both
forms render identically. It was corrected because a behaviour difference nobody intended is worth
removing whether or not anyone could see it.

### New — `graph.LabelHook`

Set `graph.LabelHook` to a function and it is called with each axis-label `FontString` immediately
after the label's text is set, before it is shown. It exists so a consumer can localise the
library's internal axis labels — substituting a locale's own digits, or applying a font that can
draw them — without the library needing to know anything about localisation.

```lua
graph.LabelHook = function(fontString)
    fontString:SetText(MyLocale:Digits(fontString:GetText()))
    fontString:SetFont(MyLocale:FontPath(), 10)
end
```

It is called at all five label sites: both Y-axis label passes, the X-axis bottom labels, and the
two remaining axis labels. Leave it `nil` and nothing changes.

### New — `graph.XLabelsEnabled`

Set `graph.XLabelsEnabled` to `true` and a line graph draws numeric labels along the bottom, under
each X gridline, following the same secondary-gridline spacing the gridlines themselves use. The
rightmost label is skipped so it cannot run off the edge of the frame. Off by default; the original
library drew no X-axis labels at all.

### Changed — the library version is bumped `+2000` over stock, and `+1000` was not enough

`minor` is `90000 + 2000 + <SVN revision>` rather than stock's `90000 + <SVN revision>`. Every
consumer embeds its own copy of LibGraph-2.0 and LibStub loads whichever registers the highest
minor, so without a bump an addon shipping a stock copy would win the load race and everything
above would silently not exist.

**The band is `+2000` because `+1000` tied, and a tie loses.** `LibStub:NewLibrary` refuses an equal
minor — `if oldminor and oldminor >= minor then return nil end` — so the second copy to load bails
at `if not lib then return end` and the winner is decided by load order alone. Measured across one
install:

| Copy | Registers | Carries |
| --- | --- | --- |
| Details | `90062` | stock r62, the `MouseIsOver` crash |
| Recount | `90068` | stock r68, the `MouseIsOver` crash |
| FastGuildInvite | `91068` | a private fork: the crash **and** the flipped `DrawHLine` |
| this copy, before | `91068` | both fixed — and tied |

`fastguildinvite` sorts early in load order, so on an install carrying both, the **crashing** copy
won and this one never registered. That is the exact outcome the bump exists to prevent, so the
bands are now explicit: `+0` stock, `+1000` a private per-addon fork, `+2000` this shared copy,
which supersedes both. A spec asserts the minor beats each of the three measured above, and a second
one pins the equal-minor-loses rule so nobody simplifies the band back.

**Existing graphs are retrofitted, so this reaches players who never update the addon that embeds
the old copy.** When this file loads over a lower-minor copy it re-runs `SetupGraph*Functions` over
everything in `lib.RegisteredGraph*`, repointing already-created graphs at the new implementations.
Verified against Details' r62 copy, which carries the same registration tables and the same retrofit
loop — so a graph built by a stock copy before this one loads still gets the Retail 12.0 fix.

### Changed — packaged for release

The repository now carries a TOC for each live flavour (Classic Era 11509, TBC 20506, Wrath 30405,
Cataclysm 40402, Mists 50504, and Retail 110207 / 120005 / 120007 / 120100), a `.pkgmeta`, and a
BigWigs packager workflow that builds on a pushed tag. It also carries a `LICENSE`, which it did not
before: the original work stays All Rights Reserved to Cryect and Xinhuan, maintenance from this
release onward is MIT, and `LibStub.lua` remains public domain.

### New — an offline test suite, and the two standing review files

None of this ships: `.pkgmeta` excludes `Tests` and `docs`, and everything else added here is a
dotfile or `CLAUDE.md`, both of which the packager prunes on its own.

The repository now carries the shared [WoWAPITesting](https://github.com/Pimptasty/WoWAPITesting)
harness as a git submodule at `Tests/wowapi` (pinned `1f8fe09`), with six spec files covering the
library end to end: the load-time contract and LibStub load race, the `debugstack`-derived texture
directory, the data-series shape sniff, the axis and lock setters, `LinearRegression`, the rotated-
texture drawing primitives and their object pools, gridlines and both label hooks, the line and
scatter refresh paths, all five realtime convolution modes, the pie chart including its hover
surface, and the shipped `TestGraph2Lib` demo. **242 examples, 0 failed.**

Line coverage of `LibGraph-2.0/LibGraph-2.0.lua` is a measured **98.05%** (1461/1490). The 29
uncovered lines are three upstream blocks with no production entry point —
`GraphFunctions:SetAutoscaleYAxis` (its assignment is commented out), the non-realtime
`SetBarColors` (shadowed by `RealtimeSetColors`), and `TestRealtimeGraphRaw` (nothing calls it).
They are left in place because this file is kept close to upstream so the three-way diff against the
forks stays readable, and `docs/AUDIT.md` records them rather than rounding the number up.

Run it from the repo root with a Lua 5.1 interpreter and nothing else:

```sh
lua Tests/wowapi/run.lua
```

### Fixed — `FindFontString` raised on a graph that had not drawn gridlines yet

`GraphFunctions:FindFontString` iterates `self.FontStrings`, and nothing constructs that table —
only `HideFontStrings` creates it. `CreateGridlines` calls `HideFontStrings` first, which is the
only reason this has never been seen in game; a consumer calling the public `FindFontString`
directly on a fresh line or scatter graph got `bad argument #1 to 'pairs' (table expected, got
nil)`. It now carries the same guard `HideFontStrings` has. Found by the new spec suite, not by a
bug report.

Two append-only files come with it. `docs/AUDIT.md` is where a peer-review session writes findings
against this library and where we answer them; `Tests/HARNESS_CONTRACT.md` is where we ask the
harness for something it does not model yet. One request went in there immediately —
`StatusBar:SetOrientation`, which Classic Era documents and the harness gives only to `Slider`, and
without which no realtime graph can be constructed offline at all. It came back **DELIVERED the same
day but not yet pushed**, so `Tests/env_local.lua` stays: it wraps `CreateFrame` and fills the two
methods only where they are absent, so it yields on its own the moment the real implementation
arrives in a pin we can move to.

### Removed — a changelog paragraph that had got into `LICENSE`

Section 2's MIT grant carried a paragraph listing this release's changes. A licence states terms and
scope; what changed belongs here. The grant is unaffected — its scope is still the section heading,
"Modifications from 2026-08-25 onward".

---

Provenance: this is GraphLib / LibGraph-2.0 by Cryect and Xinhuan, SVN r68, as vendored in
FastGuildInvite and Recount. Version 2.0.5 and earlier predate this repository and have no changelog
entries here.
