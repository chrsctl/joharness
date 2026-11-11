---
workstream: heartbeat-read-cheaper
status: in-progress
branch: heartbeat-read-cheaper
pr: none
plan: heartbeat-read-cheaper
issue: none
session: https://claude.ai/code/session_01J1YMK2xaEJbhsAHUh5Av6h
agent: sonnet
updated: 2026-11-11
next: Edit orchestrator.md Superseded and orchestrator-reference.md per plan, run ci
---

## Goal

Replace `list_triggers` `include_completed` reads with the cheap wakes and heartbeat reads.

## Decisions

- A1/A2: confirmed — `list_triggers` description: `include_completed` adds fired one-shots and project-moved tasks (pending ones are listed without it); `enabled` "Omit for both".
- A3: confirmed — grep `include_completed` in `.claude/commands` and `.agents/docs` hit only the two spots the plan names; none needs a fired wake.

## Blockers

None.

## Where to look

- `docs/plans/heartbeat-read-cheaper.md`
