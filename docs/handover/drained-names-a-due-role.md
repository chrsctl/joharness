---
workstream: drained-names-a-due-role
status: in-progress
branch: manage/drained-names-a-due-role
pr: none
plan: drained-names-a-due-role
issue: 428
session: https://claude.ai/code/session_01H4q91vzkXyaN3EyQQyq8mU
agent: sonnet
updated: 2026-10-12
next: Selftest rerun (clerk-fixture case in dispatch.sh) then prove it fails on origin/main joharness.sh, record in Review, ci+verify, retire, PR
---

## Goal

DRAINED verdict must name a due curate/clerk role (plan drained-names-a-due-role).

## Decisions

Predicate mirrors role_slots arithmetic inside the DRAINED branch of cmd_dispatch.

The plan asked for a curate case, but a curate cannot be due at DRAINED (findings need a free/held plan). Used a clerk in its own fixture with real fetch (DISPATCH_FETCH=1), plus the fetch=0 side keeps the exit verdict.

## Review
- r1: proof the new cases fail without the fix: `selftest.sh` on origin/main's joharness.sh gave 2474 passed, 2 failed (a due clerk at DRAINED is named on the verdict; the verdict does not say exit); with the fix 2476 passed, 0 failed, run 2026-10-12 (no change)
