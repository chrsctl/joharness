---
workstream: orchestrator-heartbeat-successor
status: in-progress
branch: claude/orchestrator-heartbeat-successor
pr: none
plan: orchestrator-heartbeat-successor
issue: none
session: https://claude.ai/code/session_01KyirxKSbmXU6prDj22WtaH
agent: opus
updated: 2026-10-16
next: Measure the prerequisite: find the /orchestrate heartbeat Routine (list_triggers) and read lineage
---

## Goal

A fleet that lives indefinitely and stays cheap: the heartbeat Routine is the
durable piece, the orchestrator hand-off fires it instead of deepening
lineage with create_session.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

None yet.

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` — §0 step 3, §4 HAND-OFF, Tools table.
- `.agents/docs/orchestrated.md` — Heartbeat section.
