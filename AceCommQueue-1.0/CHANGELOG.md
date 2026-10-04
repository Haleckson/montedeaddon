# AceCommQueue-1.0 Changelog

## [v1.1.1] (2026-09-27) - Retail Interface, Accurate Docs

Library `MINOR` bumped to `8`. No runtime behaviour changed; this release exists
so Retail stops flagging the library out of date.

### Bug Fixes

- **Retail flagged the library out of date** -- the TOC declared `120100`,
  `120001` and `120000` but not `120005` or `120007`. Found by FastGuildInvite's
  `Tests/zz_toc_manifest_spec.lua`, which requires every hard dependency to
  declare each `## Interface` number FGI's own TOC does; FGI hard-depends on this
  library, so on Retail it loaded only with "load out of date AddOns" enabled.
  Both numbers added; the superseded ones stay. Location: `AceCommQueue-1.0.toc`.

### Improvements

- **Listed as a library in the AddOns list** -- the TOC gains
  `## Category: Library` and the title becomes `|cffFF8000Lib: AceCommQueue-1.0|r`,
  the same convention LibAceGUIWidgets and LibLocaleOverride use, so the
  standalone addon is grouped under "Library" instead of sorting loose at the
  bottom. Location: `AceCommQueue-1.0.toc`.

- **CurseForge description brought to parity with the code** -- it said stall
  recovery happens "after five minutes without progress"; the check is lazy
  (`checkStall` runs from `drain` only when a caller enqueues behind the busy
  send), so it now says the next send on that channel triggers it. "Purely
  callback-driven" ignored `scheduleRetry`'s `C_Timer.After` backoff; reworded.
  The placeholder "CurseForge page: TBD" replaced. Location:
  `docs/Curseforge_Description.html`.

- **Three stale comments in the shipped file corrected** -- `SetStallTimeout`'s
  docstring still said the queue "cannot recover" from a stall, and the note above
  `checkStall` said it "never re-sends"; both predate v1.0.6's `releaseStuck`,
  which releases and re-sends. The header's callback contract listed only the
  v1.0.4 four-argument shape; it now names `delivered` and every `reason`.
  Location: `AceCommQueue-1.0.lua`.

- **Weak spec assertions replaced** -- writ's Lua spec check flagged
  `Tests/debug_spec.lua`'s refusal test, which asserted `is_nil` on
  `SlashCmdList["ACECOMMQUEUE_ACQ"]`. That key was misspelt (the library derives
  `ACECOMMQUEUE__ACQ`, double underscore), so the assertion passed regardless of
  behaviour. The test now counts every `SlashCmdList` entry plus every
  `SLASH_ACECOMMQUEUE*` global: unchanged after three invalid registrations, +2
  after a real one. The positive half was seen to fail before it passed.

- **Harness pin moved `8db4116` -> `bd91de2`** -- picks up the harness's lint
  baseline and its corrected `inherit="prepend"`/`"append"` order (this library
  has no XML, so no spec depended on either order). Suite 140/140, 100% line
  coverage of `AceCommQueue-1.0.lua`.

- **Dev sync watcher replicates into WoW Forever** -- `_classic_beta_` (the
  folder `WowB.exe` installs to) added to `wow-version-replication.ps1`'s flavor
  list; verified with `-DryRun` and by the files appearing after a restart.
  Dev-only; not in the zip.

---

## [v1.1.0] (2026-09-20) - WoW Forever, Current Clients, and a Truthful Stall Report

Library `MINOR` bumped to `7`. The TOC now loads on **World of Warcraft: Forever**
and declares the current build of every other flavor, and the stall report says
what actually happened to the message instead of promising an outcome that had
not been decided yet.

### New Features

- **World of Warcraft: Forever (`16001`) declared in the TOC** -- raised by
  FastGuildInvite, whose v2.14.0 hard-depends on this library and ships a
  `_Camelot` TOC; on Forever a dependency the client will not load stops the
  dependant loading. One plain TOC is enough: the client falls back to
  `<Addon>.toc` on every flavor, so no `_Camelot` file is needed. Forever is the
  retail client (`WOW_PROJECT_ID == WOW_PROJECT_MAINLINE`, `select(4,
  GetBuildInfo())` = 16001) running classic-era content; this library has no
  flavor branching, so it runs the retail path unchanged. The operator confirmed
  a 16001 TOC goes through the BigWigs packager and CurseForge without error.
  Location: `AceCommQueue-1.0.toc`.

### Bug Fixes

