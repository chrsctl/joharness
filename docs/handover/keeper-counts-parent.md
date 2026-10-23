---
workstream: keeper-counts-parent
status: in-progress
branch: claude/keeper-counts-parent
pr: none
plan: keeper-counts-parent
issue: none
session: https://claude.ai/code/session_01UKGbVMqwyJLsHC7REFXAkF
agent: sonnet
updated: 2026-10-23
next: Run ci and verify, spawn the verifier, record Review, then retire files and open the PR
---

## Goal

The user: "orchestrate command spawned a duplicate orchestrator in gx, fix in
joharness". The keeper REGISTER creates runs its first turn while the
registering orchestrator holds no wake, and starts a second orchestrator.

## Decisions

- LIVE also covers the keeper's own `parent_session_id` (already in the
  guard's `get_session` read): REGISTER and replace both create the keeper
  from the orchestrator in its first start, so this is exactly the session
  the wake test misses. One field, no extra call.

## Rejected

- `list_sessions` in the keeper: too large for an hourly persistent context.
- Keeper created with no prompt: no measurement of how such a session starts.

## Review

## Blockers

None.

## Where to look

- `.claude/commands/keeper.md:## Run` — step 2.
