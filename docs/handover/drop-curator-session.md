---
workstream: drop-curator-session
status: in-progress
branch: claude/drop-curator-session
pr: none
plan: drop-curator-session
issue: none
session: https://claude.ai/code/session_01J1YMK3gRRT247pnBtKeY8z
agent: sonnet
updated: 2026-10-28
next: Run verifier, verify, then retire and open PR
---

## Goal

Remove the curator session role and its clock; keep `./joharness.sh curate`.
Plan: `docs/plans/drop-curator-session.md`.

## Decisions

- A1: confirmed — cycle_unreadable / cycle_repo_age_h are used by clerk, scout, conduct and retro clocks (joharness.sh).
- A2: confirmed — ci reaches curate_repairs through lint_plans_in_diff only.
- A3: confirmed — no curate_* or JOHARNESS_CURATE_* use near OVERLAP-BOUND.
- Consumer conf setting JOHARNESS_CURATE_HOURS/_PLANS stays green (undeclared keys tolerated, new knobs-declared case): no retired-key shim needed.
- Selftest counts: 3847 passed before, 3742 after. Removed cadence expects: dispatch-curate 100, curate-apply 2, role 5 (+2 added), scout 1, reading-budget 1; kept curate-output cases: 43 in dispatch-curate.

## Review

## Blockers

None.

## Where to look

- `docs/plans/drop-curator-session.md` — the scope list.
