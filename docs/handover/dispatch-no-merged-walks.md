---
workstream: dispatch-no-merged-walks
status: in-progress
branch: claude/dispatch-no-merged-walks
pr: none
plan: dispatch-no-merged-walks
issue: #465
session: https://claude.ai/code/session_01VcA3PGAEEETfXDJJyQ3xn1
agent: sonnet
updated: 2026-10-13
next: Read selftest full.txt/rev.txt in scratchpad (new case PASS on new, FAIL on reverted), then ci, verify, review, retire, PR
---

## Goal

Plan docs/plans/dispatch-no-merged-walks.md: one for-each-ref call per merged filter.

## Blockers

None.

## Progress

- refs_unmerged / refs_merged helpers in joharness.sh; all seven walks converted; selftest case appended to dispatch.sh. Missing base ref lists every ref (old behaviour).
- Measured 2026-10-13, DISPATCH_FETCH=0, same checkout: dispatch 45s -> 13s, janitor 15s -> 1s; dispatch output diff = ages only.
