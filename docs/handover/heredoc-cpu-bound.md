---
workstream: heredoc-cpu-bound
status: in-progress
branch: claude/heredoc-cpu-bound
pr: none
plan: heredoc-cpu-bound
issue: 566
session: https://claude.ai/code/session_018FNpTGRJapDHTuQhgkbGwR
agent: sonnet
updated: 2026-10-23
next: Retire, PR, merge; then resume PR #565 (retire its workstream file and plan, merge)
---

## Goal

Issue #566: the heredoc timing case reds `lint` on pull request runs. User's
order: fix it, then merge PR #565 (parked on #566).

## Decisions

- Bound CPU time (user + sys), not wall clock: the case tells linear from
  quadratic (0.6 s vs 67 s), and CPU time does not grow with runner load.

- Measured 2026-10-23 in this container (4 CPUs), case lifted into a scratch
  script: linear guard `0.7s of CPU`; the quadratic `strip_heredocs`
  (`git show 70c9545e^:.agents/harness/pretool-bash-guard.sh`) FAILS at
  `57.0s of CPU`; under 24 busy loops the linear guard read 5.0 s of wall
  clock and still `0.7s of CPU`.
- `TIMEFORMAT` is local to `pbg_cpu_time`: the runner checks names a topic
  unsets at top level.

## Rejected

- Raising the wall-clock bound: the earlier raise to 15 s was outrun by
  runner load; any number is a guess at someone else's load.

## Review

- r1: (verifier) a comma-decimal locale would make `time` print `0,6` and awk read 0.0, a vacuous pass (fixed: `local LC_ALL=C` in `pbg_cpu_time`)
- r2: (verifier) comment numbers: 0.6 s vs measured 0.7 s; "four workers" and "15 s" unverifiable from the checkout (fixed: 0.7 s; 15 s is the #566 lint log, four = `JOHARNESS_SELFTEST_JOBS` default on a 4-CPU runner; no change)
- r3: (verifier) its own full-suite and `ci` runs did not finish under load (no change: this session's runs on the branch read `3300 passed, 0 failed`, `ci: pass`, `6 passed, 0 failed`; re-run after r1)

## Blockers

None.

## Where to look

- `.agents/harness/selftest/pretool-bash-guard.sh` — the heredoc case.
