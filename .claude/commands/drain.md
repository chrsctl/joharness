---
description: Work the queue item by item until this repo's mode says stop
---

Run the Loop repeatedly instead of once. Inline — no subagent for the
work itself; the Loop's own review step spawns what it spawns.

The queue stops draining while it still holds work. Counted on `origin/main`
2026-08-29, last 120 merges: 5 of 119 gaps exceed three hours, the two
longest 32.2h and 24.0h, and the tree carried 18, 18, 19 and 11 plan files at
the four longest stalls' first commit. A session drains one item and ends;
the next item waits for a human. This command is the loop that does not.

1. `./joharness.sh drain`. It names the next item, or says DRAINED.
2. Edge work named? Finishing outranks starting (step 2). `/who` it:
   yours or its session gone — take it. Another session `RUNNING` on it —
   say so to the human, skip it, take the next item instead. NEVER merge
   another session's pull request.
3. Run the FULL Loop on that one item: claim, build, verify, hand over,
   finish. Every step, not a fast path — a drain that skips review or the
   retire commit spends the time it saves on the next session.
4. Merged? Go to 1. **Re-read `drain`, never remember it.** Other sessions
   merge while this one works, so the queue you read an hour ago is a
   different queue.
5. `drain` says DRAINED — stop, and report what this run did: items merged,
   pull request numbers, what is left and why.

## What stops it

The mode, not this command. `./joharness.sh mode` says which; `drain` prints
the stop.

- **supervised** — DRAINED means no unplanned requirement, no free plan, no
  open question. Stop and ask. Do NOT invent work; that is the other mode.
- **unsupervised** — an empty queue is a trigger. `drain` names the sweep
  and the two stops: GOAL REACHED (no open requirement), or sweep dry with
  the queue empty and no edge work in flight. Say which fired.

Width is the mode's too. Under unsupervised `drain` prints the wave-1
order, one session per plan; supervised drains serially in this session.

## Limits, stated rather than engineered around

- This drives THIS session. When it ends, the drain ends. Making the FLEET
  outlive its sessions is the heartbeat's job, and that is an operator action
  with money attached (`.agents/docs/unsupervised.md`).
- Long run, so compaction will fire. That is survivable and not special: the
  workstream file plus the session-start hook are the re-orientation, which
  is why step 3 says run the full Loop including the handover write.
- Stop immediately if the human says stop, or if two consecutive items fail
  the same way — that is a repo problem, not an item problem, and grinding
  through the queue will not fix it.
