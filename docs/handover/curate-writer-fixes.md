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

## Blockers

None.

## Where to look

- `joharness.sh:curate_counts`, `curate_write_scope`, `plans_in_diff`
