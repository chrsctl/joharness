---
workstream: keeper-stillborn-spawn
status: in-progress
branch: claude/keeper-stillborn-spawn
pr: none
plan: keeper-stillborn-spawn
issue: none
session: https://claude.ai/code/session_01J1YMK4CB57ke54pkRNnbob
agent: sonnet
updated: 2026-11-08
next: Edit keeper.md per the plan, pin it in the selftest, run ci and verify
---

## Goal

Fix the chrsctl/gx keeper defect (2026-11-08): a compacted keeper spawned a
successor with no checkout and refused to restart it for 5 h.

## Decisions

- Context bound = the platform's auto-compaction, made lossless by re-reading
  keeper.md whole every wake, plus a narrower `list_triggers`. Rotation
  rejected: every create_session child is one lineage level deeper (cap 8).

## Rejected

- Keeper rotation via its own create_session or the orchestrator's REPLACE:
  +1 or +2 depth per rotation strands the fleet after a few rotations.

## Review

## Blockers

None.

## Where to look

- `.claude/commands/keeper.md:Not LIVE` — step 3.
