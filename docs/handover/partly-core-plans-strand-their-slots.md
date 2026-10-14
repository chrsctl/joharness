---
workstream: partly-core-plans-strand-their-slots
status: in-progress
branch: claude/partly-core-plans-strand-their-slots-5fa1
pr: none
plan: partly-core-plans-strand-their-slots
issue: none
session: https://claude.ai/code/session_01Ea62sjTaRhxvXCtPD1Q4g4
agent: fable
updated: 2026-10-14
next: Re-measure (a)-(d) on a fixture in this checkout, then graduate the answer into .agents/docs/orchestrated.md Bounds and file the follow-up plan
---

## Goal

Settle `docs/research/partly-core-plans-strand-their-slots.md`: does
dispatch's `DRAINED — nothing free` verdict hide a queue that waits on a
human's core edit? Graduate the answer into `.agents/docs/orchestrated.md`
(Bounds), file the harness change as a plan, delete the research file.

## Decisions

- Research file writes no code: the dispatch and orchestrate.md changes go
  in a follow-up plan in this pull request, not in this diff.

## Rejected

- None yet.

## Review

One bullet per finding, written BEFORE its fix, committed WITH it, in exactly
the form `- rN: text (fixed|wontfix: why|no change)` — `ci` checks it. Tag the
verifier's findings `(verifier)`. Clean pass = one bullet saying so. Remove
this paragraph when you add the first bullet.

## Blockers

None.

## Where to look

- `joharness.sh:drain_core_only` — the CORE ONLY list dispatch prints under NOT YOURS.
- `joharness.sh:dispatch` verdict ladder — DRAINED fires on n_free=0, n_wait=0, n_hold=0; CORE ONLY never enters it.
- `.agents/harness/queue-context.sh:qc_scope_class` — `only` vs `some` labels, same de-rank.
- `.claude/commands/orchestrate.md` health table — `status: blocked` row notifies once; no row for CORE ONLY.
