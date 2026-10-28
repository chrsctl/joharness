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
next: Write challenger.md, subagents.md lines, manage-reference Challenge section, manage.md clause
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

## Blockers

None.

## Where to look

- `.claude/agents/plan-checker.md` — shape to copy.
