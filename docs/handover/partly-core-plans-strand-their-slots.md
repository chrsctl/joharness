---
workstream: partly-core-plans-strand-their-slots
status: in-progress
branch: claude/partly-core-plans-strand-their-slots-5fa1
pr: none
plan: partly-core-plans-strand-their-slots
issue: none
session: https://claude.ai/code/session_01Ea62sjTaRhxvXCtPD1Q4g4
agent: fable
updated: 2026-10-14
next: Run ci and verify, then the verifier at fable, record the review, retire, open the pull request, merge
---

## Goal

Settle `docs/research/partly-core-plans-strand-their-slots.md`: does
dispatch's `DRAINED — nothing free` verdict hide a queue that waits on a
human's core edit? Graduate the answer into `.agents/docs/orchestrated.md`
(Bounds), file the harness change as a plan, delete the research file.

## Decisions

- Answer: YES. Re-measured 2026-10-14 on a scratch queue in this checkout
  (one requirement, one plan serving it, one core path among three scope
  entries): `slots : 4 of 4 free`, `nothing free`, plan under `NOT YOURS —
  CORE ONLY`, requirement absent from `Requirements without plans`, verdict
  `DRAINED — nothing free, nothing in flight: exit, the heartbeat re-seeds`.
  The mechanism is GROUNDED here; gx's dates and counts stay that session's
  reading (WEAK: this checkout cannot see gx).
- Route: keep the de-rank; name the wait. A manager on a partly-core plan
  spends a slot to end `core path:` blocked — same human hand, paid for
  first. A surveyor never splits a plan. Written in orchestrated.md Bounds.
- Research file writes no code: dispatch, selftest and orchestrate.md
  changes are plan `dispatch-names-the-core-wait` in this pull request.
- The wait is a line UNDER the verdict, the stall line's shape, never a
  change to the verdict word: the orchestrator's exit branches on `DRAINED`
  and the selftest matches the line whole.

## Rejected

- Manager builds the non-core part, leaves the core edit as a patch under
  `human-review`: money before the human acts, and the pull request cannot
  merge (all-or-nothing acceptance; label blocks merge). Flagged for the
  human in the pull request body as the alternative if they prefer paid
  slots over idle ones.
- Surveyor splits the plan: `manage.md` R forbids a split, and the core
  remainder has no plan-shaped home (core-only scope is red in `ci`).

## Review

One bullet per finding, written BEFORE its fix, committed WITH it, in exactly
the form `- rN: text (fixed|wontfix: why|no change)` — `ci` checks it. Tag the
verifier's findings `(verifier)`. Clean pass = one bullet saying so. Remove
this paragraph when you add the first bullet.

## Blockers

None.

## Where to look

- `joharness.sh:drain_core_only` — the CORE ONLY list dispatch prints under NOT YOURS.
- `joharness.sh:dispatch` verdict ladder — DRAINED fires on n_free=0, n_wait=0, n_hold=0; CORE ONLY never enters it.
- `.agents/harness/queue-context.sh:qc_scope_class` — `only` vs `some` labels, same de-rank.
- `.claude/commands/orchestrate.md` health table — `status: blocked` row notifies once; no row for CORE ONLY.
