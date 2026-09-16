---
plan: pending-spawns
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: joharness.sh, .claude/commands/orchestrate.md, .agents/harness/selftest/dispatch.sh
---

## Goal

Issue #255, routes 1 and 2 together. `dispatch` counts slots from git, so a
manager is invisible between `create_session` and its first push — 3 to 12
minutes, measured. In that window the count reports a slot free that is
owned, and acting on it puts a fifth manager against a cap of four, which is
the human's money spent by arithmetic rather than by decision.

## Scope

- `joharness.sh`, at `n_slots` — read `JOHARNESS_PENDING_SPAWNS` from the
  environment, digits only, absent or unreadable is 0, and subtract it. One
  line, because every verdict below reads that variable: the spawn count,
  the `OVERLAP-BOUND` gate and the DRAINED reading all follow for free.
  When it is non-zero the slots line SAYS so and names where the number came
  from, or a reader cannot tell a lowered count from a busy fleet.
- `.claude/commands/orchestrate.md` — the duty that supplies it. The
  orchestrator is the only thing that knows a spawn happened before the
  claim lands, and the ledger is where it already records one. State it at
  the spawn step, where it is applied.

## Out of scope

- Reading session state inside `dispatch` (the issue's route 3). It is the
  git view; pulling the control plane in collapses the two-signal separation
  the health table depends on, and the issue says so itself.
- Any conf key. This is a fact about one pass, not a repo setting, and a
  stale conf value would under-report slots for ever with nothing to notice.
- The under-count direction the issue also records — a blocked manager that
  unblocks and reclaims its slot. That is the blocked-versus-live question
  of issue #254, not this one.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- A fixture with N managers in flight prints one fewer free slot with
  `JOHARNESS_PENDING_SPAWNS=1` than without, and the slots line names the
  pending count. Both states asserted.
- The spawn verdict below follows the lowered count, not just the slots
  line: the same fixture tells the reader to spawn one fewer. Asserted,
  because a number that prints correctly and gates nothing is the defect
  this exists to avoid.
- It can only lower: `JOHARNESS_PENDING_SPAWNS` larger than the cap floors at
  0 free rather than going negative, and a non-numeric value reads as 0
  rather than erroring. Both asserted.
- Removing the subtraction reds a positive assertion, not only a refute.
  Verified by reverting, per Loop step 5.
- SHIPS: `joharness.sh` and `.claude/commands/` both reach every consumer,
  so an orchestrator in any repo gets the input and the duty together. In a
  consumer, `JOHARNESS_PENDING_SPAWNS=1 ./joharness.sh dispatch` under
  orchestrated mode prints the lowered count and names it.

## Where to look

- `joharness.sh:n_slots` — one assignment, read by every verdict after it.
- `joharness.sh:num_knob` — the repo's reader for conf-or-env numbers, and
  the reason this one does NOT use it.
- `.claude/commands/orchestrate.md` step 3 and its ledger grammar — where a
  spawn is recorded, which is what makes the count available.

## Traps

- Lower only. A value that could raise the count would spend the cap on
  arithmetic, which is exactly the failure being closed.
- Say it on the line. A silently lowered count is indistinguishable from a
  busy fleet, and the next reader debugs the wrong thing.
