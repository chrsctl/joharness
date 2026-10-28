---
workstream: knobs-to-constants
status: in-progress
branch: manage/knobs-to-constants
pr: none
plan: knobs-to-constants
issue: none
session: https://claude.ai/code/session_01J1YMK331e4aCGNyjpSFKPy
agent: sonnet
updated: 2026-10-28
next: Classify every KNOBS row, read gx conf, write Findings, graduate into orchestrated.md
---

## Goal

Settle docs/research/knobs-to-constants.md: which JOHARNESS_* knobs can become constants.

## Decisions

## Blockers

None.

## Where to look

- `joharness.sh` KNOBS-BEGIN..KNOBS-END
- `.agents/docs/orchestrated.md` knob table

## Review

- r1: verdict reason for CANONICAL and MAX_MANAGERS said seeded, but they are not (verifier) (fixed)
- r2: "selftest sets" 0 for RESPAWN_LIMIT/RETRO_EVENTS is assignments only; wording made explicit (verifier) (fixed)
- r3: Echo said 50 knobs, rows count 49 (verifier) (fixed)
- r4: test-reach question left unsettled for KEEP rows, deferred to any cutting plan (verifier) (wontfix: out of what the evidence here can settle)
- r5: no plan file exists for the stem; research item, so none expected (verifier) (no change)
