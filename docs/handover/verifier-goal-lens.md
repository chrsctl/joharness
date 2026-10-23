---
workstream: verifier-goal-lens
status: in-progress
branch: manage/verifier-goal-lens
pr: none
plan: verifier-goal-lens
issue: none
session: https://claude.ai/code/session_01D3dVxiGmbtVBBrjqBdtrJg
agent: sonnet
updated: 2026-10-23
next: Add goal-lens section to .claude/agents/verifier.md and one sentence to agent-selection.md Review depth
---

## Goal

Verifier gets a goal-backward lens: plan Goal/Acceptance clauses reported COVERED, STUB, UNWIRED, MISSING, UNVERIFIED.

## Decisions

## Rejected

## Review

- r1: goal lens, plan verifier-goal-lens: Goal clauses COVERED; Acceptance 1 (grep count 5) COVERED, Acceptance 2 (`ci: pass`, glossary: no new term) COVERED, Acceptance 3 (this spawn, result recorded here) COVERED once recorded (verifier) (no change)
- r2: no defects in the diff; manage.md step 5 does not name the plan stem, out of scope per plan (verifier) (wontfix: plan puts manage.md out of scope)

## Blockers

None.

## Where to look

- `.claude/agents/verifier.md` — new section.
