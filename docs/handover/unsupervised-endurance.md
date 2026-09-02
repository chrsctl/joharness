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
next: Pre-flight the connector trap, then get the cap number, then flip mode and start
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

Two, both before any spend:

1. **The connector trap, unverified.** `.agents/docs/unsupervised.md`
   records that a Routine created by `create_trigger` stores no MCP
   connectors, so its fired sessions have no `mcp__github__*`. This
   environment has no `gh`, so such a session cannot open or merge a pull
   request — step 7 is unreachable and the fleet cannot complete the Loop.
   Must be settled by firing one throwaway before the real heartbeat.
2. **Cap value outstanding.** A cap with no number is not a cap.

## Where to look

- `docs/plans/unsupervised-endurance.md` — the plan, its two human gates,
  and the fourth wall it names in itself.
- `.agents/docs/unsupervised.md` — operator procedure and the connector
  trap.
- T0 evidence recorded at claim time: `./joharness.sh sources` says sweep
  NOT dry, findings(4 unmarked); queue holds two plans, both serving
  `unsupervised-mode`.
