---
workstream: stranded-branch-plans
status: in-progress
branch: claude/stranded-branch-plans
pr: none
plan: stranded-branch-plans
issue: none
session: https://claude.ai/code/session_01J1YMK5JiVnb6MHweCHr34Q
agent: opus
updated: 2026-11-11
next: Read the plan-checker findings, then build the STRANDED mark in joharness.sh:dispatch_branch_plans and its printer
---

## Goal

A plan filed on a branch that never opened a pull request has no owner. Mark
such branches `STRANDED <n>d` in dispatch, count them in the verdict, and have
the orchestrator notify a human once. The human stays the only one who lets a
branch plan into the queue.

## Decisions

- A1: confirmed — `dispatch_branch_plans` computes `days` per row from the oldest add commit.
- A2: confirmed — `own` and `wfs` read the branch's workstream files in the same loop.
- A3: confirmed — `.agents/docs/orchestrated.md` "the scheduler cannot see a pull request".
- A4: confirmed — `knobs-declared.sh` reds a read with no KNOBS row and a dispatch key with no table row.
- "No workstream file" = none ADDED since the merge base, as `release_noclaim_rows` reads it: a requirement manager's plan-only pull request retires its claim before the PR opens, and that edge must not read STRANDED.
- The mark is a suffix on the row (`held 3d  STRANDED 3d`), so every existing row expect still reads its prefix.

## Rejected

## Review

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_branch_plans` — the reader.
- `.agents/harness/selftest/dispatch-branch-plans.sh` — the cases.
