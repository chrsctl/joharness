---
workstream: hold-until-fix-retires
status: in-progress
branch: claude/hold-until-fix-retires
pr: none
plan: hold-until-fix-retires
issue: none
session: https://claude.ai/code/session_01J1YMK4wp9cyBubHVHvhdvK
agent: sonnet
updated: 2026-11-10
next: Build per the plan, then ci, verify, review.
---

## Goal

Red-base HOLD lifts only when the fix retires, not when a plan names the
issue (chrsctl/gx, 2026-11-10, #1449).

## Decisions

- The fix plan row is the one exemption, read by its own `issue:` on the
  base: holding it would deadlock the hold.

## Rejected

None yet.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — `dpark` / `dhold`.
