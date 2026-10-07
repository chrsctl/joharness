---
plan: drain-loop
urgency: normal
agent: opus
effort: medium
needs: none
requirement: none
scope: .claude/commands/drain.md, .claude/commands/curate.md, .agents/harness/AGENTS.md, .agents/docs/unsupervised.md, shared:joharness.sh
---

## Goal

Human ask, 2026-10-07: "Add an infinity loop to drain … like the normal loop
just with parallelity 1." `/drain` today takes ONE item and stops; the next
item waits for a human to re-invoke it (supervised) or for the heartbeat
(unsupervised). The orchestrator loops over the whole queue until DRAINED,
with `JOHARNESS_MAX_MANAGERS` items at once. `/drain` should loop the same
way with one item at a time, inline: finish an item, re-read `drain`, take
the next, until DRAINED. The human chose this over the heartbeat Routine
and over `/loop`; it reverses the "one item per session" rule.

## Scope

- `.claude/commands/drain.md` — step 5 loops back to step 1 instead of
  stopping; between items: fresh `origin/main`, re-read the Loop and this
  file (compaction decays rules), new branch per item. "What stops it":
  DRAINED, the human, an item that cannot reach merge, an item above this
  session's tier, a stop-and-ask condition. Parallelity 1: the `spawn one
  session per` line is not this session's order.
- `.claude/commands/curate.md` — the curate is the CURRENT item; under
  `/drain` the loop continues after it.
- `.agents/harness/AGENTS.md` — the "Queue still holds work after the merge"
  paragraph: same session, next item, one at a time; orchestrated managers
  unchanged.
- `.agents/docs/unsupervised.md` — "The one stop": session loops to DRAINED;
  heartbeat re-seeds after the session ends.
- `joharness.sh` — comments only (`cmd_drain` header, curate block) that say
  the next item is the next session's. No behaviour change.

## Out of scope

- `.claude/commands/manage.md` — a manager stays one item; orchestrated mode
  is the parallel loop and unchanged.
- Spawning sessions from `/drain`, any cap knob, any new `joharness.sh`
  output. Parallelity is 1 by construction: the session does the work.
- Creating a heartbeat Routine (operator action, money).

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed (diff touches `joharness.sh`).
- `grep -rn "one item per session\|next item is the next session" .claude .agents joharness.sh`
  — no hit outside `manage.md`.

## Where to look

- `.claude/commands/drain.md` — the whole command.
- `joharness.sh:cmd_drain` — header comment.
- `.claude/commands/orchestrate.md` — the loop this mirrors, at cap 1.

## Traps

- Every item gets the full Loop — claim, review, retire commit, merge. A
  loop is no excuse for a fast path.
- Never merge another session's pull request.
- Protocol text: supervised session, human-asked — fine; never under
  unsupervised.
