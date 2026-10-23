---
plan: keeper-counts-parent
urgency: urgent
agent: sonnet
effort: high
needs: none
requirement: none
issue: none
scope: .claude/commands/keeper.md, .agents/docs/orchestrated.md, shared:.agents/harness/selftest/orchestrated.sh
---

## Goal

A human ran `/orchestrate` in chrsctl/gx (session_01YEVrWjByLAa4hKmqJH4ubu,
2026-10-23 00:38Z). Its REGISTER made the keeper, whose first turn (prompt
`/keeper`) ran at once: the orchestrator was still in its first start, held
no `/orchestrate pass` wake, and was not the one the keeper last started, so
the keeper started a second (session_01Xztqx6wP9fX4HdRSfv1stg), which exited
at "## 0. Start" step 3 as duplicate. Every REGISTER and every replace pays
this. The keeper's guard `get_session` already returns `parent_session_id`:
the orchestrator whose REGISTER made it. Count it LIVE.

## Scope

- `.claude/commands/keeper.md` — step 2: also LIVE, the guard read's
  `parent_session_id` when `get_session` finds it titled exactly
  `orchestrator: <owner/repo>` and `RUNNING` or `PENDING`. Last paragraph:
  only a human-started orchestrator that is not the keeper's parent is
  still missed.
- `.agents/docs/orchestrated.md` — "Keeper liveness reads wakes, not
  sessions" and the Heartbeat paragraph say the same.
- `.agents/harness/selftest/orchestrated.sh` — pin the new clause.

## Out of scope

- `list_sessions` in the keeper: ~78k characters an hour into one persistent
  context (orchestrated.md, Keeper liveness).
- Creating the keeper without a prompt: untested platform behaviour.
- `orchestrate.md`: its duplicate exit already stops the second one.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed.
- The new selftest needle FAILS against the old keeper.md.

## Where to look

- `.claude/commands/keeper.md:## Run` — step 2's LIVE test.
- `.agents/docs/orchestrated.md:Keeper liveness reads wakes, not sessions`.

## Traps

- Docs state status quo: no incident narrative in markdown.
