---
workstream: finish-level-at-merge
status: in-progress
branch: finish-level-at-merge
pr: none
plan: finish-level-at-merge
issue: none
session: https://claude.ai/code/session_01J1YMK5XJnYWH5pXzz3wazu
agent: opus
updated: 2026-11-12
next: Confirm assumptions A1-A3 against joharness.sh:checks_gate, then build
---

## Goal

Under `JOHARNESS_CHECKS=local`, re-measure "0 behind" at the end of `finish`
and at the merge call, so a base that moves mid-run never merges unchecked.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:checks_gate` — the single fetch and the certificate write.
