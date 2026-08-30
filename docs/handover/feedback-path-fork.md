---
workstream: feedback-path-fork
status: done
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-30
next: Retire this file, open the pull request, merge.
---

## Goal

`fb_current_path` forked `git ls-files`, an `awk` and a `printf | grep -c`
for every recorded path that no longer exists, inside the loop over recorded
pairs. A path goes missing exactly when the finish ritual retires a file, so
the fork count grows by one group for every workstream file and plan this
repo has ever completed. Unbounded, and the fix is to cut the cost rather
than raise the ceiling.

Picked up from an IDLE session (`session_01SHPKsgu5WMHQ4g7MhTwRhm`,
disconnected, last turn 21h before this one) under step 2: finishing
outranks starting, and a session that is not `RUNNING` is not holding its
branch.

## Decisions

- **No plan, and that is the carve-out being used.** Base-branch cost found
  by `ci` at the edge of other work, root-caused, minimal, its own pull
  request.
- **The original framing is dead and stayed dead.** It said `main` was RED —
  `feedback` 268 against a 265 ceiling. Neither number survives: PR 146 moved
  the ceilings to 267/275 while this branch sat 46 commits behind, and
  `main` at `f2e82af` counts 255/258, green. The fix stands on its own —
  it removes an unbounded cost — but not on the urgency it was written with.
- **`case` globs instead of the awk.** Same literal, path-boundary semantics:
  a path carrying `+`, `(` or `{` matches itself and not its siblings.
- **`FB_CUR`, because the cache did not survive the caller.** The hot call
  site was `$(fb_current_path ...)`, and a command substitution is a
  subshell — `FB_LS_READ=1` died in it every time, so `git ls-files` forked
  once per miss anyway. Measured 18 forks under a comment claiming one. The
  function now assigns the answer to a global and the loop calls it plainly.
- **Numbers, re-counted on the merge base this actually lands on**
  (`./joharness.sh perf`, `f2e82af`, 2026-08-30): `feedback` 255 -> 202,
  `review` 258 -> 208. Wall clock moves far less — `feedback` 3.44/3.64/3.47s
  before against 3.42/3.39/3.35s after — because the merged-history walk
  dominates and the forks were never the wall-clock cost.
- **The ceiling was not lowered onto 202.** One post-fix sample cannot size a
  band, which is the rule the perf block already states and the mistake that
  made it flap twice.
- **Output is byte-identical**, checked against a worktree at the pre-fix
  commit: the full report, plus per-path reports for five paths.

## Rejected

- **Raising the budget to match.** Its own breach message forbids it, and the
  growth is unbounded — a raised ceiling would be breached again on a
  schedule.
- **Reading `git ls-files` unconditionally at the top of `fb_walk`.** One
  fork always, including for the run with nothing missing. `FB_CUR` keeps
  the laziness and costs the same one fork when it is needed.

## Review

Round 1, opus, self — the inherited session's own round, kept verbatim.

- r1: `fb_current_path` had no test at all, so the hoist could have changed
  its semantics silently. (fixed — two cases)
- r2: the ambiguity case as first written was green over nothing: it produced
  ZERO suffix matches, not several, so the refusal branch was never reached.
  (fixed — the fixture now makes the recorded path match two files)
- r3: the first "moved file" case asserted a repair the code does not do and
  must not. (fixed — the case is the prefixed-directory one that exists)

Round 2, opus, this session, on the reconciled diff.

- r4: the branch's premise was stale — `main` is not red, and the 265 ceiling
  it names has not existed since PR 146. A fix whose stated reason is false
  gets merged on a reason nobody can check. (fixed — re-measured against
  `f2e82af`; the goal is now the unbounded cost, not an outage)
- r5: **the cache never worked.** `$(fb_current_path ...)` runs in a subshell,
  so the global it sets is discarded before the next call. 18 `git ls-files`
  forks measured, under a comment asserting one. (fixed — `FB_CUR`; 18 -> 1,
  and `feedback` 219 -> 202 on top of what the branch had already saved)
- r6: nothing could have caught r5. The perf shim logs the binary name, not
  its argv, so 18 `git ls-files` and 1 are both just "git". (fixed — a case
  shims `git`, counts `ls-files`, and asserts 1; it goes red at 8 when the
  substitution is put back, checked by putting it back)
- r7: that case would be free if the fixture retired only one file. (fixed —
  it asserts the carrying-edge count is above 1, and prints it: 8)
- r8: the hoist trades forks for bash-loop iterations, ~103 tracked files per
  miss, and the counted budget cannot see the cost it moved. (recorded, no
  change — timed three runs each way, no wall-clock regression; the counted
  saving is 53 commands and the wall-clock saving is ~4%, and the second
  number is the one a reader would otherwise infer from the first)
- r9: "86 such paths in the default window" does not reproduce — 18, both
  windows, counted with a shim. (fixed — the comment now carries the number
  and the command that produced it)
- r10: PR 146's own merge commit breaches the ceiling that PR set —
  `feedback` 270 against 267 at `bfedce8` — and no run looks, because on
  `main` HEAD is `origin/main`, `selftest_inert_diff` is true, and `ci` skips
  the perf section entirely. A branch is also measured before its own merge
  enters the pinned 20-edge window, so green-before and red-after is
  structural. (recorded in the perf block, NOT fixed here — it is a plan,
  not this diff)
- r11: verifier round owed and NOT run. This session is under a standing
  instruction not to spawn subagents unless asked, so the one reader that did
  not write the diff is missing. Same gap recorded on the last several edges;
  the diff has had two adversarial rounds from the author instead.

## Blockers

None.

## Where to look

- `joharness.sh:fb_current_path` — the hoist, `FB_CUR`, and the re-counted
  numbers.
- `joharness.sh` perf block — the three-merge resample and r10.
- `.agents/harness/selftest/feedback.sh` — the fork-count case.
