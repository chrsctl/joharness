---
plan: orchestrator-heartbeat-successor
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: .claude/commands/orchestrate.md, .agents/docs/orchestrated.md, .agents/harness/selftest/orchestrated.sh
---

## Goal

The human asked for a fleet that lives indefinitely and stays cheap. A
session costs only while it runs a turn, so the scheduler (a heartbeat
Routine) is the durable piece, never a live session. Today the §4 hand-off
deepens lineage one level per hand-off and, guarded, falls back to one
long session whose passes re-read its whole history. Replace the hand-off,
when a heartbeat exists, with a successor the Routine starts, so depth
never grows and context never compounds, without losing the ledger, the
leads or the one-orchestrator rule.

## Scope

- `.claude/commands/orchestrate.md` §4 HAND-OFF: when a heartbeat Routine
  exists, the successor is `fire_trigger(<its id>, text=<the wake, pass=1,
  with ledger>)` instead of `create_session`. The ledger rides `text`, so
  `respawns=`, `notified=`, `corewait=`, KILL state survive. Retitle before
  firing (as today). Find the fired session (`list_sessions`, title
  `orchestrator: <owner/repo>`, created after the fire) and forward lead
  lines with `send_message`, as step 4 does; not found = report `lead not
  forwarded`.
- The heartbeat test is "## 0. Start" step 5 (which Routine counts, and
  whether it is up to date): §4 fires that Routine only when step 5 found
  it up to date.
- Same file, "## 0. Start" step 3: an `orchestrator: <owner/repo>` session
  counts as live when `RUNNING`, or `IDLE` with `updated_at` within `2 ×
  JOHARNESS_HEALTH_MINUTES`. An orchestrator between passes reads IDLE; a
  RUNNING-only test lets each hourly firing start a second orchestrator
  (66-69 min sessions against an hourly cadence).
- `.agents/docs/orchestrated.md`: Heartbeat section (why the scheduler,
  not a session; measured Routine-fired depth); every sentence still saying
  the orchestrator always hands off by `create_session` (the loop list
  near "Schedule the next pass", "Start each run fresh", the
  `JOHARNESS_ORCHESTRATOR_PASSES` knob row).
- `.agents/harness/selftest/orchestrated.sh`: needles pinning the
  IDLE-with-`updated_at` rule and the `fire_trigger` successor; each must
  fail with its clause removed.

## Out of scope

- Creating, pausing or editing any Routine. Recurring spend is the
  human's (`orchestrated.md`, Heartbeat, "Operator action, always").
- The lineage guard itself (merged by PR #506); it stays the fallback for
  a fleet with no heartbeat.
- `joharness.sh:112` knob help text: not a `.md` file; name it in the PR
  body if its wording goes stale.

## Prerequisite (measure first, before any edit)

Two readings, both from a heartbeat Routine the operator created in the
claude.ai Routines UI:

1. `get_session` (no `session_id`) `lineage` in a session the Routine fires
   on schedule.
2. The same in a session that `fire_trigger` starts when called from a
   session at depth d > 0, and whether `fire_trigger`'s result or
   `list_sessions` names that session's id.

Depth 0 in both = build as scoped. `fire_trigger`-fired depth = d + 1 =
the design fails (it deepens like the hand-off): do not build; record the
reading in `orchestrated.md` and retire. A Routine made from a session
cannot serve: its sessions get no repository and no session tools
(`orchestrated.md`, Heartbeat). No heartbeat Routine exists =
`status: blocked`, `next:` = `money: create an hourly /orchestrate
heartbeat Routine in the claude.ai UI so its lineage can be read`.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Mutation: each new needle's clause deleted from a scratch copy of
  `orchestrate.md` — that needle FAILs.
- Both prerequisite readings quoted in `orchestrated.md` with the command
  and date.

## Verifier findings this plan answers (PR #506, round 2)

- RUNNING-only one-orchestrator test vs IDLE-between-passes: overlap every
  firing, duplicate manager spawn on an unclaimed `@new`.
- Ending discards the ledger: respawn budget restored at the limit (false
  `respawns:` blocks), once-only pushes repeat hourly, KILL interrupt lost.
- Leads to an ended session are lost.
- A daily cadence leaves managers unsupervised up to a day; firing the
  successor at once removes the gap.

## Where to look

- `.claude/commands/orchestrate.md` — "## 0. Start" step 3 and 5, §4
  HAND-OFF, the Tools table (`fire_trigger` is not listed today).
- `.agents/docs/orchestrated.md` — "Start each run fresh", "Heartbeat:
  making the fleet long".
