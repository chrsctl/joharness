---
workstream: perf-budget-pins-the-ref-shape
status: in-progress
branch: claude/current-state-review-oxfb7f
pr: none
plan: perf-budget-pins-the-ref-shape
issue: none
session: https://claude.ai/code/session_011LSGxqQsZyuMYSqxa3jVT5
agent: opus
updated: 2026-09-02
next: Build the pinned shape in perf, recalibrate the budgets against it, prove a regression still reds
---

## Goal

ci is red in every session container of this repo because four perf rows
count a fork per remote-tracking ref and the budgets were calibrated against
a one-branch CI checkout. The plan carries the measurements.

## Decisions

- (filled as the work decides them)

## Rejected

- (filled as the work rejects them)

## Review

Pending.

## Blockers

None.

## Where to look

- `joharness.sh:perf_count`, `perf_rows`, `perf_report`.
