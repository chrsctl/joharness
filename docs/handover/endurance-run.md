---
workstream: endurance-run
status: in-progress
branch: claude/endurance-run
pr: none
plan: docs/plans/unsupervised-endurance.md
issue: 165
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-31
next: Fleet is live from T0 18:56:18Z. Do not answer it. Poll, and record what stops it.
---

## Goal

Measure the bullet the requirement's Goal is built on: started once, the
fleet keeps going for hours with no human turn, for as long as a goal is
open.

## Authorisation

"Implement unsupervised endurance", 2026-08-31, after "Flip the mode"
earlier the same day and after issue #165 put the cost in front of the
requester.

## Decisions

- **This branch holds the CLAIM and stays unmerged during the run.** Merging
  it would free `unsupervised-endurance` and let a spawned session claim the
  run it is inside.
- **Setup is a separate branch** (PR 173): the committed mode flip, and a
  plan recorded while sizing the run.

## T0 — the run starts, and the goal's size beside it

Started **2026-08-31T18:56:18Z**, `main` at `e971d84`. Counted, not
recalled (`./joharness.sh sources`, that minute):

| | at T0 |
| --- | --- |
| open requirement | 1 — `docs/product/unsupervised-mode.md` |
| free plans | **1** — `marker-gate-needs-no-done.md` [sonnet, medium] |
| claimed plans | 1 — `unsupervised-endurance`, this run |
| unmarked findings (a source) | **4** |
| known-gap markers | 0 |
| failing checks | 0 |
| sweep verdict | NOT dry — findings(4) |

**This is the number the plan's Trap demands beside the wall-clock.** One
free plan is a thin queue. If the fleet stops in twenty minutes, that is
queue depth and not endurance, and it must be reported as such. What can
carry it further is the sweep: 4 unmarked findings are a live source, and
under the goal bound a session may generate plans from them while the
requirement is open.

## Review

To be recorded before the merge.

## Blockers

None.