- **The stall report promised an outcome that had not been decided** -- peer-review
  finding 2. `checkStall` emitted its `geterrorhandler()` report *before* calling
  `releaseStuck`, and the report stated as fact that "the message is being re-sent
  and the queue released, so nothing is dropped". `releaseStuck` has two exits, and
  the second -- `scheduleRetry` returning false, which happens on any host that set
  `SetRetryPolicy(0)` (a supported configuration; the docstring says "0 disables"),
  on a message whose shared refusal/stall budget was already spent, or on a client
  without `C_Timer` -- abandons the message with `reason = "lost"`. A maintainer who
  read "nothing is dropped" stopped looking for the dropped message.

  The report is now written after `releaseStuck` returns, choosing its final clause
  from the boolean: *"The message is being re-sent and the queue released..."* or
  *"The retry budget for this message was already spent, so it has been DROPPED (its
  callback reported reason="lost") and the queue released"*. The once-per-queue
  gate and the waiting count are both read before the call, because `releaseStuck`
  bumps `q.stalls` and its abandon path drains the queue. Two specs in
  `Tests/delivery_spec.lua` pin each wording and assert the other is absent (the
  dropped case drives `SetRetryPolicy(0)`); mutation-verified by forcing the re-send
  clause, which fails exactly the dropped-wording spec. Location:
  `AceCommQueue-1.0.lua`, `checkStall`.

### Improvements

- **Interface list brought current for every flavor** -- peer-review finding 1,
  re-verified against warcraft.wiki.gg's TOC format page on 2026-09-20 rather than
  the finding's 2026-08-07 numbers (Mainline had moved again in between). Added
  `20506` (TBC / Anniversary), `38002` (Wrath), `50504` (Mists) and `120100`
  (Mainline). The superseded entries stay; nothing prunes them and their cost is
  nil. Location: `AceCommQueue-1.0.toc`.

- **README and CurseForge description brought in line with the library** -- the
  description still said ChatThrottleLib "drains ALERT before NORMAL before BULK"
  and that this library's ordering "mirrors" it. Both are false: CTL gives its
  priorities an *equal share* of bandwidth, and the strict ordering is this
  library's alone (see the ChatThrottleLib section of `README.md`). The
  description also predated retry, stall detection and recovery, the
  whole-message verdict, the `reason` argument, `Unstick` and the `MINOR` feature
  table, which it now carries. Release notes in the description are grouped New /
  Changed / Fixed from this version on.

- **Development process moved to the writ inbox** -- the `docs/AUDIT.md` and
  `Tests/HARNESS_CONTRACT.md` boards were imported into writ and deleted. The
  audit board's two findings are the fixes above; all eight harness items were
  already delivered at the current `Tests/wowapi` pin and were closed with the
  evidence. `CLAUDE.md`, `.github/copilot-instructions.md` and `Tests/env_acq.lua`
  point at the inbox instead. No shipped file changed.

- **luacheck configuration corrected** -- `.luacheckrc` listed `SlashCmdList` under
  `read_globals` with a comment claiming field assignment on a read-only global is
  permitted; luacheck reports it as W122. It is now under `globals`. The `Tests`
  block gains `Enum` (read) and `LibStub` (writable, because `env_acq.lua`'s
  `evict` clears its registry to re-run the library file). Dev-only; the shipped
  file is untouched.

## [v1.0.6] (2026-08-04) - Stalls: Diagnosed Correctly, Then Recovered

Library `MINOR` bumped to `6`. **v1.0.5's stall detector reported ordinary client
throttling as a host addon's bug, and then left the queue blocked anyway.** This
release makes the diagnosis truthful by asking ChatThrottleLib, and turns
detection into recovery: a stuck queue releases and re-sends instead of dying.

### Bug Fixes

- **A throttled send was reported as a stalled queue, blaming the wrong addon** —
  `ChatThrottleLib:Despool` moves a send the client THROTTLED into `Prio.Blocked`
  with the message still on the pipe, retries it from there roughly 2.5 times a
  second, and fires **no callback** for the entire time it is doing so — only the
  non-throttled branch reaches `msg.callbackFn`. From this library's side that is
  indistinguishable from a callback that was lost, and the 60-second default
  reported it as one, naming "a `SendCommMessage` wrapper that suppresses a send"
  as the cause with no way to establish that. Observed in the wild against
  `togpmv-o` WHISPER queues, where it sent a maintainer to audit two addons that
  were not at fault; whisper addon-message throttling on a populated realm trips
  60 seconds routinely.

  `checkStall` now looks the send up in CTL's own queue before reporting anything
  (`ctlStillQueued`), and stays silent for as long as CTL still has it. The match
  is on the message's own `(prefix, distribution, target)`, never on the pipe's
  mere existence — AceComm-3.0 names CTL pipes after the prefix alone
  (`queueName = prefix`), so one pipe carries every peer on that prefix and
  traffic to a different peer must not vouch for this send. The entry below covers
  why the lookup cannot be keyed at all. Reads are nil-safe and CTL is
  feature-detected, so a client without it falls back to timeout-only reporting
  rather than erroring inside the error path. Location: `AceCommQueue-1.0.lua`,
  `ctlStillQueued` / `checkStall`.

