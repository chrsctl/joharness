---
workstream: defect-park-calls-clerk
status: in-progress
branch: manage/defect-park-calls-clerk
pr: none
plan: defect-park-calls-clerk
issue: none
session: https://claude.ai/code/session_01J1YMK6ujSkf22kYBVj7zeA
agent: opus
updated: 2026-10-28
next: Confirm A1-A3 against joharness.sh, then build clerk_due early promotion
---

## Goal

A manager parked on a `defect: #<n>` issue no plan names makes the clerk due
at once (after `JOHARNESS_DEFECT_CLERK_HOURS`), not after the 24h cadence.

## Decisions

## Rejected

## Review

## Blockers

None.

## Where to look

- `joharness.sh:clerk_due` — shared cadence reader.
