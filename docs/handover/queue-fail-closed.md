---
workstream: queue-fail-closed
status: in-progress
branch: claude/queue-fail-closed
pr: none
plan: queue-fail-closed
issue: none
session: https://claude.ai/code/session_01MGeFxF7JmsWwnj5MiThqag
agent: opus
updated: 2026-10-22
next: Write failing selftests for drain_hook, janitor_candidates, janitor_apply, then fix joharness.sh
---

## Goal

Queue readers and writers fail closed: a missing or broken queue hook reads
UNREADABLE (never DRAINED), the janitor keeps blocked/done claims, and a
claim with no `status:` line gets `status: abandoned` on release.

## Decisions

- None yet.

## Rejected

- None yet.

## Review

- r0: placeholder until review runs (no change)

## Blockers

None.

## Where to look

- `joharness.sh:drain_hook`, `janitor_candidates`, `janitor_apply`.
