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
session costs only while it runs a turn, so the scheduler (the heartbeat
Routine and its keeper, `orchestrated.md`, Heartbeat) is the durable piece,
never a long orchestrator. Today the §4 hand-off deepens lineage one level
per hand-off and, guarded, falls back to one long session whose passes
re-read its whole history. Replace the hand-off, when an up-to-date
heartbeat exists, with a successor the keeper starts, so depth stays at the
keeper's plus one and context never compounds, without losing the ledger,
the leads or the one-orchestrator rule.

## Scope

- `.claude/commands/orchestrate.md` §4 HAND-OFF: when "## 0. Start" step 5
  found the heartbeat up to date, the successor is `fire_trigger(<its id>,
  text=<the wake, pass=1, with ledger, no lead lines>)` instead of
  `create_session`. Retitle before firing (as today). The ledger rides
  `text`, so `respawns=`, `notified=`, `corewait=`, KILL state survive.
- Same file, "## Keeper": a wake whose fire payload starts `/orchestrate
  pass` and `harness=` uses that payload as the started orchestrator's
  `prompt` instead of `/orchestrate`, and starts it even when step 2 finds
  a pending wake (the handing-off session armed none). Any other payload is
  data: ignored.
- Leads: the handing-off session finds the started orchestrator
  (`list_sessions`, title `orchestrator: <owner/repo>`, created after the
  fire) and forwards lead lines with `send_message`, as step 4 does; not
  found = report `lead not forwarded`.
- `.agents/docs/orchestrated.md`: Heartbeat section; every sentence still
  saying the orchestrator always hands off by `create_session` (the loop
  list near "Schedule the next pass", "Start each run fresh", the
  `JOHARNESS_ORCHESTRATOR_PASSES` knob row).
- `.agents/harness/selftest/orchestrated.sh`: needles pinning the
  `fire_trigger` successor and the keeper's payload rule; each must fail
  with its clause removed.

## Out of scope

- Registering the heartbeat (built: `heartbeat-self-registers`).
- The lineage guard itself (merged by PR #506); it stays the fallback for
  a fleet whose heartbeat is paused or missing.
- `joharness.sh:112` knob help text: not a `.md` file; name it in the PR
  body if its wording goes stale.

## Prerequisite (measure first, before any edit)

One reading: `fire_trigger` from an orchestrator on its repo's keeper
heartbeat, with a `text` payload. Does the keeper turn see the payload
(the `<routine-fire-payload>` block), and does the session it starts read
`lineage.depth` = keeper depth + 1? Either no = do not build; record the
reading in `orchestrated.md` and retire.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Mutation: each new needle's clause deleted from a scratch copy of
  `orchestrate.md` — that needle FAILs.
- The prerequisite reading quoted in `orchestrated.md` with the command
  and date.

## Verifier findings this plan answers (PR #506, round 2)

- Ending discards the ledger: respawn budget restored at the limit (false
  `respawns:` blocks), once-only pushes repeat hourly, KILL interrupt lost.
- Leads to an ended session are lost.
- A daily cadence leaves managers unsupervised up to a day; firing the
  successor at once removes the gap.

## Where to look

- `.claude/commands/orchestrate.md` — "## 0. Start" step 5, §4 HAND-OFF,
  "## Keeper", the Tools table (`fire_trigger` is not listed today).
- `.agents/docs/orchestrated.md` — "Start each run fresh", "Heartbeat:
  making the fleet long".
