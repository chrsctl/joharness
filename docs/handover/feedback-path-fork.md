---
workstream: feedback-path-fork
status: review
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-30
next: Open the pull request and merge it; the base branch is red until it lands.
---

## Goal

`origin/main` is red on the perf budget — `feedback` 268 against 265,
`review` 271 — and it crossed on the merge that added the 129th edge. Root
cause and fix, no plan, because the base branch is red now and every branch
cut from it inherits that.

## Decisions

- **No plan, and that is the carve-out being used.** The Loop's "NOTHING
  builds unplanned" has one exception this is not (copy or sync), so the
  honest statement is: this is a base-branch failure found by `ci` at the
  edge of another piece of work, root-caused, minimal, and its own pull
  request rather than folded into the research graduation it interrupted —
  `.agents/docs/research/README.md` forbids a research diff touching
  anything but itself and its graduation target.
- **`fb_current_path` forked per MISSING path, inside the loop over recorded
  pairs.** `git ls-files` + an `awk` + a `printf | grep -c`, once per path
  that no longer exists. A path goes missing exactly when the finish ritual
  retires a file, so the count grows by one group for every workstream file
  and plan this repo has ever completed: **86** such paths in the default
  window on 2026-08-30.
- **Third instance of this exact shape**, after `review_prior` and
  `fb_report_path` earlier this session — and the third time the perf budget
  named it rather than a reader. The budget is doing the job it was built
  for.
- **The number was not raised.** `feedback` 268 → **242**, `review` 271 →
  **245**, both under the 265 that was already there. One `git ls-files` for
  the whole run, cached, and the suffix match moved into `case` globs that
  fork nothing — the same literal, path-boundary semantics the awk had.
- **Output is byte-identical**, proved by `diff` against a worktree at the
  pre-fix commit: the full report, and per-path reports for five paths
  including one that no longer exists.

## Rejected

- **Raising the budget to match.** Its own breach message forbids exactly
  that, and the growth is unbounded — every future retirement adds another
  miss, so a raised ceiling would be breached again on a schedule.

## Review

Round 1, opus, self — the verifier round is owed and named in Blockers.

- r1: `fb_current_path` had no test at all, so the hoist could have changed
  its semantics silently. (fixed — two cases: a recorded path that gained a
  directory still resolves, and an ambiguous one is never guessed onto a
  sibling)
- r2: the ambiguity case as first written was green over nothing. It removed
  the recorded file and added an unrelated sibling, which produces ZERO
  suffix matches, not several — so the refusal branch was never reached.
  Caught by loosening `-eq 1` to `-ge 1` and watching it stay green. (fixed
  — the fixture now makes the recorded path match two files, and the
  loosening reds it)
- r3: the first "moved file" case asserted a repair the code does not do and
  must not: an arbitrary move (`old/x` to `new/x`) leaves the recorded path
  as no suffix of the new one. Only the prefixed-directory case is repaired.
  (fixed — the case is the one that exists, and reverting the suffix match
  reds it)

## Blockers

None, but a verifier round on this diff is owed before merge.

## Where to look

- `joharness.sh:fb_current_path` — the hoist.
- `joharness.sh:perf_rows` — the budget that caught it; unchanged.