- **The ChatThrottleLib lookup assumed every host is Ace3-shaped** — `ctlStillQueued`
  indexed `CTL.Prio[prio].ByName[prefix]`, which only resolves because AceComm-3.0
  happens to set `queueName = prefix`. CTL takes `queueName` as a free parameter,
  and its author's own model is `extension+chattype+destination`; a host calling
  CTL directly, or a wrapper that rewrites the priority, files the message
  somewhere that keyed lookup cannot see. This library ships standalone, so its
  hosts are not all Ace3-shaped.

  A miss was not benign: the queue would conclude the callback was lost, report a
  stall, and **re-send a message still sitting in CTL's pipe** — a duplicate on
  the wire, which is the failure this library exists to prevent arrived at from
  the other end. The check now scans every pipe in every priority and matches on
  the message's own `(prefix, distribution, target)` rather than on where it was
  filed. The two error directions are not symmetric — a false positive costs
  silence, a false negative costs a duplicate — so the scan is deliberately biased
  toward matching, and widening it can only trade the expensive error for the
  cheap one. Cost is irrelevant: it runs only after `stallTimeout` seconds of
  silence, or from an explicit `Unstick`, never on the send path. Location:
  `AceCommQueue-1.0.lua`, `ctlStillQueued`.

- **The stall clock was not restarted when a stall was acted on** — found while
  specifying the recovery below. With `progressAt` left at its stale value, every
  message enqueued during the retry backoff re-entered `checkStall` on the same
  timestamp; the second pass found `inFlightItem` already taken and would have
  released the slot mid-backoff, racing the retry against whatever drained behind
  it. Acting on a stall now counts as progress. Location:
  `AceCommQueue-1.0.lua`, `releaseStuck`.

### New Features

- **Stall recovery — the queue releases and re-sends instead of staying dead** —
  v1.0.5 detected and deliberately never recovered, on the reasoning that the
  library could not tell whether the stuck message had reached anyone. Consulting
  CTL removes that uncertainty: a message CTL has no record of and never reported
  on is one it never accepted, which is exactly the documented suppression case
  where **nothing was delivered**. So the slot is reclaimed — safe because there
  is nothing left in flight for the next message's chunks to interleave with —
  and the message is re-queued at the **head** of its priority bucket under the
  existing `SetRetryPolicy` budget, sharing one budget per message with refusal
  retries. When that budget is spent the message is reported `reason = "lost"`
  and the queue moves on rather than blocking behind it. Location:
  `AceCommQueue-1.0.lua`, `releaseStuck`.

- **`AceCommQueue:Unstick([key])` and `/acq unstick`** — forces recovery on demand
  for a queue that is stuck right now, instead of waiting out the timeout. Returns
  the number of queues released and the number left alone. Applies the same CTL
  safety test as the automatic path: a manual command is not a reason to let two
  messages into CTL at once. Location: `AceCommQueue-1.0.lua`, `Unstick`.

- **`reason = "lost"`** — a fifth callback value, for a send whose callback never
  arrived and whose retries are exhausted. Distinct from `"suppressed"` (dropped
  on purpose, nothing to do) and `"refused"` (the client said no). Location:
  `AceCommQueue-1.0.lua`, `releaseStuck`.

### Improvements

- **Default stall timeout raised from 60 to 300 seconds** — 60 sits inside normal
  whisper-throttle territory. The report accuses a host addon of a bug, so
  reporting late costs nothing and reporting wrongly costs a maintainer an audit
  of the wrong codebase. `SetStallTimeout` still overrides it; `0` still disables.

- **Stalls are loud once per queue per session, then counted** — matching the
  existing treatment of refusals. A wrapper that suppresses every send stalls every
  message, and one error per message trains people to ignore the error, which is
  the same silent failure by a slower route. The running total is in `/acq status`
  as `stalls=N`.

- **A callback arriving after its send was released is ignored** — each send is
  stamped with a per-queue epoch that recovery retires. Without it, the late
  arrival that caused the stall would advance the queue on behalf of a message
  nobody is waiting for, putting a second message into CTL alongside the one now
  in flight — the interleaving this library exists to prevent. Location:
  `AceCommQueue-1.0.lua`, `sendNext`.

- **The public-API spec is now an exact set comparison** — it claimed to check
  "exactly the documented public API" while spot-checking three methods, and had
  already let `SetRetryPolicy` and `SetStallTimeout` ship unlisted. Location:
  `Tests/smoke_spec.lua`.

- **Harness adopted, 38 commits forward, and a test-environment lie fixed** — the
  `Tests/wowapi` pin was stale, so the suite had been trusted all session against
  a harness missing (among much else) `reset() no longer empties the frame
  registry`, the fix for load-time frames being orphaned so ChatThrottleLib could
  never despool. The adoption log names this addon directly: `Tests/env_acq.lua`
  defined **only** the bare `SendChatMessage` / `BNSendGameData` globals, on a
  "Classic-shaped symmetry" comment that was simply wrong. Blizzard's own Classic
  Era source has both namespaced forms (`C_ChatInfo.SendChatMessage` at
  `GlobalAPI.lua:780`, `C_BattleNet.SendGameData` at `GlobalAPI.lua:527`); the
  bare globals are deprecation fallbacks that forward to them. CTL feature-detects
  the namespaced form, so the suite was loading the real ChatThrottleLib and
  driving the branch no client takes.

  **This did not invalidate the results above**, and the reason is worth recording
  rather than assuming: CTL hooks and calls `C_ChatInfo.SendAddonMessage`
  *unconditionally* (`ChatThrottleLib.lua:245` and `:638`) — the feature-detect at
  `:235` is only for `SendChatMessage`, whose hook feeds the `nBypass` statistic
  this library never reads. The addon-message path was exercised correctly
  throughout. Pinned by a spec now so it cannot regress quietly. Location:
  `Tests/env_acq.lua`, `Tests/smoke_spec.lua`.

