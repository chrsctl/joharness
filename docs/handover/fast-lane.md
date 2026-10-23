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
next: Retire workstream and plan file, PR, finish, merge
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
- r18: (verifier) a retired claim counted only if fin_own_ws listed it (added in a non-merge commit, not inherited), while the tree reader took any changed fast file: an inherited-then-edited or merge-added claim bound until the retire commit and nothing after, so finish passed unbounded work (fixed: retired claims read under the tree rule, from history: the last version a branch commit carried, if it says fast, differs from the base and is no symlink; selftest cases for both)
- r19: (verifier) a symlink claim let a target outside the repo decide the lane (fixed: a symlink is never a claim, in the tree or in history; it counts as a path)
- r20: (verifier) a planned branch editing a stale fast file on main becomes fast-lane (no change in code: an edit that leaves it saying fast is a claim by the rule; plans README says delete a stale one, never edit it)
- r21: (verifier) sort -zu ran under the caller's locale, where collation may fold distinct paths (fixed: LC_ALL=C)
- r22: (verifier) the retired walk read quoted ls-tree lines, so a retired claim named with a quote, tab or backslash escaped the bound (fixed: one `git log -z` over docs/handover, paths compared raw; selftest case)
- r23: (verifier) basemap was read quoted, so deleting a stale non-ASCII fast file on main put a planned branch in the lane (fixed: base blob read by exact path, `rev-parse <base>:<path>`; selftest case)
- r24: (verifier) renaming the claim inside docs/handover/ read as two claims (fixed: a retired claim counts only when the tree holds none, and only the newest; selftest case)
- r25: (verifier) commits of a merged sub-branch counted, so merging a retired fast branch bound planned work (fixed: `--first-parent -m`, the branch's own line, whose merge commits still show their own adds; selftest case)
- r26: (verifier) one ls-tree fork per commit: 4.4s at 1501 commits, paid on every branch (fixed: one log, a rev-parse per candidate path only)
- r27: (verifier) "first entry = last version" held on linear history only (fixed: first-parent order is the branch's own line, newest first)
- r28: (verifier) the retired-symlink check had no test (fixed: mode read by exact path; selftest case retires a symlink whose target string carries plan: fast)
- r29: (verifier) a bare `-m` follows the caller's log.diffMerges: under `combined` or `remerge` a claim that arrived intact from a merged side branch and was retired here bound nothing (fixed: `-c log.diffMerges=first-parent` on the call; selftest case runs under `combined`)
- r30: (verifier) the base-blob comparison had no test (fixed: a stale fast file edited, reverted to base, then deleted on planned work; the mutant reds it)
- r31: (verifier) a claim added and retired wholly on a merged side branch binds nothing here (no change: by design, a merged branch's commits are not this branch's; that branch's own ci bound it, and dropping a claim is r7's accepted escape)
- r32: (verifier) git before 2.31 ignores log.diffMerges and gives per-parent diffs to `-m` (no change: unverified here, no old git in the container; reasoned verdicts unchanged, each path is judged at the merge commit's own blob)
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
A retired claim is judged by the same rule on its last version in history
(r18), never by a narrower one. Second churn (r18 to r22-r28): the walk is
the hazard, not the rule. Resolution: the tree decides when it holds a
claim; otherwise one `git log --first-parent -m -z` over docs/handover/
names the newest written file, judged by exact path. No ls-tree parsing, no
merged branch's commits, one claim at most.

## Blockers

None.

## Where to look

- `docs/plans/fast-lane.md` — the item.
- `joharness.sh:lint_fast_lane` — the bound; `lint_not_fast`, `review_tier`.
- `.agents/harness/selftest/fast-lane.sh` — the cases.
