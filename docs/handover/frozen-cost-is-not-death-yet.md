---
workstream: frozen-cost-is-not-death-yet
status: in-progress
branch: claude/frozen-cost-is-not-death-yet
pr: none
plan: frozen-cost-is-not-death-yet
issue: none
session: https://claude.ai/code/session_01GYdGcmwBnhagB59b3g1UXa
agent: opus
updated: 2026-10-10
next: Run ci and verify, verifier review, retire, PR, merge
---

## Goal

Settle `docs/research/frozen-cost-is-not-death-yet.md`: may the health table
read a frozen `cost_usd` as death, and after what floor. Graduate to
`.claude/commands/orchestrate.md` step 2, delete the research file.

## Decisions

- Settled NO, no floor: `usage.cost_usd` is a turn-end write (30/30 rows,
  usage iff post_turn_summary), so frozen on RUNNING = turn length, on IDLE =
  by definition. A live RUNNING manager read with no cost for 101 minutes.
- Graduation = one entry in orchestrate.md step 2 "decide nothing" list, the
  why in orchestrated.md beside push age. No new table row.

## Rejected

- A RUNNING-only floor: the 101-minute first turn with no cost refutes it;
  no knob bounds a turn's length.

## Review

- r0: not yet reviewed (no change)

## Blockers

None.

## Where to look

- `docs/research/frozen-cost-is-not-death-yet.md` — the item.
- `.claude/commands/orchestrate.md` step 2 — graduation target.
- `.agents/docs/orchestrated.md` — push-age and knob-table precedent.
