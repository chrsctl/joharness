---
workstream: orchestrator-heartbeat-successor
status: in-progress
branch: claude/orchestrator-heartbeat-successor
pr: none
plan: orchestrator-heartbeat-successor
issue: none
session: https://claude.ai/code/session_01KjRsJjm6q7mKQCqKQLbwJZ
agent: opus
updated: 2026-10-22
next: Take the prerequisite reading (fire_trigger on the keeper heartbeat with a text payload) before any edit
---

## Goal

Fleet lives indefinitely and stays cheap: when an up-to-date heartbeat
exists, the orchestrator's §4 hand-off fires the keeper with the ledger as
payload instead of create_session, so lineage depth stays at keeper + 1.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

Not reviewed yet.

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` — "## 0. Start" step 5, §4 HAND-OFF, "## Keeper".
