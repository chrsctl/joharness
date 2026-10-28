---
workstream: challenge-before-planning
status: in-progress
branch: manage-challenge-before-planning
pr: none
plan: challenge-before-planning
issue: none
session: https://claude.ai/code/session_01J1YMK6mXq7g3A6BrcNGZYZ
agent: sonnet
updated: 2026-10-28
next: Run ci and verify, then open PR (body: consumers receive .claude/agents/challenger.md at sync and run ci over it)
---

## Goal

Add the `challenger` stranger reader (four lenses) run on a requirement before
planning, and run plan-checker on every plan a planning pass writes.

## Decisions

- A1: confirmed — manage.md sends a requirement straight to `/plan`.
- A2: confirmed — plan-checker spawn is gated to opus/fable in manage.md §2.
- A3: confirmed — sync lists `.claude/agents` dir (checked below).
- A4: confirmed — checked below.

## Review

- r1: ci selftest: manage.md `ref § Challenge;` parsed as heading name (verifier: clean pass otherwise) (fixed)
- r2: verifier could not finish ci/verify in its window; no defect found in the diff (verifier) (no change)

## Blockers

None.

## Where to look

- `.claude/agents/plan-checker.md` — shape to copy.
