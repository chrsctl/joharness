---
workstream: ci-red-legible
status: in-progress
branch: manage-ci-red-legible
pr: none
plan: ci-red-legible
issue: none
session: https://claude.ai/code/session_018LP1zJBU9VzCGCFeWbLinc
agent: sonnet
updated: 2026-10-24
next: Retire plan and workstream file, open PR, merge
---

## Goal

Plan docs/plans/ci-red-legible.md: ci verdict names failing stages; run immune to edits of its own script.

## Decisions

## Review

- r1: (verifier) branch 13 behind origin/main, selftest_counted conflict (fixed: merged, kept main's per-case rate and the new last lines)
- r2: (verifier) no test for the selftest last lines (fixed: three cases in ci-selftest-scope.sh)
- r3: (verifier) selftest output no longer streams (fixed: main's tee form kept in the merge)

## Blockers

None.

## Where to look

- `joharness.sh:run_check`, `cmd_ci`, `selftest_counted`, last line.
