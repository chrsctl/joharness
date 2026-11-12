---
workstream: finish-pass-certifies-level-at-merge
status: in-progress
branch: research/finish-pass-certifies-level-at-merge
pr: none
plan: finish-pass-certifies-level-at-merge
issue: none
session: https://claude.ai/code/session_01J1YMK7RMRKD58eoujx5QMg
agent: opus
updated: 2026-11-12
next: Run verifier on the branch diff, record in Review, then ci, finish, retire, PR, merge
---

## Goal

Settle `docs/research/finish-pass-certifies-level-at-merge.md`: does a local
`finish: pass` certify the head is level with the base when the manager merges?
Graduate the answer, delete the research file.

## Decisions

- Answer: NO. `joharness.sh:checks_gate` fetches the base once, before the
  refusals, and pins `tip`; nothing after the suites fetches, and no manager
  step between pass and `merge_pull_request` does. Graduated to
  `consumer-repos.md` § Local checks ("What a local pass certifies").
- The fix is code, so it is a plan (`docs/plans/finish-level-at-merge.md`),
  not built here: a research PR writes no code (`.agents/docs/research.md`).
- Both fixes, not one: an end-of-run fetch in `finish` (cheap, reuses
  OUTRUN/CATCH-UP) plus a fetch-and-ancestor check at the merge call, since
  the PR calls after the pass are a window too. Branch protection named as
  the only full close (a human's setting).
- gx incident readings kept WEAK: this session cannot read chrsctl/gx.

## Rejected

- Docs-only answer ("turn on branch protection"): leaves every consumer on
  local checks with the race until a human acts; the harness can shrink it
  to seconds itself.

## Blockers

None.

## Where to look

- `joharness.sh:finish` — what the level check measures, and when.
