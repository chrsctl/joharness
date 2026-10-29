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
next: Write orchestrator.md (HOLD row, DEFECT-BOUND at RUN END) and orchestrated.md why, then ci and verify
---

## Goal

Two or more managers parked on the same unplanned `blocking:` defect = a red
base every new manager hits; dispatch holds new spawns until a plan names the
issue.

## Decisions

- A1: confirmed — `cmd_dispatch` reads `DEFECT_STATE` per row for the
  in-flight list only; the spawn loop reads `holdmap`, `wavemap`, labels.
- A2: not re-taken (consumer session records); the plan's goal stands on A1.
- Counted park: state PARKED, UNPLANNED, STUCK or RECHECK with no plan on
  the base or a live branch naming the issue (`DEFECT_NAMED`, set by
  `dispatch_defect_state`: the same `named` that gates RESUME). RESUME (fix
  retired) and UNREADABLE (no number) never count.
- Every spawn row holds (plans, research, CORE ONLY, the planning manager):
  each finishes on the same red base. Threshold 2, no knob: the plan names
  none.
- Own counter `n_dhold`, never `n_hold`: `n_hold` feeds OVERLAP-BOUND, and a
  surveyor cannot fix a red base.
- Verdict `DEFECT-BOUND`, after RESUME/fixed rows (a RECHECK respawn is a
  resume, not a spawn); with nothing in flight and no role due it says
  exit, so orchestrator.md RUN END names it.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_defect_state` — the park states.
- `joharness.sh:cmd_dispatch` — the spawn rows.
