---
workstream: perf-window-fixed-cost
status: in-progress
branch: claude/perf-window-fixed-cost
pr: none
plan: perf-window-fixed-cost
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-30
next: Correct the falsified mechanism in perf_rows and in the plan, then hand the optimisation on
---

## Goal

Claimed `perf-window-fixed-cost`. Research before code found that the plan's
own Goal — and the comment I merged in #138 — state a mechanism that is
FALSE. Correcting the record is the work; the optimisation the plan describes
is still wanted and still sonnet-sized, but it cannot be built on a wrong
premise.

## Decisions

- Measured before touching anything, as the plan instructs. That is what
  caught it: the plan says "measure which one carries the variance before
  changing either", and doing so falsified the plan's own framing.
- Correcting the merged comment outranks doing the optimisation. A comment
  asserting a mechanism the code does not have is what stops the next reader
  checking — this repo's own words, in `fb_cache_load`, about exactly this
  failure.

## Rejected

- Implementing the batching win in the same change. Two candidates looked
  clean (fold `sort -u` into the awk; take `%s` in `fb_edges`' existing
  format so `fb_label` stops forking per edge) and the first is not
  behaviour-preserving: selection among two candidate workstream files is by
  sorted order today, and 2 of 51 edges carry two candidates. A cost fix that
  silently changes which document is scored is the metric-gaming failure this
  repo just graduated a finding about.

## Review

None yet.

## Blockers

None.

## Where to look

- `joharness.sh:PERF_EDGES` — the knob that actually pins the window during
  measurement.
- `joharness.sh:perf_count` — where it overrides JOHARNESS_FEEDBACK_EDGES,
  which is why an outside-in sweep of that variable reads as flat.
- `joharness.sh:fb_workstream` — the per-edge forks.
