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
next: Selftest run in flight (unverified); run .agents/harness/selftest.sh, confirm new curate-apply cases red on main then green, then ci+verify, review, retire
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
