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

## Review

- r1: leftover wording says commits NOTHING though branch may carry code beside the plan (verifier) (wontfix: plan text fixes this wording and dispatch_retired_edges uses it; a plan riding a product PR with its plan retired elsewhere is the stale-claim case the human closes)
- r2: leftover counted per plan and doubled with an edge leftover row for one branch (verifier) (fixed: one row per branch)
- r3: name reuse after the cut reads as leftover (verifier) (wontfix: indistinguishable from git alone; plan Traps only requires the retire postdate the merge base); %h abbreviated hash (fixed: %H)

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_branch_plans`
