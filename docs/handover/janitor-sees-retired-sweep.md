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
next: ci + verify, retire plan and workstream file, PR, merge
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
- `cmd_drain` was deleted on main (orchestrated-only) before this merged, so
  the readers are `cmd_janitor` and `dispatch`, and the timing fallback is
  `time DISPATCH_FETCH=0 JOHARNESS_JANITOR_HOURS=1 ./joharness.sh dispatch`
  after merging main, 2026-10-10: origin/main's joharness.sh 5.953s/6.024s,
  this branch's 6.179s/5.843s — within noise.

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
- r3: (verifier) a non-sweep branch whose reconcile merge carries the base's
  delete of a real stamped file reads as a retired sweep (`-m` shows it on
  the merge, identity passes on `^1`). (fixed — a delete counts only if the
  file's ADD commit is also off the base; fixture `feat-reconciles`)
- r4: (verifier) a branch deleting a stamped leftover the base carries (what
  `cleanup --apply` tells a branch to do) reads as a retired sweep. (fixed —
  same add-off-base rule; fixture `tidy-leftovers`)
- r5: (verifier) any branch cut from a retired sweep is also named, via
  `for-each-ref --contains`. (wontfix — fails closed: it only delays a sweep
  while the real sweep's pull request is open, and telling a descendant from
  the sweep needs a per-ref ownership read the plan's perf rule argues against)
- r6: (verifier) a retire dated far in the future held the cycle for as long
  as the branch stands, against the plan's "no branch reads IN FLIGHT
  forever". (fixed — a retire more than one cycle ahead is ignored; within
  that it reads as now; fixture `janitor-future`)
- r7: (verifier) the tree walk prefilters `grep -i janitor`, the history log
  was case-sensitive, so `Janitor-<stamp>.md` vanished at its retire. (fixed —
  `:(icase)` pathspec; fixture `janitor-upper`)
- r8: (session) mutation for r3/r4/r6/r7, 2026-10-10: all three guards removed
  in one run of `bash .agents/harness/selftest.sh` gave 2458 passed, 4 failed,
  exactly the four new cases; restored, 2462 passed, 0 failed. (no change)

## Blockers

None.

## Where to look

- `joharness.sh:janitor_branches` — the function changed.
