---
research: frozen-cost-is-not-death-yet
urgency: normal
agent: opus
effort: high
graduates: .claude/commands/orchestrate.md
---

<!--
Split out of `docs/research/push-age-is-not-death.md` (issue #283) when that
node closed. Its half — may a row order a respawn on push age — was answered
NO and graduated (`.agents/docs/orchestrated.md`, "And push age is not death
either"; code in PR #362). This is its option 2, which it said must land
separately: a new class of evidence, not a deletion. Recover the parent:
`git log --diff-filter=D -p -- docs/research/push-age-is-not-death.md`.
-->

## Question

May the orchestrator's health table read a frozen `cost_usd` as evidence of
death, and if so, after what minimum frozen window?

## Echo

Every field the health table now keys on — `status_bucket`, `updated_at`,
the head from git — has been measured frozen on a session that was alive.
`cost_usd` is the one field #283 found that separated a dead session from a
suspended one. But a live `IDLE` manager also held cost still for up to 31
minutes, and a `RUNNING` one froze every field, cost included, for 172s. So
the question is whether frozen cost is a death signal at ANY window, and
what floor would keep it from killing a live session. It would put a
control-plane money field into the evidence table for the first time.

## Sweep

`goal-directed` — enough readings, with known outcomes, to set or refuse a
floor. Not a survey of every session field: the four others below are
already refuted.

## What would settle it

- **A frozen-cost window on a session known DEAD, and the longest one on a
  session known ALIVE, both re-sampled by a context that can read the plane.**
  A floor above every alive window and below the dead ones settles YES with a
  number; overlap settles NO.
- **The suspension case.** A suspended fleet freezes cost too (negative
  control below). Whatever test is written must not fire across a
  suspension, or it is push age's mistake in a new field.

## Method

Not yet run. Readings below are the issue's. The verifier
(`.claude/agents/verifier.md`) has no control-plane call, so the second
context must be named up front: the operator, or a session tooled for the
plane (issue #267; the verifier's own "What you cannot see"). Read first:

    git log --diff-filter=D -p -- docs/research/liveness-in-a-long-turn.md
    git log --diff-filter=D -p -- docs/research/push-age-is-not-death.md

## Findings

All WEAK: issue #283 and its comment, re-read against the issue and never
re-sampled.

- **Five signals, four refuted.** Push age (wrong 3 for 3 at the largest
  age, 2026-10-05); `updated_at` (a sweep artefact, two unrelated sessions
  1.6 ms apart); `status_detail` / `task_summary` (byte-identical across 23
  minutes of live work); `connection_status` (`connected` survives death);
  `worker_epoch` (bumped 4→5 on a corpse at frozen cost on 2026-09-17, and
  1→2 on all three survivors across the suspension — moves in both cases).
  `cost_usd` alone separated them.
- **Negative control.** A session read at `136.9262205` on
  2026-09-17T19:31:07Z with an unmoved head, open as possibly dead, read at
  `144.76052` after the 18-day suspension — suspended, never dead.
- **Four alive windows.** 2026-10-07, one live manager, `IDLE`,
  `connected`, turn ended on a background run: 28.058789 20:19:50Z–20:38:09Z
  (18m19s), 32.2565868 21:15:04Z–21:34:19Z (19m15s), 36.8669214
  22:11:07Z–22:30:41Z (19m34s), 42.1354032 22:55:14Z–23:26:01Z (30m47s).
  Reads 13–15 minutes apart met a two-reads-plus-IDLE-plus-unmoved-head test
  on every one. It finished its work.
- **The all-fields freeze.** `.agents/docs/orchestrated.md`: a `RUNNING`
  manager with every leaf key byte-identical, cost included, for 172.273s
  while working. From saved pages, re-computable, never confirmed real.
- **Precedent.** A sentence licensing a kill on a 13-minute frozen pair was
  graduated once and withdrawn on review (`orchestrated.md`, under the knob
  table). A floor below 31 minutes repeats it.
- **No such test exists today.** `git grep -n cost_usd -- .claude .agents`
  finds it only in `.agents/docs/orchestrated.md`, never in the health
  table — so #283's comment proposing a "floor" under a frozen-cost test
  names a test the table does not carry.

## Consequence for the queue

No plan waits on this. If it settles YES, a plan adds one row to
`.claude/commands/orchestrate.md` step 2's evidence table, with the floor
and the windows that set it.

## Verification

Not yet run. Every finding above is WEAK for the reason in `## Method`.

## Graduates to

`.claude/commands/orchestrate.md` — the step 2 evidence table, where every
kill the orchestrator orders is keyed.
