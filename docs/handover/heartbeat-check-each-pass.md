---
workstream: heartbeat-check-each-pass
status: in-progress
branch: claude/emoji-titles-heartbeat-plans
pr: none
plan: heartbeat-check-each-pass
issue: none
session: https://claude.ai/code/session_013WPACvxW5KcJsqRQBABnmC
agent: sonnet
updated: 2026-10-23
next: Edit orchestrate.md Pass entry, ref step 5, orchestrated.md; pin; ci, verify, verifier
---

## Goal

Requester: the joharness heartbeat broke ("fix in general"). A keeper
archived mid-run left the Routine bound to a repo-less session, and the
live orchestrator never re-checked. Every pass re-checks and replaces.

## Decisions

- Per-pass check reuses the superseded check's `list_triggers` answer
  (`include_completed` is a superset of the unfiltered call): cost is one
  `get_session` on the bound keeper a pass.
- Runs after Retired, Superseded, Duplicate: a pass that does nothing
  touches no Routine.
- REGISTER keeps "at most once per session": a second break in one run is
  reported, not re-replaced, so a broken platform cannot loop paid keepers.

## Rejected

- A fallback line in the Routine prompt for a repo-less session: that
  session holds no `create_session`/`get_session`, so it can only notify,
  and the prompt spec (`/keeper` exactly) would change for every consumer.

## Review

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md:Pass entry` — the new bullet.
- `.agents/docs/orchestrate-reference.md:0. Start` — step 5.
