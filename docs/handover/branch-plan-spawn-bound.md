---
workstream: branch-plan-spawn-bound
status: in-progress
branch: claude/branch-plan-spawn-bound
pr: none
plan: branch-plan-spawn-bound
issue: none
session: https://claude.ai/code/session_01PN6Nqao6ybhpUNmB9wKKvb
agent: sonnet
updated: 2026-10-10
next: Edit orchestrate.md "Report, every pass" and manage.md step 0, then ci
---

## Goal

Put the branch-plan spawn bound (orchestrated.md, "A plan the queue cannot see") into orchestrate.md and manage.md.

## Review

- r1: acceptance grep matched only orchestrate.md; manage.md said "Carry the plan" capitalised (verifier) (fixed: now lowercase mid-sentence)
- r2: manage.md new paragraph sat under the resume rule and could be read as a resume (verifier) (fixed: "Not a resume")
- r3: orchestrated.md still said the commands lack the bound (verifier) (fixed: sentence rewritten; outside plan Scope, a stale claim this diff made false)
- r4: workstream file missing from diff (verifier) (wontfix: committed at claim, 56f6d29c)

## Blockers

None.
