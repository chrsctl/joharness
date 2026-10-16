---
plan: heartbeat-self-registers
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: .claude/commands/orchestrate.md, .agents/docs/orchestrated.md, .agents/harness/selftest/orchestrated.sh, .agents/scripts/bootstrap-consumer.sh, .agents/harness/selftest/bootstrap-consumer.sh, docs/plans/orchestrator-heartbeat-successor.md
---

## Goal

Requester, 2026-10-16: the heartbeat "should automatically register if not
existent", when the orchestrate command runs. A Routine a session makes
with `create_new_session_on_fire` fires a session with no repository, no
session tools and no GitHub tools (the joharness test fire, 2026-10-16), so
a self-made fresh-session heartbeat cannot orchestrate. The requester chose
the keeper design: `/orchestrate` creates one `keeper: <owner/repo>` session
(repository attached, tools present) and a heartbeat Routine bound to it;
each hourly wake, the keeper starts a fresh orchestrator when none is live.

## Scope

- `.claude/commands/orchestrate.md` "## 0. Start" step 5: register when
  none exists; repair a session-made stale one; never touch a paused or a
  human-made one. New spec reasons (`unbound`, `keeper-gone`, `paused`).
  New "## Keeper" section: the wake's one check and one spawn.
- `.agents/docs/orchestrated.md` Heartbeat section: the keeper design, its
  spec, why bound and not fresh, the human's veto (pause).
- `.agents/harness/selftest/orchestrated.sh`: needles for the new clauses.
- `.agents/scripts/bootstrap-consumer.sh` heartbeat note + its selftest.
- `docs/plans/orchestrator-heartbeat-successor.md`: rewrite to fire the
  keeper's heartbeat at hand-off instead of a UI-made Routine.

## Out of scope

- The hand-off through the keeper (that plan, rewritten).

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- SHIPS: in gx after the sync, `/orchestrate` with no heartbeat prints
  `heartbeat registered: <trigger id>, keeper <session id>`, and
  `list_triggers` shows `heartbeat: chrsctl/gx` bound to that keeper.
