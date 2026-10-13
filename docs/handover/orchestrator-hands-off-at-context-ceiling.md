---
workstream: orchestrator-hands-off-at-context-ceiling
status: in-progress
branch: claude/orchestrator-hands-off-at-context-ceiling
pr: none
plan: orchestrator-hands-off-at-context-ceiling
issue: none
session: https://claude.ai/code/session_01LhNpou3t5necUED7S7hFeJ
agent: opus
updated: 2026-10-13
next: Run selftest and ci, then verifier review at opus, retire, PR, merge
---

## Goal

Orchestrator hands its ledger to a fresh successor session after
`JOHARNESS_ORCHESTRATOR_PASSES` passes, so pass N stops re-reading passes
1..N-1 at cache-read price.

## Decisions

- Hand-off text lives in orchestrate.md §4 as a HAND-OFF block after the
  `harness=` recompute rule: it replaces the arm, so it sits where the arm is.
- Trigger: the `pass=` the arm would write exceeds dispatch's `passes :`
  line. Default 6 hands off at pass 6 (it would arm 7).
- One `get_session` self-read per pass feeds the `context:` line, §3's own
  id and the hand-off model, so the report line costs no extra call.
- DRAINED/PAUSED and the out-of-band arm never hand off: nothing is armed
  there, and the pass the out-of-band wake fires decides.
- `knobs-declared-once` not on main: no `KNOBS` row.
- Selftest cases in `selftest/orchestrated.sh` (plan scope), not
  `selftest/dispatch.sh` where other header cases live.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `docs/plans/orchestrator-hands-off-at-context-ceiling.md` — the plan.
