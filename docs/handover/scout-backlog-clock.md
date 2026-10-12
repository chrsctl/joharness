---
workstream: scout-backlog-clock
status: in-progress
branch: manage/scout-backlog-clock
pr: none
plan: scout-backlog-clock
issue: none
session: https://claude.ai/code/session_015XZqoZowkJNj1BS7e66AuG
agent: opus
updated: 2026-10-12
next: Research scout_due, cmd_scout, cmd_dispatch; then build per plan Scope
---

## Goal

Scout runs when the backlog runs low, not only on the DRAINED clock
(`docs/plans/scout-backlog-clock.md`). Four conf keys, a backlog trigger in
`scout_due`, five report lines in `cmd_scout`, dispatch spawns a backlog-due
scout without the DRAINED gate.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:scout_due` — the clock and the new backlog trigger.
