---
workstream: conduct-c2
status: in-progress
branch: claude/conduct-c2
pr: none
plan: conduct-c2
issue: none
session: https://claude.ai/code/session_01J1YMK5wBEqA2zM6S2dy3iq
agent: opus
updated: 2026-10-28
next: Run plan-checker on docs/plans/conduct-c2.md, then build c2-run.sh from the prototype
---

## Goal

Add audit question C2 to retro-audit: run the selftest cases a sampled branch
touched once with its change and once without, and read each case's word, so
"Test for a fix must FAIL without it" is checked after merge.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

- None yet.

## Blockers

None.

## Where to look

- `git show c10cee3c:docs/research/conduct-c2-design-prototype/c2-run.sh` — measured prototype.
