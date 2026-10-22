---
workstream: orchestrator-retitles-at-run-end
status: in-progress
branch: manage/orchestrator-retitles-at-run-end
pr: none
plan: orchestrator-retitles-at-run-end
issue: none
session: https://claude.ai/code/session_01Ya7H7BbQxuskmRA1AdtA8f
agent: opus
updated: 2026-10-22
next: Run ci, verify, negative needle checks, verifier review, then finish
---

## Goal

An orchestrator whose run ended (DRAINED, PAUSED exit, human stop) retitles
itself `orchestrator (retired): <owner/repo>`; a duplicate exit takes
`orchestrator (duplicate): <owner/repo>`.

## Decisions

- Branch `manage/...`: `plan/orchestrator-retitles-at-run-end` is the merged
  plan-adding branch, not a claim.

## Rejected

None yet.

## Review

None yet.

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md:## 4.` — every §4 edit.
