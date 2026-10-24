---
workstream: dispatch-held-merged-pr
status: in-progress
branch: manage/dispatch-held-merged-pr
pr: none
plan: dispatch-held-merged-pr
issue: 594
session: https://claude.ai/code/session_01GjKnsgJV4qubTD63CuMiH7
agent: sonnet
updated: 2026-10-24
next: ci red only on selftest git-exec budget (89316 vs 88960 on branch); compare with baseline origin/main ci in /tmp/basewt (task bnq6q169b); trim fixture or justify budget bump, then verify, verifier review, retire, PR
---

## Goal

`dispatch` `plans on a branch` line says `N commit(s) after merged PR #n` when the holding branch's `pr:` merged and the tip is ahead (issue #594 case 2).

## Decisions

- Built: dispatch_branch_plans emits a 7th field (0 or n:pr) from workstream pr:; bplans awk appends it. Selftest case in dispatch-branch-plans.sh (own fixture repo). ci/verify not yet confirmed green.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — `bplans` awk.
