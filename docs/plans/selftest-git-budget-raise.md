---
plan: selftest-git-budget-raise
urgency: urgent
agent: sonnet
effort: medium
needs: none
requirement: none
issue: 603
scope: shared:joharness.sh
---

## Goal

`./joharness.sh ci` reds on `origin/main` (202a48ca): `selftest git execs:
89189 (budget 88960)`. The budget is a count plus a tenth from 2026-10-14 and
the suite has outgrown it (issue #603), so every manager's `ci` is red.
Find what grew, fix a topic that re-runs work if one does; else set the
default to the measured count plus a tenth.

## Scope

- `joharness.sh` — the `JOHARNESS_SELFTEST_GIT_BUDGET` default (knob table
  row and every other place the number is spelled) and the comment above
  `selftest_counted` that dates the count.

## Assumptions

- A1: the budget default is spelled at the knob row only — evidence: `grep -rn 88960 . --exclude-dir=.git` — confidence: medium
- A2: the red reproduces on a clean `origin/main` — evidence: `JOHARNESS_CHECKS=local ./joharness.sh ci -v` prints `selftest git execs: N (budget 88960)` with N over it — confidence: medium (the clerk's own run did not finish inside its time bound)

## Out of scope

- Changing how `selftest_counted` counts, or dropping the budget check.
- Trimming selftest topics beyond one that plainly re-runs identical work.

## Escape

Answered in the pull request body: Entry (which merge pushed the count over:
bisect `ci -v` counts across recent merges, or say why not), Gate (the budget
is the gate and it fired; why did the merge that crossed it pass `ci`?),
Route (the budget is this repo's gate: fixed here).

## Acceptance

- `./joharness.sh ci -v` — prints `selftest git execs: N (budget B)` with N <= B, and `ci: pass`.
- B is the measured N plus a tenth, and the comment above `selftest_counted` names the measuring command and date.
- `./joharness.sh verify` — `0 failed`.

## Where to look

- `joharness.sh:selftest_counted` — the count and the comparison.
- `joharness.sh` knob table row `JOHARNESS_SELFTEST_GIT_BUDGET`.

## Traps

- Measured number names the command and when; never a written one.
- NEVER skip, disable or quarantine a test to get green.
- Test for a fix must FAIL without it: the over-budget `ci` run is the test.
