---
workstream: orchestrator-heartbeat-successor
status: blocked
branch: claude/orchestrator-heartbeat-successor
pr: none
plan: orchestrator-heartbeat-successor
issue: none
session: https://claude.ai/code/session_01KyirxKSbmXU6prDj22WtaH
agent: opus
updated: 2026-10-16
next: money: create an hourly /orchestrate heartbeat Routine in the claude.ai UI so its lineage can be read
---

## Goal

A fleet that lives indefinitely and stays cheap: the heartbeat Routine is the
durable piece, the orchestrator hand-off fires it instead of deepening
lineage with create_session.

## Decisions

- Did not build ahead of the measurement: the plan makes depth d+1 a
  no-build outcome, so code before the reading may be thrown away.

## Rejected

- None yet.

## Review

None yet.

## Blockers

- Prerequisite unmet (plan, "Prerequisite"): no heartbeat Routine exists.
  `list_triggers` (2026-10-16, this session) returned three Routines, none
  with a `cron_expression`: `Orchestrate pass 3` is a one-shot `run_once_at`
  reminder bound to a persistent session (`/orchestrate pass` wake, not a
  heartbeat); the other two are disabled (`auto_disabled_session_gone`).
  Creating a recurring Routine is the human's spend (Out of scope). This
  manager session reads `lineage` depth 2 (`get_session`), so it cannot
  stand in for a Routine-fired reading. Unblock: operator creates an hourly
  `/orchestrate` Routine; a manager then takes both readings and builds.

## Where to look

- `.claude/commands/orchestrate.md` — §0 step 3, §4 HAND-OFF, Tools table.
- `.agents/docs/orchestrated.md` — Heartbeat section.
