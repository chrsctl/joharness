---
workstream: heartbeat-read-cheaper
status: review
branch: heartbeat-read-cheaper
pr: none
plan: heartbeat-read-cheaper
issue: none
session: https://claude.ai/code/session_01J1YMK2xaEJbhsAHUh5Av6h
agent: sonnet
updated: 2026-11-11
next: Open PR, finish, merge
---

## Goal

Replace `list_triggers` `include_completed` reads with the cheap wakes and heartbeat reads.

## Decisions

- A1/A2: confirmed — tool description: `include_completed`: "also include one-shot scheduled tasks that have already fired ... and scheduled tasks moved to a project"; `enabled`: "Omit for both"; `list_triggers` description: `include_completed` adds fired one-shots and project-moved tasks (pending ones are listed without it); `enabled` "Omit for both".
- A3: confirmed — grep `include_completed` in `.claude/commands` and `.agents/docs` hit only the two spots the plan names; none needs a fired wake.

## Review

- r1: handover stale (next/status) (verifier) (fixed)
- r2: A1 description not quoted in Decisions (verifier) (fixed)

## Blockers

None.

## Where to look

- `docs/plans/heartbeat-read-cheaper.md`
