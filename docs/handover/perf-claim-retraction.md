---
workstream: perf-claim-retraction
status: done
branch: claude/perf-base-branch-unmeasured-fix
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-30
next: Retire this file, open the pull request, merge.
---

## Goal

Retract two false claims I put on `main` in PR 149 and PR 150, and pin the
behaviour so they cannot come back. Started as "implement
`perf-base-branch-unmeasured`"; testing the plan's premise before building
on it is what ended it.

## What was claimed, and what is true

- **"On `main`, HEAD is origin/main, so `selftest_inert_diff` is true and
  `ci` skips the perf section."** FALSE. `selftest_inert_diff` returns 1 when
  the merge base EQUALS the rev — that is the first thing it checks — which
  is exactly the case on `main`. The skip never fires there. Checked by
  running `./joharness.sh ci` in a worktree standing on `main`: the perf
  table prints.
- **"PR 146's own merge commit counts `feedback` 270 against the 267 it set,
  unseen."** FALSE. It counts **255, ok**. The 270 came from a detached
  worktree, which SHARES the repository's refs — so the walk read an
  `origin/main` that had moved on two merges. With the ref pinned where it
  stood at that merge, in a clone rather than a worktree, it is 255. The
  runner agrees: the `lint` job for `bfedce8` (which runs `./joharness.sh
  ci`, `fetch-depth: 0`) concluded SUCCESS.

Both were written from reading rather than running, and both read plausibly
enough to survive a review round, a merge, and a plan built on them.

## Decisions

- **The plan is retired, not implemented.** Its Goal was the first claim.
  With `main` measured on every push, a post-merge regression is caught by
  `main`'s own run — which is a design, not a gap.
- **The methodological finding is what survives, and it goes in the perf
  block.** `git worktree add --detach <sha>` measures that commit's CODE
  against TODAY's history. Right for comparing code, which is what the bands
  in that file are for; wrong for "what did CI see", which is what I used it
  for. The isolated-clone recipe is recorded beside it.
- **Two cases, on the base branch.** The suite had nothing that contradicted
  either claim, which is why they survived.

## Rejected

- **Quietly deleting the plan.** The wrong mechanism is on `main` in a code
  comment; a reader who finds it needs the correction next to it, not a gap
  where it used to be. Same treatment the FB_LIMIT paragraph got — corrected
  in place, third time in this file's history.
- **Re-sampling the band now.** The samples above it were taken by the
  worktree method, so they answer "code, against the history of the day they
  were taken". Re-sampling correctly is real work and would land a new band
  next to an old one measured differently. The ceiling stays 267/275, loose
  on purpose, and the file now says which question a row has to answer.

## Review

Round 1, opus, self.

- r1: the first mutation test hit the WRONG FUNCTION. `churn_top` and
  `selftest_inert_diff` carry a byte-identical guard line, and a
  replace-first-occurrence patched `churn_top` at line 792 while the target
  was at 834. The suite redded one unrelated churn case, my two cases stayed
  green, and I read that as "my cases are vacuous". They are not. (fixed —
  mutated by line number; both cases red, along with two existing
  `selftest_inert_diff` cases, and only those four)
- r2: I nearly filed that misreading as a second instance of the
  vacuous-assertion class, which would have put a false example into the
  plan filed for it one merge earlier. A test that fails to red is a
  hypothesis about the test AND about the mutation; I checked only the first.
  (recorded — the mutation is the other half of the experiment and gets
  verified too)
- r3: the retraction states two claims as false without saying they were
  reviewed and merged anyway. A correction that hides how far the error
  travelled teaches nothing. (fixed — the comment names PR 149 and PR 150,
  and that this is the third wrong perf mechanism in that file)
- r4: verifier round owed and NOT run — standing instruction, same as the
  last several edges.

## Blockers

None.

## Where to look

- `joharness.sh`, the perf block — the retraction and the clone recipe.
- `joharness.sh:selftest_inert_diff` — line 3 is the guard that makes the
  first claim false.
- `.agents/harness/selftest/perf.sh` — the two base-branch cases.