- **`Tests/env_acq.lua` now adopts the harness's globals instead of hand-rolling
  them** — `M.install()` begins with `wow.reset()`, and what remains is only what
  this suite genuinely steers: the clock, the bandwidth gauge, the steerable
  `C_ChatInfo.SendAddonMessage`, and the loopback wire. Deleted as redundant:
  local `hooksecurefunc`, `securecallfunction`, `xpcall`, `wipe`/`table.wipe`,
  `Enum`, `Ambiguate`, `SlashCmdList`, `DEFAULT_CHAT_FRAME`, and the
  `SendChatMessage` / `BNSendGameData` pair. Maintaining private copies of a
  shared model is exactly how the branch bug above survived.

  Two of those copies were **less faithful than the harness's**, which is the
  concrete argument against keeping them. The local `hooksecurefunc` captured the
  original's returns as `{orig(...)}` and replayed them with `unpack`, which drops
  a returned `nil` — and CTL reads a send's verdict as `select(-1, true, ...)`, so
  a swallowed `nil` became "no return values", which CTL treats as **success**.
  The local `Ambiguate` ignored its context argument entirely and returned the
  name unchanged whatever it was handed, so a call site passing the wrong context
  could never fail a spec.

- **The test clock no longer runs backwards between spec files** — `M.fresh()`
  reset `M.now` to `0`, which the harness documents as the hazard that drives
  ChatThrottleLib's bandwidth gauge negative (`MAX_CPS * (now - LastAvailUpdate)`)
  and queues every send, making a spec's result depend on how far the *previous
  spec file* had advanced the clock. It was masked here because `fresh()` reloads
  CTL outright and then pins the gauge — but relying on that masking is how it
  stops being masked. The clock now only moves forward. Location:
  `Tests/env_acq.lua`, `M.fresh`.

- **Editor diagnostics on the spec files fixed at the source, not silenced** —
  `.luarc.json` carried `workspace.ignoreDir: ["Tests"]`, which was the worst of
  both worlds: the language server still diagnoses an open file, so the specs got
  false warnings *and* no real checking. Fifteen were showing.

  - `package` / `require` reported undefined: `runtime.builtin` now enables
    `package`/`io`/`os` and the loader globals are declared, matching the
    harness's own config.
  - Twelve `redundant-parameter` warnings on `assert.is_true(cond, message)`:
    caused by the `${3rd}/luassert` stub typing `is_true` as single-argument when
    luassert genuinely takes a message. The mistyped library is removed rather
    than the diagnostic disabled — `redundant-parameter` usually indicates a real
    arity bug and must keep firing.
  - `Tests` is now checked with the correct settings; only `Tests/wowapi` (the
    submodule, which carries its own config and is not ours to fix) is ignored.

  Also added `GetTime` and `C_Timer` to `.luacheckrc`'s `read_globals` — both are
  read by the library and neither was declared.

- **The addon-local `Tests/coverage.lua` deleted** — the harness took ownership of
  it and the local copy was a stale duplicate. Invocation is now
  `lua Tests/wowapi/coverage.lua`. Docs updated in `README.md`, `CLAUDE.md` and
  `.github/copilot-instructions.md`.

- **Suite grown to 138 specs, still at 100% line coverage** (299/299), including
  both branches of the CTL consultation, the shared-pipe precision case, a
  host-chosen queue name, a wrapper-rewritten priority, retry exhaustion, the
  late-callback guard, the pending-retry guard, and every `Unstick` path.

- **The hardening's specs were rewritten end-to-end, then mutation-verified** —
  the first versions hand-built a message table and injected it into
  `CTL.Prio[...].ByName[...]`, which exercises the scan loop against a fixture of
  our own authoring and proves nothing about whether a real host-chosen
  `queueName` produces that state. They now drive the real ChatThrottleLib —
  `CTL:SendAddonMessage(...)` with the bandwidth gauge pinned at 0 — so CTL
  genuinely enqueues under the name and priority it was handed, and one spec
  covers both directions: held by CTL → silent, then drained by CTL → reported.

  Their teeth were then confirmed rather than assumed. Reverting `ctlStillQueued`
  to the pre-hardening keyed lookup fails both positive specs at the
  "CTL has it: say nothing" assertions. The same check was run across the rest of
  this release's behavioural specs by disabling seven guards — the epoch guard,
  both pending-retry guards, the loud-once gate, `Unstick`'s CTL safety check, and
  retry-on-release — which failed nine specs between them. No survivors.

  One pre-existing spec did NOT fail and is now misnamed: `reports once per stall,
  not once per blocked message` passes trivially, because a released queue drains
  and later messages never re-trip the timeout. Left in place with its assertion
  intact, but it is no longer evidence of the property its name claims.

