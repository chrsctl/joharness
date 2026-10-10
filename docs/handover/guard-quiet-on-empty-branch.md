---
workstream: guard-quiet-on-empty-branch
status: in-progress
branch: manage/guard-quiet-on-empty-branch
pr: none
plan: guard-quiet-on-empty-branch
issue: #296
session: https://claude.ai/code/session_014p49UQjkTFd79dEVDXh5mv
agent: sonnet
updated: 2026-10-10
next: Edit handover-guard.sh no-upstream arm + one selftest case, run acceptance, review, retire, PR
---

## Goal

Issue #296: guard blocks stops on an untouched, never-pushed branch. Quiet when zero commits ahead of base.

## Decisions

- Small enough to build directly, no workers.

## Review

- r1: (verifier) no defects in the diff; ran guard in scratch repo: empty branch quiet, 1 commit ahead warns, missing origin/main warns, old guard warned on the empty branch (no change needed)
- r2: (verifier) unreadable-base arm has no selftest case (wontfix: plan does not require one; checked by hand)
- r3: (verifier) verifier's shell mishap added an empty commit and deleted origin/main ref locally (fixed: commit dropped, ref restored; origin/main refetched f869968c)
- r4: `./joharness.sh verify` failed 2 of 6 on first run, 6 passed 0 failed on re-run (no change: flake, cause not found)

## Blockers

None.
