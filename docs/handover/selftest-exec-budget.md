---
workstream: selftest-exec-budget
status: in-progress
branch: claude/selftest-exec-budget
pr: none
plan: selftest-exec-budget
issue: none
session: https://claude.ai/code/session_01DbKVTgyQe9eSSKFCEcgi1Z
agent: opus
updated: 2026-10-14
next: Baseline count running on origin/main; write count+10% as the KNOBS default, commit joharness.sh, then re-count
---

## Goal

Bound the selftest's git execs with a counted budget in `ci_selftest`, and
remove invocations in dispatch/clerk/scout topics that re-run the same
command on the same fixture state.

## Decisions

- Re-runs on unchanged state, found by scanning every wrapper call pair with
  only assertions between (scratch script, not kept): two in dispatch.sh
  (the `dsp` after the PENDING_SPAWNS=1 case, the MAX_MANAGERS=20 run after
  `after`), none in clerk.sh, one in scout.sh (`out2="$(cdt)"`) that IS the
  assertion (a re-run picks the identical sample) and stays. The plan's
  premise of many removable re-runs did not hold; the budget is the main lever.
- Passing ci prints the selftest's last line plus the count, not its
  thousands of PASS lines; verbose or red prints all (the selftest itself
  sets JOHARNESS_VERBOSE=1, so ci-selftest-scope still sees its stub).

## Rejected

- Fixture cache: rejected in the plan (fixtures mutate in place; absolute origin URLs).

## Review

## Blockers

None.

## Where to look

- `joharness.sh:ci_selftest` — the stage the budget lands in.
