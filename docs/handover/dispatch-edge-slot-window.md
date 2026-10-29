---
workstream: dispatch-edge-slot-window
status: in-progress
branch: manage/dispatch-edge-slot-window
pr: none
plan: dispatch-edge-slot-window
issue: 701
session: https://claude.ai/code/session_01J1YMK53poa2Ag5SDkEp9AR
agent: opus
updated: 2026-10-29
next: Confirm assumptions A1-A6, run plan-checker, then build the aged-edge window in joharness.sh dispatch
---

## Goal

Issue #701: a retired no-claim-file edge branch holds a manager slot forever.
Bound the hold by `JOHARNESS_EDGE_SLOT_HOURS`; past it the row stays listed,
items stay withheld, slot is freed.

## Decisions

## Rejected

## Review

## Blockers

None.

## Where to look

- `joharness.sh:dispatch` — edge loop, `n_edge`.
- `.agents/harness/selftest/dispatch.sh:mgr-eta` — fixture to extend.
