---
workstream: guard-spares-harness-started-children
status: in-progress
branch: guard-spares-harness-started-children
pr: none
plan: guard-spares-harness-started-children
issue: 338
session: https://claude.ai/code/session_018JNyVFgb7drBGd8kEKiDNj
agent: opus
updated: 2026-10-10
next: Run perf, ci, verify; then verifier review
---

## Goal

Issue #338: the Stop guard counts a repo's own MCP server (a non-shell child
of the agent) as background work the session left running, so it fires on
every stop. Count only subtrees under the agent's shell children.

## Decisions

- Follow the plan as written (shell-seeded counted pass).

## Rejected

- None yet beyond the plan's own Out of scope.

## Review

## Blockers

None.

## Where to look

- `.agents/harness/handover-guard.sh` — `bg_running=` awk program, `counted` pass.
