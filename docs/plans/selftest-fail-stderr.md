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
GitHub `lint` job (whole `dispatch-park` topic red at once, 52 or 140 FAILs),
green locally and green on re-run. A red run says only `FAIL <label>`, never
why. Make a red run print the first failing command's stderr and the fixture's
git state, so the next flake is diagnosable; then fix the fixture if that
evidence (or the code read below) names a cause.

## Scope

- `.agents/harness/selftest/dispatch-park.sh` — the fixture build (`git init`,
  `symbolic-ref`, `dfcommit`) must fail loudly: check each setup step, and on
  a failed step print its stderr plus `git --version`.
- `.agents/harness/selftest.sh` — `fail()` prints the captured stderr of the
  last fixture command (bounded to 20 lines) when one was recorded.

## Assumptions

- A1: the flake is real — evidence: run 42783980756 on PR #738 has
  `run_attempt: 2`, `conclusion: success`; the issue reports attempt 1 red
  with 52 FAILs under `dispatch-park`; attempt 1's logs are not readable
  here, so the FAIL counts are unchecked — confidence: medium
- A2: the cause is a fixture setup step failing on the runner (git 2.56.0
  there, 2.43.0 here) — evidence: issue's reading only; not reproduced —
  confidence: low. Research it first: diff `dispatch-park.sh` fixture
  commands against behaviours that changed between those git versions.
- A3: `fail()` is defined at `.agents/harness/selftest.sh:fail` and topics are
  sourced, so a change there reaches every topic — confidence: high

## Out of scope

- Other topics' fixtures: fix only what evidence from this topic names.
- Retrying failed topics in CI: that would hide the flake (never kick CI).
- Editing `.github` (core path).

## Acceptance

- Selftest case: with a fixture command forced to fail (e.g. `git` shimmed to
  exit 1 with stderr `boom`), the run prints `boom` next to the FAIL line.
  The case must FAIL without the change.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Plan's `## Review` records, for A2, what was found: a named cause fixed in
  this PR, or `no cause found, diagnostics only`. In the latter case the PR
  body says `Refs #729`, not `Closes`.

## Escape

Entry, Gate and Route are answered in the PR body, each with its command:
Entry — bisect or say why not (first red `main` run 42730168302, merge of
#724); Gate — `ci` selftest should have caught a setup failure but only
counts asserts; Route — this repo owns the gate, fixed here.

## Where to look

- `.agents/harness/selftest.sh:fail` — the failure printer.
- `.agents/harness/selftest/dispatch-park.sh:dfcommit` — fixture commit helper.
- `.agents/harness/selftest.sh:SELFTEST_FIRST` — dispatch-park starts first on
  a worker; check whether start-time contention matters.

## Traps

- NEVER skip, disable or quarantine a test to get green.
- A number you did not count this run is a written number; cite commands.
- Diagnostics must not change PASS/FAIL counts or the per-case git-exec
  budget (`JOHARNESS_SELFTEST_GIT_PER_CASE`).
