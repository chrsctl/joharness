---
workstream: selftest-split-heavy-topics
status: in-progress
branch: manage/selftest-split-heavy-topics
pr: none
plan: selftest-split-heavy-topics
issue: none
session: https://claude.ai/code/session_01J1YMK6sevmb3gKW62mXN7e
agent: sonnet
updated: 2026-10-28
next: Split dispatch.sh and release.sh at the seams, add SELFTEST_FIRST claim order, selftest-shards cases
---

## Goal

Build plan selftest-split-heavy-topics: cut dispatch and release at fixture seams, claim longest units first.

## Decisions

- A1: confirmed — suite green with the split, no dsp*/df* cross reads (3801 passed, 0 failed).
- A2: confirmed — same run.
- A3: confirmed — runner's duplicate-name check passes.
- A4: confirmed — st_run inherits globals; added `st_firsts` knob for the claim-order cases.
- Timing (`bash .agents/harness/selftest.sh`, nproc 4, alternating, nothing else running): base 411s, head 347s, base 425s, head 322s. Base mean 418s, head mean 334.5s = 0.80x.
- PASS/FAIL/SKIP lines base vs head differ only by the six new selftest-shards cases (3795 -> 3801 passed, 1 skipped both).
- Claim-order case fails without the code: swapping the `first` pass to `rest` gave `FAIL a unit SELFTEST_FIRST names is claimed before the rest...` (3800 passed, 1 failed). FATAL-half cases assert `selftest_first_problems` output, so they fail without that function.

## Review

- r1: edge review of the diff: moved lines byte-identical, FATAL checks, unlisted names ignored in worker (fixed: none needed) (no change)

## Blockers

None.

## Where to look

- `.agents/harness/selftest.sh:selftest_worker` — the claim loop.
