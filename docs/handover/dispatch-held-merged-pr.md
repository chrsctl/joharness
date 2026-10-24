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
next: Read ci and verify results (background task output), fix any red, run verifier review, record ## Review, retire files, open PR
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
