---
workstream: blocked-before-claim-row
status: in-progress
branch: blocked-before-claim-row
pr: none
plan: blocked-before-claim-row
issue: none
session: https://claude.ai/code/session_012J8LutqGHqhZDE49agfS81
agent: opus
updated: 2026-10-10
next: Verifier review, record findings, retire, PR
---

## Goal

Give the orchestrator's health table one correct row for a manager blocked
by a permission prompt before its first push, and stop the merged row
matching a ledger entry still `new`.

## Decisions

- Merged row also matches when the item file is gone from fresh
  `origin/main`: a manager that claims and merges inside one pass interval
  leaves its ledger entry `new`, and the plan's head-only condition would
  route it to UNCLAIMED and a wrong REPORT. A never-born branch cannot fake
  the item vanishing, so the blocked case stays out.
- Confirm row is labelled BLOCKED BEFORE CLAIM too, so all three rows read
  as one family; respawn resets the entry to `@new` with no `held=`.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md`, `## 2. Health pass`.
- `.agents/docs/orchestrated.md`, "Blocked before its first push".
