---
description: Work the queue item by item, the full Loop on each, until DRAINED
---

The orchestrator's loop at parallelity 1. Take the next item, run the full
Loop on it, merge, take the next — until DRAINED. One item at a time,
inline: no subagent for the work itself, no session spawned; the Loop's own
review step spawns what it spawns.

The queue stops draining while it still holds work. Counted on `origin/main`
2026-08-29, last 120 merges: 5 of 119 gaps exceed three hours, the two
longest 32.2h and 24.0h, and the tree carried 18, 18, 19 and 11 plan files at
the four longest stalls' first commit. A session that stops after one merge
leaves the rest of that queue to whoever comes next; this one does not.

1. `./joharness.sh drain`. It names the next item, or says DRAINED.
2. Edge work named? Finishing outranks starting (step 2). `/who` it:
   yours or its session gone — take it. Another session `RUNNING` on it —
   say so to the human, skip it, take the next item instead. NEVER merge
   another session's pull request.
3. No edge work of yours, and `curate    : DUE` with none in flight? THAT is
   this item, ahead of the queue: the plan queue has moved under its
   own declarations, so the plans you would otherwise pick are describing
   themselves wrongly. Read `.claude/commands/curate.md` WHOLE and follow it —
   one pass, one pull request, then step 6. Nothing is invented: every plan it
   touches already exists, which is why an unattended session may take it too.
   A curate already IN FLIGHT is somebody else's; carry on to the queue.
   AFTER the edge, never before it: Loop step 2 is "Finishing outranks
   starting", and `drain` prints the blocks in that order for the same reason. A
   session that took a curate while its own branch sat at the edge would leave
   that branch to rot.
4. Item's `agent` tier above this session's model? Not yours to implement
   (Loop step 2): stop the loop, report it with the tier it wants.
5. Run the FULL Loop on that ONE item: claim, build, verify, hand over,
   finish. Every step, not a fast path — a drain that skips review or the
   retire commit spends the time it saves on the next item. Its own branch,
   cut from fresh `origin/main`; never stack the next item on the last.
6. Merged? Report one line: what merged, the pull request number. Then
   between items, every time:
   - `git status` clean, every branch you made merged or pushed — nothing
     of yours lives only here. Then `git fetch origin main`; the next
     branch is cut from that (step 5).
   - Re-read `.agents/harness/AGENTS.md` and THIS file, whole. Rules decay
     over a long context and task state survives — measured
     (`.agents/docs/handover/README.md`, Compaction). Item N+1 deserves the
     rules item 1 had.
   - Back to step 1.

Parallelity 1 is the whole difference from `/orchestrate`. `drain`'s
`spawn one session per:` line is the fleet's fan-out, not this session's
order: spawn nothing, the other plans wait their turn here. Want more
than one at once? That is orchestrated mode and `JOHARNESS_MAX_MANAGERS`
— the human's number, not this command's.

## What stops it

- **DRAINED** — supervised: stop and ask. Do NOT invent work.
  Unsupervised: exit; nothing is invented, the heartbeat re-seeds.
- **The human says stop.** Immediately, mid-item included: hand over, push.
- **An item that cannot reach merge** — blocked, waiting on a human, a
  stop-and-ask condition (money, credentials, hardware, product direction,
  a conflict into `main` that does not resolve clean). Hand it over with
  `status: blocked`, push, stop, say why. Never skip to the next item:
  finishing outranks starting, so `drain` would name it again anyway, and a
  loop that leaves a trail of half-built branches is worse than one that
  stopped.
- **An item above this session's tier** (step 4).
- **The session's own end** — a turn limit, a reclaimed container. The
  workstream file is the defence, as always: same commit as code, pushed.

## Limits, stated rather than engineered around

- This drives THIS session. Making the FLEET outlive its sessions is the
  heartbeat's job, and that is an operator action with money attached
  (`.agents/docs/unsupervised.md`).
- No cap on items. One item costs what it costs, and the loop multiplies
  it by the queue; the human's lever is "stop", which this command obeys at
  once.
