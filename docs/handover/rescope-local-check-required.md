---
workstream: rescope-local-check-required
status: in-progress
branch: rescope-local-check-required
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01J1YMK3wwJz9YkeDMqXZ4zM
agent: sonnet
updated: 2026-10-29
next: Verify dispatch no longer holds role-on-demand, review, retire, open PR, merge
---

## Goal

Surveyor for `rescope local-check-required`: role-on-demand held behind
local-check-required on `joharness.sh`.

## Decisions

- Both plans edit `joharness.sh` in place, in disjoint functions
  (`checks_gate` vs `cmd_role`/`role_start_stop`); role-on-demand's Traps
  already expects a reconcile merge. Marked `shared:joharness.sh` on both
  sides, frontmatter `scope:` only.
