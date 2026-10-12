---
workstream: scout-backlog-clock
status: done
branch: manage/scout-backlog-clock
pr: none
plan: scout-backlog-clock
issue: none
session: https://claude.ai/code/session_015XZqoZowkJNj1BS7e66AuG
agent: opus
updated: 2026-10-12
next: ci + verify after review fixes, then retire and PR
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

- r1: (verifier) backlog spawn ignored JOHARNESS_PENDING_SPAWNS: an unpushed scout from last pass let every health pass spawn another (fixed)
- r2: (verifier) scout_n_plans counted docs/plans/RETIRED.md once origin/main was merged in (fixed)
- r3: (verifier) scout_reviewer trimmed bad characters, so alice_acme read as another account aliceacme; now any non-login value reads none (fixed)
- r4: (verifier) the AUTOMERGE sentence says the key governs no merge while scout.md section 6 still merges by it (wontfix: the plan orders this wording; scout-proposes-on-issues rewrites scout.md)
- r5: (verifier) JOHARNESS_SCOUT_HOURS=0 also switches the backlog off, undocumented (fixed: orchestrated.md row says so)
- r6: (verifier) report said a scout is due while one is in flight (fixed)
- r7: (verifier) a failed cat-file on docs/plans read as zero plans, failing open (fixed: entry read via ls-tree, a failed read is unreadable)
- r8: (verifier) budget resolves from the working-tree conf, unlike reviewer and research (no change: plan names num_knob for numbers; recorded under Decisions)

## Blockers

None.

## Where to look

- `joharness.sh:scout_due` — the clock and the new backlog trigger.
