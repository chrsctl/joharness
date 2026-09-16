---
workstream: orchestrated-run-row
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: orchestrated-run
issue: none
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: sonnet
updated: 2026-09-16
next: Review, retire this file and open the pull request
---

## Goal

Scope bullet 2 of `docs/plans/orchestrated-run.md`, for the run in flight in
`chrsctl/gx` since 2026-09-11. The requester asked for the counting and the
row. Not a new run: this one is already going and its numbers are the ones
the Runs table wants.

## Decisions

- One row for the CLEAN WINDOW only, 2026-09-11T09:53:25Z to
  2026-09-13T03:50:34Z, with the stall recorded beside it rather than
  inside it. Merges stop dead for 3.5 days after that because GitHub could
  allocate no runner account-wide, so step 7's first condition could never
  be met; a rate spanning the outage measures the outage.
- The run is NOT over, so the row says so. `.agents/docs/orchestrated.md`
  already has the shape for this — run 2's paragraph is an in-flight
  observation with no row — but this run has enough counted to earn one.
- Ledger columns (nudges, kills, respawns) come from the orchestrator's own
  one-shot check-in Routines, whose prompts carry the ledger. That reads
  another session's record without interrupting a live one.
- The plan's state block says gx's knobs are unconfirmed. False, and this
  session made it so by not reading gx: the conf carries
  `JOHARNESS_MAX_MANAGERS=4` with the requester's 2026-09-06 decision, and
  `JOHARNESS_MODE=orchestrated` merged. Corrected in the same pull request.

## Rejected

- Messaging the live orchestrator for its ledger. It is RUNNING and mid-pass;
  a message queues a turn and costs the run a step for data its own Routines
  already carry.

## Review

- r1: (session) the first framing of this work blamed the 3.5-day gap on the GitHub Actions outage, reading it from gx's conf note. The orchestrator's own ledger says otherwise: its self-armed pass chain stopped at 04:14Z and every manager resumed within 30 seconds of it at 14:54Z three days later, so the fleet was not blocked, it was not running. Both walls are real and they are different findings. (fixed — the entry names the freeze mechanism, and the outage separately under the boundary collision)
- r2: (session) "at least 31 managers" from a 40-session read would have been a written number dressed as a count: the dump was capped and its oldest entry postdated the run's start. (fixed — re-read at limit 100, whose oldest session predates the run by four days, giving 59 inside the window and 61 to date)
- r3: (session) merges nearly went in as 44 from the repo-wide search, which counts two harness syncs and a session the orchestrator names as the human's own. The fleet's own count is 41. (fixed — 41 in the row, 44 named beside it with the difference explained)

## Blockers

None.

## Where to look

- `.agents/docs/orchestrated.md` Runs — run 1's row is the shape to match.
- `chrsctl/gx:joharness.conf` — the knobs, and the requester's own note on
  why checks went local on 2026-09-16.
