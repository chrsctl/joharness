---
workstream: role-on-demand
status: in-progress
branch: mgr/role-on-demand
pr: none
plan: role-on-demand
issue: none
session: https://claude.ai/code/session_01J1YMK6gHK4nAR5kZPp5VAT
agent: opus
updated: 2026-10-29
next: Confirm assumptions A1-A6 against joharness.sh, then run plan-checker
---

## Goal

Let an ordered pass of clerk, retro audit and retro trace run whether the
clock says due or not (`--ordered`), keeping the in-flight, twin and
unreadable gates, so on-demand never means two of one role.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

- None yet.

## Blockers

None.

## Where to look

- `joharness.sh:role_start_stop` — the cadence gate `--ordered` skips.
