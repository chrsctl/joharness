---
research: selftest-runtime
urgency: normal
agent: opus
effort: high
graduates: .agents/harness/selftest.sh
---

## Question

Where do the 493 s of `.agents/harness/selftest.sh` go? And which changes
cut that time most without dropping a case that fails without its fix?

## Echo

The selftests are about 24.8k lines (`cat .agents/harness/selftest.sh
.agents/harness/selftest/*.sh | wc -l`), about 1.6 times the code they
test. Two verifier runs of `time bash .agents/harness/selftest.sh` in a
cloud container with 4 CPUs and the default `JOHARNESS_SELFTEST_JOBS`
measured `real 8m13.848s` and `real 8m51.963s`. `ci-selftest-scope.sh`
writes "16s of a 22s ci run", which these measurements contradict.

Every branch whose diff touches harness code pays this on each `ci` and
`finish` (`ci-selftest-scope.sh` skips the suite otherwise). On a busy base, `finish`
had to be re-run three times in one session while main kept moving.
Rule: no case is skipped, disabled or quarantined to save time.

## Sweep

goal-directed: complete when the top topics by wall time are named with
their causes, covering at least 80% of the total, and each cause has a
proposed change with its estimated saving.

## What would settle it

- Per-topic wall time and git-exec count, measured with the command named.
- The serial chains (`SELFTEST_CHAINS`) and how much of the run they cover.
- Duplicate fixtures: repos built the same way in several topics.
- Cases that assert the same output twice.
- Per change: the saving, and the proof that no case loses its
  fail-without-the-fix property.

Settled either way: "no change saves over 20%" is an answer too.

## Method

Pending: the researching session fills it.

## Findings

Pending.

## Consequence for the queue

Pending. Expected: one or more plans, for example a shared fixture cache,
splitting chains, or a single-topic selector (the last also serves
research conduct-c2-design).

## Verification

Pending: a second context checks the findings.

## Graduates to

`.agents/harness/selftest.sh`: the runner's header records where the time
goes and the budget it holds.
