---
workstream: carried-plan-leftover
status: in-progress
branch: carry-plan-leftover
pr: none
plan: carried-plan-leftover
issue: none
session: https://claude.ai/code/session_013WhZ4JbA3WMrdZqaLXhj8F
agent: sonnet
updated: 2026-10-10
next: Read selftest dispatch output (bgxhx8p6z); confirm new fixture passes and fails without change; then ci, verify, review, retire, PR
---

## Goal

Carried-and-retired plan on an unmerged branch prints as a leftover, not a plan on a branch.

## Decisions

- Leftover rows are 5-field (trailing "leftover") from dispatch_branch_plans; dispatch folds them into leftover_rows; plans-on-a-branch awk keeps NF==4.

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_branch_plans`
