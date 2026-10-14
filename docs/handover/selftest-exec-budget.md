---
workstream: selftest-exec-budget
status: in-progress
branch: claude/selftest-exec-budget
pr: none
plan: selftest-exec-budget
issue: none
session: https://claude.ai/code/session_01DbKVTgyQe9eSSKFCEcgi1Z
agent: opus
updated: 2026-10-14
next: Take the baseline git-exec count on origin/main with a wrapper git, then add the budget to ci_selftest
---

## Goal

Bound the selftest's git execs with a counted budget in `ci_selftest`, and
remove invocations in dispatch/clerk/scout topics that re-run the same
command on the same fixture state.

## Decisions

- None yet.

## Rejected

- Fixture cache: rejected in the plan (fixtures mutate in place; absolute origin URLs).

## Review

## Blockers

None.

## Where to look

- `joharness.sh:ci_selftest` — the stage the budget lands in.
