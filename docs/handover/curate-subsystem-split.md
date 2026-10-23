---
workstream: curate-subsystem-split
status: in-progress
branch: curate-subsystem-split
pr: none
plan: curate-subsystem-split
issue: none
session: https://claude.ai/code/session_01JmCnCxUTGjht3FQwZJsY8d
agent: sonnet
updated: 2026-10-23
next: Add layers PROPOSE to cmd_curate, knob, selftest cases
---

## Goal

Add a `JOHARNESS_CURATE_LAYERS` PROPOSE signal to `curate` (plan: curate-subsystem-split).

## Decisions

- Small shared-file edit: built directly, no worker fan-out.

## Blockers

None.

## Where to look

- `joharness.sh:cmd_curate` — splitthr path to mirror.
