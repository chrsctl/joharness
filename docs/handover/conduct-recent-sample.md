---
workstream: conduct-recent-sample
status: in-progress
branch: claude/conduct-recent-sample
pr: none
plan: conduct-recent-sample
issue: none
session: https://claude.ai/code/session_01J1YMK3jCqjLJi3BLSYzNCG
agent: opus
updated: 2026-10-28
next: Run plan-checker on docs/plans/conduct-recent-sample.md, then confirm A1-A4
---

## Goal

Conduct samples the work merged since its last run, riskiest first, and its
C1 CONCERN rate shows on the dispatch `conduct   :` line.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

- None yet.

## Blockers

None.

## Where to look

- `joharness.sh:conduct_candidates` — candidate window.
- `joharness.sh:conduct_sample` — risk order.
