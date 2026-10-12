---
workstream: free-branch-plans
status: in-progress
branch: claude/free-branch-plans
pr: none
plan: free-branch-plans
issue: 423
session: https://claude.ai/code/session_01Nm4goRUANzvNDQdDAJ5Ubr
agent: opus
updated: 2026-10-12
next: ci + verify green on the round-2 fixes, then retire and open the pull request
---

## Goal

Issue #423 piece A + closer half of D: give a plan filed on an abandoned
branch, and an empty done branch, a mechanical path to main via
`joharness.sh free <branch>`, run by a manager; dispatch prints FREEABLE.

## Decisions

- `free` merges with `--no-commit`, commits once after curate, then runs
  `ci` on the commit; red = `reset --hard` to the pre-merge head. ci needs a
  committed HEAD to diff against origin/main, so "nothing committed" means
  the end state, not every instant.
- A free manager claims as `workstream: free-<key>`, `plan: none`, key =
  `free_key <branch>` (non `[A-Za-z0-9._-]` -> `-`), read by
  `dispatch_rescope_branches free-` (prefix now a parameter). Dispatch lists
  it under managers in flight and counts its slot; a key it covers is never
  FREEABLE again; a branch carrying a `free-*` claim is never FREEABLE.
- `free` also drops `leftover` stems (base added and retired them), not only
  DONE ON MAIN: either re-adds a retired plan.
- `curate --apply` touches the whole queue; `free` restores every file it
  changed that is not a plan the owner added, so a free touches only the
  plans it brings in.
- `dispatch_branch_plans <branch>`: one branch, its own claimed plan and an
  abandoned branch's plans included, so `free` reads DONE on any owner.
- Dispatch still hides a janitor-released (`status: abandoned`) branch's
  plans, as #297 chose, so such a branch is never FREEABLE; `free` works on
  it when a human orders it. Gap noted in the PR body.
- The empty-done kind needs a real `plan:` in the workstream file: a
  `plan: none` done record is a role's (a surveyor's "holds genuine" stays
  unmerged by design, and dispatch reads it there).

## Rejected

- Empty-done FREEABLE on any `status: done, pr: none` file: freed the
  surveyor's settle record and broke 4 rescope cases in selftest/dispatch.sh.

## Review

- r1: (verifier) freeing an empty done branch whose record names a plan the base carries deleted the record only: the finished plan went back to the spawn list. (fixed — `free` step 2 also retires the `docs/plans` or `docs/research` file a dropped `status: done` record names; selftest/free.sh carry-fin case)
- r2: (verifier) a plan branch whose workstream file is `blocked` (or `review`, or names a `pr:`) was FREEABLE and `free` deleted the human's question. (fixed — `free_owner_held`, read by both `dispatch_freeable` and `free`; cases in free.sh and dispatch.sh)
- r3: (verifier) once the free manager's retire commit deleted its claim, the owner was offered again while the pull request was open. (fixed — an owner whose tip sits in another live unmerged branch, or a branch carrying a `free: merge` commit, is never FREEABLE; dispatch.sh case)
- r4: (verifier) a janitor-released (`abandoned`) free claim hid its owner for good. (fixed — an abandoned free claim neither covers a key nor holds the owner; dispatch.sh gone-w case)
- r5: (verifier) `free` committed onto the base branch, and ran with no claim. (fixed — refuses `cur` = base and a branch lacking `docs/handover/free-<key>.md`; free.sh cases)
- r6: (verifier) the selftest "counts as a free item" held with the count code removed. (fixed — pins the verdict's count at one more than before the stale branch)
- r7: (verifier) an untracked file in the merge's way read as a conflict and pointed the manager at a `conflict:` block. (fixed — the clean-tree refusal reads `git status --porcelain`, untracked included; free.sh case)
- r8: (verifier) owners `a/b` and `a-b` share key `a-b`: one claim hides both rows while it stands. (wontfix: two such branches both doc-only and stale at once is far-fetched; the cost is one pass's delay, and r3's containment check frees the other once the claim's merge lands)
- r10: (verifier, round 2) a refused free ended `status: done` per manage.md, an unclosable done record dispatch calls edge work, and its key hid the owner for the stale window. (fixed — a refusal for the owner's state deletes the claim, one for the manager's own state is fixed and rerun; a `done` free claim holds no key; dispatch.sh gone-d case)
- r11: (verifier, round 2) `free` step 2 retired a plan a live builder claim held. (fixed — `free_plan_claimed` keeps it; free.sh build-b case)
- r12: (verifier, round 2) the ancestry containment hid an owner forever behind a same-commit copy or a branch cut from it, and cost one merge-base per ref pair. (fixed — an owner is held only by a `free: merge <owner>` merge commit on a live, unreleased branch, read once per ref; dispatch.sh prod-w case)
- r13: (verifier, round 2) the `free: merge` self-exclusion had no failing test: the manager's branch was too young to be offered anyway. (fixed — the fixture's merge and retire commits are dated past the stale window)
- r14: (verifier, round 2) a retired plan's recover line read the owner's tip, an older version than the one deleted. (fixed — retired paths recover from the pre-free head, which the push publishes)
- r15: (verifier, round 2) any `pr:` on the owner's workstream file holds it, so a gone author's open plan-only pull request is never FREEABLE; a stem in both docs/plans and docs/research deleted both. (fixed for the second — first match only; the first: wontfix, an open pull request is the human's to close or merge, and orchestrated.md's row names it)
- r9: (verifier) the author's "610 passed" came from a scratch runner with a topic filter (`ONLY_TOPICS` copy of selftest.sh in the scratchpad), not a repo command. (no change — measured numbers in the PR body come from `bash .agents/harness/selftest.sh`)

## Blockers

None.

## Where to look

- `docs/plans/free-branch-plans.md` — the plan.
