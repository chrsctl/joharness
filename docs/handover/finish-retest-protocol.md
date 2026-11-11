---
workstream: finish-retest-protocol
status: in-progress
branch: manager/finish-retest-protocol
pr: none
plan: finish-retest-protocol
issue: none
session: https://claude.ai/code/session_01J1YMK5ir4zBQWg9RLmp1Uh
agent: opus
updated: 2026-11-11
next: Confirm A1-A4, run plan-checker, then build checks_catch_up RETEST
---

## Goal

Local-mode `finish` gets one written loop: test a head in full once; after
each merge of the base, retest only what that merge could have changed
(`JOHARNESS_RETEST_PATHS`); merge when green and level.

## Decisions

- None yet.

## Review

- None yet.

## Blockers

None.

## Where to look

- `joharness.sh:checks_catch_up` — CATCH-UP conditions widened to RETEST.
- `joharness.sh:checks_gate` — certificate removal on a full run.
- `joharness.sh:checks_local_check` — what `local-check` is handed.
