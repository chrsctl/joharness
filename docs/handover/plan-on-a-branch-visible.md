---
workstream: plan-on-a-branch-visible
status: in-progress
branch: claude/plan-on-a-branch-visible-x7k2
pr: none
plan: plan-on-a-branch-visible
issue: 297
session: https://claude.ai/code/session_011826jrSc2fYHWmqxniAGSN
agent: opus
updated: 2026-10-10
next: Research dispatch_rescope_branches, then add dispatch_branch_plans + block + fixtures
---

## Goal

Issue #297: `dispatch` reads `docs/plans/` on the base branch only, so a plan
riding on an unmerged branch is invisible to the orchestrator. Print such
plans in a block (never free, never counted), tell the orchestrator to
report URGENT ones first, and tell the manager to drive its own plan-only
pull request to merged.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_rescope_branches` — ref walk to copy.
