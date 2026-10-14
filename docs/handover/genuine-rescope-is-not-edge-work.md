---
workstream: genuine-rescope-is-not-edge-work
status: in-progress
branch: claude/genuine-rescope-is-not-edge-work
pr: none
plan: genuine-rescope-is-not-edge-work
issue: 492
session: https://claude.ai/code/session_012aeEK469hHzaddGFthH93A
agent: opus
updated: 2026-10-14
next: Run selftest, mutation-check both new assertions, ci, verify, verifier
---

## Goal

A surveyor that finds holds GENUINE (status done, pr none, plan none, never
merged) must not read as edge work: no EDGE, no lead, a dispatch row saying
it holds no slot, and the orchestrator drops its ledger entry instead of
nudging it forever (issue #492).

## Decisions

- Finished rescope ranks 6 in the hook, below abandoned (5): nothing to
  finish and nobody to nudge, so it sorts last and the cap hides it first.
  Set by `finished_rescope` after `rank_of`, never from a status word, so a
  file writing some status word cannot buy rank 6.
- `dispatch_rescope_branches` gains a sixth field, `pr`; the `free-` loop
  reads it into `_`. `pr:` empty, `none`, `NONE` or `#`-prefixed of those
  counts as no pr, the same normalisation as the hook's `pr_num`.
- Hook fixture is its own repo (`finishedrescopework`), so the existing
  order and cap assertions stay byte-identical.
- README rank table: `abandoned` row said 4, the code prints 5; fixed while
  adding the rank-6 row (r1).

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `.agents/harness/handover-context.sh:rank_of` — rank mapping.
- `joharness.sh:cmd_dispatch` — rescope in-flight loop.
