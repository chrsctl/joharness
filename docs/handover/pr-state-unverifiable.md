---
workstream: pr-state-unverifiable
status: in-progress
branch: claude/pr-state-unverifiable
pr: none
plan: docs/plans/pr-state-unverifiable.md
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-30
next: Implement the reworded edge line and its cases.
---

## Goal

Stop the session-start hook asserting a pull request is open when it cannot
know. Found by following the hook's own top-ranked instruction and
discovering the pull request it named was closed nine days ago.

## Decisions

- **Wording, not a network call.** The hook must stay offline and is already
  411 of a 700 perf budget.
- **Rank unchanged.** git cannot tell a closed pull request from an open one,
  so rank 2 is still the honest guess; only the claim was dishonest.
- **`urgency: urgent`.** It misdirects the first thing every session reads.

## Rejected

- Dropping the `pr:` field from the ranking. It is still the best available
  signal that a branch reached an edge; the defect is the certainty, not the
  signal.

## Review

To be recorded before the merge.

## Blockers

None.
