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
next: ci and verify on this head, third verifier pass, then retire and PR
---

## Goal

A typo fix should not pay the full plan cost. Define a fast lane (`plan:
fast`) narrow enough that `ci` proves a branch qualifies; it skips the plan
file and keeps workstream file, verifier, ci, verify and finish.

## Decisions

- The proposed rule holds; it is ci-provable. Claim = a `docs/handover/`
  file saying `plan: fast` that this branch changed against the merge base
  with `origin/main` (tree, untracked included) or added and retired
  (`fast_lane_ws`; research section below). Exactly one. Then: at most 3
  other paths, none at or under a core path (`protocol_paths`), no
  `docs/plans/*.md` the base lacks. New ci stage `fast lane`, after
  `plans on this branch`; every breach named.
- Counted: `git diff -z --no-renames --name-only <base>` plus untracked,
  `sort -zu`, minus the one claim file, compared as exact strings. Deletes
  and both sides of a rename count.
- A node named `fast` (plan, research or requirement) is red in graph lint:
  a workstream claim resolves research/product stems too, so any of the
  three would turn the lane into a claim on it.
- Review: a claim file from `fast_lane_ws` = haiku, over its `agent:`. The
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
- r11: (verifier) a path holding a newline then the fast workstream path matched the exemption: grep -F reads each line as a pattern, so `.github/x<NL>docs/handover/typo.md` passed as 0 files (fixed: exact string compare per entry; claim paths holding a newline are never claims; selftest case)
- r12: (verifier) r4's fix bound every branch to a stale plan: fast file inherited unchanged from main: false red on planned work (fixed: a claim is a fast file this branch changed or retired, never one inherited untouched; review reads the same set; selftest case)
- r13: (verifier) any number of plan: fast workstream files were exempt (fixed: more than one is a breach; one lane, one file; selftest case)
- r14: (verifier) a path both deleted in the diff and untracked on disk (`git rm --cached`) counted twice (fixed: the path stream is `sort -zu`)
- r15: (verifier) the docs/plans/*/* arm had no test (fixed: a nested docs/plans/sub/x.md in the green state)
- r16: (verifier) control characters in a path printed raw, and the newline display was unverified on bash 3.2 (fixed: display passes the path through `tr` to `?`, no bash replacement-string quoting)
- r17: (verifier) r4's record said one reader used by both while review kept its own tree read, and Decisions still named plans_in_diff (fixed: review_report now takes the set from fast_lane_ws; Decisions rewritten)

## Research: claim set (review churn, r4 then r12)

Requirements the claim set must meet: (1) an uncommitted, merge-added or
inherited-then-edited fast file binds (r4); (2) a fast file inherited
UNCHANGED from main never binds anyone (r12); (3) a retired own file binds
(selftest); (4) review reads the same set (r17); (5) one claim, not N (r13).
Conflicting pair: (1) read as "every tree file" vs (2). Resolution: the
claim is a fast file THIS branch changed against the merge base (in the
path stream the bound already walks) or added and retired. Covers (1) and
(3), excludes (2) by construction; one function serves the stage and review.

## Blockers

None.

## Where to look

- `docs/plans/fast-lane.md` — the item.
- `joharness.sh:lint_fast_lane` — the bound; `lint_not_fast`, `review_tier`.
- `.agents/harness/selftest/fast-lane.sh` — the cases.
