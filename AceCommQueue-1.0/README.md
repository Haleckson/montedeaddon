# AceCommQueue-1.0

A transparent send-queue library for World of Warcraft addons that use AceComm-3.0.

## Quick Start

```lua
-- AceComm-3.0 first, then any SendCommMessage wrapper of your own, then this LAST.
local Ace = LibStub("AceAddon-3.0"):NewAddon("MyAddon", "AceComm-3.0")
LibStub("AceCommQueue-1.0"):Embed(Ace)

-- Send exactly as before. Queueing is transparent.
Ace:SendCommMessage("MYPREFIX", payload, "GUILD", nil, "BULK",
    function(arg, sent, total, delivered, reason)
        if delivered == false then
            -- the client refused it; `reason` says which kind of failure
        end
    end)
```

That is the whole integration. Existing `self:SendCommMessage(...)` call sites keep working unchanged — the signature never changes.

## The contract — five rules

Every one of these fails *silently* when broken, which is why they are worth reading once.

| # | Rule | Consequence of breaking it |
| --- | --- | --- |
| 1 | **`Embed` LAST** — after `AceComm-3.0`, and after any `SendCommMessage` wrapper you install | The queue wraps only part of the chain, so some sends bypass it entirely |
| 2 | **A wrapper that suppresses a send MUST call `callbackFn(callbackArg, 0, 0, nil)`** | That `(prefix, distribution, target)` queue blocks until the stall check releases it — five minutes of delay per message, every message |
| 3 | **Read the callback's 4th argument as a boolean** — never as an `Enum.SendAddonMessageResult` | `Success` is `0`, which is truthy in Lua; a refusal reads as a successful send |
| 4 | **`SetDebug` / `SetRetryPolicy` / `SetStallTimeout` are session-global** — one LibStub instance is shared by every addon that embeds it | You silently change behaviour for other addons, not just your own |
| 5 | **Feature-detect anything above `MINOR` 1** — you get the highest copy loaded in the session, which may be older than the one you built against | An unguarded call to a newer setter errors at load |

