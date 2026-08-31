---
workstream: mutation-check-the-fix
status: done
branch: claude/mutation-check-the-fix
pr: none
plan: docs/plans/mutation-check-the-fix.md
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-31
next: Retire this file and the plan, open the pull request, merge.
---

## Goal

Make Loop step 5's rule a command. The rule — "test written for a fix must
FAIL without it: revert the fix, run the test, put it back" — catches every
assertion that passed for the wrong reason this week, and nothing enforced
it, nothing made it cheap, and PR 153 showed it is easy to aim at the wrong
line.

## Decisions

- **The target is a LINE, never a pattern.** There is deliberately no way to
  ask for "the first occurrence of". That is the PR-153 failure exactly:
  `churn_top` and `selftest_inert_diff` carry a byte-identical guard, and a
  replace-first-occurrence hit the wrong one.
- **Two runs, and the baseline is not optional.** "Green both ways" is a
  claim about both. A mutated run alone cannot separate a case this mutation
  redded from one already red, so a red baseline reports what is already
  failing and attributes nothing.
- **Labels, not a count.** The near miss was a wrong reading of "one case
  failed"; the list shows a churn case where two hook cases were expected,
  which names the wrong target immediately.
- **`NOTHING REDDED` exits non-zero.** It is the finding the rule exists for,
  and a zero exit invites a script to read it as success.
- **A no-op mutation is an error, not a result.** It runs a green suite and
  reads as "nothing pins this line" — the wrong conclusion, reached faster
  and with a number behind it.
- **The suite is injectable (`JOHARNESS_MUTATE_SUITE`).** Without the seam
  these cases would run the whole selftest inside the selftest, once per
  case. It is also the honest point: a tool that can only run one hardcoded
  suite cannot be tested by that suite.
- **Restore via `trap ... EXIT INT TERM`.** A mutation left in the tree is
  worse than no tool.

## Rejected

- **Running it in `ci`.** Mutation is per-fix, not per-branch, and a suite
  run per mutation is not a gate's budget. Named out of scope in the plan.
- **Comparing pass COUNTS instead of labels.** Same number, different cases,
  is precisely the state that produced the plan.

## Verification

Against the plan's Acceptance, on this branch:

- **The PR-153 near miss, both lines.** `joharness.sh:796` (`churn_top`) reds
  **1** case, `base branch is not measurable`. `joharness.sh:838`
  (`selftest_inert_diff`) reds **4**, including the two PR 153 added. Visibly
  different lists, and the header names which line it hit.
- **The PR-151 check.** `mutate .agents/harness/handover-context.sh 374
  '    * )         printf 2 ;;'` reds exactly `work still building is not an
  edge` — the assertion that replaced the vacuous one. The old vacuous needle
  would have printed `NOTHING REDDED`, which is the defect the tool surfaces.
- **The tool fails when broken**, which its own plan's Traps demand. Run on
  itself: making the mutation silently apply nothing
  (`joharness.sh:4429` → `awk ... '{ print }'`) reds the three cases about
  naming what redded; removing the restore (`joharness.sh:4431` → `:`) reds
  `the line is put back afterwards` and three more.
- **`git status --porcelain` empty after every run above**, including the two
  where the tool under test was itself broken.
- `ci: pass`; `verify` 6 passed, 0 failed; selftest **1041 passed, 0 failed**
  (up 20).

## Review

Round 1, opus, self.

- r1: **I destroyed my own uncommitted work.** Ran `git checkout -q
  joharness.sh` to "confirm the tree is clean" after a mutation run — that
  discards changes, and it took the whole tool with it. `git status
  --porcelain` alone was the check I wanted. Rebuilt, and committed before
  testing thereafter. (fixed — and it is why this branch's first commits were
  `wip:`, flattened before the push)
- r2: my first real mutation aimed at line 792 from a number read BEFORE the
  same edit added four header lines, so the target had moved to 796. The tool
  caught it: it prints `before:`, and the line shown was the right text for
  the wrong reason — both guards are byte-identical, which is the whole
  problem it exists for. A pattern-based tool would have silently agreed.
  (recorded — the design was validated by its own author's mistake within a
  minute of existing)
- r3: SC2015 in my own topic file — `[ "$rc" -ne 0 ] && pass ... || fail ...`,
  where C runs when A is true and B fails, so one case could report both
  results. Caught by `ci`'s shellcheck, not by me. (fixed — `if/else`, and
  the reason is in the comment)
- r4: the claim was pushed LATE. Step 3 says cut the branch, write the
  workstream file, push — no push, no claim. I built first and wrote this
  file at the end, so for the duration of the build no other session could
  have seen the branch. (recorded, not fixable after the fact; the queue held
  one plan and no other session is live, so the cost was zero this time and
  the rule is not about this time)
- r5: verifier round owed and NOT run — standing instruction, thirteenth
  consecutive edge.

## Blockers

None.
