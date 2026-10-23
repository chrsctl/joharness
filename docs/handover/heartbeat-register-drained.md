---
workstream: heartbeat-register-drained
status: in-progress
branch: claude/heartbeat-register-drained
pr: none
plan: heartbeat-register-drained
issue: none
session: https://claude.ai/code/session_01D8rDGonCmGBgmUyRnLNe8F
agent: sonnet
updated: 2026-10-23
next: Verifier and edge review; record in ## Review; then ci, verify, PR, finish
---

## Goal

A DRAINED orchestrator that registers the heartbeat must not cause a second
orchestrator. REGISTER's keeper takes its post on the first turn. The first
hourly wake does the LIVE check.

## Decisions

- REGISTER's `create_session` prompt is `/keeper register`, and the Routine
  keeps `/keeper`. The marker is explicit, so the keeper never has to guess
  "first turn" from its own context.
- The register turn starts nothing, whatever the parent's state. The
  registering orchestrator has just read dispatch. If it dies without
  finishing, the next hourly wake recovers within the hour.

## Rejected

- create_session with no prompt: whether a Routine can wake a session that
  never ran is unverified on the platform.
- Keeper counts a retired parent as LIVE: a retired title is never LIVE
  (ref § 0. Start step 3), and on later wakes the parent stays retired
  forever.
- Skip REGISTER on a DRAINED run: then nothing restarts the fleet when new
  plans land.

## Review

## Blockers

None.

## Where to look

- `.claude/commands/keeper.md:## Run`
- `.agents/docs/orchestrate-reference.md:## 0. Start` — step 5, REGISTER.
