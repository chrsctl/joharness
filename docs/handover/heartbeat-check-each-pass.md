---
workstream: heartbeat-check-each-pass
status: review
branch: claude/emoji-titles-heartbeat-plans
pr: none
plan: heartbeat-check-each-pass
issue: none
session: https://claude.ai/code/session_013WPACvxW5KcJsqRQBABnmC
agent: sonnet
updated: 2026-10-23
next: ci and verify green, then retire workstream and plan, open PR, finish, merge
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

- r1: REPLACE on a pass reached REGISTER step 2 with no `list_sessions` answer; on a pass step 2 now archives none, REPLACE archived the bound keeper (verifier) (fixed in .agents/docs/orchestrate-reference.md)
- r2: once-per-session cap did not plainly cover REPLACE, so a repeat break could buy a keeper every pass; cap now names REPLACE, later break = stale line only, pinned (verifier) (fixed in .agents/docs/orchestrate-reference.md)
- r3: Start heading said never per pass; REPLACE lineage failure said "stop", undefined on a pass; now "end step 5 (a pass carries on)", refute pins (verifier) (fixed in .claude/commands/orchestrate.md)
- r4: Pass entry order named only Retired then Superseded, so Heartbeat could run before a superseded exit; order now spelled (verifier) (fixed in .claude/commands/orchestrate.md)
- r5: `include_completed` superset of the unfiltered call unmeasured (verifier) (no change: the list_triggers tool description says it only adds fired one-shots and project-moved tasks to a default answer that already lists paused ones)
- r6: plan acceptance wants a heartbeat line on every later pass; a healthy check prints none (verifier) (wontfix: plan retires with this branch; silence on a healthy heartbeat matches step 5 at start)
- r7: added orchestrated.md sentence left an over-long unwrapped line (verifier) (fixed in .agents/docs/orchestrated.md)
- r8: no negative pin that the old two-check skip line is gone (verifier) (fixed in .agents/harness/selftest/orchestrated.sh)
- r9: plan role-title-emoji acceptance grep vacuous, match sites unnamed, code points unchecked; nine single code points checked here (verifier) (fixed in docs/plans/role-title-emoji.md)

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md:Pass entry` — the new bullet.
- `.agents/docs/orchestrate-reference.md:0. Start` — step 5.
