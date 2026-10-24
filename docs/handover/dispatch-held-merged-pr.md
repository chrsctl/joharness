---
workstream: dispatch-held-merged-pr
status: in-progress
branch: manage/dispatch-held-merged-pr
pr: none
plan: dispatch-held-merged-pr
issue: 594
session: https://claude.ai/code/session_01GjKnsgJV4qubTD63CuMiH7
agent: sonnet
updated: 2026-10-24
next: Research anchors, then build the bplans append in joharness.sh with a selftest case
---

## Goal

`dispatch` `plans on a branch` line says `N commit(s) after merged PR #n` when the holding branch's `pr:` merged and the tip is ahead (issue #594 case 2).

## Decisions

## Review

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — `bplans` awk.
