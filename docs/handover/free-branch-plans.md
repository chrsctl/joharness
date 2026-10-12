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
next: Get ci and verify green (dispatch rescope cases, shellcheck), then verifier review at opus
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

## Blockers

None.

## Where to look

- `docs/plans/free-branch-plans.md` — the plan.
