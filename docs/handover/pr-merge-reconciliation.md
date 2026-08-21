---
workstream: pr-merge-reconciliation
status: in-progress
branch: claude/pr-merge-reconciliation-conflicts-q0kog4
pr: none
plan: none
session: https://claude.ai/code/session_012i58uFXJsp2qJQznVEY25W
agent: sonnet
updated: 2026-08-21
next: Commit, push
---

## Goal

Parallel sessions cut branches from `main` and finish by merging back (Loop
step 7). Nothing said what a session does when another PR merges first and
its own branch now conflicts with `main` — at finish, or mid-build for a
long-running session. Add the rule: fetch main and check ahead/behind (do
not trust the stale session-start view), reconcile (merge main in, resolve)
before merging; unresolvable conflict stops the session, never forces a
merge through.

## Decisions

- Put rule in `docs/product/README.md` Branch flow, beside the existing
  merge-commits-never-rebase bullet — same section already owns finish-time
  mechanics.
- Reused word "reconciliation" would collide with the existing section of
  that name (consumer-repo harness sync) — named the new bullet
  "Conflict at finish" instead.
- Added "merge conflict into `main` that does not resolve clean" to
  `harness/AGENTS.md` Decide-alone's stop-and-ask list. First draft said
  STOP + ask human without touching that list — `/code-review` (high)
  caught the contradiction: Decide-alone's list is stated as exhaustive
  ("ONLY"), so the new instruction silently lost to it for a literal
  reader. Fixed by adding the case there instead of leaving it implicit.
- Added a pointer at Loop step 4 (Build), not just step 7 (Finish) —
  `/code-review` caught that the periodic-recheck rule for long-running
  sessions had no trigger point in the file sessions actually read during
  Build.

## Rejected

None yet.

## Blockers

None.

## Where to look

- `docs/product/README.md:Branch flow` — bullet list this extends.
- `harness/AGENTS.md:Loop` step 7 (Finish) — pointer added.
