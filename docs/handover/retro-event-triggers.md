---
workstream: retro-event-triggers
status: in-progress
branch: claude/retro-event-triggers-k7m2
pr: none
plan: retro-event-triggers
issue: none
session: https://claude.ai/code/session_01J1YMK5Sd1Dd2vzKcKvG8Gj
agent: opus
updated: 2026-10-29
next: Confirm assumptions A1-A6 against joharness.sh, run plan-checker, then build retro_due/conduct_due floor triggers
---

## Goal

Start retro passes when the evidence calls for them, not only by the
168h clock: stalled/respawns blocks, an untraced CONCERN, or a full sample
make a mode due early once `JOHARNESS_RETRO_FLOOR_HOURS` (default 24) have
passed since its ledger landed.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

- None yet.

## Blockers

None.

## Where to look

- `joharness.sh:retro_due` / `joharness.sh:conduct_due` — the due logic.
- `.agents/harness/selftest/retro.sh` — fixtures.
