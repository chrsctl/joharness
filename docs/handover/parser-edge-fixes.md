---
workstream: parser-edge-fixes
status: in-progress
branch: manage/parser-edge-fixes
pr: none
plan: parser-edge-fixes
issue: none
session: https://claude.ai/code/session_016U698AEBhNudBfB2LQf6f1
agent: sonnet
updated: 2026-10-22
next: Build the plan's fixes in joharness.sh, one selftest case each
---

## Goal

Implement docs/plans/parser-edge-fixes.md.

## Decisions

## Rejected

## Review

- r1: finish test never reached checks_gate (no JOHARNESS_CHECKS=local) (verifier) (fixed)
- r2: fb_cache_save test passes on old eval too; the refactor is behaviour-neutral, no red case possible (verifier) (no change)
- r3: issue_verdict printed an empty number for #000 (verifier) (fixed)
- r4: fb_marker rejected a verdict followed by a period (verifier) (fixed)
- r5: FB_LIMIT wrapped past 9 digits (verifier) (fixed)
- r6: branch behind origin/main (verifier) (fixed)
- r7: duplicate section header in feedback.sh (verifier) (fixed)
- r8: new cases red on origin/main: marker, zeros, continuation, churn, role_line 141 (no change)

## Blockers

None.

## Where to look

- `joharness.sh` functions named in the plan.
