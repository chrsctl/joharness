---
workstream: defect-recheck
status: in-progress
branch: claude/defect-recheck
pr: none
plan: defect-recheck
issue: none
session: https://claude.ai/code/session_01MQumdxosGQZZvBDND5TrvK
agent: opus
updated: 2026-10-23
next: Research dispatch_defect_state, check A1/A2, run plan-checker
---

## Goal

A manager parked on `defect: #<n>` re-checks once the base moved after the
block, so a defect fixed with no plan resumes within hours, not after the
48h UNPLANNED human ping.

## Decisions

## Rejected

## Review

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_defect_state` — the state reader.