Full detail in [Suppression Compatibility](#suppression-compatibility), [Delivery Contract](#delivery-contract) and [Feature detection](#feature-detection--important-if-you-do-not-control-which-copy-loads).

## What you get, and what you do not

You get **ordering** (one message in flight per `(prefix, distribution, target)`, the next not submitted until the previous message's final chunk is confirmed), a **truthful delivery verdict** covering the whole message rather than its last chunk, **automatic retry** of a refused send, **no silent drops**, and **self-recovery** for a queue whose callback never arrives.

You do **not** get any confirmation that a receiver got the message. Every callback in this stack reports *submission* — that the client accepted the bytes — not delivery. Nothing here is an acknowledgement, and end-to-end reliability remains your application protocol's job. See [What ChatThrottleLib actually does underneath](#what-chatthrottlelib-actually-does-underneath).

## The Problem

AceComm-3.0 splits large messages into `FIRST`/`NEXT`/`LAST` chunks and hands them all to ChatThrottleLib (CTL) at once. CTL files each submission into a pipe identified by **(priority, queue name)**, and AceComm names every queue after the prefix alone. So the same prefix sent at two different priorities lands in **two different pipes, in two different priority classes** — which CTL drains *concurrently*, each with its own share of the bandwidth.

(CTL does **not** drain `ALERT` before `NORMAL` before `BULK`. Its priorities get an equal share of available bandwidth when all are backlogged. See [What ChatThrottleLib actually does underneath](#what-chatthrottlelib-actually-does-underneath) — several of its behaviours are the opposite of what the names suggest.)

If a second message is submitted on the same prefix immediately after a large first message, and the two use different CTL priorities, CTL can drain the second message's chunks **ahead of remaining chunks from the first message**. The receiver's AceComm spool is keyed on `prefix + distribution + sender` — one slot per stream. When a new `FIRST` frame arrives mid-stream, the partial spool is overwritten: the assembled payload is a splice of both messages, and any checksum the consumer applies to it fails.

```
BULK  message: FIRST ─── NEXT ─── NEXT ─── LAST
NORMAL message:            FIRST ─ LAST
                                ↑
                      receiver spool corrupted here
```

## The Solution

AceCommQueue-1.0 maintains an **app-level queue** per `(prefix, distribution, target)`. Only one message is ever active in CTL at a time for that combination. The next queued message is not submitted until CTL's callback confirms the previous message's final chunk was handed off.

Between messages, higher-priority items drain first (`ALERT > NORMAL > BULK`), so an urgent message pushed onto the queue still goes out before pending lower-priority traffic.

## Requirements

- LibStub
- AceComm-3.0

Source and issues: <https://github.com/Pimptasty/AceCommQueue>. Published on CurseForge as **AceCommQueue-1.0**.

## Compatibility

One `.toc` covers **Classic Era, Anniversary realms, Burning Crusade, Wrath, Cataclysm, Mists, Retail and World of Warcraft: Forever**. There are no per-flavor code paths: everything the library calls exists on all of them, and the two optional APIs it touches (`C_Timer` for retry backoff, `GetTime` for stall detection) are feature-detected, degrading quietly rather than erroring where they are missing.

Forever (interface `16001`) is the retail client running classic-era content -- `WOW_PROJECT_ID` is `WOW_PROJECT_MAINLINE` there and `select(4, GetBuildInfo())` is `16001` -- so an addon that branches on project ID takes its retail path. This library has no such branch. The plain `AceCommQueue-1.0.toc` is the last TOC the client tries on every flavor, so declaring `16001` in it is all Forever needs; no `_Camelot` file is shipped.

### Feature detection — important if you do not control which copy loads

LibStub resolves the **highest `MINOR` loaded in the session**, and this library ships both standalone and embedded inside other addons. So the copy your code talks to may be **older than the one you developed against** — if a user has an out-of-date standalone install, or another addon embeds an older copy and yours is not present.

Calling an API that copy does not have is a `nil` call error in your addon, not a graceful no-op. Guard anything added after `MINOR` 3:

```lua
local ACQ, MINOR = LibStub("AceCommQueue-1.0")
ACQ:Embed(self)                                    -- always present

if ACQ.SetRetryPolicy then ACQ:SetRetryPolicy(0) end   -- MINOR 5+
if ACQ.SetStallTimeout then ACQ:SetStallTimeout(0) end -- MINOR 5+
if ACQ.Unstick then ACQ:Unstick() end                  -- MINOR 6+
```

| Added in | API / behaviour |
| --- | --- |
| 1 | `Embed`, `SetDebug`, `RegisterSlashCommand`, the queue itself |
| 4 | Rejected sends report `(arg, 0, 0, nil)`; numeric `target` accepted; raised sends reach `geterrorhandler()` |
| 5 | `SetRetryPolicy`, `SetStallTimeout`, automatic retry, stall detection, whole-message delivery verdict, the `reason` argument |
| 6 | `Unstick`, `/acq unstick`, stall **recovery** (release and re-send), ChatThrottleLib consulted before reporting a stall, `reason = "lost"`, default stall timeout 60 → 300 |
| 7 | The stall report states which outcome happened (re-sent, or dropped with `reason = "lost"`) instead of always claiming a re-send; TOC declares Forever (`16001`) and the current build of every flavor. No API change |

The **callback contract degrades safely without guards**: on an older copy the fifth argument is simply `nil`, and the fourth is the final chunk's verdict rather than the whole message's. Code written against the current contract still runs — it just gets less information. Only the two setters can actually error, and only if called unguarded.

If your addon depends on the newer behaviour, declare `## Dependencies: AceCommQueue-1.0` and require the standalone, or embed a current copy in your own `Libs` folder.

## How It Works

`Embed` wraps the addon object's existing `SendCommMessage` with a queued dispatcher. The original `SendCommMessage` — whether AceComm's directly or a chain of wrappers you've already installed — is captured at embed time and called internally by the drain when a slot is available.

All existing call sites in your addon use `self:SendCommMessage(...)` unchanged. Queueing is fully transparent.

### What ChatThrottleLib actually does underneath

Worth reading before you reason about priority, because several things below are the opposite of what the names suggest.

**CTL is neither a Blizzard API nor an Ace3 library.** It is a single public-domain file by Mikk that addon authors copy into their addons. It happens to ship inside Ace3, but it registers as a bare global (`_G.ChatThrottleLib`) with its own version guard, not through LibStub. Whichever loaded copy has the highest `version` wins for the entire client. An addon that never embeds it just calls `C_ChatInfo.SendAddonMessage` directly and is outside its control entirely — CTL can only hook the raw global to *notice* that traffic and yield to it, never stop it. Blizzard provides nothing here but the raw call and a server-side rate limit that disconnects you for exceeding it.

**Priorities are not priorities.** CTL's own header says it plainly: *"Priorities get an equal share of available bandwidth when fully loaded."* `OnUpdate` divides by `nSendablePrios` with no weighting and no preemption, so an `ALERT` gets a **third** of the budget when all three classes are backlogged — it does not go first. The strict `ALERT → NORMAL → BULK` ordering is **this library's**, and serialising here is what makes priority mean anything between messages.

**Pipe identity is `(priority, queueName)`, and AceComm sets `queueName = prefix`.** That has a consequence worth knowing:

- Two messages on the **same prefix at the same priority** land in the **same pipe**, which is strictly FIFO. CTL already delivers them in order and this library adds nothing there.
- Two messages on the **same prefix at different priorities** land in **two pipes, in two classes, draining concurrently with independent budgets**. That is the interleaving that corrupts a receiver's reassembly, and it is the specific case this library exists to prevent.

So the core protection earns its keep exactly when a prefix is sent at more than one priority. If your addon uses one priority per prefix, you are getting the delivery-verdict, retry and no-silent-drop guarantees rather than the ordering one.

**Head-of-line blocking is real.** `Despool`'s loop condition tests only the current ring position's head (`Prio.avail > ring.pos[1].nSize`). If that message does not fit the remaining budget the loop exits rather than advancing to a pipe whose head would fit — so one large frame stalls every other flow in its class until the bucket refills.

**Nothing here is an acknowledgement.** The callback chain reports *submission* — `didSend`, meaning the client accepted it — not delivery. No layer in this stack confirms that a receiving addon got anything. End-to-end reliability is an application-protocol concern, and this library cannot provide it.

## Integration

### Step 1 — Load the library

**As embedded (ship the file in your own Libs folder):**

Add to your `.toc` before your own files:
```
Libs\LibStub\LibStub.lua
Libs\AceCommQueue-1.0\AceCommQueue-1.0.lua
```

**As external (standalone addon, user installs separately):**

Declare the dependency in your `.toc`:
```
## Dependencies: AceCommQueue-1.0
```

### Step 2 — Embed into your addon

In your addon's `OnInitialize` (or equivalent), embed AceCommQueue-1.0 **after** AceComm-3.0 and any `SendCommMessage` wrappers:

```lua
function MyAddon:OnInitialize()
    -- AceComm must already be embedded first
    AceComm:Embed(self)

    -- Optional: install any wrappers around SendCommMessage here

    -- AceCommQueue must be last so it wraps the complete chain
    local ACQ = LibStub("AceCommQueue-1.0")
    ACQ:Embed(self)
end
```

After this, every call to `self:SendCommMessage(...)` in your addon goes through the queue automatically.

### Step 3 — Register the slash command (optional)

If you want to be able to toggle debug output and inspect queue state at runtime, call `RegisterSlashCommand` in `OnInitialize`:

```lua
LibStub("AceCommQueue-1.0"):RegisterSlashCommand("/acq")
```

See the [Slash Commands](#slash-commands) section for what each command does.

## Suppression Compatibility

If your addon has a wrapper around `SendCommMessage` that sometimes suppresses sends (for example, a guard that blocks sends while in a raid), the wrapper **must** call the callback with `(callbackArg, 0, 0, nil)` when suppressing. This satisfies the library's last-chunk detection (`sent >= total`, where `0 >= 0`) and unblocks the queue so it never stalls permanently.

```lua
-- Example suppression wrapper
local originalSend = target.SendCommMessage
target.SendCommMessage = function(self, prefix, text, dist, target, prio, callbackFn, callbackArg)
    if isInRaid() then
        -- Must unblock the queue
        if callbackFn then callbackFn(callbackArg, 0, 0, nil) end
        return
    end
    originalSend(self, prefix, text, dist, target, prio, callbackFn, callbackArg)
end
```

Install this wrapper **before** calling `ACQ:Embed(self)` so AceCommQueue wraps the complete chain.

## Delivery Contract

**This is the part senders most often miss, and it is the difference between a message you know arrived and one you only assume did.**

Every call to a queued `SendCommMessage` ends in **exactly one** terminal callback, if you supplied one:

```lua
callbackFn(callbackArg, bytesSent, bytesTotal, delivered, reason)
```

The fourth argument is the **delivery verdict**; the fifth names the outcome:

| `delivered` | `reason` | Meaning | What you should do |
| --- | --- | --- | --- |
| `true` | `nil` | Every chunk was accepted by the client | Nothing |
| `false` | `"refused"` | The client **refused** it. It did not go out, and the library has already retried | Re-send later, or tell the user — the data did not arrive |
| `nil` | `"suppressed"` | One of your own wrappers dropped it deliberately | **Nothing** — this is your addon working as designed |
| `nil` | `"rejected"` | The library refused the call: empty/non-string prefix, `nil` text, or an unknown priority | Fix the call; the message was never queued |
| `nil` | `"error"` | The send raised. The error has already gone to `geterrorhandler()` | The message did not arrive |
| `nil` | `"lost"` | The send's callback never arrived, ChatThrottleLib has no record of it, and the retry budget is spent | Treat as not delivered. Almost always a wrapper suppressing without calling back — fix that, and the retries will stop being needed |

`reason` was added in `MINOR` 5 because `delivered == nil` alone is ambiguous — it covers a deliberate suppression, where doing nothing is the *correct* response, alongside two cases where a message was genuinely lost. Appending it is backward compatible: a callback declaring four parameters is unaffected.

**Check the fourth argument.** WoW silently discards addon messages under congestion, and ChatThrottleLib retries only its own throttle result — every other refusal is dropped with no retry and no error. That boolean is the only signal that reaches you.

Two consequences worth stating plainly, because they bite good code:

- **`delivered` reflects the whole message, not the last chunk.** If any chunk of a multipart send was refused, you get `false` even though later chunks succeeded. A partial multipart stream reassembles into a corrupt payload on the receiver, so treat `false` as "this message did not arrive", never as "most of it did".
- **It is a boolean, not an enum.** AceComm-3.0 discards ChatThrottleLib's `Enum.SendAddonMessageResult` and forwards only `didSend`. Comparing the fourth argument against `Enum.SendAddonMessageResult.AddonMessageThrottle` (or any other enum member) can never match. There is no way to tell *why* the client refused from up here.

If you supply **no** callback, the library reports a refused message through `geterrorhandler()` itself, so a dropped comm can never be completely silent. Supplying a callback means you have taken ownership of reporting it — a callback that ignores its arguments is the one shape that still loses the signal.

Intermediate chunk callbacks are **not** forwarded. The queue consumes them to detect the final chunk (`sent >= total`) and to watch for a refusal, then calls yours once, at the end.

A send that raises is passed to `geterrorhandler()` as well as reported as `nil` — the queue keeps draining, but the error still reaches your bug catcher exactly as it would with no queue in the way. The same applies to an error raised by *your* callback.

### Automatic retry

When the client refuses a send, the library retries it **3 times with a doubling backoff** (1s, 2s, 4s) before reporting `false`. Retrying is safe: a refused chunk leaves the receiver's spool incomplete, so a retry's fresh `FIRST` frame replaces the aborted stream rather than duplicating a message that already arrived.

The queue for that `(prefix, distribution, target)` stays blocked during the backoff, and the retried message keeps its place at the head of its priority bucket — so ordering survives a retry, and a channel the client just refused does not get more traffic piled onto it.

```lua
ACQ:SetRetryPolicy(retries, baseDelay)   -- defaults: 3, 1
ACQ:SetRetryPolicy(0)                    -- disable; report the refusal immediately
```

### Stall detection and recovery

The queue clears its in-flight slot only when a send's callback arrives. If a callback **never** arrives, that `(prefix, distribution, target)` would be blocked for the rest of the session with every later message waiting behind one that will never finish. In practice this means a `SendCommMessage` wrapper that suppressed a send without calling `callbackFn(callbackArg, 0, 0, nil)` — the one contract this library asks of you.

After **300 seconds without progress** on an in-flight send, the next caller to find that queue busy triggers recovery: the stuck message is **released and re-sent** under the normal retry budget, and the queue carries on. The first stall on each queue is reported through `geterrorhandler()`, naming the queue, how long it was quiet, how many messages were waiting, and **which outcome actually happened**: the message is being re-sent, or its retry budget was already spent (including a host that set `SetRetryPolicy(0)`) and it has been dropped with `reason = "lost"`. Later stalls on the same queue are counted in `/acq status` as `stalls=N` rather than repeated. `/acq status` also shows `idle=Ns` per queue.

```lua
ACQ:SetStallTimeout(seconds)   -- default 300; 0 disables
```

Four properties worth knowing:

- **ChatThrottleLib is asked before anything is reported.** CTL retries a *throttled* send out of its blocked ring several times a second and fires **no callback** while it does — from this library's side, indistinguishable from a callback that was lost. So the check looks the send up in CTL's own queue (matching distribution and target, because AceComm names CTL pipes after the prefix alone and one pipe carries every peer). If CTL still has it, the send is alive and nothing is reported, however long it has been quiet. This is the difference between a real fault and ordinary whisper throttling on a busy realm.
- **Recovery re-sends; it does not drop.** Releasing is safe only because CTL has confirmed it holds nothing of that send — with nothing left in flight there are no chunks for the next message to interleave with. The message goes back at the **head** of its priority bucket, so ordering survives. When the retry budget is spent it is reported `reason = "lost"` and the queue moves on rather than staying blocked.
- **It measures time since the last chunk, not since the send started.** ChatThrottleLib's bandwidth is shared with every other addon on the client, so a large multipart send legitimately takes a long time; a slow-but-progressing send keeps resetting the clock and can never trip this.
- **There is no timer.** The check runs when a caller finds the queue busy — the moment the stall first costs something. A queue that stalls and is never used again is never reported, because nothing is being held up by it. `/acq unstick` forces recovery on demand when you do not want to wait out the timeout.

A callback that arrives *after* its send was released is recognised and ignored, so a very late arrival cannot advance the queue on behalf of a message nobody is waiting for.

Retries are deliberately **bounded**. Because the verdict is a boolean, the library cannot distinguish a `ChannelThrottle` that would succeed on the next attempt from a `NotInGroup` that never will — so an unbounded retry would spin forever on the one case that cannot be fixed. On a client with no `C_Timer` there is no way to back off, so the refusal is reported immediately instead.

## API Reference

### `AceCommQueue:Embed(target)`

Wraps `target.SendCommMessage` with the queued dispatcher.

- `target` — the addon table. Must already have `SendCommMessage` (i.e. AceComm-3.0 must be embedded first).
- Safe to call multiple times; subsequent calls on the same object are silently ignored.
- Returns `target` for chaining, or `nil` if the target was unusable.
- Sets `target.__AceCommQueue_embedded = true`. That flag is part of the contract: code handed someone else's addon object can read it to tell whether sends on that object are queued (one terminal callback) or raw AceComm (one callback per chunk).

### `AceCommQueue:SetRetryPolicy(retries, baseDelay)`

How a send the client refused is retried. See [Delivery Contract](#delivery-contract).

- `retries` — attempts after the first. `0` disables retrying. Default `3`.
- `baseDelay` — seconds before the first retry, doubling each time. Default `1`.
- Both are preserved across a LibStub upgrade, including a deliberate `0`.
- **Session-global**, like `SetDebug`: one LibStub library instance is shared by every addon that embeds it, so this sets the policy for *all* of them. It belongs to the top-level addon, not to a library in the middle.

### `AceCommQueue:SetStallTimeout(seconds)`

Seconds without progress on an in-flight send before the queue is reported as stalled. See [Stall detection](#stall-detection-and-recovery).

- `seconds` — `0` disables the check. Default `300`.
- Floored at twice the total retry backoff, so a retry in progress is never mistaken for a stall.
- Session-global, and preserved across a LibStub upgrade.

### `AceCommQueue:Unstick([key])`

Force a stuck queue to release its in-flight send and carry on, without waiting out `SetStallTimeout`. The released message is re-sent under the normal retry budget.

- `key` — optional queue key exactly as `/acq status` prints it, separators included. Omit to sweep every stuck queue.
- Returns two numbers: how many queues were released, and how many were **left alone** because ChatThrottleLib still holds their message.
- A queue CTL still holds is never released, by this or by the automatic path — releasing it would let the next message's chunks interleave with the ones CTL has yet to send, which is the corruption this library exists to prevent.
- `/acq unstick` calls this with no key.

### `AceCommQueue:SetDebug(flag)`

Enable or disable debug output at runtime.

- `flag` — `true` to enable, `false` to disable.
- Debug is **off by default**.

### `AceCommQueue:RegisterSlashCommand(cmd)`

Register a slash command to control the library at runtime. Call once — either from the host addon's `OnInitialize`, or from a standalone wrapper's `ADDON_LOADED` handler.

- `cmd` — a slash command string including the slash, e.g. `"/acq"`.

## Slash Commands

All commands below assume `RegisterSlashCommand("/acq")` was called. Substitute your chosen command.

| Command | Description |
| --- | --- |
| `/acq` | Toggle debug output on/off |
| `/acq on` | Enable debug output |
| `/acq off` | Disable debug output |
| `/acq status` | Print the current state of all queues — key, in-flight flag, item count per priority bucket, refusal and stall counts, and idle time on an in-flight send |
| `/acq unstick` | Release every stuck queue and re-send what was stuck. Queues whose message ChatThrottleLib still holds are left alone and reported separately |

Debug output appears in the chat frame and includes: enqueue events (prefix, dist, priority, queue depth), drain events (which item is being sent), completion events (bytes sent vs total, suppression detection), send errors, and idle state when all buckets are empty.

## Standalone Distribution

When distributing as a standalone addon, create a standard `.toc` file and register the slash command automatically:

```lua
-- In your standalone ADDON_LOADED handler
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, _, addonName)
    if addonName == "AceCommQueue-1.0" then
        LibStub("AceCommQueue-1.0"):RegisterSlashCommand("/acq")
        -- Optionally read a SavedVariables key here and call SetDebug accordingly
    end
end)
```

When shipped embedded inside another addon's `Libs` folder, do not register the slash command from the library file itself — let the host addon decide whether and with what command to register it.

## Upgrading — what changed for existing integrators

**Read this if your addon already embeds AceCommQueue.** Behaviour changed in `MINOR` 4, 5 and 6, and because LibStub resolves the highest `MINOR` loaded, **an addon that consumes the standalone copy picks these up with no code change of its own**. Nothing here requires action to keep working — but the changes below are visible to your users. (`MINOR` 7 changes only the wording of the stall report and the TOC's interface list.)

### You may see new errors that were previously silent

A send the client **refuses** used to disappear without a trace. It is now reported:

- If you pass a `callbackFn`, it receives `false` as its fourth argument. Nothing goes to the error handler — supplying a callback means you own the report.
- If you pass **no** callback, the library reports the first refusal on each `(prefix, distribution, target)` queue through `geterrorhandler()`, so it lands in the user's bug catcher. Subsequent refusals on that same queue are counted rather than repeated — a player with no guild would otherwise generate one error per message forever, which trains everyone to ignore it. The running total is in `/acq status` as `refused=N`.

If your addon broadcasts on `GUILD`/`RAID`/`PARTY` without checking that the player is actually in one, that is where you will see it. **The error is real** — those messages were being dropped before too; you just could not tell.

### Sends are now retried, so a refused message can take longer to fail

A refused send is retried 3× with a 1s/2s/4s backoff before reporting failure, and that queue is held for the duration so ordering survives. A message that previously failed instantly and silently can now take ~7 seconds to be reported as failed, with later messages on the same key waiting behind it. Successful sends are completely unaffected.

Call `ACQ:SetRetryPolicy(0)` after embedding if you want the old fail-fast behaviour.

### If you check the callback's fourth argument, re-read it

It is now the verdict for the **whole message** rather than the final chunk's, so a multipart send with one refused chunk correctly reports `false` where it previously reported `true`. See [Delivery Contract](#delivery-contract) — in particular, it is a **boolean**, never an `Enum.SendAddonMessageResult` member.

There is also a **fifth argument** now, naming the outcome (`"refused"`, `"suppressed"`, `"rejected"`, `"error"`, `"lost"`). If you count delivery failures, use it: `delivered == nil` on its own cannot tell a deliberate suppression — where doing nothing is correct — from a message that was genuinely lost. Four-parameter callbacks are unaffected.

`"lost"` is new in `MINOR` 6: the send's callback never arrived, ChatThrottleLib has no record of it, and the retry budget is spent. The message's fate is genuinely unknown — it may have reached the wire with only the notification lost, though in practice a message CTL never reported on is one it never accepted.

### A blocked queue now recovers itself

If one of your wrappers suppresses a send without calling `callbackFn(callbackArg, 0, 0, nil)`, that queue used to go quiet forever. It is now released and the message **re-sent** after 300 seconds without progress, or on demand via `/acq unstick` — see [Stall detection and recovery](#stall-detection-and-recovery).

`MINOR` 5 reported this after 60 seconds and named a suppressing wrapper as the cause. That was wrong often enough to matter: ChatThrottleLib retries a throttled send with no callback at all, so ordinary whisper throttling on a busy realm looked identical to a broken wrapper and was reported as one. The check now consults CTL first and stays silent while CTL still holds the message. **Fixing your wrapper is still the right fix** — recovery costs a five-minute delay per message — but you will no longer be blamed for the client's throttling.

### Smaller changes

| Change | `MINOR` | Effect on you |
| --- | --- | --- |
| A rejected message (bad prefix, `nil` text, unknown priority) now calls your callback with `(arg, 0, 0, nil)` | 4 | Your callback fires where it previously did not. Intended: a caller chaining its next send is no longer stranded |
| A numeric `target` (channel index) no longer raises | 4 | Previously an error; now works |
| A large backlog no longer loses messages | 4 | Strictly a fix |
| Errors raised by a send, or by your callback, go to `geterrorhandler()` | 4 | Previously visible only with debug output on |

### If you are a library sitting between a host addon and this queue

If your library is handed the host addon's AceComm-enabled object (`config.aceAddon` or equivalent) and calls `aceAddon:SendCommMessage(...)` on it, you never call `Embed` yourself — **the host does, or does not**. Three things follow, and none of them are true for a normal addon integrator.

**1. You cannot assume the queue is there, and the callback contract differs when it is not.**

| | Callback fires |
| --- | --- |
| Host embedded AceCommQueue | **Once**, at the end, with the whole-message verdict |
| Host did not | **Once per chunk**, with that chunk's `didSend` |

A delivery check written for one shape misbehaves under the other — counting a multipart send as several failures, or waiting for a terminal callback that arrives per-chunk. Detect it on the object you were given:

```lua
if aceAddon.__AceCommQueue_embedded then
    -- one terminal callback, argument 4 is the message-level verdict
end
```

That flag is part of the contract, not an internal — `Embed` sets it and it is safe to read.

**2. Do not call `SetRetryPolicy` or `SetDebug`.** They live on the LibStub library table, so they are **session-global**: every addon in the session that embeds AceCommQueue shares one retry policy and one debug flag. A middle library flipping either changes behaviour for unrelated addons that never asked. Surface it to your host and let the host decide.

**3. Pass a callback so failures land in *your* diagnostics, not the error handler.**

If you send without one, a refused message is reported by **this library** through `geterrorhandler()` — correct, but it attributes the failure to the comm layer rather than to your library's own debug/status surface, and your host has no structured way to see it. Pass `callbackFn`/`callbackArg` (arguments 6 and 7) and record the verdict yourself:

```lua
aceAddon:SendCommMessage(prefix, message, distribution, target, priority,
    function(ctx, sent, total, delivered)
        if delivered == false then
            self:Debug("COMMS", "SEND", "not delivered: %s", ctx.prefix)
            self.lastSendFailed = ctx          -- surface it in your status output
        end
    end, { prefix = prefix, target = target })
```

### If you vendor a copy

Re-vendor it. A vendored copy older than the standalone loses to it at runtime whenever both are installed, so your embedded copy is only what runs for users **without** the standalone addon — which means those users are the ones still on the old behaviour, including the dropped-message bugs.

## Queue Keys

One queue exists per `(prefix, distribution, target)`. The distribution and target are folded to a single case, so `"GUILD"` and `"Guild"` — or `"Bob"` and `"bob"` — address the same queue rather than silently running two in parallel. A numeric `target` (a channel index, which AceComm accepts) is supported.

Messages on different keys are independent: two prefixes, or two whisper targets, progress at the same time. Only same-key traffic is serialized, because only same-key traffic can corrupt a receiver's spool.

## Tests

The library ships an offline unit-test suite that runs outside the game, against the **real** Ace3 stack (`CallbackHandler-1.0`, `ChatThrottleLib`, `AceComm-3.0`) loaded from the sibling `Ace3` addon folder — including an end-to-end reproduction of the chunk-interleaving corruption this library exists to prevent.

```sh
git submodule update --init            # once, for the shared test harness
lua Tests/wowapi/run.lua               # run the suite (needs only Lua 5.1)
lua Tests/wowapi/coverage.lua AceCommQueue-1.0.lua   # run it with a line-coverage report
```

`Tests/` is excluded from the packaged release.

## LibStub Versioning

The library follows LibStub's upgrade semantics. The `MINOR` integer is bumped with each revision during development. The highest-`MINOR` copy loaded wins; older copies loaded afterward are silently discarded. The library name (`AceCommQueue-1.0`) does not change between revisions — only between breaking API changes.

Per-queue state (`queues` table) and the `debug` flag are preserved across LibStub upgrades within the same WoW session.
