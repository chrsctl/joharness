---
workstream: rescope-local-check-required
status: done
branch: rescope-local-check-required
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01J1YMK3wwJz9YkeDMqXZ4zM
agent: sonnet
updated: 2026-10-29
next: none — the overlap on joharness.sh is real; role-on-demand waits for local-check-required to merge
---

## Goal

Surveyor for `rescope local-check-required`: role-on-demand held behind
local-check-required on `joharness.sh`.

## Decisions

- Both plans EDIT `joharness.sh` IN PLACE (`checks_gate` vs `cmd_role` /
  `role_start_stop`). Neither appends to or registers in it, and no bare
  directory claim exists, so manage-reference § Surveyor changes nothing.
  The hold is GENUINE. No pull request.

## Review

- r1: marking `shared:joharness.sh` breaks § Surveyor, in-place edits stay (verifier) (fixed: scope edits reverted)
