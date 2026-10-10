---
workstream: janitor-sees-retired-sweep
status: in-progress
branch: janitor-sees-retired-sweep
pr: none
plan: janitor-sees-retired-sweep
issue: 292
session: https://claude.ai/code/session_0139meDaJSq7MhLGgdeuTT4r
agent: opus
updated: 2026-10-10
next: Run selftest, mutation-check the fixtures, ci + verify, verifier review
---

## Goal

Issue #292: after a janitor sweep's retire commit and before its PR merges,
`./joharness.sh janitor` reads DUE with nothing in flight. Make
`janitor_branches` see retired sweeps via commit history.

## Decisions

- New helper `janitor_retired_branches`, called at the end of
  `janitor_branches`, so all three readers (`cmd_janitor`, `drain`,
  `dispatch`) get the rows with no reader change: each counts any row as in
  flight and prints fields 1-2 (`cmd_janitor` also 3, which reads `retired`).
- Identity read at the delete's PARENT (`^1`, then `^2`): `-m` prints a merge
  once per parent and `%H` does not say which.
- Error branch fails closed like `scout_retired_ts`: a row
  `unreadable  git-log-failed  retired`, so a broken log never reads DUE.
- Fixture dates relative to now via `@<epoch> +0000` (the `blkat` shape in
  `selftest/dispatch.sh`), portable where `date -d` is not.
- Perf, this checkout (191 origin refs), 2026-10-10:
  `time JOHARNESS_JANITOR_HOURS=1 DISPATCH_FETCH=0 ./joharness.sh janitor`
  8.161s before, 8.187s after. `time ./joharness.sh drain` 2.829s/2.871s
  before (janitor not due under conf; no walk either way).

## Rejected

## Review

- r1: (session) the first fixture's `cadence   : IN FLIGHT` expect pinned
  nothing: with `janitor_retired_branches` call replaced by `:`, `bash
  .agents/harness/selftest.sh` 2026-10-10 gave 2454 passed, 4 failed — the
  three row assertions red, the cadence word green (earlier sweeps in the
  topic hold the cycle). (fixed — the case asserts the row only)
- r2: (session) dropping `--full-history` alone reds nothing (2458 passed, 0
  failed, same date): git 2.43 `-m` already disables simplification on the
  reconciled shape (scratch repo: `git log -m b --not main -- path` prints the
  retire, `git log b --not main -- path` prints nothing). Dropping both at
  line 5332 reds exactly the reconciled case (2457 passed, 1 failed). (no
  change — `--full-history` kept as the plan specifies, for gits where `-m`
  does not imply it; fixture comment says it pins the pair)

## Blockers

None.

## Where to look

- `joharness.sh:janitor_branches` — the function changed.
