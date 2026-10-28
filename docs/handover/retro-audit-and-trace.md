---
workstream: retro-audit-and-trace
status: in-progress
branch: claude/retro-audit-and-trace
pr: none
plan: retro-audit-and-trace
issue: none
session: https://claude.ai/code/session_01J1YMK5rjqiJNckSSTh2gN7
agent: opus
updated: 2026-10-28
next: Confirm A1-A5, run plan-checker, then build the joharness.sh audit/trace merge
---

## Goal

Merge conduct and retro into ONE role, retro, with modes audit (today's
conduct) and trace (today's retro); audit CONCERNs become trace's input.

## Decisions

## Rejected

## Review

## Blockers

None.

## Where to look

- `joharness.sh:cmd_conduct`, `joharness.sh:cmd_retro`, `joharness.sh:cmd_role` — the two halves and the shared prelude.
