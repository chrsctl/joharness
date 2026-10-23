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

- r1 (verifier): REPLACE on a pass reaches REGISTER step 2 with no `list_sessions` answer (fixed: on a pass step 2 archives none; REPLACE already archived the bound keeper)
- r2 (verifier): the once-per-session cap did not plainly cover REPLACE, so a repeat break could buy a keeper every pass (fixed: REGISTER cap names REPLACE; later break = stale line only; pinned)
- r3 (verifier): "## 0. Start (… never per pass)" heading false; REPLACE lineage failure said "stop", undefined on a pass (fixed: heading names step 5 each pass; "end step 5 (a pass carries on)"; refute pins)
- r4 (verifier): Pass entry order named only Retired then Superseded, so Heartbeat could run before a superseded exit (fixed: order spelled Retired, superseded, Duplicate, Heartbeat)
- r5 (verifier): `include_completed` superset of the unfiltered call unmeasured (no change: the `list_triggers` tool description says it only adds fired one-shots and project-moved tasks to the default answer, which already lists paused ones)
- r6 (verifier): plan acceptance wants a heartbeat line on every later pass; a healthy check prints none (wontfix: plan retires with this branch; silence on a healthy heartbeat matches step 5 at start)
- r7 (verifier): added `orchestrated.md` sentence left an over-long unwrapped line (fixed: rewrapped)
- r8 (verifier): no negative pin that the old two-check skip line is gone (fixed: refute)
- r9 (verifier): plan role-title-emoji acceptance grep vacuous, match sites unnamed, code points unchecked (fixed: grep over set/match spellings, sites named, code-point command; nine single code points checked here)

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md:Pass entry` — the new bullet.
- `.agents/docs/orchestrate-reference.md:0. Start` — step 5.
