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
next: Confirm assumptions A1-A4, run plan-checker, then build the STRANDED mark
---

## Goal

A plan filed on a branch that never opened a pull request has no owner. Mark
such branches `STRANDED <n>d` in dispatch, count them in the verdict, and have
the orchestrator notify a human once. The human stays the only one who lets a
branch plan into the queue.

## Decisions

## Rejected

## Review

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_branch_plans` — the reader.
- `.agents/harness/selftest/dispatch-branch-plans.sh` — the cases.