- **A comment in the shipped file was factually wrong** — `PRIO_ORDER` was
  annotated as "matching CTL's own priority ordering". CTL has no priority
  ordering to match: its own header states "Priorities get an equal share of
  available bandwidth when fully loaded", and `OnUpdate` divides by
  `nSendablePrios` with no weighting and no preemption, so an ALERT gets a third
  of the budget when all three classes are backlogged. The strict ALERT → NORMAL →
  BULK ordering is this library's alone, and serialising here is what makes
  priority mean anything between messages. Location: `AceCommQueue-1.0.lua`.

---

## [v1.0.5] (2026-08-03) - Delivery Contract: No More Silent Drops

Library `MINOR` bumped to `5`. **The library was reporting messages as delivered
that demonstrably were not.** This release makes the delivery verdict truthful,
retries what the client refuses, and guarantees a refused message can never be
completely silent.

### Bug Fixes

- **A refused chunk was reported to the sender as a successful delivery** —
  `internalCb` inspected only the final chunk's callback, so a multipart message
  whose middle chunk the client refused still reported
  `callbackFn(arg, 700, 700, true)`. Verified end-to-end against the real
  ChatThrottleLib and AceComm-3.0: with chunk 2 of 3 refused, two chunks reached
  the wire, the sender was told the send succeeded, and the receiver reassembled
  a corrupt payload from the surviving chunks. The verdict is now watched on
  **every** chunk and reflects the whole message. Location:
  `AceCommQueue-1.0.lua`, `sendNext`.

  Root cause, traced through the shipped stack: `ChatThrottleLib:Despool` retries
  only `AddonMessageThrottle`; every other refusal (`GeneralError`,
  `NotInGroup`, `ChannelThrottle`) falls to the `else` branch, where the message
  is dequeued and destroyed with `DelMsg` and no retry. AceComm-3.0's
  `ctlCallback` then declares two parameters, discarding CTL's result enum and
  forwarding only the `didSend` boolean. That boolean was the one signal
  available to this library, and it was being ignored on every chunk but the last.

### New Features

- **Automatic retry of a refused send** — Three retries with a doubling backoff
  (1s, 2s, 4s) before reporting failure, tunable via
  `AceCommQueue:SetRetryPolicy(retries, baseDelay)` and disabled with `0`.
  Retrying is safe because a refused chunk leaves the receiver's spool
  incomplete: a retry's fresh `FIRST` frame replaces the aborted stream rather
  than duplicating a delivered message. The queue stays blocked through the
  backoff and the retried message re-enters at the **head** of its priority
  bucket, so ordering survives and a channel the client just refused is not
  handed more traffic. Bounded on purpose — since AceComm reduces the result to a
  boolean, a `ChannelThrottle` that would succeed is indistinguishable from a
  `NotInGroup` that never will. Uses `C_Timer.After` (fire-and-forget, never
  cancelled) and feature-detects it, reporting immediately where it is absent.
  Location: `AceCommQueue-1.0.lua`, `scheduleRetry`.

- **A refused message with no callback is reported by the library** — The common
  call shape `SendCommMessage(prefix, text, "GUILD")` has nobody to tell, so a
  refusal there used to vanish entirely. It now goes to `geterrorhandler()`,
  naming the prefix and queue. Supplying a callback means taking ownership of the
  report. Location: `AceCommQueue-1.0.lua`, `reportOutcome`.

  **Reported loudly once per queue per session, then counted.** A survey of the
  consuming addons (ClassicCalendar, Dibs, FastGuildInvite, PersonalShopper,
  TOGProfessionMaster, DeltaSync, TOGBankClassic) found that essentially all of
  them broadcast on `GUILD` with **no callback**, so an unconditional report would
  give a player in a refusing state — no guild, not grouped — one error per
  message for as long as it lasted. That trains people to ignore the error, which
  is the same silent failure by a slower route. The running total per queue is in
  `/acq status` as `refused=N`.

- **`reason` — a 5th callback argument naming the outcome** —
  `callbackFn(callbackArg, sent, total, delivered, reason)`, where `reason` is
  `"refused"`, `"suppressed"`, `"rejected"`, `"error"`, or `nil` when the message
  was delivered. Requested by DeltaSync while adopting the delivery contract:
  `delivered == nil` alone is ambiguous, because it covers a deliberate
  suppression — where doing nothing is the *correct* response — alongside a
  rejected call and a raised send, where a message was genuinely lost. A consumer
  counting delivery failures could not tell them apart. Appending the argument is
  backward compatible; four-parameter callbacks are unaffected.
  Location: `AceCommQueue-1.0.lua`, `reportOutcome` / `reportUnsent`.

