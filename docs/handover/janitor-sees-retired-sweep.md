---
workstream: janitor-sees-retired-sweep
status: in-progress
branch: janitor-sees-retired-sweep
pr: none
plan: janitor-sees-retired-sweep
issue: 292
session: https://claude.ai/code/session_0139meDaJSq7MhLGgdeuTT4r
agent: opus
updated: 2026-10-10
next: Research janitor_branches + scout_retired_ts, then build the retired-sweep log and three fixtures
---

## Goal

Issue #292: after a janitor sweep's retire commit and before its PR merges,
`./joharness.sh janitor` reads DUE with nothing in flight. Make
`janitor_branches` see retired sweeps via commit history.

## Decisions

## Rejected

## Review

## Blockers

None.

## Where to look

- `joharness.sh:janitor_branches` — the function changed.
