---
workstream: starved-counts-green-runs
status: in-progress
branch: manager/starved-counts-green-runs
pr: none
plan: starved-counts-green-runs
issue: none
session: https://claude.ai/code/session_01J1YMK3ThwWNCgDW9ez1fyc
agent: opus
updated: 2026-11-11
next: Check A1/A2 in joharness.sh:checks_gate, run plan-checker, then build the OUTRUN line and its selftest cases
---

## Goal

STARVED counts BEHIND refusals, so a red run counts as "outrun" and a human
gets asked a question with no human decision in it. `finish` prints OUTRUN /
NOT OUTRUN on a BEHIND refusal from the certificate; manager.md §4 counts
only OUTRUN and offers the human a real choice.

## Decisions

- None yet.

## Review

- None yet.

## Blockers

None.

## Where to look

- `joharness.sh:checks_gate` — BEHIND branch and certificate handling.
- `.agents/harness/selftest/checks.sh:kccu_sync` — CATCH-UP fixtures.
