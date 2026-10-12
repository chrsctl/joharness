---
workstream: sampling-conduct-reviewer
status: in-progress
branch: sampling-conduct-reviewer
pr: none
plan: sampling-conduct-reviewer
issue: 251
session: https://claude.ai/code/session_01Qn8AF7S1z5UosETCFQcJpb
agent: opus
updated: 2026-10-12
next: Research scout_due, cmd_scout, cmd_clerk, cmd_dispatch; then build conduct subcommand
---

## Goal

Issue #251: add a sampling conduct reviewer — a periodic sonnet session that
reads a deterministic sample of retired managers' artifacts and records C1
(criterion asserts the refused behaviour) per branch in `docs/conduct-log.md`,
plus `./joharness.sh conduct` report with tally so the owner can judge the
spend.

## Decisions

- Ledger columns `date | stem | C1 | note`: plan Scope lists a `C2` column
  but also says only ONE question is asked; an always-empty column would
  skew the tally. A later plan adding the worker-ownership question adds C2.

## Rejected

None yet.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:scout_due` — clock to copy.
