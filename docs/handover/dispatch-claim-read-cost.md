---
workstream: dispatch-claim-read-cost
status: in-progress
branch: manage/dispatch-claim-read-cost
pr: none
plan: dispatch-claim-read-cost
issue: none
session: https://claude.ai/code/session_01J1YMK4ss2KinjRSUaz7NWc
agent: opus
updated: 2026-10-28
next: Profile dispatch per claim branch (git and non-git execs), record it here before any code
---

## Goal

Halve the per-ref time of `joharness.sh dispatch` (and `release`) without
changing what it decides or prints: read each branch's facts once instead of
per-helper git calls. Plan `docs/plans/dispatch-claim-read-cost.md`.

## Decisions

- Claimed; profile next.

## Rejected

- None yet.

## Review

- None yet.

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — the per-branch walk.
