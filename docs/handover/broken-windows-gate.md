---
workstream: broken-windows-gate
status: in-progress
branch: claude/broken-windows-gate-mgr
pr: none
plan: broken-windows-gate
issue: none
session: https://claude.ai/code/session_01HGTPqiqvLRRKSqLu3R3KhF
agent: sonnet
updated: 2026-10-23
next: Research lint_ws_in_diff, add broken-windows lint to ci, selftest topic, README bullet
---

## Goal

Make "never skip/disable a test" a ci check: added skip marker or TODO/FIXME in non-md file reds ci unless `## Review` waives the path.

## Decisions

## Rejected

## Review

## Blockers

None.

## Where to look

- `joharness.sh:lint_ws_in_diff`
