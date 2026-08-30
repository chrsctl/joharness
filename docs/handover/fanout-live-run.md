---
workstream: fanout-live-run
status: review
branch: claude/fanout-live-run
pr: none
plan: fanout-live-run
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-30
next: Merge once green
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

## Result — the four numbers

**Sessions started: 2.** One per free wave-1 plan, spawned 20:21:13Z.

**Pull requests merged: 2**, both merged by the session that opened them, with
no human turn:

| plan | PR | opened | merged | spawn to merged |
| --- | --- | --- | --- | --- |
| perf-ceiling-resample | #146 | 20:43:48Z | 20:45:54Z | 24 min |
| flag-abandoned-in-flight | #147 | — | 21:14Z | 53 min |

**Wall-clock unattended: 53 minutes**, 20:21:13Z to 21:14Z. Not hours. The
requirement's claim is that a fleet "keeps going for hours with no human turn";
this run does NOT establish that and must not be read as if it did.

**How it ended: the work ran out, not the mode's stop.** Both sessions finished
their one named plan, merged it, and went IDLE without taking further queue
work — because the spawn prompt told each to stop there. That bound was the
point, and it means the dry-sweep stop was never exercised either.

Cost: $4.87 + $10.05 = $14.92 for two merged plans.

## What this run does and does not evidence

Evidenced:

- Fan-out starts a fleet. Two sessions, two branches, two merges, no collision.
- Unattended self-merge works end to end, including the finishing ritual: both
  pull requests retired their own plan and workstream file.
- A spawned session reconciles when the base moves under it. `2aa8b6b` at
  21:10Z is `flag-abandoned-in-flight` merging `origin/main` in before
  finishing — 1 of 2 merges, which is the same cost in kind as the 25.4%
  baseline in `.agents/docs/product/README.md`, on a sample far too small to
  compare against it.
- Quality held at sonnet, unattended. #146 took five samples, avoided both
  traps its prompt named, and derived its headroom from the swing the file
  already measured rather than picking a round number — sharper than the flat
  300 this session had left. #147 shipped env-overridable thresholds whose
  defaults carry their measurement, as its plan required.

NOT evidenced, and the requirement still wants both:

- **Endurance.** 53 minutes is not "hours", and the fleet stopped because its
  work was exhausted, not because it kept finding more.
- **Generate-work-at-the-edge.** The repo mode was deliberately not flipped
  (see Decisions), so an empty queue was never a trigger. That half of
  `unsupervised-mode` remains unmeasured.

## Review

opus, adversarial, on the run rather than on a diff.

- r1: the honest failure mode here was writing "the fleet ran unattended" and
  letting it read as the requirement satisfied. It measured 53 minutes against
  a claim about hours. Stated as not-evidenced rather than hedged. (fixed)
- r2: checked both merged diffs rather than counting the merges. A run that
  reports "2 merged" without reading what merged would pass a fleet that
  shipped nonsense. Both hold up; #146's reasoning is better than what it
  replaced. (no action)
- r3: the reconcile at 21:10Z is one data point and reads as confirmation of
  the 25.4% baseline. It is not: n=2. Recorded as same-in-kind, explicitly not
  as a rate. (fixed)
- r4: the fleet's stop was my instruction, not the harness's. Recording it as
  "the fleet ended cleanly" would credit the mode for a bound I imposed. (fixed)

## Blockers

None.

## Where to look

- `.agents/docs/unsupervised.md` — the cadence and the proved stop.
- `.agents/harness/queue-context.sh:qc_mode` — what the fleet is ordered to do.
