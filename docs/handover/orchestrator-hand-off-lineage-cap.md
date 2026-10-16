---
workstream: orchestrator-hand-off-lineage-cap
status: in-progress
branch: claude/orchestrator-hand-off-lineage-cap
pr: none
plan: orchestrator-hand-off-lineage-cap
issue: none
session: https://claude.ai/code/session_01NAJQNsQCP5ob8fkWYjKsVg
agent: opus
updated: 2026-10-16
next: Verify the gx chain from this session, then graduate into orchestrate.md §0 and §4
---

## Goal

Settle `docs/research/orchestrator-hand-off-lineage-cap.md`: can §4 HAND-OFF
strand the fleet at the control plane's lineage cap; graduate the guard into
`.claude/commands/orchestrate.md`.

## Decisions

- Second context = this manager session's own `get_session` calls.

## Rejected

None yet.

## Review

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` — §0 Start, §4 HAND-OFF.
- `.agents/docs/orchestrated.md` — "Start each run fresh", Heartbeat.
