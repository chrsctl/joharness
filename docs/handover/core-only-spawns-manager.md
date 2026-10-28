---
workstream: core-only-spawns-manager
status: in-progress
branch: claude/core-only-spawns-manager
pr: none
plan: core-only-spawns-manager
issue: none
session: https://claude.ai/code/session_01J1YMK5BpmpDmvYP7cKXntH
agent: opus
updated: 2026-10-28
next: Confirm A1-A4, then change dispatch so a CORE ONLY plan spawns after free plans
---

## Goal

"We should only wait for the PRs to be merged not the implementation." A
CORE ONLY plan gets a manager; the human only merges its `human/<stem>` PR.

## Decisions

- (pending)

## Rejected

None yet.

## Review

None yet.

## Blockers

None.

## Where to look

- `joharness.sh:drain_core_only` — the block being replaced.
