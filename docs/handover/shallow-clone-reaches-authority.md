---
workstream: shallow-clone-reaches-authority
status: in-progress
branch: claude/shallow-clone-reaches-authority
pr: none
plan: shallow-clone-reaches-authority
issue: 439
session: https://claude.ai/code/session_01RXca2ZFK5BrCwuBp3oKkUV
agent: opus
updated: 2026-10-13
next: Research the anchors, then build the hook bound, authority verdict, selftest and role-command steps
---

## Goal

A fresh shallow cloud session must not exit UNVERIFIED over a fetch it can
run itself, and an orchestrator must not spawn into that race (issue #439).

## Decisions

- None yet.

## Rejected

- None yet.

## Review

- Not reviewed yet.

## Blockers

None.

## Where to look

- `joharness.sh:cmd_authority` — the UNVERIFIED branches.
- `.agents/harness/handover-context.sh` — shallow fetch block.
