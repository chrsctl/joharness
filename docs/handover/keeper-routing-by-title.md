---
workstream: keeper-routing-by-title
status: in-progress
branch: claude/keeper-routing-by-title
pr: none
plan: keeper-routing-by-title
issue: none
session: https://claude.ai/code/session_01XeXyvPqHBEa67tQe5q8JrV
agent: opus
updated: 2026-10-16
next: Replace the argument routing with title routing, add needles
---

## Goal

Stop orchestrators running the Keeper section (gx runaway, 2026-10-16).

## Decisions

- Route by `get_session` title: the title is set by `create_session`
  before the first turn, and no prompt text can change it. Evidence:
  session_01YbGi98QX7H7Ue8AQQyeuwe, prompt `/orchestrate pass`, said "I
  took the notice's `keeper` argument over the `pass` arguments".

## Rejected

- Argument routing (`/orchestrate keeper`): measured misread above.

## Review

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` top routing line, "## Keeper".
