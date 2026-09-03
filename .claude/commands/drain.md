---
description: Take the queue's next item, run the Loop on it, exit
---

One item, the full Loop, then stop. Inline — no subagent for the work
itself; the Loop's own review step spawns what it spawns.

The queue stops draining while it still holds work. Counted on `origin/main`
2026-08-29, last 120 merges: 5 of 119 gaps exceed three hours, the two
longest 32.2h and 24.0h, and the tree carried 18, 18, 19 and 11 plan files at
the four longest stalls' first commit. Those numbers argue for the
heartbeat, which fires the next session; they are not an argument for this
session taking a second item. This command makes one session take one item
cleanly, and stop (`.agents/docs/unsupervised.md`).

1. `./joharness.sh drain`. It names the next item, or says DRAINED.
2. Edge work named? Finishing outranks starting (step 2). `/who` it:
   yours or its session gone — take it. Another session `RUNNING` on it —
   say so to the human, skip it, take the next item instead. NEVER merge
   another session's pull request.
3. Run the FULL Loop on that ONE item: claim, build, verify, hand over,
   finish. Every step, not a fast path — a drain that skips review or the
   retire commit spends the time it saves on the next session.
4. Report: what merged, the pull request number, what `drain` says is left.
   Then stop. The next item is the next session's.

## What stops it

The item finishing, in both modes. `./joharness.sh drain` says what is left;
it never orders a second item on the same session.

- **supervised** — the human re-invokes `/drain` for the next item. At
  DRAINED (no unplanned requirement, no free plan, no open question): stop
  and ask. Do NOT invent work.
- **unsupervised** — the heartbeat fires the next session. At DRAINED: exit.
  Nothing is invented; the queue is the whole of the work.

## Limits, stated rather than engineered around

- This drives THIS session, for one item. Making the FLEET outlive its
  sessions is the heartbeat's job, and that is an operator action with money
  attached (`.agents/docs/unsupervised.md`).
- Stop immediately if the human says stop.
