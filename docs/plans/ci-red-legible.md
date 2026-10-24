---
plan: ci-red-legible
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
issue: none
scope: joharness.sh, .agents/harness/selftest/ci-output.sh
---

## Goal

Two ways a red `ci` was misread in one session (branch
manage/dispatch-held-merged-pr, 2026-10-24). First, the verdict
`ci: FAIL (1)` counts stages and names none. The selftest stage held a
failing case AND an over-budget count; the reader saw the budget lines, read
it as the only red, and reported that. Second, `joharness.sh` was edited
while a `ci; verify` run was in flight, and the run died with
`./joharness.sh: line 8383: syntax error near unexpected token ')'`. That error
said nothing true about the code. Make the verdict name what failed, and make
a run immune to edits of its own script.

## Scope

- `joharness.sh:run_check` — record each failing stage's name.
- `joharness.sh:cmd_ci` — verdict `ci: FAIL (<n>: <stage>, <stage>)`, e.g.
  `ci: FAIL (1: harness selftest)`.
- `joharness.sh:selftest_counted` — when the stage is red, its last line
  says which of the two reds hold: `selftest: <F> case(s) failed` and/or
  `selftest: git execs over budget`.
- `joharness.sh` last line — `main "$@"` becomes `main "$@"; exit $?` on ONE
  line. bash reads a script as it runs: after `main` returns it reads on
  from its old byte offset, and an edit that moved the bytes lands it mid-`case`.
  A line is parsed whole before it runs, so the `exit` is read before
  `main` starts.
- `.agents/harness/selftest/ci-output.sh` — the verdict case
  (`expect … "ci: FAIL (1)"`) expects the stage name; one new case: a
  `joharness.sh` whose tail is rewritten while `main` runs (a fixture
  subcommand that sleeps, or a stub sourced the same way) exits with
  `main`'s status and prints no `syntax error`.

## Assumptions

- A1: nothing parses `ci: FAIL (` beyond ci-output.sh — evidence: `grep -rn "ci: FAIL (" --exclude-dir=.git .` — confidence: high
- A2: the line-8383 error came from the `ci` process reading on after `main` returned, not from `verify` — evidence: `./joharness.sh` ends `main "$@"` with nothing after it; reproduce with the new case before the fix — confidence: medium

## Out of scope

- The selftest's own `FAIL lines by topic:` block (it already exists).
- `finish`'s verdict wording.
- Locking the tree or refusing edits during a run.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- The new edit-during-run case fails (prints `syntax error`) with the last-line change reverted.
- The verdict case fails with the `cmd_ci` change reverted.
- `./joharness.sh verify` — `0 failed`.

## Where to look

- `joharness.sh:run_check` — `CHECK_FAILS` counting.
- `joharness.sh:cmd_ci` — the `ci: FAIL (%s)` printf.
- `joharness.sh:selftest_counted` — the budget lines.
- `joharness.sh:main` — the dispatch `case` and the bare `main "$@"` after it.
- `.agents/harness/selftest/ci-output.sh` — `and the verdict counts the failures`.

## Traps

- `joharness.sh` is also in `selftest-git-budget-per-case`'s scope; both edit `selftest_counted`. Whichever lands second merges `origin/main` in and keeps both.
- Test for a fix must FAIL without it.
- Never `pgrep -f`/`pkill -f` a pattern your own command line carries.
