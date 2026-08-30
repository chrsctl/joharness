---
workstream: fanout-live-run
status: in-progress
branch: claude/fanout-live-run
pr: none
plan: fanout-live-run
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-30
next: Record sessions started, pull requests merged, hours unattended, and how the fleet ended
---

## Goal

Measure what `unsupervised-fanout` shipped: whether a fleet started per-wave
actually runs and merges without a human turn. The mechanism has tests; the
requirement's claim has never had a run.

## Decisions

- **Go confirmed by the human 2026-08-30**, with blast radius chosen
  explicitly: "Full: fleet merges its own PRs" — sessions run the full Loop
  including step 7 self-merge, unattended. Recorded here because the plan's
  Out of scope requires the answer be recorded, not just obtained.
- **Precondition restored honestly, not waived.** Draining the queue this
  session left one free plan and no wave. Three real plans were queued first
  (#145) so wave 1 holds three; the run measures a fan-out that had somewhere
  to go.
- **The repo mode is NOT flipped.** Step 7's self-merge is a supervised rule,
  so the fan-out and the unattended merging can both be exercised as they
  stand. What unsupervised adds is generating work at an empty queue, which
  is the one behaviour a spawned session should not have here — and flipping
  `joharness.conf` is repo-wide, so it would license it for the unrelated
  session already live on another branch.
- Each spawned session is given ONE named plan and told to stop after it.
  Bounding generation is what makes the run safe to leave alone.

## Rejected

- Committing `JOHARNESS_MODE=unsupervised` to `main` for the run. Spawned
  sessions read the conf (env → marker → conf, and a fresh clone has neither
  of the first two), so it is the only channel that reaches them — and it
  reaches every other session too, for as long as the run lasts.

## Review

None yet.

## Blockers

None.

## Where to look

- `.agents/docs/unsupervised.md` — the cadence and the proved stop.
- `.agents/harness/queue-context.sh:qc_mode` — what the fleet is ordered to do.
