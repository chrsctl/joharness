---
workstream: kill-survives-its-interrupt
status: in-progress
branch: manage/kill-survives-its-interrupt
pr: none
plan: kill-survives-its-interrupt
issue: none
session: https://claude.ai/code/session_01J1YMK623RvaZoLEwPbLFo1
agent: opus
updated: 2026-11-11
next: Check assumptions A1-A3, run plan-checker, then build the killing= row
---

## Goal

A KILL never completes: the interrupt moves `updated_at`, the drop-record row
matches first and eats the kill. Make a KILL in progress survive its own
interrupt and finish (ledger key `killing=<head>`, a row above drop-record).

## Decisions

- None yet.

## Review

- None yet.

## Blockers

None.

## Where to look

- `.claude/commands/orchestrator.md:drop that record` — the row that eats the kill.
