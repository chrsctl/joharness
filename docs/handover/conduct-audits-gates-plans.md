---
workstream: conduct-audits-gates-plans
status: in-progress
branch: claude/conduct-audits-gates-plans
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_017pMbD2M6TccgTkfZh9TDpS
agent: opus
updated: 2026-10-25
next: Write the two plans, run ci, verifier, open the plans-only pull request
---

## Goal

User reviewed whether conduct is necessary and chose to improve it, not
delete it. Today conduct audits old work, asks one narrow question, and
nothing acts on what it finds. Plans: C1 moves into the verifier and
plan-checker as prevention; conduct becomes an auditor of the gates (recent,
risky sample; C2 "a fix's test fails without it"; CONCERN feeds retro; rate
visible in dispatch).

## Decisions

- Two plans, not one: C1 at the gates is independent and small.
- C2's runtime is measured as the build's first step, not a separate
  research item: the user picked a plan.

## Rejected

- Deleting conduct: it is the only independent measure of the gates.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:conduct_candidates`: the sample sorts all history by hash.
