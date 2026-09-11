---
workstream: curator-in-the-loop
status: in-progress
branch: claude/work-visibility-orchestrator-zvzo62
pr: 237
plan: curator-in-the-loop
issue: none
session: https://claude.ai/code/session_01BrSMgwe9csBqCjehd6v16R
agent: opus
updated: 2026-09-11
next: Build dispatch_curate_due as the one reader, wire cmd_drain, then drain.md and the AGENTS.md clause; cases first
---

## Goal

The curator shipped wired only into orchestrated mode, and with a 168h clock.
The requester corrected both: it belongs in the cycle `/start` runs, and it has
to run as often as work is produced. Plan: `docs/plans/curator-in-the-loop.md`.

Third item on this branch, and it re-opens a retired edge: PR 237 is open and
unmerged, so the retire commit is no longer last and has to be redone. Taken
here rather than on a new branch because shipping a curator the default mode
cannot reach is shipping the wrong thing, and the fix is not separable from
what it fixes.

## Decisions

- Two triggers, not one. Production (`JOHARNESS_CURATE_PLANS` plan files
  changed since the last curate) is primary, because that is what makes
  declarations untrue. Time (`JOHARNESS_CURATE_HOURS`) is kept for the case
  production cannot see: code moving UNDER a plan breaks its anchors with no
  plan file changing.
- Measured, not guessed: plan files touched per week on `origin/main`, last 12
  weeks, 2026-09-11 — `0` eight times, then `32`, `55`, `10`. A 168h clock
  fires eight times over nothing and about three times over 97 changes. Both
  defaults stay written numbers and say so.
- ONE reader (`dispatch_curate_due`) for both entrypoints. Two readers of one
  cadence is two answers to "is a curate due", and the orchestrator and a
  supervised session would act on different ones.
- Placed after the edge block and before the queue verdict in `drain`:
  finishing outranks starting, and a truthful queue is worth having before the
  pick rather than after it.

## Rejected

- A Routine. The requester named `/start` as the driver; a Routine would be a
  second driver for the same cadence and the two could disagree.
- Keeping the curator SUPERVISED ONLY. It edits `docs/plans/` and no protocol
  path, so an unattended session may take it — and the idle queue that needs
  it most is the unattended fleet's.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:cmd_drain` — where the block goes.
- `joharness.sh:cmd_start` — why orchestrated-only was unreachable.
