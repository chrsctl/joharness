---
workstream: hold-followups
status: in-progress
branch: claude/hold-followups
pr: none
plan: hold-followups
issue: none
session: https://claude.ai/code/session_01J1YMK4wp9cyBubHVHvhdvK
agent: sonnet
updated: 2026-11-11
next: Build the four fixes per the plan, then ci, verify, review.
---

## Goal

Fix the four findings reported on PR #734, as the requester asked.

## Decisions

- Finding 1: a retired fix lifts the hold even if a second plan names the
  issue: the gx failure was spawns before the fix merged; after it merged
  the base is green with the known fix, and RESUME still waits for the
  second plan as before.
- Finding 4: no `worktree prune` in cleanup (a selftest pins that runs share
  the repo); remove the run's own admin entry instead.

## Rejected

None yet.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — `dpark`, the fix-row exemption.
- `.agents/scripts/c2-run.sh:c2_cleanup`.
