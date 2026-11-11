---
workstream: retired-edge-stall-window
status: in-progress
branch: manage/retired-edge-stall-window
pr: none
plan: retired-edge-stall-window
issue: none
session: https://claude.ai/code/session_01J1YMK3Z2R5D8EtAQqikw7t
agent: opus
updated: 2026-11-11
next: Confirm A1-A4, run plan-checker, then build the dispatch window change
---

## Goal

A retired edge row (manager past its retire commit, running `finish`) gets a
stall clock that fits `finish` (stall + local-check minutes), and a nudge
that does not ask for a handover.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

- None yet.

## Blockers

None.

## Where to look

- `joharness.sh:dispatch_retired_edges` — the edge scan.
