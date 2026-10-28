---
workstream: scout-proposal-challenge
status: in-progress
branch: claude/scout-proposal-challenge
pr: none
plan: scout-proposal-challenge
issue: none
session: https://claude.ai/code/session_01J1YMK5C2fe8TYggJmcDRMu
agent: sonnet
updated: 2026-10-28
next: Run ci, verify, verifier review; retire commit; open PR
---

## Goal

Seeded `/scout <idea>` pass; every proposal carries Against and Measure
(plan `docs/plans/scout-proposal-challenge.md`).

## Decisions

- A1-A5: confirmed by reading scout.md, clerk.md, product README (2026-10-28).
- A6: confirmed. Fixture requirement with two clauses each followed by an
  indented `measure:` line, plan `serves: 2`: `./joharness.sh ci` no `serves
  clause` error; `serves: 3`: `DEAD ...: serves clause '3' — requirement
  'zz-fixture' has 2 clause(s)`. Fixtures deleted (2026-10-28).
- Build done by manager directly (three small edits, no workers).

## Review

- r1: (verifier) clerk Never "Plans only" collides with requirement from proposal (fixed: Never carve-out)
- r2: (verifier) open questions answered via §4 trigger gap/wording (fixed: human's counting comment answers)
- r3: (verifier) challenger sees draft lacking Against/Measure (fixed: draft excludes Against, includes Measure draft; none found)
- r4: (verifier) lens rule unseeded, exists scope (fixed: Memory dedupe is unseeded exists)
- r5: (verifier) §3 "only when an answer carries one" vs seeded (fixed: seeded excepted)
- r6: (verifier) seeded pass keeps §3/§4 unclear (no change: same prelude; plan scope)
- r7: (verifier) Measure per clause mapping (fixed: line names its clause)
- r8: (verifier) seed quoted publicly may hold secrets (wontfix: plan mandates quoting; reviewer reads before approval)

## Blockers

None.

## Where to look

- `docs/plans/scout-proposal-challenge.md` — the plan.