- **Stall detection (`LIBREQ-ACQ-002`)** — `inFlight` is cleared only by a send's
  completion callback, so a callback that never arrives leaves that
  `(prefix, distribution, target)` blocked for the rest of the session with every
  later message queued behind it. In practice: a `SendCommMessage` wrapper that
  suppressed a send without calling `callbackFn(callbackArg, 0, 0, nil)`. After
  60 seconds without progress, the next caller to find the queue busy triggers a
  `geterrorhandler()` report naming the queue, the idle time and the number of
  messages waiting; `/acq status` shows `idle=Ns` per queue.
  `AceCommQueue:SetStallTimeout(seconds)` tunes it, `0` disables.
  Location: `AceCommQueue-1.0.lua`, `checkStall`.

  Three deliberate properties. It **detects and never recovers** — clearing
  `inFlight` would mean abandoning the in-flight message or re-sending it, and
  the library cannot tell which is safe because it does not know whether that
  message reached anyone; nothing is dropped, and the queue drains normally if
  the callback eventually arrives. It measures **time since the last chunk**, not
  since the send began, so a slow-but-progressing multipart send under shared
  ChatThrottleLib bandwidth can never trip it. And it uses **no timer**: the check
  runs when a caller finds the queue busy, which is the moment a stall first
  costs something — a timer would have meant one timer object per chunk on the
  hot path of a library that is otherwise purely callback-driven. The threshold is
  floored at twice the total retry backoff so a retry in progress is never
  mistaken for a stall.

### Improvements

- **The delivery verdict is now a documented four-state contract** — `true`
  delivered, `false` refused by the client, `nil` never attempted (suppressed,
  rejected, or raised), with `reason` naming which. `README.md` gained a
  **Delivery Contract** section
  covering it, including the two traps that bite otherwise-careful callers: the
  verdict describes the whole message rather than the last chunk, and it is a
  **boolean**, so comparing it against `Enum.SendAddonMessageResult` members can
  never match.

- **Debug output records the verdict** — the completion line now carries
  `delivered=<bool>` alongside the byte counts and suppression flag, and each
  retry logs its attempt number and backoff.

- **Offline suite grown to 118 specs, still 100% line coverage (226/226)** — New
  `Tests/delivery_spec.lua` covers the verdict, per-chunk refusal, retry success
  and exhaustion, ordering across a backoff, policy tuning and upgrade
  persistence, the no-`C_Timer` path, every `reason` value, and stall detection
  including that a progressing send never trips it and that a stall leaves the
  queue untouched. `Tests/env_acq.lua` gained a `C_Timer`
  whose `After` returns **nothing** — matching the real API, so a `:Cancel()` on
  its result cannot silently no-op — plus a refusable transport so a spec can
  reject one specific chunk of a multipart message.

---

## [v1.0.4] (2026-08-03) - Offline Test Suite, Iterative Drain & Callback Contract

Library `MINOR` bumped to `4`. The library gained an offline unit-test suite that
runs the **real** Ace3 stack outside the game; the three bugs below were found by
it and are fixed here.

### New Features

- **Offline unit-test suite (77 specs, 100% line coverage)** — Built on the
  shared WoWAPITesting harness, added as the git submodule `Tests/wowapi`. Runs
  with nothing but a Lua 5.1 interpreter: `lua Tests/wowapi/run.lua`, or
  `lua Tests/coverage.lua AceCommQueue-1.0.lua` for the suite plus an exact
  line-coverage report (137/137). Excluded from the packaged zip via `.pkgmeta`.
  Locations: `Tests/`, `.busted`, `.luacheckrc`, `.pkgmeta`.

- **The suite runs against real Ace3, not stubs** — `Tests/env_acq.lua` loads
  `CallbackHandler-1.0`, `ChatThrottleLib` and `AceComm-3.0` from the sibling
  `Ace3` addon install, so the queue is exercised against the exact code that
  ships to players. It supplies the client globals those files read at load time
  (`hooksecurefunc`, `securecallfunction`, `geterrorhandler`, `Enum`,
  `C_ChatInfo`, `GetFramerate`, `table.wipe`), a frozen clock, and a pinned
  `ChatThrottleLib.avail` so CTL's despool schedule is deterministic.

- **End-to-end reproduction of the interleaving corruption** —
  `Tests/interleave_spec.lua` starves CTL of bandwidth until it genuinely
  interleaves two multipart messages on one prefix, replays the resulting wire
  into a real AceComm receiver, and asserts the reassembled payload is corrupt;
  it then asserts that with `Embed` in place the receiver gets both messages
  intact and in order. The library's premise is demonstrated per run rather than
  assumed.

### Bug Fixes

- **A numeric `target` raised an error out of `SendCommMessage`** — AceComm-3.0's
  own signature check permits `type(target) == "number"` (a channel index for
  `CHANNEL` sends), but `makeKey` called `target:lower()` directly, so any such
  send died with `attempt to index local 'target' (a number value)` before it was
  ever queued. Both key components are now stringified before case folding
  (`tostring(target):lower()`), and a nil `target` is still distinguished from an
  empty one. Location: `AceCommQueue-1.0.lua`, `makeKey`.

- **A large backlog silently lost messages** — `drain` called itself from the
  send-completion callback. Because ChatThrottleLib sends straight out whenever
  bandwidth allows, most completions are synchronous, so a backlog draining after
  a burst nested one `pcall` per queued message: measured at ~4.3 stack frames
  per message (1282 frames for 300 queued). Past the interpreter's stack limit
  the overflow was caught by `sendNext`'s own `pcall`, reported to the caller as
  an ordinary failed send, and the drain moved on — 20 000 queued messages
  delivered 19 999, 50 000 delivered 49 997, with no error anywhere. The drain is
  now an iterative loop: a re-entrant call from a synchronous completion sets
  `q.pending` and returns, and the loop picks the next message up at the same
  stack depth. `Tests/queue_spec.lua` asserts constant submission depth across a
  200-message backlog and full delivery of a 20 000-message one.
  Location: `AceCommQueue-1.0.lua`, `drain` / `sendNext`.

