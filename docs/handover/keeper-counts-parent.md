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
next: Retire plan and workstream file, open the PR, merge on green
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

- r1: (verifier) "the guard read" unanchored in keeper.md; a literal reader could reuse a stale read (fixed: "this wake's guard `get_session` (no `session_id`)")
- r2: (verifier) no rule for an absent or empty `parent_session_id` (fixed: "absent or empty = skip it")
- r3: (verifier) the parent_session_id fact carried no measurement date, unlike keeper.md's other platform read (fixed: "(read 2026-10-23)")
- r4: (verifier) only the keeper.md step 2 clause was pinned; orchestrated.md and keeper.md's last paragraph could revert green (fixed: three needles added)
- r5: edge review: a parent stuck RUNNING or PENDING suppresses restarts, same as the last-started session already does (no change: no new hazard class)

## Blockers

None.

## Where to look

- `.claude/commands/keeper.md:## Run` — step 2.
