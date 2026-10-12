---
workstream: branch-plan-done-on-main
status: in-progress
branch: claude/branch-plan-done-on-main
pr: none
plan: branch-plan-done-on-main
issue: 423
session: https://claude.ai/code/session_01DBge7Ng2dPpNZwrYjn7XCX
agent: opus
updated: 2026-10-12
next: Research dispatch_branch_plans and its readers, then build DONE ON MAIN + held Nd
---

## Goal

Issue #423 pieces C and age-half of D: each `plans on a branch` row in
dispatch says whether its stem is already done on main and how long it has
been held.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

- None yet.

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_branch_plans` — the row producer.
- `joharness.sh:cmd_dispatch` — the NF readers.
