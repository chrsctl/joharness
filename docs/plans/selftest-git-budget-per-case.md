---
plan: selftest-git-budget-per-case
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
issue: none
scope: joharness.sh, .agents/harness/selftest/ci-selftest-scope.sh, shared:.agents/harness/selftest.sh
---

## Goal

`ci`'s selftest stage reds when the suite's git execs pass a fixed number,
`JOHARNESS_SELFTEST_GIT_BUDGET`. The suite grows with every plan, so the
fixed number goes stale and reds `main` with no regression in it (issue #603:
`origin/main` at 202a48ca counted 89189 against 88960, with 3534 cases where
the number was set at 2813). Make the budget a rate: git execs per passing
case. Adding cases then raises the limit, and a topic that re-runs work, or a
new topic whose cases cost more git execs than the average, still reds the stage.

## Scope

- `joharness.sh:selftest_counted` — keep the suite's output (it streams
  today) and read its `<P> passed, <F> failed` line (selftest.sh prints it).
  Red when `execs > per_case * P`. Print
  `selftest git execs: <n> for <P> cases (<n/P, one decimal> per case, budget <per_case>)`.
  A suite that prints no count line = red, `suite printed no pass count`.
- `joharness.sh` knob table (line `JOHARNESS_SELFTEST_GIT_BUDGET|…`) —
  replace it with `JOHARNESS_SELFTEST_GIT_PER_CASE`, an integer. Default =
  measured execs per passing case on this repository, plus a tenth, rounded
  up; the comment above `selftest_counted` names the command, the date and
  both counts.
- `.agents/harness/selftest/ci-selftest-scope.sh` — the budget cases: the
  stub suite prints `2 passed, 0 failed`; at the budget passes, one exec past
  it reds; a stub printing no count line reds with `suite printed no pass count`.
- `.agents/harness/selftest.sh` — the knob name in its env scrub list.

## Assumptions

- A1: selftest.sh prints exactly one `%d passed, %d failed` line at its end — evidence: `.agents/harness/selftest.sh` (`printf '\n%d passed, %d failed`) — confidence: high
- A2: nothing outside the three files reads `JOHARNESS_SELFTEST_GIT_BUDGET` — evidence: `grep -rn SELFTEST_GIT_BUDGET --exclude-dir=.git .` — confidence: high
- A3: execs per case is about 25 today (89316 / 3534 on branch manage/dispatch-held-merged-pr, 2026-10-24) — evidence: `./joharness.sh ci -v` — confidence: medium; measure again, never copy this number

## Out of scope

- Making any topic cheaper.
- A per-topic budget.
- Changing what the counting wrapper counts (every git exec, from outside the suite).

## Acceptance

- `./joharness.sh ci -v` prints `selftest git execs: <n> for <P> cases (` and `ci: pass`.
- `JOHARNESS_SELFTEST_GIT_PER_CASE=1 ./joharness.sh ci` prints `Over budget` and `ci: FAIL`.
- `grep -rn SELFTEST_GIT_BUDGET --exclude-dir=.git .` prints nothing.
- The new no-count-line case fails with the `selftest_counted` change reverted.
- `./joharness.sh verify` — `0 failed`.

## Where to look

- `joharness.sh:selftest_counted` — the wrapper, the count, the red.
- `joharness.sh:cmd_ci` — `run_check "harness selftest" ci_selftest`.
- `.agents/harness/selftest/ci-selftest-scope.sh` — the two `JOHARNESS_SELFTEST_GIT_BUDGET=` cases and the exported-git-function case.
- `.agents/harness/selftest.sh` — the count line and the env scrub list.

## Traps

- `joharness.sh` is also in `ci-red-legible`'s scope: dispatch puts the two in separate waves; merge `origin/main` in before finish.
- Test for a fix must FAIL without it.
- Measured number names the command and when.
