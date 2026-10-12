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
next: Finish selftest run, verifier review, ci+verify, then PR
---

## Goal

Scout runs when the backlog runs low, not only on the DRAINED clock
(`docs/plans/scout-backlog-clock.md`). Four conf keys, a backlog trigger in
`scout_due`, five report lines in `cmd_scout`, dispatch spawns a backlog-due
scout without the DRAINED gate.

## Decisions

- Both triggers true: the backlog reason wins in `SCOUT_DUE`, since it is the
  one that may spawn now; the clock alone would wait for DRAINED.
- Backlog spawn is held by `JOHARNESS_MAX_MANAGERS=0` (PAUSED): the plan bypasses
  only the DRAINED gate, and a human's pause is not that gate.
- `JOHARNESS_SCOUT_RESEARCH` read from the base branch's conf like the reviewer
  (money switch, fail closed); budget via `num_knob` like other numbers.
- Reviewer login filtered to `[A-Za-z0-9-]`: it is printed to the orchestrator.
- `.claude/commands/orchestrate.md` spawn-table row: one cell changed, outside the
  plan's Scope, because the row said "only under DRAINED" and would have kept
  the orchestrator from spawning a backlog-due scout. Flagged in the PR.

## Rejected

- Adding the backlog cases to the existing scout fixture: its later conduct
  cases read the same history; a second fixture at the file's end isolates them.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:scout_due` — the clock and the new backlog trigger.
