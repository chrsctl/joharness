---
workstream: dispatch-held-merged-pr
status: blocked
branch: manage/dispatch-held-merged-pr
pr: none
plan: dispatch-held-merged-pr
issue: 594
session: https://claude.ai/code/session_01GjKnsgJV4qubTD63CuMiH7
agent: sonnet
updated: 2026-10-24
next: defect: #603: ci red on origin/main, selftest git execs 89189 over budget 88960; item code+selftest done on branch
---

## Goal

`dispatch` `plans on a branch` line says `N commit(s) after merged PR #n` when the holding branch's `pr:` merged and the tip is ahead (issue #594 case 2).

## Decisions

- Built: dispatch_branch_plans emits a 7th field (0 or n:pr) from workstream pr:; bplans awk appends it. Selftest case in dispatch-branch-plans.sh (own fixture repo). ci/verify not yet confirmed green.

## Review

## Blockers

ci reds only on the selftest git-exec budget, reproduced on origin/main 202a48ca (89189 vs 88960); branch adds 127 (89316). Filed #603. Resume once main is green or the budget is raised.


## Where to look

- `joharness.sh:cmd_dispatch` — `bplans` awk.
