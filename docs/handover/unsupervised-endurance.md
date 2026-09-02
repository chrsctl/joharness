---
workstream: unsupervised-endurance
status: in-progress
branch: claude/gastown-review-owjgzg
pr: none
plan: unsupervised-endurance
issue: none
session: https://claude.ai/code/session_01JU2E2vNtdyc5di2jrZfBRg
agent: opus
updated: 2026-09-02
next: BLOCKED on an operator action — the heartbeat must be created from the claude.ai Routines UI, not by a session
---

## Goal

Drive attempt four at the requirement's one open bullet — "Started once,
the fleet keeps going for hours with no human turn". The plan
(`docs/plans/unsupervised-endurance.md`) reserves two gates to the human;
both were answered 2026-09-02: **heartbeat first, then run**, and **cap the
run** rather than letting a dry sweep bound it.

This file claims the plan so a spawned fleet cannot take it — the plan's
own instruction, because the first session to reach the queue would
otherwise claim the plan that says spawning is the human's call.

## Decisions

- Claimed by this session before any spawn, per the plan's "the session
  driving the run claims this plan itself".
- Heartbeat authorised by the requester. `.agents/docs/unsupervised.md`
  says a session never creates one and reading the procedure is not
  authorisation; the requester's answer is what opens that gate, and it is
  recorded here rather than inferred.
- Cap chosen over dry-sweep bound. The sweep is NOT dry at T0 (4 unmarked
  findings), so a dry-sweep bound is open-ended. Cap value is the
  requester's and is still outstanding.

## Blockers

**The heartbeat cannot be created by this session, and the run cannot start
without one.** Settled at zero cost, no firing — see r1. The remedy is the
one the trap's own paragraph names: create it from the claude.ai Routines
UI, or from a session holding the connectors. That is an operator action.

Cap value is also still outstanding, but it is downstream of the above.

## Review

- r1: (session, pre-flight) the connector trap is REAL here and is not
  workaroundable from a session. Two probes, no firing, no spend:
  `create_trigger` with `connectors: ["github"]` fails outright — "the
  connectors parameter is not available for this organization"; the same
  call without it succeeds and returns the tool's own warning, "this
  trigger stores no MCP connectors, so the sessions it fires will run
  without connector (mcp__<server>__*) tools ... create it from a session
  that holds them, or ask the user to create it from the claude.ai routines
  UI". Both probes deleted. Consequence: a heartbeat created by a session
  fires sessions with no `mcp__github__*`, and this environment has no `gh`
  CLI, so a fired session cannot open or merge a pull request. Loop step 7
  is unreachable, the fleet cannot finish a plan, and a run started this way
  would measure a fleet that cannot merge rather than endurance (open —
  needs the operator)
- r2: (session) `.agents/docs/unsupervised.md` says to settle this by
  firing one throwaway and checking it could reach GitHub. Reading the
  stored grant back is strictly cheaper and strictly earlier — it costs no
  session at all — and the tool now warns at creation time, which it may
  not have when that line was written. Worth graduating into that file's
  procedure when this run closes (open)

## Where to look

- `docs/plans/unsupervised-endurance.md` — the plan, its two human gates,
  and the fourth wall it names in itself.
- `.agents/docs/unsupervised.md` — operator procedure and the connector
  trap.
- T0 evidence recorded at claim time: `./joharness.sh sources` says sweep
  NOT dry, findings(4 unmarked); queue holds two plans, both serving
  `unsupervised-mode`.
