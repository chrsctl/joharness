---
workstream: defect-resume
status: in-progress
branch: manage/defect-resume
pr: none
plan: defect-resume
issue: none
session: https://claude.ai/code/session_01ENEGqyRYxV6z71Z3DKMxfr
agent: opus
updated: 2026-10-23
next: Research cmd_dispatch, analysis_one, dispatch_branch_plans; then build PARKED/RESUME rows
---

## Goal

`docs/plans/defect-resume.md`: dispatch and the orchestrator treat a
`defect:` block as parked, resume it once the fix retires, and reach a human
only when nothing is fixing it.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

- r0: placeholder until review runs (no change)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch`, `analysis_one`, `dispatch_branch_plans`.
