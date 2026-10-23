---
workstream: fast-lane
status: in-progress
branch: claude/fast-lane
pr: none
plan: fast-lane
issue: none
session: https://claude.ai/code/session_01PoyAytHA6a4PwcFm6XW6qK
agent: opus
updated: 2026-10-23
next: Re-run ci and verify on the fixes, second verifier pass, then retire and PR
---

## Goal

A typo fix should not pay the full plan cost. Define a fast lane (`plan:
fast`) narrow enough that `ci` proves a branch qualifies; it skips the plan
file and keeps workstream file, verifier, ci, verify and finish.

## Decisions

- The proposed rule holds; it is ci-provable. A branch is fast-lane when a
  workstream file in the tree says `plan: fast` (the set `review` reads),
  or one it added and retired does (`fast_lane_ws`). Then, against the merge base with
  `origin/main`: at most 3 paths changed, none at or under a core path
  (`protocol_paths`), no plan added (`plans_in_diff`). New ci stage
  `fast lane`, after `plans on this branch`; every breach named.
- Counted: `git diff -z --no-renames --name-only <base>` plus untracked,
  minus the fast workstream files only. The workstream file is the lane's own cost and is gone
  by merge; deletes and both sides of a rename count as touched.
- A node named `fast` (plan, research or requirement) is red in graph lint:
  a workstream claim resolves research/product stems too, so any of the
  three would turn the lane into a claim on it.
- `review_tier`: `plan: fast` = haiku, over the workstream's `agent:`. The
  bound is what makes one pass enough; a fixed depth is what ci can print.
  The recipe is a floor, never a cap on a deeper pass.
- dispatch, the hook, `free`: no code change; janitor says a fast claim
  holds no item. A scratch clone with
  a pushed `plan: fast` branch showed dispatch prints no row for it and the
  hook prints it like any claim: a stem with no file is no queue item. The
  selftest pins dispatch's silence. Graph lint was the one reader treating
  it as a missing stem (DEAD ... never existed): fixed there.

## Rejected

- Counting the workstream file toward 3: every fast branch would start at
  1 of 3, and the file is deleted before merge anyway.

## Review

- r1: (verifier) a quoted path (`.github/a"b.yml`, tab, newline) slipped the core-path match: git quotes it even with quotePath off (fixed: lint_fast_lane reads `-z` output; selftest case)
- r2: (verifier) a non-ASCII plan name slipped "no plan added": plans_in_diff reads quoted names (fixed: the stage finds added plans in its own `-z` walk, a docs/plans/*.md the base lacks; selftest case)
- r3: (verifier) every path under docs/handover/ went uncounted, not only the branch's own workstream file (fixed: only the fast workstream files themselves are exempt; selftest case)
- r4: (verifier) the stage read committed, non-merge, non-inherited workstream files while review read the tree: an edited inherited file, one added in a merge, or an uncommitted one got haiku depth and no bound (fixed: one reader, fast_lane_ws, used by both; tree first, then the branch's retired files; selftest cases)
- r5: (verifier) FAST_LANE_FILES lives in joharness.sh, which a fast branch may edit (wontfix: true of every ci rule; that edit is itself one of the 3 files and the diff the reviewer reads, and the core paths are where an unforgeable bound would live, a human's call)
- r6: (verifier) janitor called a stale `plan: fast` claim a typo naming docs/plans/fast.md (fixed: janitor says it holds no item, the fast lane)
- r7: (verifier) a branch can drop out by rewriting `plan: fast` to another value (no change in code: an older gap, `plan: none` was never bound; docs now say ci proves a branch that declares the lane qualifies, not that every unplanned branch does)
- r8: (verifier) a stale origin/main makes main's files count (no change: finish refuses a head behind a fresh fetch, so the false red cannot reach a merge)
- r9: (verifier) a consumer carrying a node named fast reds at its next sync, undocumented (fixed: plans README says rename it)
- r10: (verifier) deleted, renamed and untracked paths, and fast-named research and requirement nodes, had no test: mutants survived (fixed: selftest cases for each)

## Blockers

None.

## Where to look

- `docs/plans/fast-lane.md` — the item.
- `joharness.sh:lint_fast_lane` — the bound; `lint_not_fast`, `review_tier`.
- `.agents/harness/selftest/fast-lane.sh` — the cases.
