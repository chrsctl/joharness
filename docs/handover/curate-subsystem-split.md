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
next: Await verifier review, record in ## Review, retire plan+workstream, PR, finish
---

## Goal

Add a `JOHARNESS_CURATE_LAYERS` PROPOSE signal to `curate` (plan: curate-subsystem-split).

## Decisions

- Small shared-file edit: built directly, no worker fan-out.

## Review

- r1: first path component is coarse here (every `.agents/*` path is one layer); matches the plan wording, signal rarely fires on this repo (verifier) (wontfix: plan specifies first components)
- r2: root-file-counts-as-`.` rule had no selftest case (verifier) (fixed: case `a.sh, b/x, c/y` added)
- r3: output line appends text beyond the plan wording; selftest matches the prefix (verifier) (no change)
- r4: `./joharness.sh curate` on this branch prints NOTHING TO CURATE; no queue plan trips it (no change)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_curate` — splitthr path to mirror.
