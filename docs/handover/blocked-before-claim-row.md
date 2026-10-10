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
next: Edit orchestrate.md health table per plan Scope, then orchestrated.md
---

## Goal

Give the orchestrator's health table one correct row for a manager blocked
by a permission prompt before its first push, and stop the merged row
matching a ledger entry still `new`.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md`, `## 2. Health pass`.
- `.agents/docs/orchestrated.md`, "Blocked before its first push".
