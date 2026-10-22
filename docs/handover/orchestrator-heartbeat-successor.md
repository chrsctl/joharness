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
next: Prerequisite failed (fire_trigger refused); reading recorded in orchestrated.md; review, retire, PR, merge
---

## Goal

Fleet lives indefinitely and stays cheap: when an up-to-date heartbeat
exists, the orchestrator's §4 hand-off fires the keeper with the ledger as
payload instead of create_session, so lineage depth stays at keeper + 1.

## Decisions

- Prerequisite reading failed: auto-mode classifier refused fire_trigger on the keeper heartbeat; per the plan (either no = do not build) the reading goes in orchestrated.md Heartbeat and the plan retires unbuilt.
- No retry of the keeper fire and no block: the refusal is itself the reading an orchestrator in auto mode would get.

## Rejected

- Self-bound probe Routine fired with text: the platform drops text for a Routine bound to the firing session, so it cannot stand in for the keeper reading.

## Review

Not reviewed yet.

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` — "## 0. Start" step 5, §4 HAND-OFF, "## Keeper".
