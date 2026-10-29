---
workstream: c2-run-prune-race
status: in-progress
branch: manage/c2-run-prune-race
pr: none
plan: c2-run-prune-race
issue: 687
session: https://claude.ai/code/session_01J1YMK68B2FzdJmugJTTtFh
agent: sonnet
updated: 2026-10-29
next: Drop worktree prune from c2_cleanup, add planted-entry selftest case, run ci
---

## Goal

Stop `ci` flaking in selftest `c2-run.sh` (issue #687): parallel c2-run copies
prune each other's worktree admin dirs.

## Decisions

- A1: confirmed — selftest xargs -P 4 runs against one `c2r_fx`.
- A2: confirmed — `c2_cleanup` ends with `git worktree prune`.
- A3: confirmed as plan states (medium; not reproduced at topic level).
- A4: to confirm by ci run.

## Blockers

None.

## Where to look

- `.agents/scripts/c2-run.sh:c2_cleanup`
- `.agents/harness/selftest/c2-run.sh` near `xargs`