- **A rejected message never reported back to its caller** — The dispatcher's
  input validation (empty or non-string prefix, `nil` text, unknown priority)
  returned without calling `callbackFn`. Callers chain their next send on that
  callback — the same contract the README requires of suppressing wrappers — so
  one bad argument stranded the caller's pipeline permanently. Rejected messages
  now report `(callbackArg, 0, 0, nil)`, identical to the suppression signal, via
  the new `reportUnsent` helper. Location: `AceCommQueue-1.0.lua`.

- **An error raised by the caller's own callback could double-fire it** — When
  the callback fired for the final chunk and then raised, the error escaped into
  the drain's `pcall`, which treated the delivered message as a failed send and
  called the same callback again with `(arg, 0, 0, nil)`. The completion path now
  tracks whether the callback already fired and pcalls the caller's callback, so
  a broken callback can neither be re-invoked nor stall the queue.
  Location: `AceCommQueue-1.0.lua`, `sendNext`.

### Improvements

- **Send errors are no longer swallowed** — A send that raises is still caught so
  the queue keeps draining, but the error is now passed to `geterrorhandler()`,
  landing in the player's bug catcher exactly as it would with no queue in the
  way. The same applies to an error raised by the caller's callback. Previously
  both were visible only with debug output enabled.
  Location: `AceCommQueue-1.0.lua`.

- **`.pkgmeta` `ignore:` rewritten in canonical form** — `Tests` added, and the
  dotfile entries (`.git`, `.github`, `.vscode`, `.luarc.json`,
  `.markdownlint.json`, `.markdownlintignore`) removed: the packager prunes
  dotfiles unconditionally, so those entries never did anything and implied
  coverage they were not providing. Location: `.pkgmeta`.

- **Dev sync watcher now mirrors the packager's exclusions** — Two fixes to
  `wow-version-replication.ps1`, which replicates the source tree into the other
  installed WoW flavors and is meant to make them look like the packaged release.
  First, a bare folder name from `.pkgmeta`'s `ignore:` list compiled to `^docs$`,
  which matches only a *file* named `docs` — so `docs` (and now `Tests`) were
  listed, reported as loaded at startup, and replicated anyway. Bare
  non-wildcard entries are now resolved against the repo and treated as a prefix
  match when they name a directory, exactly as `release.sh`'s `parse_ignore()`
  rewrites them to `dir/*`. Second, the always-skip list is now a single
  "any path component beginning with a dot" rule matching the packager's
  unconditional `-name ".*" -prune`, replacing the four hand-listed git entries —
  necessary because dot-entries cannot be expressed in `.pkgmeta` at all, and
  load-bearing because `.git` here is a gitdir *pointer file* that would aim a
  replicated copy at the wrong repository. Verified with `-DryRun`.
  Location: `wow-version-replication.ps1`.

- **Documentation** — `README.md` gained a Callback Contract section (the three
  ways a message terminates), a Queue Keys section (case folding, numeric
  targets, key independence) and a Tests section; the receiver-spool description
  was corrected to `prefix + distribution + sender`. `CLAUDE.md` and
  `.github/copilot-instructions.md` gained the test-suite workflow.
  `Tests/HARNESS_CONTRACT.md` records what the shared harness should absorb —
  chiefly that **WoW's `xpcall` forwards arguments and stock Lua 5.1's does
  not**, which silently sends empty addon messages through ChatThrottleLib
  offline until shimmed.

---

## [v1.0.3] (2026-07-28) - Classic Era 1.15.9, Packaging Fixes & Dev Tooling

Library `MINOR` bumped to `3`. No runtime behaviour changed — the queue, drain,
priority ordering and `Embed` contract are byte-for-byte identical to v1.0.2.

### Bug Fixes

- **`.pkgmeta` `ignore:` entries rewritten in the packager's expected syntax** —
  The list used `**` recursive-glob syntax (`docs/**`, `**/*.ps1`, `**/*.bat`)
  rather than the path-and-single-`*` form the BigWigs packager's `ignore:`
  block expects, so those entries were not reliably excluding the docs folder or
  the dev PowerShell/batch scripts from the package. Rewritten as `docs`,
  `"*.ps1"` and `"*.bat"`, and the directory entries lost their redundant
  trailing slashes. The `*`-leading entries remain quoted because a bare leading
  `*` is a YAML alias indicator and would fail to parse. Location: `.pkgmeta`.

### Improvements

- **Classic Era 1.15.9 support** — `Interface:` bumped `11508` → `11509` so the
  library is not flagged out-of-date on the current Era client. The `11507`
  entry is retained for the Anniversary-realm build; all other flavor IDs
  (TBC, Wrath, Cata, MoP, Retail) are unchanged.
  Location: `AceCommQueue-1.0.toc`.

