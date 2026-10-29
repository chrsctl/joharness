---
workstream: dispatch-holds-shared-defect
status: in-progress
branch: manage/dispatch-holds-shared-defect
pr: none
plan: dispatch-holds-shared-defect
issue: none
session: https://claude.ai/code/session_01J1YMK5sbgbhefzA9MHbwCu
agent: opus
updated: 2026-10-29
next: Check A1 against joharness.sh:dispatch_defect_state and cmd_dispatch, then build the HOLD
---

## Goal

Two or more managers parked on the same unplanned `blocking:` defect = a red
base every new manager hits; dispatch holds new spawns until a plan names the
issue.

## Decisions

## Review

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_defect_state` — the park states.
- `joharness.sh:cmd_dispatch` — the spawn rows.
