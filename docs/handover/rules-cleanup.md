---
workstream: rules-cleanup
status: in-progress
branch: rules-cleanup
pr: none
plan: rules-cleanup
issue: none
session: https://claude.ai/code/session_01GdPHVTtzFeJHFTdksHvAHv
agent: opus
updated: 2026-10-22
next: History out of orchestrated.md and orchestrate.md, then ci, verify, review
---

## Goal

Rule files disagree with each other and with the code, load more than each
session needs, and carry history caveman.md forbids. Fix contradictions,
cut always-loaded text, move history out of docs (plan rules-cleanup).

## Decisions

- Keeper prompt is `/keeper` (the heartbeat REGISTER and spec), so the
  schedule names keeper.md and the keeper role comes from the prompt like
  every role. The title stays a guard on both files: keeper.md runs only
  titled `keeper:`, and orchestrate.md sends a keeper-titled session to
  keeper.md (live Routines still on `/orchestrate keeper` keep working
  until REPLACE, which accepts both prompts).
- Banner and `start` gain the `/keeper` route (joharness.sh, outside the
  plan's scope list): without it the banner tells a keeper it is the
  orchestrator, the very contradiction item 4 removes.
- reading-budget.sh's pointer check (outside the scope list) becomes a
  check that no `(why: history/` pointer and no history/ directory return;
  the byte bounds stay. Not a disabled test: its subject was deleted by
  the plan.
- AGENTS.md Block names `block_reason_ok` as the one list; step 2 keeps
  routing, unplanned-build, tier and boundary rules, drops the picking
  order (dispatch and the role commands own it).

## Rejected

- None yet.

## Review

## Blockers

None.

## Where to look

- `docs/plans/rules-cleanup.md` — the item.
