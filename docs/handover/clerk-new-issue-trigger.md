---
workstream: clerk-new-issue-trigger
status: in-progress
branch: clerk-new-issue-trigger
pr: none
plan: clerk-new-issue-trigger
issue: none
session: https://claude.ai/code/session_01J1YMK5uhS1o6RkivUJMsPa
agent: opus
updated: 2026-10-29
next: Run plan-checker, confirm A1-A5, then build cmd_clerk last read / issue wait lines
---

## Goal

A new open GitHub issue starts the clerk ahead of the 24h cadence: the
orchestrator reads issues, `./joharness.sh clerk` supplies `last read` and
`issue wait`.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:clerk_due` — the one "last read" computation to reuse.
