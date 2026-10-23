---
plan: roles-beyond-cap
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: joharness.sh, .agents/harness/selftest/dispatch-curate.sh, .agents/harness/selftest/clerk.sh, .agents/harness/selftest/curate-apply.sh, .agents/harness/selftest/scout.sh, .agents/harness/selftest/dispatch-branch-plans.sh, .claude/commands/orchestrate.md, .claude/commands/clerk.md, .claude/commands/curate.md, .agents/docs/orchestrated.md, .agents/docs/orchestrate-reference.md
---

## Goal

Repo owner, relayed from consumer `chrsctl/gx`: `JOHARNESS_MAX_MANAGERS`
should cap managers only. There, dispatch printed `clerk due, held — no free
slot: roles share JOHARNESS_MAX_MANAGERS with managers` (curate the same)
while 4 of 4 slots held managers, and the clerk's last noop marker was 246h
old. Role sessions must still run while every manager slot is full.

## Scope

- `joharness.sh:cmd_dispatch` — `slots` counts managers in flight only: a
  curator or clerk in flight no longer subtracts. `curate DUE` and
  `clerk DUE` spawn beyond the cap, as scout and conduct already do; each
  keeps at most one in flight and its own cadence. `JOHARNESS_MAX_MANAGERS=0`
  holds every role (the human's pause). Printed lines that state the old
  rule change: `takes one slot (roles share JOHARNESS_MAX_MANAGERS)`,
  `held — no free slot`, the `slots` line's role note.
- Surveyor and freer leave the cap too (decision, flagged in the PR body):
  a `free-<key>` claim in flight stops subtracting from `slots`, FREEABLE rows
  stop counting as free manager items, at most one freer in flight; a
  surveyor never subtracted in code, its docs said it did. The OVERLAP-BOUND
  trigger keeps its idle-slot condition: that is what the verdict detects,
  not a budget.
- `joharness.sh:clerk_due` comment — "takes a slot".
- Selftests: the assertions on the old lines change; a new test fails
  without the change: every slot full, dispatch still prints
  `clerk DUE: spawn` and `curate DUE: spawn`.
- Protocol text: `.claude/commands/orchestrate.md` §3,
  `.agents/docs/orchestrated.md` (role table note, clerk row, Concurrency),
  `.agents/docs/orchestrate-reference.md` Role sessions table and notes,
  `.claude/commands/clerk.md`, `.claude/commands/curate.md`.

## Out of scope

- `joharness.conf` — core path; the cap value stays 4.
- The scout and conduct rules — already beyond the cap.
- Any consumer repository; the change reaches gx through the normal sync.

## Acceptance

- `bash .agents/harness/selftest/dispatch-curate.sh` — green, including the
  full-slots case; reverting the `cmd_dispatch` change turns it red.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Plan `ci` calls SHIPS: the dispatch selftests run in every consumer's
  `verify`.

## Where to look

- `joharness.sh:cmd_dispatch` — `n_roles`, `n_slots`, `role_slots`, the
  freeable loop, the DRAINED role_will_spawn branch.
- `.agents/harness/selftest/dispatch-curate.sh` — existing role-slot asserts.

## Traps

- Never edit a core path (`./joharness.sh protocol-paths`).
- Never skip, disable or quarantine a test to get green.
- The test for the fix must FAIL without it.