- **`MINOR` bumped to `3`** — Shipped-revision bump so LibStub resolves this copy
  over an embedded v1.0.2 copy. Per-session state (`queues`, `debug`) is still
  preserved across the upgrade. Location: `AceCommQueue-1.0.lua` (line 31).

### Repository & Dev Tooling

Dev-environment maintenance carried over from the previously unreleased
`2026-06-10` batch. None of these files alter runtime behaviour; most are
excluded from the packaged zip via `.pkgmeta`.

- **`CLAUDE.md` project instructions** — Added library-specific Claude guidance
  (tool-usage rules, multi-version `.toc` correctness, the `Embed` transparency
  and `callback(arg, 0, 0, nil)` queue-unblock contracts, `MINOR`/state-preservation
  rules, and the commit/version/changelog process). Excluded from the zip.
- **`.github/copilot-instructions.md`** — Copilot-flavoured mirror of the same
  rules. Excluded from the zip (under `.github/`).
- **`wow-version-replication.ps1` dev sync watcher + `.vscode/tasks.json`** —
  Per-repo mutex-guarded watcher that replicates the source tree into every
  installed WoW flavor (`_classic_`/`_anniversary_`/`_retail_`), driven by the
  `.pkgmeta` `ignore:` list so synced installs mirror the packaged release. The
  VS Code `folderOpen` task auto-launches it. Both excluded from the zip
  (`**/*.ps1`, `.vscode/`).
- **`LICENSE` (MIT) + `license-output: LICENSE` in `.pkgmeta`** — Explicit MIT
  license; the packager emits it into the zip.
- **`.markdownlintignore`** — Excludes `.pkgmeta` and `LICENSE` from markdownlint.
- **`CHANGELOG_ARCHIVE.md` convention** — Established the archive split (with a
  pointer at the bottom of this file) ahead of the BigWigs 125,000-char
  release-body limit; nothing archived yet.
- **`.pkgmeta` ignore list** — Added `**/*.ps1`, `**/*.bat`, `.markdownlintignore`,
  and `CLAUDE.md` so the new dev files stay out of the CurseForge package.

---

## [v1.0.2] (2026-04-02) - Packaging: Ace3 as a Required Dependency

No library code changed.

### Improvements

- **LibStub external replaced with an `ace3` required-dependency** — The
  `externals:` block checked LibStub out of the CurseForge SVN trunk into
  `Libs/LibStub`, which bundled a second LibStub copy into the standalone
  release. Replaced with `required-dependencies: [ace3]`, so CurseForge resolves
  Ace3 (which already carries LibStub and AceComm-3.0) as a client-side
  dependency instead. Embedders are unaffected — they supply their own LibStub.
  Location: `.pkgmeta`.

- **Stale `Libs/LibStub` entry dropped from the VS Code workspace** — Followed
  the external removal so the workspace no longer references a folder the
  packager stops creating. Location: `AceCommQueue-1.0.code-workspace`.

---

## [v1.0.1] (2026-04-01) - Release Documentation

No library code changed.

### Improvements

- **`CHANGELOG.md` added** — Seeded with the v1.0.0 entry and wired to the
  packager via the existing `manual-changelog:` block, so the changelog is
  published as the GitHub release body and the CurseForge changelog.

- **CurseForge description expanded** — Added the problem statement (CTL
  priority-bucket reordering corrupting the receiver's `prefix + sender` spool),
  the integration walkthrough, the suppression-wrapper contract, and the slash
  command reference. Location: `docs/Curseforge_Description.html`.

---

## [v1.0.0] (2026-04-01) - Initial Public Release

### New Features

- **Transparent send queue** — Per-`(prefix, distribution, target)` app-level queue sits on top of AceComm-3.0. Only one message is ever active in ChatThrottleLib at a time for a given channel combination. The next queued message is not submitted until CTL's callback confirms the previous message's final chunk was handed off, eliminating the chunk-interleaving bug that causes CRC-fail INTEGRITY-MISMATCH errors on receivers.

- **Priority-aware draining** — Between messages, higher-priority items drain first (`ALERT > NORMAL > BULK`), matching CTL's own priority ordering. Urgent messages are never held behind lower-priority backlog.

- **Suppression compatibility** — Works with send-suppression wrappers (e.g. in-raid guards). Suppressing wrappers call `callbackFn(callbackArg, 0, 0, nil)` to satisfy last-chunk detection (`0 >= 0`) and unblock the queue cleanly.

- **LibStub versioning** — Standard LibStub upgrade semantics. The highest-MINOR copy loaded wins; older copies are silently discarded. Queue state and debug flag are preserved across upgrades within the same session.

- **Slash commands** — Optional `/acq` command registration via `RegisterSlashCommand("/acq")`. Supports `debug on|off` and `queues` subcommands for runtime inspection without a reload.

- **SetDebug API** — Toggle debug output at runtime via `AceCommQueue:SetDebug(true/false)`.

---

Older releases are archived in [CHANGELOG_ARCHIVE.md](CHANGELOG_ARCHIVE.md).
