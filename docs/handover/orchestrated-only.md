---
workstream: orchestrated-only
status: in-progress
branch: claude/orchestrated-only
pr: none
plan: orchestrated-only
issue: none
session: https://claude.ai/code/session_015NtQ5zqgi5mjrZ9Xkofo2K
agent: opus
updated: 2026-10-10
next: Research the mode switch callers in joharness.sh, then decompose
---

## Goal

Requester, 2026-10-08: "Only orchestrator mode should be left over" —
everywhere, consumers included, fail-closed default gone. One mode:
`/manage <item>` = manager, anything else = orchestrator.

## Decisions

- (none yet)

## Rejected

- (none yet)

## Review

## Blockers

None.

## Where to look

- `joharness.sh:run_mode`, `joharness.sh:unattended` — the switch.
