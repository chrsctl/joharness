---
research: noop-curate-stays-due
urgency: normal
agent: sonnet
effort: medium
graduates: .claude/commands/curate.md
---

## Question

After a curator pass that finds nothing to propose, does `dispatch` keep
reporting `curate : DUE` even though the clock that pass should have reset
is unchanged?

## Echo

`curate.md` §0 step 2 says: "No PROPOSE findings = say so and exit: nothing
to do spawns nothing and writes nothing." The clerk handles the same case
differently. `clerk.md` §4: "No plans written = no pull request … Push the
no-op record instead, so the clock dates this pass" — a `clerk-noop-<stamp>`
branch, which `dispatch` reads (`orchestrated.md`, the `clerk :` row). The
curate clock has no such record, so a pass that found nothing leaves the
clock where it was. Every later orchestrator run sees `curate DUE` again,
spends a curator slot, and gets the same empty answer. The answer decides
whether `curate.md` needs the clerk's no-op record, or something like it.

## Sweep

`goal-directed`: one measured instance in `chrsctl/gx`, plus the two role
commands' text.

## What would settle it

YES if `dispatch` prints `curate : DUE` after a curator pass that exited with
no findings, with the same count as before that pass. NO if the count reset,
or the clock reads anything that pass left behind.

## Method

In `chrsctl/gx`, 2026-10-13:

```
JOHARNESS_PENDING_SPAWNS=0 ./joharness.sh dispatch   # 02:23Z, before the curator
# curator session spawned 02:23Z (sonnet), title "curator: 2026-10-13"
JOHARNESS_PENDING_SPAWNS=0 ./joharness.sh dispatch   # 02:36Z, 02:50Z, 03:05Z, after it
```

## Findings

- **The curator found nothing and wrote nothing.** Its final summary read:
  "curate pass: no findings; all 3 plans held, no changes … no workstream,
  branch, or PR was created" (control plane, session updated 02:24Z).
- **Dispatch stayed DUE at the same count afterwards.** At 03:05Z dispatch
  printed `curate : DUE — 10 plan file(s) changed since the last curate (>=
  10)`, the same reason it gave at 02:23Z, before the pass. It also printed
  `verdict : DRAINED — nothing free, nothing in flight; a role is due: spawn
  it, then schedule the next pass`. So the fleet does not drain at all,
  unless the orchestrator applies its own "at most ONE of each per run" rule.
- **The clerk does not have this problem.** In the same run the clerk read
  `not due — 0h since the last clerk pass found nothing to plan
  (clerk-noop-20261013T014903Z)`, right after its own empty pass.

Cost here: one sonnet curator session that could do nothing (0.11 USD). Every
new orchestrator run from now on spends a curator on the same empty answer,
until 10 more plan files change or a curate merges.

## Consequence for the queue

Canonical decides. The obvious candidate mirrors the clerk:
`curate.md` §0 step 2 pushes a `curate-noop-<UTC stamp>` branch at
`origin/main` when there are no PROPOSE findings, and the `curate :` clock in
`dispatch` (and `orchestrated.md`'s row for it) dates from the newer of the
last curate merge and that branch. The alternative is to say outright that
a no-op curate is meant to recur, and have dispatch stop printing "a role is
due" for it once one has run.

## Verification

UNVERIFIED by a second context. The dispatch lines and the curator summary
are from one orchestrator session in `chrsctl/gx`.

## Graduates to

`.claude/commands/curate.md` §0 step 2, the sentence that writes nothing.
The dispatch clock follows from what that sentence leaves behind.
