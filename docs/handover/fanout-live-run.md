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
next: Re-check the second session; record the four numbers when the wave ends. Sessions started, pull requests merged, hours unattended, and how the fleet ended
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

## Observations

**Run start 2026-08-30T20:21:13Z. Sessions started: 2.**

Observation 1, 20:52Z (31 min in):

- `perf-ceiling-resample` (session_01TX1g3u…, sonnet): **DONE**. Branch cut,
  built, reviewed, PR #146 opened 20:43:48Z and **merged by the session itself
  at 20:45:54Z** — 24 minutes from spawn to merged, no human turn. Plan file
  and workstream file both retired by the pull request. Session then went IDLE
  and took no further queue work, as instructed. Cost $4.87.
- `flag-abandoned-in-flight` (session_01HLUEzT…, sonnet): RUNNING at 31 min,
  "shellcheck warnings on selftest; fixing now". Branch and workstream file
  pushed at ~20:31Z.

Quality of the unattended merge, checked rather than assumed: #146 took five
samples (#141-#145), avoided both traps the spawn prompt named, and derived its
headroom from the swing the file already measured instead of picking a round
number — feedback 267, review 275. It also established empirically why the two
rows differ (feedback walks merged edges only, so an unmerged branch commit does
not move it; review sees +5), which the plan did not ask for and which is
better reasoning than the flat 300 this session left behind.

## Review

None yet.

## Blockers

None.

## Where to look

- `.agents/docs/unsupervised.md` — the cadence and the proved stop.
- `.agents/harness/queue-context.sh:qc_mode` — what the fleet is ordered to do.
