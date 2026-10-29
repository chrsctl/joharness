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
next: Record verifier findings in ## Review, then finish (retire commit, PR, merge)
---

## Goal

Stop `ci` flaking in selftest `c2-run.sh` (issue #687): parallel c2-run copies
prune each other's worktree admin dirs.

## Decisions

- A1: confirmed — selftest xargs -P 4 runs against one `c2r_fx`.
- A2: confirmed — `c2_cleanup` ends with `git worktree prune`.
- A3: confirmed as plan states (medium; not reproduced at topic level).
- A4: confirmed — ci: pass with the existing worktrees 1 case.

## Review

- r1: clean pass; new case fails with prune restored (planted gone), passes without (verifier) (no change)
- r2: orphan admin dir if add dies before workdir exists, nothing prunes it; plan accepts trade-off (verifier) (wontfix: plan accepts; leak not break)

## Blockers

None.

## Where to look

- `.agents/scripts/c2-run.sh:c2_cleanup`
- `.agents/harness/selftest/c2-run.sh` near `xargs`
