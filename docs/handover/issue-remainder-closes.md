---
workstream: issue-remainder-closes
status: in-progress
branch: claude/clever-pascal-qz32iv
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_01J1YMK5fH2288GR1soijKET
agent: haiku
updated: 2026-11-20
next: Run ci and verify, review, open PR
---

## Goal

Report PR #789 (consumer gx): `Closes #N` is chosen from the plan's
`## Issue remainder` heading alone, so an issue closes as completed while its
PR body or the plan's `## Out of scope` names an undone part (5 of 134 gx
`Closes` PRs). Fix: decide `Closes`/`Refs` at PR open from every place an
undone part shows, and have the plan-checker red a deferral without the heading.

## Decisions

- Report options 1 and 2 both taken: 1 covers the build-time route (4 of 5
  cases), 2 the clerk-wrote-wrong-heading route. Option 3 (mechanical check)
  skipped: no marker exists for "deferred to a human".
- #789's research node not carried: the fix answers its question; the human
  closes #789.

## Rejected

- None.

## Review

## Blockers

None.

## Where to look

- `.agents/docs/manager-reference.md` § Plan issue — the Closes/Refs rule.
