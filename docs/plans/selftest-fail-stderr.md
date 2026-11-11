---
plan: selftest-fail-stderr
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
serves: all
issue: 729
scope: .agents/harness/selftest.sh, .agents/harness/selftest/dispatch-park.sh
---

## Goal

Issue #729: `./joharness.sh ci` "harness selftest" fails intermittently on the
GitHub `lint` job (whole `dispatch-park` topic red at once), green locally and
on re-run. Setup stderr and each case's `wanted:`/`got:` already reach the CI
log (topics run with `2>&1`, `selftest.sh:selftest_unit`); only the "FAIL lines
by topic" summary is bare. The gap is that nobody has read what the log shows
ABOVE the first FAIL. Find that, then fix the fixture if it names a cause.

## Scope

- `.agents/harness/selftest/dispatch-park.sh` — check each setup step
  (`git init`, `symbolic-ref`, `dfcommit`) and on failure print the step name,
  its stderr and `git --version`, then skip the topic's cases as ONE counted
  FAIL instead of ~50.
- `.agents/harness/selftest.sh` — only if the evidence needs it.
- A new case in `.agents/harness/selftest/dispatch-park.sh` itself (no new
  topic file, so no `SELFTEST_TOPICS` edit): run the setup helper with `git`
  shadowed by a shell function that prints `boom` and returns 1, in a subshell
  with its own counters; assert `boom` and the step name appear.

## Assumptions

- A1: the flake is real — evidence: run 42783980756 on PR #738 has
  `run_attempt: 2`, `conclusion: success`; attempt 1's logs and the 52 FAIL
  count are unchecked from here — confidence: medium
- A2: a fixture setup step fails on the runner (git 2.56.0 there, 2.43.0
  here) — evidence: the issue's reading only — confidence: low. First action:
  read attempt 1's job log (`get_job_logs`, or `gh run view --log` for run
  42783980756) above the first FAIL. Log gone = say so.
- A3: #724's merge changed only docs (`git diff --stat 43b8bd22^1 43b8bd22`),
  so run 42730168302 is a flake, not a regression — confidence: high

## Out of scope

- Other topics' fixtures: fix only what evidence names.
- Retrying failed topics in CI (hides the flake).
- Editing `.github` (core path).

## Acceptance

- `./joharness.sh ci 2>&1 | grep -c "setup step failed"` — `0` on a healthy
  tree; the new case's own PASS lines show the forced failure prints `boom`.
  The case must FAIL without the change.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- PR body states A2's outcome: cause found and fixed (`Closes #729`) or
  `no cause found, diagnostics only` (`Refs #729`).

## Escape

Answered in the PR body: Entry — #724 is docs-only (A3), so a flake, not a
merge; Gate — selftest asserts cases but not that fixture setup succeeded;
Route — this repo owns the gate, fixed here.

## Where to look

- `.agents/harness/selftest.sh:selftest_unit` — where topic output is captured with `2>&1`.
- `.agents/harness/selftest.sh:fail()` — the failure printer.
- `.agents/harness/selftest/dispatch-park.sh:dfcommit` — fixture commit helper.
- `.agents/harness/selftest.sh:SELFTEST_FIRST` — dispatch-park starts first on
  a worker; check whether start-time contention matters.

## Traps

- NEVER skip, disable or quarantine a test to get green.
- A number you did not count this run is a written number; cite commands.
- Diagnostics must not change PASS/FAIL counts or the per-case git-exec
  budget (`JOHARNESS_SELFTEST_GIT_PER_CASE`).
