---
workstream: curate-writer-fixes
status: in-progress
branch: curate-writer-fixes
pr: none
plan: curate-writer-fixes
issue: none
session: https://claude.ai/code/session_01D4is7qg9UAwnXVgyFR9ZBy
agent: sonnet
updated: 2026-10-22
next: Selftest green except timing flake (80 KB prose, 5s vs 4s under load); new cases verified red on main. Read ci and verify results, review, retire, PR
---

## Goal

Fix four curate defects per `docs/plans/curate-writer-fixes.md`.

## Decisions

- curate_counts emits path, stem, S or - (marked); curate_hits counts any mark. Declutter skip rule: Scope bullet naming the path with create or new file. Mode kept via cat into file; symlink refused.

## Rejected

## Review

- r1: (verifier) curate_write_scope returned rm's status, so a failed write reported success (fixed: cat failure returns 1)
- r2: (verifier) the ORDER-suppression guard was untested at total 3 (fixed: added a marked-plus-unmarked case, total 2; reasoned red without the guard, not mutation-run)
- r3: (verifier) ci-graph-lint.sh in scope: but untouched (no change: the rename case runs through caci in curate-apply.sh, same ci)
- r4: (verifier) curate_marked_new substring match too loose (fixed: backticked path, word-start create)
- r5: (verifier) marked-new path drops out of the declutter count (no change: intended, a new file is not gone)
- r6: (verifier) symlink refusal repeats each --apply pass (no change: cosmetic)

## Blockers

None.

## Where to look

- `joharness.sh:curate_counts`, `curate_write_scope`, `plans_in_diff`
