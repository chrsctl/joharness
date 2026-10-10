---
workstream: janitor-zero-candidate-says-why
status: review
branch: janitor-zero-candidate-says-why
pr: none
plan: janitor-zero-candidate-says-why
issue: #308
session: https://claude.ai/code/session_01HC1jyidELLTKbSHmh4hpkB
agent: sonnet
updated: 2026-10-10
next: Merge the pull request
---

## Goal

Issue #308: janitor's zero-candidate line must say what was counted.

## Review

- r1: (verifier) the no-age and unreadable-file `continue`s are counted in neither bucket, so all-dropped-that-way still prints "every claim pushed inside" (wontfix: the plan names these two as getting no counter; widening is a separate plan)
- r2: (verifier) zero claims at all also takes the n_released=0 branch and prints the old sentence (wontfix: plan keeps those bytes unchanged and the selftest pins them; pre-existing)
- r3: (verifier) `stale_s / 3600` integer division prints 0h for sub-hour windows (wontfix: pre-existing, copied from the old line, out of scope)
- r4: measured 2026-10-10: `bash .agents/harness/selftest.sh` 2457 passed, 0 failed with the change; with joharness.sh reverted to origin/main, 2453 passed, 4 failed (the four new expects).

## Blockers

None.
